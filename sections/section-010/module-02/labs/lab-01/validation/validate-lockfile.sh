#!/usr/bin/env bash
# PASS when package-lock.json is in step with package.json, installed once, and node_modules matches it.
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

perses_call() {
  # perses_call METHOD PATH [JSON]: calls the Perses API from the tester pod.
  # Prints the response body, then the HTTP status code on the last line.
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | kubectl -n observability exec -i deploy/tester -- \
      curl -s -w '\n%{http_code}' -X "$method" -H 'Content-Type: application/json' \
      --data-binary @- "http://perses.perses.svc.cluster.local:8080$path"
  else
    kubectl -n observability exec deploy/tester -- \
      curl -s -w '\n%{http_code}' -X "$method" "http://perses.perses.svc.cluster.local:8080$path"
  fi
}
http_code() { tail -n 1; }
builder_sh() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $1"; }
# send_to_pod NAMESPACE DEPLOYMENT LOCAL_FILE DESTINATION: writes a local file
# into the pod. kubectl exec -i can drop the end of stdin (a file then arrives
# short or empty), so the sizes are compared and the copy is repeated.
send_to_pod() {
  local want got
  want="$(wc -c < "$3" | tr -d ' ')"
  for _ in 1 2 3 4 5; do
    kubectl -n "$1" exec -i "deploy/$2" -- sh -c "mkdir -p \"\$(dirname '$4')\" && cat > '$4'" < "$3" &&
      got="$(kubectl -n "$1" exec "deploy/$2" -- sh -c "wc -c < '$4'" | tr -d ' ')" &&
      [ "$got" = "$want" ] && return 0
    sleep 1
  done
  echo "ERROR: $3 did not arrive whole at $2:$4." >&2
  return 1
}
put_app_file() {
  # put_app_file LOCAL_FILE PATH_IN_APP
  send_to_pod embed app-builder "$1" "/workspace/app/$2"
}
plugin_sh() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $1"; }
put_plugin_file() {
  # put_plugin_file LOCAL_FILE PATH_IN_MODULE
  send_to_pod perses plugin-builder "$1" "/workspace/status-badge/$2"
}
app_get() { kubectl -n observability exec deploy/tester -- curl -s "http://app.localtest.me:8081$1"; }

OUT="$(kubectl -n embed exec -i deploy/app-builder -- sh -c 'cd /workspace/app && node -' <<'JS'
const fs = require('fs');
const { execSync } = require('child_process');
const wrong = [];
if (!fs.existsSync('package-lock.json')) { console.log('WRONG package-lock.json is missing: run npm install'); process.exit(0); }
const lock = JSON.parse(fs.readFileSync('package-lock.json', 'utf8'));
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
if (lock.lockfileVersion !== 3) wrong.push(`lockfileVersion is ${lock.lockfileVersion}, expected 3`);
const root = (lock.packages || {})[''] || {};
for (const field of ['dependencies', 'devDependencies']) {
  const a = JSON.stringify(Object.entries(root[field] || {}).sort());
  const b = JSON.stringify(Object.entries(pkg[field] || {}).sort());
  if (a !== b) wrong.push(`package-lock.json ${field} differ from package.json: run npm install`);
}
const core = ['client', 'components', 'plugin-system', 'dashboards', 'explore'];
for (const name of core) {
  const paths = Object.keys(lock.packages || {}).filter((p) => p.endsWith('node_modules/@perses-dev/' + name));
  if (paths.length !== 1) wrong.push(`@perses-dev/${name} has ${paths.length} entries in the lockfile`);
  else if (lock.packages[paths[0]].version !== '0.54.0') wrong.push(`@perses-dev/${name} is locked at ${lock.packages[paths[0]].version}`);
}
if (!fs.existsSync('node_modules/.package-lock.json')) wrong.push('node_modules is missing: run npm ci');
let raw;
try { raw = execSync('npm ls --all --json', { stdio: ['ignore', 'pipe', 'ignore'] }).toString(); }
catch (error) { raw = error.stdout ? error.stdout.toString() : '{}'; }
const problems = (JSON.parse(raw || '{}').problems) || [];
if (problems.length) wrong.push(`npm ls reports ${problems.length} problem(s), first: ${problems[0]}`);
console.log(wrong.length ? 'WRONG ' + wrong.slice(0, 4).join('; ') : 'OK');
JS
)"
case "$OUT" in
  OK) echo "PASS: the lockfile matches package.json and holds one copy of each core Perses package." ; exit 0 ;;
  *) echo "FAIL: ${OUT#WRONG }" ; exit 1 ;;
esac

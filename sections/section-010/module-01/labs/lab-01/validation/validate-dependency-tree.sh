#!/usr/bin/env bash
# PASS when npm reports no dependency problems and only one version of each core Perses package is installed.
set -uo pipefail

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
if (!fs.existsSync('node_modules')) { console.log('WRONG node_modules is missing: run npm install'); process.exit(0); }
for (const file of ['.npmrc', process.env.HOME + '/.npmrc']) {
  if (fs.existsSync(file) && /legacy-peer-deps|force/.test(fs.readFileSync(file, 'utf8'))) {
    console.log(`WRONG ${file} turns off peer dependency checks`); process.exit(0);
  }
}
let raw;
try { raw = execSync('npm ls --all --json', { stdio: ['ignore', 'pipe', 'ignore'] }).toString(); }
catch (error) { raw = error.stdout ? error.stdout.toString() : '{}'; }
const tree = JSON.parse(raw || '{}');
const problems = tree.problems || [];
const watched = ['@perses-dev/client', '@perses-dev/components', '@perses-dev/plugin-system', '@perses-dev/dashboards'];
const seen = {};
(function walk(node) {
  for (const [name, child] of Object.entries(node.dependencies || {})) {
    if (watched.includes(name) && child.version) (seen[name] = seen[name] || new Set()).add(child.version);
    walk(child);
  }
})(tree);
const wrong = [];
if (problems.length) wrong.push(`npm ls reports ${problems.length} problem(s), first: ${problems[0]}`);
for (const name of watched) {
  const versions = [...(seen[name] || [])];
  if (versions.length !== 1 || versions[0] !== '0.54.0') wrong.push(`${name} installed as ${versions.join(', ') || 'nothing'}`);
}
console.log(wrong.length ? 'WRONG ' + wrong.join('; ') : 'OK');
JS
)"
case "$OUT" in
  OK) echo "PASS: one version of each core Perses package, and no npm problems." ; exit 0 ;;
  *) echo "FAIL: ${OUT#WRONG }" ; exit 1 ;;
esac

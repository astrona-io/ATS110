#!/usr/bin/env bash
# PASS when package.json uses exact versions only and /workspace/app/.npmrc sets save-exact without turning peer checks off.
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
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
const expected = {"@perses-dev/client": "0.54.0", "@perses-dev/components": "0.54.0", "@perses-dev/dashboards": "0.54.0", "@perses-dev/explore": "0.54.0", "@perses-dev/plugin-system": "0.54.0", "@perses-dev/spec": "0.2.0", "@perses-dev/prometheus-plugin": "0.58.0", "@perses-dev/timeseries-chart-plugin": "0.13.0", "@perses-dev/stat-chart-plugin": "0.13.0", "react": "18.3.1", "react-dom": "18.3.1", "echarts": "5.5.0"};
const all = Object.assign({}, pkg.dependencies || {}, pkg.devDependencies || {});
const wrong = [];
for (const [name, version] of Object.entries(all)) {
  if (!/^\d+\.\d+\.\d+$/.test(version)) wrong.push(`${name} is "${version}", not an exact version`);
}
for (const [name, version] of Object.entries(expected)) {
  if (all[name] !== version) wrong.push(`${name} is ${all[name] || 'missing'}, expected ${version}`);
}
let npmrc = '';
try { npmrc = fs.readFileSync('.npmrc', 'utf8'); } catch (error) { wrong.push('.npmrc is missing in /workspace/app'); }
if (npmrc && !/^\s*save-exact\s*=\s*true\s*$/m.test(npmrc)) wrong.push('.npmrc does not set save-exact=true');
if (/legacy-peer-deps|force/.test(npmrc)) wrong.push('.npmrc turns off peer dependency checks');
console.log(wrong.length ? 'WRONG ' + wrong.slice(0, 4).join('; ') + (wrong.length > 4 ? ` (and ${wrong.length - 4} more)` : '') : 'OK');
JS
)"
case "$OUT" in
  OK) echo "PASS: every dependency is an exact version, and .npmrc sets save-exact=true." ; exit 0 ;;
  *) echo "FAIL: ${OUT#WRONG }" ; exit 1 ;;
esac

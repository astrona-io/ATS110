#!/usr/bin/env bash
# PASS when package.json pins every Perses package, React and ECharts to the versions that match Perses v0.54.0.
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
put_app_file() {
  # put_app_file LOCAL_FILE PATH_IN_APP
  kubectl -n embed exec -i deploy/app-builder -- sh -c "mkdir -p \"\$(dirname '/workspace/app/$2')\" && cat > '/workspace/app/$2'" < "$1"
}
plugin_sh() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $1"; }
put_plugin_file() {
  # put_plugin_file LOCAL_FILE PATH_IN_MODULE
  kubectl -n perses exec -i deploy/plugin-builder -- sh -c "mkdir -p \"\$(dirname '/workspace/status-badge/$2')\" && cat > '/workspace/status-badge/$2'" < "$1"
}
app_get() { kubectl -n observability exec deploy/tester -- curl -s "http://app.localtest.me:8081$1"; }

OUT="$(kubectl -n embed exec -i deploy/app-builder -- sh -c 'cd /workspace/app && node -' <<'JS'
const pkg = require('./package.json');
const expected = {"@perses-dev/client": "0.54.0", "@perses-dev/components": "0.54.0", "@perses-dev/dashboards": "0.54.0", "@perses-dev/explore": "0.54.0", "@perses-dev/plugin-system": "0.54.0", "@perses-dev/spec": "0.2.0", "@perses-dev/prometheus-plugin": "0.58.0", "@perses-dev/timeseries-chart-plugin": "0.13.0", "@perses-dev/stat-chart-plugin": "0.13.0", "react": "18.3.1", "react-dom": "18.3.1", "echarts": "5.5.0"};
const all = Object.assign({}, pkg.dependencies || {}, pkg.devDependencies || {});
const wrong = Object.entries(expected).filter(([name, version]) => all[name] !== version)
  .map(([name, version]) => `${name} is ${all[name] || 'missing'}, expected ${version}`);
if (all['@perses-dev/core']) wrong.push('@perses-dev/core is deprecated; the app must not depend on it');
console.log(wrong.length ? 'WRONG ' + wrong.join('; ') : 'OK');
JS
)"
case "$OUT" in
  OK) echo "PASS: package.json pins the expected versions." ; exit 0 ;;
  *) echo "FAIL: ${OUT#WRONG }" ; exit 1 ;;
esac

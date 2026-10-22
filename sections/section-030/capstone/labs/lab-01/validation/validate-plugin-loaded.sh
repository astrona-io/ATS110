#!/usr/bin/env bash
# PASS when Perses lists the plugin module StatusBadge 0.2.0 once, and still lists the plugins that ship with it.
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

LIST="$(kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses.svc.cluster.local:8080/api/v1/plugins')"
VERSIONS="$(printf '%s' "$LIST" | kubectl -n observability exec -i deploy/tester -- \
  jq -r '[.. | objects | select(has("metadata")) | select(.metadata.name? == "StatusBadge") | .metadata.version] | join(",")' 2>/dev/null)"
if [ -z "$VERSIONS" ]; then
  if printf '%s' "$LIST" | grep -q '"StatusBadge"'; then
    VERSIONS="unknown"
  else
    echo "FAIL: /api/v1/plugins does not list StatusBadge. Is the archive mounted and was Perses restarted?"
    exit 1
  fi
fi
if [ "$VERSIONS" != "0.2.0" ] && [ "$VERSIONS" != "unknown" ]; then
  echo "FAIL: Perses lists StatusBadge as version(s) $VERSIONS, expected only 0.2.0."
  exit 1
fi
if ! printf '%s' "$LIST" | grep -q '"TimeSeriesChart"'; then
  echo "FAIL: TimeSeriesChart is gone from /api/v1/plugins: the plugins that ship with Perses must stay."
  exit 1
fi
echo "PASS: Perses loads StatusBadge 0.2.0 next to its own plugins."
exit 0

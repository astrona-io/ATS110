#!/usr/bin/env bash
# PASS when Perses accepts a dashboard with a valid StatusBadge spec and refuses one that breaks the schema.
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

perses_call DELETE /api/v1/projects/inventory/dashboards/grader-badge-valid >/dev/null 2>&1 || true
perses_call DELETE /api/v1/projects/inventory/dashboards/grader-badge-invalid >/dev/null 2>&1 || true

VALID_CODE="$(perses_call POST /api/v1/projects/inventory/dashboards '{"kind":"Dashboard","metadata":{"name":"grader-badge-valid","project":"inventory"},"spec":{"display":{"name":"grader-badge-valid"},"duration":"1h","variables":[],"panels":{"badge":{"kind":"Panel","spec":{"display":{"name":"Badge"},"plugin":{"kind":"StatusBadge","spec":{"label":"Targets up","warning":1,"critical":0,"unit":"targets"}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"count(up == 1)"}}}}]}}},"layouts":[{"kind":"Grid","spec":{"items":[{"x":0,"y":0,"width":6,"height":4,"content":{"$ref":"#/spec/panels/badge"}}]}}]}}' | http_code)"
perses_call DELETE /api/v1/projects/inventory/dashboards/grader-badge-valid >/dev/null 2>&1 || true
case "$VALID_CODE" in
  200|201) ;;
  *) echo "FAIL: Perses refused a dashboard with a valid StatusBadge panel (HTTP $VALID_CODE). Did the schema gain the optional unit field?" ; exit 1 ;;
esac

INVALID_CODE="$(perses_call POST /api/v1/projects/inventory/dashboards '{"kind":"Dashboard","metadata":{"name":"grader-badge-invalid","project":"inventory"},"spec":{"display":{"name":"grader-badge-invalid"},"duration":"1h","variables":[],"panels":{"badge":{"kind":"Panel","spec":{"display":{"name":"Badge"},"plugin":{"kind":"StatusBadge","spec":{"label":"Targets up","warning":"high","critical":0}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"count(up == 1)"}}}}]}}},"layouts":[{"kind":"Grid","spec":{"items":[{"x":0,"y":0,"width":6,"height":4,"content":{"$ref":"#/spec/panels/badge"}}]}}]}}' | http_code)"
perses_call DELETE /api/v1/projects/inventory/dashboards/grader-badge-invalid >/dev/null 2>&1 || true
case "$INVALID_CODE" in
  200|201) echo "FAIL: Perses accepted warning: \"high\". The StatusBadge schema is not enforced." ; exit 1 ;;
esac
echo "PASS: Perses validates StatusBadge panels against the plugin schema."
exit 0

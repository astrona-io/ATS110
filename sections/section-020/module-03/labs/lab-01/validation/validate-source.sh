#!/usr/bin/env bash
# PASS when App.tsx loads the saved dashboard and renders it, and the DatasourceApi reads project datasources.
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

check() {
  # check FILE DESCRIPTION PATTERN: the pattern must occur in the file under src/.
  if ! builder_sh "grep -Eq -- '$3' src/$1"; then
    echo "FAIL: src/$1 does not $2."
    exit 1
  fi
}
check App.tsx "request the saved dashboard overview of the project inventory" "/api/v1/projects/inventory/dashboards/overview"
check App.tsx "render DashboardProvider" "<DashboardProvider"
check App.tsx "render the Dashboard component" "<Dashboard( |/)"
check App.tsx "give the dashboard to DatasourceStoreProvider" "DatasourceStoreProvider +dashboardResource"
check App.tsx "give the variables of the dashboard to VariableProvider" "initialVariableDefinitions=[{]dashboard[.]spec[.]variables"
check datasource-api.ts "read the project datasources" "/api/v1/projects/"
check datasource-api.ts "implement getDatasource for a project" "getDatasource *= *async *[(]project"
check datasource-api.ts "implement listDatasources for a project" "listDatasources *= *async *[(]project"
if builder_sh "grep -Eq -- 'directUrl|prometheus.demo|<EmbeddedPanel' src/App.tsx"; then
  echo "FAIL: src/App.tsx still contains a direct Prometheus address or the hard-coded panels."
  exit 1
fi
echo "PASS: App.tsx loads and renders the saved dashboard, and the DatasourceApi reads project datasources."
exit 0

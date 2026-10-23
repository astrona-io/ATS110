#!/usr/bin/env bash
# PASS when a Prometheus query sent to the app's origin reaches Prometheus through nginx and the Perses proxy.
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

ANSWER="$(app_get '/proxy/globaldatasources/prometheus/api/v1/query?query=up')"
if printf '%s' "$ANSWER" | grep -q '"status":"success"'; then
  echo "PASS: /proxy/globaldatasources/prometheus answers through the app's origin."
  exit 0
fi
echo "FAIL: /proxy/globaldatasources/prometheus/api/v1/query on app.localtest.me:8081 did not answer with Prometheus data."
echo "      First bytes of the answer: $(printf '%s' "$ANSWER" | head -c 120)"
exit 1

#!/usr/bin/env bash
# PASS when the query schema has at least two valid and two invalid tests and percli plugin test-schemas passes.
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
  send_to_pod perses plugin-builder "$1" "/workspace/demo-series/$2"
}
app_get() { kubectl -n observability exec deploy/tester -- curl -s "http://app.localtest.me:8081$1"; }

COUNT_VALID="$(plugin_sh "ls demo-series/schemas/queries/static-series/tests/valid/*.json 2>/dev/null | wc -l" | tr -d ' ')"
COUNT_INVALID="$(plugin_sh "ls demo-series/schemas/queries/static-series/tests/invalid/*.json 2>/dev/null | wc -l" | tr -d ' ')"
case "$COUNT_VALID" in ''|*[!0-9]*) COUNT_VALID=0 ;; esac
case "$COUNT_INVALID" in ''|*[!0-9]*) COUNT_INVALID=0 ;; esac
if [ "$COUNT_VALID" -lt 2 ] || [ "$COUNT_INVALID" -lt 2 ]; then
  echo "FAIL: found $COUNT_VALID valid and $COUNT_INVALID invalid tests in schemas/queries/static-series/tests; at least 2 of each are needed."
  exit 1
fi
if ! OUT="$(plugin_sh "cd demo-series && percli plugin test-schemas" 2>&1)"; then
  echo "FAIL: percli plugin test-schemas reported a failure:"
  echo "$OUT" | tail -n 15
  exit 1
fi
if ! echo "$OUT" | grep -q "SUCCESS"; then
  echo "FAIL: percli plugin test-schemas printed no success line:"
  echo "$OUT" | tail -n 15
  exit 1
fi
echo "PASS: $COUNT_VALID valid and $COUNT_INVALID invalid tests, and percli plugin test-schemas passes."
exit 0

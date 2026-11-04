#!/usr/bin/env bash
# PASS when the query schema accepts every hidden valid case and rejects every hidden invalid case.
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

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/valid-plain.json" <<'SOURCEFILE'
{"kind":"StaticSeries","spec":{"query": "up"}}
SOURCEFILE
cat > "$WORK/valid-with-ds.json" <<'SOURCEFILE'
{"kind":"StaticSeries","spec":{"query": "up","datasource":{"kind":"DemoSource"}}}
SOURCEFILE
cat > "$WORK/valid-long-query.json" <<'SOURCEFILE'
{"kind":"StaticSeries","spec":{"query": "sum(rate(http_requests_total[5m]))"}}
SOURCEFILE
cat > "$WORK/invalid-empty-query.json" <<'SOURCEFILE'
{"kind":"StaticSeries","spec":{"query": ""}}
SOURCEFILE
cat > "$WORK/invalid-no-query.json" <<'SOURCEFILE'
{"kind":"StaticSeries","spec":{}}
SOURCEFILE
cat > "$WORK/invalid-old-placeholder.json" <<'SOURCEFILE'
{"kind":"StaticSeries","spec":{"query": "up","datasource":{"kind":"YourDatasourceKind"}}}
SOURCEFILE
cat > "$WORK/invalid-other-ds.json" <<'SOURCEFILE'
{"kind":"StaticSeries","spec":{"query": "up","datasource":{"kind":"PrometheusDatasource"}}}
SOURCEFILE
cat > "$WORK/invalid-extra-field.json" <<'SOURCEFILE'
{"kind":"StaticSeries","spec":{"query": "up","step":"15s"}}
SOURCEFILE
cat > "$WORK/invalid-query-number.json" <<'SOURCEFILE'
{"kind":"StaticSeries","spec":{"query": 5}}
SOURCEFILE

plugin_sh "rm -rf /tmp/grade && mkdir -p /tmp/grade && cp -r demo-series/schemas demo-series/cue.mod demo-series/package.json /tmp/grade/ && rm -rf /tmp/grade/schemas/queries/static-series/tests && mkdir -p /tmp/grade/schemas/queries/static-series/tests/valid /tmp/grade/schemas/queries/static-series/tests/invalid"
for f in "$WORK"/valid-*.json; do
  send_to_pod perses plugin-builder "$f" "/tmp/grade/schemas/queries/static-series/tests/valid/$(basename "$f")" || exit 1
done
for f in "$WORK"/invalid-*.json; do
  send_to_pod perses plugin-builder "$f" "/tmp/grade/schemas/queries/static-series/tests/invalid/$(basename "$f")" || exit 1
done
if ! OUT="$(plugin_sh "percli plugin test-schemas --plugin.path /tmp/grade" 2>&1)"; then
  echo "FAIL: the query schema does not behave as required on the grader's cases:"
  echo "$OUT" | command grep -v "^✓" | tail -n 15
  plugin_sh "rm -rf /tmp/grade" >/dev/null 2>&1 || true
  exit 1
fi
plugin_sh "rm -rf /tmp/grade" >/dev/null 2>&1 || true
echo "PASS: the query schema accepts all 3 valid cases and rejects all 6 invalid cases of the grader."
exit 0

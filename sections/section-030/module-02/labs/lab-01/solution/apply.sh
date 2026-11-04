#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the environment stays as the seed left it.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail
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
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"

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

cat > "$WORK/status-badge.cue" <<'SOURCEFILE'
package model

import "strings"

kind: "StatusBadge"
spec: close({
	label:    strings.MinRunes(1) & strings.MaxRunes(40)
	warning:  number & >=0
	critical: number & >=0
	format?:  *"number" | "percent"
})
SOURCEFILE
put_plugin_file "$WORK/status-badge.cue" schemas/panels/status-badge/status-badge.cue

cat > "$WORK/basic.json" <<'SOURCEFILE'
{"kind":"StatusBadge","spec":{"label": "Targets up","warning": 1,"critical": 0}}
SOURCEFILE
put_plugin_file "$WORK/basic.json" schemas/panels/status-badge/tests/valid/basic.json
cat > "$WORK/zero-limits.json" <<'SOURCEFILE'
{"kind":"StatusBadge","spec":{"label": "Targets up","warning": 0,"critical": 0}}
SOURCEFILE
put_plugin_file "$WORK/zero-limits.json" schemas/panels/status-badge/tests/valid/zero-limits.json
cat > "$WORK/percent.json" <<'SOURCEFILE'
{"kind":"StatusBadge","spec":{"label": "Targets up","warning": 1,"critical": 0,"format":"percent"}}
SOURCEFILE
put_plugin_file "$WORK/percent.json" schemas/panels/status-badge/tests/valid/percent.json
cat > "$WORK/empty-label.json" <<'SOURCEFILE'
{"kind":"StatusBadge","spec":{"label": "","warning": 1,"critical": 0}}
SOURCEFILE
put_plugin_file "$WORK/empty-label.json" schemas/panels/status-badge/tests/invalid/empty-label.json
cat > "$WORK/negative-warning.json" <<'SOURCEFILE'
{"kind":"StatusBadge","spec":{"label": "Targets up","warning": -1,"critical": 0}}
SOURCEFILE
put_plugin_file "$WORK/negative-warning.json" schemas/panels/status-badge/tests/invalid/negative-warning.json
cat > "$WORK/bad-format.json" <<'SOURCEFILE'
{"kind":"StatusBadge","spec":{"label": "Targets up","warning": 1,"critical": 0,"format":"bytes"}}
SOURCEFILE
put_plugin_file "$WORK/bad-format.json" schemas/panels/status-badge/tests/invalid/bad-format.json
cat > "$WORK/extra-field.json" <<'SOURCEFILE'
{"kind":"StatusBadge","spec":{"label": "Targets up","warning": 1,"critical": 0,"colour":"red"}}
SOURCEFILE
put_plugin_file "$WORK/extra-field.json" schemas/panels/status-badge/tests/invalid/extra-field.json
cat > "$WORK/missing-critical.json" <<'SOURCEFILE'
{"kind":"StatusBadge","spec":{"label": "Targets up","warning": 1}}
SOURCEFILE
put_plugin_file "$WORK/missing-critical.json" schemas/panels/status-badge/tests/invalid/missing-critical.json

plugin_sh "cd status-badge && percli plugin test-schemas"
plugin_sh "cd status-badge && percli plugin lint"
echo "[solution] Schema tightened, tests added, and the checks pass."

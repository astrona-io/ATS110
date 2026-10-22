#!/usr/bin/env bash
# PASS when the app was built after /workspace/app/src/App.tsx last changed and nginx serves its page and JavaScript.
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

if ! builder_sh "test -s /srv/dist/index.html && test -n \"\$(find /srv/dist/index.html -newer /workspace/app/src/App.tsx)\"" ; then
  echo "FAIL: /srv/dist/index.html is missing or older than /workspace/app/src/App.tsx. Build and deploy the app again."
  exit 1
fi

PAGE="$(app_get /)"
if ! printf '%s' "$PAGE" | grep -q 'id="root"'; then
  echo "FAIL: http://app.localtest.me:8081/ does not serve the app page."
  exit 1
fi
SCRIPT_PATH="$(printf '%s' "$PAGE" | grep -o 'src="/assets/[^"]*\.js"' | head -n 1 | sed 's/^src="//; s/"$//')"
if [ -z "$SCRIPT_PATH" ]; then
  echo "FAIL: the page does not load a script from /assets/. Check the base path in vite.config.ts."
  exit 1
fi
SCRIPT="$(app_get "$SCRIPT_PATH")"
case "$SCRIPT" in
  "<"*) echo "FAIL: $SCRIPT_PATH answers with HTML, not JavaScript." ; exit 1 ;;
esac
if ! printf '%s' "$SCRIPT" | grep -q 'StatChart'; then
  echo "FAIL: the served script does not contain StatChart."
  exit 1
fi
echo "PASS: the built app is served at http://app.localtest.me:8081/."
exit 0

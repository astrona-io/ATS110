#!/usr/bin/env bash
# Creates the starting state for ats-110-capstone-020.
#
# The fix is NOT applied here: producing it is the task.
set -euo pipefail

HELM_VERSION="3.22.1"
PERSES_VERSION="0.54.0"
PERSES_CHART_VERSION="0.23.3"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT


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

echo "[env] Installing the app's npm packages and building it (several minutes)..."
builder_sh "npm install --no-audit --no-fund"
builder_sh "npm run build && npm run deploy"

echo "[lab] Replacing the GlobalDatasource prometheus with one called metrics that is not the default..."
perses_call DELETE /api/v1/globaldatasources/prometheus >/dev/null || true
perses_call POST /api/v1/globaldatasources '{"kind":"GlobalDatasource","metadata":{"name":"metrics"},"spec":{"default":false,"plugin":{"kind":"PrometheusDatasource","spec":{"proxy":{"kind":"HTTPProxy","spec":{"url":"http://prometheus.observability:9090"}}}}}}' >/dev/null || true

echo "[lab] Starting state ready."

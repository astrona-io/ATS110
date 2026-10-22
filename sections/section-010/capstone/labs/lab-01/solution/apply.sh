#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the environment stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail
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

cat > "$WORK/package.json" <<'SOURCEFILE'
{
  "name": "inventory-dashboard-app",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "build": "vite build",
    "typecheck": "tsc --noEmit",
    "deploy": "rm -rf /srv/dist/* && cp -r dist/. /srv/dist/"
  },
  "dependencies": {
    "@emotion/react": "11.14.0",
    "@emotion/styled": "11.14.1",
    "@hookform/resolvers": "3.10.0",
    "@mui/material": "6.5.0",
    "@perses-dev/client": "0.54.0",
    "@perses-dev/components": "0.54.0",
    "@perses-dev/dashboards": "0.54.0",
    "@perses-dev/explore": "0.54.0",
    "@perses-dev/plugin-system": "0.54.0",
    "@perses-dev/prometheus-plugin": "0.58.0",
    "@perses-dev/spec": "0.2.0",
    "@perses-dev/stat-chart-plugin": "0.13.0",
    "@perses-dev/timeseries-chart-plugin": "0.13.0",
    "@tanstack/react-query": "4.44.0",
    "date-fns": "4.4.0",
    "date-fns-tz": "3.2.0",
    "echarts": "5.5.0",
    "immer": "10.2.0",
    "lodash": "4.18.1",
    "react": "18.3.1",
    "react-dom": "18.3.1",
    "react-hook-form": "7.90.0",
    "react-router-dom": "6.30.6",
    "use-resize-observer": "9.1.0"
  },
  "devDependencies": {
    "@types/react": "18.3.31",
    "@types/react-dom": "18.3.7",
    "@vitejs/plugin-react": "4.7.0",
    "typescript": "5.9.3",
    "vite": "6.4.5"
  }
}
SOURCEFILE
cat > "$WORK/vite.config.ts" <<'SOURCEFILE'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  base: '/',
  build: {
    outDir: 'dist',
    chunkSizeWarningLimit: 8192,
  },
});
SOURCEFILE
put_app_file "$WORK/package.json" package.json
put_app_file "$WORK/vite.config.ts" vite.config.ts
builder_sh "rm -rf node_modules package-lock.json && npm install --no-audit --no-fund"
builder_sh "npm run build && npm run deploy"

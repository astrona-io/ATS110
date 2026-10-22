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

cat > "$WORK/datasource-api.ts" <<'SOURCEFILE'
import {
  BuildDatasourceProxyUrlParams,
  DatasourceApi,
  DatasourceResource,
  GlobalDatasourceResource,
} from '@perses-dev/client';
import { DatasourceSelector } from '@perses-dev/spec';

// nginx serves this app and forwards /api/ and /proxy/ to the Perses server,
// so every request below goes to the same origin as the page.
async function getJson<T>(path: string): Promise<T> {
  const response = await fetch(path);
  if (!response.ok) {
    throw new Error(`${path} answered ${response.status}`);
  }
  return (await response.json()) as T;
}

export class PersesDatasourceApi implements DatasourceApi {
  // The same URL layout the Perses server uses for its datasource proxy.
  buildProxyUrl = ({ project, dashboard, name }: BuildDatasourceProxyUrlParams): string => {
    let url = `${!project && !dashboard ? 'globaldatasources' : 'datasources'}/${encodeURIComponent(name)}`;
    if (dashboard) {
      url = `dashboards/${encodeURIComponent(dashboard)}/${url}`;
    }
    if (project) {
      url = `projects/${encodeURIComponent(project)}/${url}`;
    }
    return `/proxy/${url}`;
  };

  getDatasource = async (): Promise<DatasourceResource | undefined> => undefined;

  listDatasources = async (): Promise<DatasourceResource[]> => [];

  listGlobalDatasources = async (pluginKind?: string): Promise<GlobalDatasourceResource[]> => {
    const all = await getJson<GlobalDatasourceResource[]>('/api/v1/globaldatasources');
    return pluginKind ? all.filter((datasource) => datasource.spec.plugin.kind === pluginKind) : all;
  };

  getGlobalDatasource = async (selector: DatasourceSelector): Promise<GlobalDatasourceResource | undefined> => {
    const all = await this.listGlobalDatasources(selector.kind);
    return all.find((datasource) =>
      selector.name ? datasource.metadata.name === selector.name : datasource.spec.default,
    );
  };
}
SOURCEFILE
cat > "$WORK/default.conf" <<'SOURCEFILE'
# nginx serves the built app and forwards the Perses API and the datasource
# proxy to the Perses server, so the browser only talks to one origin.
server {
    listen 80;
    root /usr/share/nginx/html;

    location / {
        try_files $uri /index.html;
    }

    location /api/ {
        proxy_pass http://perses.perses.svc.cluster.local:8080;
    }

    location /proxy/ {
        proxy_pass http://perses.perses.svc.cluster.local:8080;
    }
}
SOURCEFILE
put_app_file "$WORK/datasource-api.ts" src/datasource-api.ts
builder_sh "npm run build && npm run deploy"

kubectl -n embed create configmap embed-app-nginx --from-file=default.conf="$WORK/default.conf" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n embed rollout restart deployment/embed-app
kubectl -n embed rollout status deployment/embed-app --timeout=120s

perses_call POST /api/v1/globaldatasources '{"kind":"GlobalDatasource","metadata":{"name":"prometheus"},"spec":{"default":true,"plugin":{"kind":"PrometheusDatasource","spec":{"proxy":{"kind":"HTTPProxy","spec":{"url":"http://prometheus.observability:9090"}}}}}}' >/dev/null

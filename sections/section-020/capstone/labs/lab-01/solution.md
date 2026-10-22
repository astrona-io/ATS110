# Solution: Make An Embedded Dashboard Show Data

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

There are three independent faults, one in each component between the browser and Prometheus: the app builds the wrong proxy URL, nginx does not forward `/proxy/`, and Perses has no default Prometheus datasource called `prometheus`.

## Step 1: Follow one query from the app's origin

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s 'http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/query?query=up' | head -c 200
```

The answer starts with `<!doctype html>`: nginx answered with the app's `index.html` instead of forwarding the request. Look at the nginx configuration:

```sh
kubectl -n embed get configmap embed-app-nginx -o jsonpath='{.data.default\.conf}'
```

There is a `location /api/` block but no `location /proxy/` block. So every `/proxy/` path falls through to `try_files` and returns `index.html`.

## Step 2: Give nginx its proxy route back

Save this as `default.conf`:

```nginx
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
```

Apply it to the ConfigMap and restart nginx so it reads the new file:

```sh
kubectl -n embed create configmap embed-app-nginx --from-file=default.conf=default.conf \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n embed rollout restart deployment/embed-app
kubectl -n embed rollout status deployment/embed-app
```

## Step 3: Check the datasource in Perses

Send the same query again:

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s 'http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/query?query=up'
kubectl -n observability exec deploy/tester -- curl -s http://app.localtest.me:8081/api/v1/globaldatasources
```

Now Perses answers, with an error that the datasource `prometheus` does not exist. The list shows one global datasource, `metrics`, with `default: false`. The app looks for the default Prometheus datasource, and there is none. Recreate `prometheus` as the default, next to `metrics`. Save this as `globaldatasource-prometheus.json`:

```json
{"kind":"GlobalDatasource","metadata":{"name":"prometheus"},"spec":{"default":true,"plugin":{"kind":"PrometheusDatasource","spec":{"proxy":{"kind":"HTTPProxy","spec":{"url":"http://prometheus.observability:9090"}}}}}}
```

Apply it with `percli`, through a port-forward to Perses in a second terminal (`kubectl -n perses port-forward svc/perses 8080:8080`):

```sh
percli login http://perses.localtest.me:8080
percli apply -f globaldatasource-prometheus.json
```

The query through the app's origin now returns `"status":"success"`.

## Step 4: Fix the proxy URL in the app

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
builder "grep -n -A3 'buildProxyUrl' src/datasource-api.ts"
```

`buildProxyUrl` returns `http://prometheus.observability:9090`, a cluster-internal address the browser cannot reach. Replace the file with the version that returns `/proxy/...` URLs. Save this as `datasource-api.ts`:

```typescript
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
```

Copy it in, build and deploy:

```sh
copy_to_builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cat > /workspace/app/$2" < "$1"; }
copy_to_builder datasource-api.ts src/datasource-api.ts
builder "npm run build && npm run deploy"
```

With `kubectl -n embed port-forward svc/embed-app 8081:8081` running, both panels at `http://app.localtest.me:8081` show data.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Rename `metrics` to `prometheus` by deleting it | Works for the app, but removes a datasource other users may rely on; the task asks you to keep it |
| Point `buildProxyUrl` at the Prometheus Service through a new nginx route | The browser still bypasses Perses and its datasource configuration; the grader rejects direct addresses |
| Only fix nginx | Queries then reach Perses, which still has no default datasource called `prometheus` |

# A DatasourceApi That Uses The Perses Proxy

The guide's app answers every datasource lookup with one object it wrote into its own code. A real application should use what Perses already knows: the datasources an administrator configured, with their credentials kept on the server. And the browser should never need to reach Prometheus itself. Both goals meet in one interface, `DatasourceApi`, which this part implements against the Perses server.

## What the interface asks for

`DatasourceStoreProvider` does not fetch datasources itself. It calls an object you give it, and that object must implement the `DatasourceApi` interface from `@perses-dev/client`. The interface has four required functions and one optional one:

| Function | What it returns |
| --- | --- |
| `getDatasource(project, selector)` | One datasource of a project |
| `getGlobalDatasource(selector)` | One global datasource, chosen by name or by being the default |
| `listDatasources(project, pluginKind?)` | All datasources of a project, optionally of one plugin kind |
| `listGlobalDatasources(pluginKind?)` | All global datasources, optionally of one plugin kind |
| `buildProxyUrl({ project, dashboard, name })` | The URL that queries for this datasource are sent to (optional) |

A **selector** names the datasource plugin kind, for example `PrometheusDatasource`, and optionally a datasource name. Without a name, the default datasource of that kind is meant. The official guide imports this interface from `@perses-dev/dashboards`; in the 0.54.0 packages it is exported by `@perses-dev/client`.

## Ask Perses through the app's origin

The app is served by nginx, and nginx forwards `/api/` and `/proxy/` to Perses. So the app can call the Perses API on its own origin. Send the same request from the `tester` pod, to the app's address:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- curl -s http://app.localtest.me:8081/api/v1/globaldatasources
```

The answer is a JSON list with one `GlobalDatasource`, named `prometheus`. Its `spec.default` is `true`, its plugin kind is `PrometheusDatasource`, and its plugin spec has a `proxy` of kind `HTTPProxy` with the URL `http://prometheus.observability:9090`. There is no `directUrl`: this datasource is meant to be reached through Perses.

The Perses **proxy** is the server endpoint that forwards a query to the datasource. For a global datasource, its path is `/proxy/globaldatasources/<name>/`, followed by the datasource's own API path. Send a Prometheus query through it, again on the app's origin:

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s 'http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/query?query=up'
```

The answer is Prometheus' own JSON, with `"status":"success"` and one result for the job `prometheus`. Three components handled that request: nginx forwarded it to Perses, Perses looked up the datasource `prometheus`, and the Perses proxy forwarded it to Prometheus. The browser only ever sees the app's origin.

## Write the DatasourceApi

The implementation below reads global datasources from `/api/v1/globaldatasources`, picks one by name or by `spec.default`, and builds proxy URLs in the same layout the Perses server uses. Project datasources return nothing here, because the app only uses the global one. Save this as `datasource-api.ts`:

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

The functions are arrow functions assigned to properties, not class methods. `DatasourceStoreProvider` stores and calls them later, and an arrow function keeps the right `this` however it is called.

Now replace the app's fake datasource with this one. The new `App.tsx` imports `PersesDatasourceApi`; the providers stay as the guide wrote them. Save this as `App.tsx`:

```tsx
import { ReactElement, useMemo, useState } from 'react';
import { ThemeProvider } from '@mui/material';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ChartsProvider, generateChartsTheme, getTheme, SnackbarProvider } from '@perses-dev/components';
import {
  DataQueriesProvider,
  dynamicImportPluginLoader,
  PluginRegistry,
  TimeRangeProvider,
} from '@perses-dev/plugin-system';
import { DatasourceStoreProvider, Panel, VariableProvider } from '@perses-dev/dashboards';
import { DashboardResource } from '@perses-dev/client';
import { DurationString, TimeRangeValue } from '@perses-dev/spec';
import * as prometheusPlugin from '@perses-dev/prometheus-plugin';
import * as timeseriesChartPlugin from '@perses-dev/timeseries-chart-plugin';
import { PersesDatasourceApi } from './datasource-api';

const datasourceApi = new PersesDatasourceApi();
// The providers expect a dashboard resource; an empty one is enough for panels outside a dashboard.
const embeddedDashboard = { kind: 'Dashboard', metadata: {}, spec: {} } as DashboardResource;

const pluginLoader = dynamicImportPluginLoader([
  { resource: prometheusPlugin.getPluginModule(), importPlugin: () => Promise.resolve(prometheusPlugin) },
  { resource: timeseriesChartPlugin.getPluginModule(), importPlugin: () => Promise.resolve(timeseriesChartPlugin) },
]);

const queryClient = new QueryClient({
  defaultOptions: { queries: { refetchOnWindowFocus: false, retry: 0 } },
});

export default function App(): ReactElement {
  const [timeRange, setTimeRange] = useState<TimeRangeValue>({ pastDuration: '30m' });
  const [refreshInterval, setRefreshInterval] = useState<DurationString>('30s');
  const muiTheme = useMemo(() => getTheme('light'), []);
  const chartsTheme = useMemo(() => generateChartsTheme(muiTheme, {}), [muiTheme]);

  return (
    <ThemeProvider theme={muiTheme}>
      <ChartsProvider chartsTheme={chartsTheme}>
        <SnackbarProvider anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} variant="default" content="">
          <PluginRegistry
            pluginLoader={pluginLoader}
            defaultPluginKinds={{ Panel: 'TimeSeriesChart', TimeSeriesQuery: 'PrometheusTimeSeriesQuery' }}
          >
            <QueryClientProvider client={queryClient}>
              <TimeRangeProvider
                timeRange={timeRange}
                refreshInterval={refreshInterval}
                setTimeRange={setTimeRange}
                setRefreshInterval={setRefreshInterval}
              >
                <VariableProvider>
                  <DatasourceStoreProvider dashboardResource={embeddedDashboard} datasourceApi={datasourceApi}>
                    <div style={{ height: 320, padding: 16 }}>
                      <DataQueriesProvider
                        definitions={[{ kind: 'PrometheusTimeSeriesQuery', spec: { query: 'up{job="prometheus"}' } }]}
                      >
                        <Panel
                          panelOptions={{ hideHeader: false }}
                          definition={{
                            kind: 'Panel',
                            spec: {
                              display: { name: 'Prometheus target up' },
                              plugin: { kind: 'TimeSeriesChart', spec: { legend: { position: 'bottom', size: 'medium' } } },
                            },
                          }}
                        />
                      </DataQueriesProvider>
                    </div>
                  </DatasourceStoreProvider>
                </VariableProvider>
              </TimeRangeProvider>
            </QueryClientProvider>
          </PluginRegistry>
        </SnackbarProvider>
      </ChartsProvider>
    </ThemeProvider>
  );
}
```

Copy both files into the builder. A second helper sends a file from your machine into the app folder:

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
copy_to_builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cat > /workspace/app/$2" < "$1"; }
copy_to_builder datasource-api.ts src/datasource-api.ts
copy_to_builder App.tsx src/App.tsx
```

## Build and check

Build and deploy, then check that the old address is gone from the built JavaScript and the proxy path is in it:

```sh
builder "npm run build && npm run deploy"
builder "grep -c 'prometheus.demo.do.prometheus.io' /srv/dist/assets/*.js; grep -c '/proxy/' /srv/dist/assets/*.js"
```

The first count is `0` and the second is at least `1`. Start `kubectl -n embed port-forward svc/embed-app 8081:8081` in a second terminal and open `http://app.localtest.me:8081`. The panel "Prometheus target up" shows a line at 1, with data from the Prometheus server in your cluster. Your browser's developer tools show the query requests going to `/proxy/globaldatasources/prometheus/api/v1/query_range` on the app's own address.

You now have an app that uses the datasource configured in Perses and sends every query through the Perses proxy. The open question is how to show more than one panel, with different queries, and how to control the time range they share.

## Common pitfalls

> [!WARNING]
> - **Returning a URL to Prometheus from `buildProxyUrl`.** The browser then has to reach Prometheus itself, which it cannot do from outside the cluster.
> - **Importing `DatasourceApi` from `@perses-dev/dashboards`.** In the 0.54.0 packages it lives in `@perses-dev/client`.
> - **Forwarding `/api/` but not `/proxy/` in nginx.** The datasource is found, but every query returns the app's `index.html` instead of data.
> - **Expecting a datasource that is not the default.** Without a name in the selector, `getGlobalDatasource` looks for `spec.default: true`.

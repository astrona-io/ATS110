# Solution: Embed Two Panels That Query Through Perses

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: a query sent to the app's origin reaches Prometheus through the Perses proxy, the built JavaScript holds both panels and both queries and no longer the demo server, and the build was made after your change to `App.tsx`.

## Step 1: See where the app gets its data

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
builder "grep -n 'directUrl\|buildProxyUrl' src/App.tsx"
```

The app's `FakeDatasourceApi` returns a datasource with `directUrl: 'https://prometheus.demo.do.prometheus.io'`. That address must go.

## Step 2: Check the path the queries will take

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s 'http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/query?query=up'
```

The answer has `"status":"success"`: nginx forwards `/proxy/` to Perses, and Perses forwards to Prometheus. The app only has to build URLs in that layout.

## Step 3: Write the DatasourceApi

Save this as `datasource-api.ts`:

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

## Step 4: Write the two-panel app

Save this as `App.tsx`:

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
import * as statChartPlugin from '@perses-dev/stat-chart-plugin';
import { PersesDatasourceApi } from './datasource-api';

const datasourceApi = new PersesDatasourceApi();
// The providers expect a dashboard resource; an empty one is enough for panels outside a dashboard.
const embeddedDashboard = { kind: 'Dashboard', metadata: {}, spec: {} } as DashboardResource;

const pluginLoader = dynamicImportPluginLoader([
  { resource: prometheusPlugin.getPluginModule(), importPlugin: () => Promise.resolve(prometheusPlugin) },
  { resource: timeseriesChartPlugin.getPluginModule(), importPlugin: () => Promise.resolve(timeseriesChartPlugin) },
  { resource: statChartPlugin.getPluginModule(), importPlugin: () => Promise.resolve(statChartPlugin) },
]);

const queryClient = new QueryClient({
  defaultOptions: { queries: { refetchOnWindowFocus: false, retry: 0 } },
});

function EmbeddedPanel(props: { name: string; query: string; plugin: { kind: string; spec: object } }): ReactElement {
  return (
    <div style={{ height: 300, padding: 16 }}>
      <DataQueriesProvider definitions={[{ kind: 'PrometheusTimeSeriesQuery', spec: { query: props.query } }]}>
        <Panel definition={{ kind: 'Panel', spec: { display: { name: props.name }, plugin: props.plugin } }} />
      </DataQueriesProvider>
    </div>
  );
}

export default function App(): ReactElement {
  const [timeRange, setTimeRange] = useState<TimeRangeValue>({ pastDuration: '1h' });
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
                    <EmbeddedPanel
                      name="HTTP requests per second"
                      query="sum(rate(prometheus_http_requests_total[5m]))"
                      plugin={{ kind: 'TimeSeriesChart', spec: { legend: { position: 'bottom', size: 'medium' } } }}
                    />
                    <EmbeddedPanel
                      name="Targets up"
                      query="count(up == 1)"
                      plugin={{ kind: 'StatChart', spec: { calculation: 'last-number' } }}
                    />
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

## Step 5: Copy, build and deploy

```sh
copy_to_builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cat > /workspace/app/$2" < "$1"; }
copy_to_builder datasource-api.ts src/datasource-api.ts
copy_to_builder App.tsx src/App.tsx
builder "npm run build && npm run deploy"
builder "grep -c 'prometheus.demo.do.prometheus.io' /srv/dist/assets/*.js; grep -c 'count(up == 1)' /srv/dist/assets/*.js"
```

The first count is `0`, the second at least `1`. With `kubectl -n embed port-forward svc/embed-app 8081:8081` running, `http://app.localtest.me:8081` shows "HTTP requests per second" as a line and "Targets up" as the number 1.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set `directUrl` to `http://prometheus.observability:9090` | The browser cannot resolve a cluster-internal name; the grader also rejects the direct address |
| Add `StatChart` to the panel but not to the plugin loader | The panel shows an error that the plugin cannot be found |
| Put both panels in one `DataQueriesProvider` | Both panels draw both queries |

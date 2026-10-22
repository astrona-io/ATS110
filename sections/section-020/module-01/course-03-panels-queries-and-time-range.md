# Panels, Queries And The Time Range

One panel proves the setup works; a useful page shows several. Each panel needs its own queries, but all of them should follow the same time range, and refresh together. This part adds a second panel of another type, and shows which provider controls what when there is more than one panel.

## One query list per panel

`DataQueriesProvider` holds the queries for the components inside it, and `Panel` draws the results it finds there. So each panel gets its own `DataQueriesProvider`. Everything above it, from the theme to the datasource store, stays shared. A small component keeps that pattern in one place:

```tsx
function EmbeddedPanel(props: { name: string; query: string; plugin: { kind: string; spec: object } }): ReactElement {
  return (
    <div style={{ height: 300, padding: 16 }}>
      <DataQueriesProvider definitions={[{ kind: 'PrometheusTimeSeriesQuery', spec: { query: props.query } }]}>
        <Panel definition={{ kind: 'Panel', spec: { display: { name: props.name }, plugin: props.plugin } }} />
      </DataQueriesProvider>
    </div>
  );
}
```

`EmbeddedPanel` takes a title, one PromQL query and the panel plugin with its spec. The `div` gives the panel a height; a panel fills its parent, and a parent without a height leaves it zero pixels tall.

## A second panel type

The second panel shows one number instead of a line. That is the `StatChart` panel plugin, in the package `@perses-dev/stat-chart-plugin`. Its spec needs a `calculation`, which says how to turn a series into one value; `last-number` takes the most recent value. A panel plugin only works if `PluginRegistry` knows it, so the app must import the package and add it to the plugin loader. Check that the package is installed in the builder:

<!-- astrona:playground:renew -->

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
builder npm ls @perses-dev/stat-chart-plugin
```

The tree shows `@perses-dev/stat-chart-plugin@0.13.0`, the version that ships with Perses v0.54.0. It was in `package.json` from the start, but no code imported it yet.

## The time range and the refresh interval

`TimeRangeProvider` holds two values for every panel inside it. The **time range** is either relative, such as `{ pastDuration: '1h' }` for the last hour, or absolute, with a start and an end. The **refresh interval** is how often the queries run again, as a duration string such as `30s`; `0s` turns automatic refresh off. The app keeps both in React state and hands the provider the functions to change them, so a time picker added later only needs to call `setTimeRange`.

Put it together. This version shows a time series of the `up` metric and a single number for `prometheus_tsdb_head_series`, the number of series Prometheus holds in memory, over the last hour, refreshed every 30 seconds. Save this as `App.tsx`:

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
                      name="Target up"
                      query="up"
                      plugin={{ kind: 'TimeSeriesChart', spec: { legend: { position: 'bottom', size: 'medium' } } }}
                    />
                    <EmbeddedPanel
                      name="Series in memory"
                      query="prometheus_tsdb_head_series"
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

The file still needs `datasource-api.ts` next to it, with the `PersesDatasourceApi` class that reads global datasources from Perses and builds `/proxy/` URLs. If the builder does not have it yet, check with `builder ls src`. Copy the new file in, then build and deploy:

```sh
copy_to_builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cat > /workspace/app/$2" < "$1"; }
copy_to_builder App.tsx src/App.tsx
builder "npm run build && npm run deploy"
```

With `kubectl -n embed port-forward svc/embed-app 8081:8081` running, open `http://app.localtest.me:8081`. Two panels stack on the page: "Target up" with a line at 1, and "Series in memory" with one large number. Wait 30 seconds and both update together, because both read the same refresh interval.

## Change the time range for every panel

Change `pastDuration: '1h'` to `'5m'` and rebuild:

```sh
builder "sed -i \"s/pastDuration: '1h'/pastDuration: '5m'/\" src/App.tsx && npm run build && npm run deploy"
```

Reload the page. The time series now covers five minutes, and the stat panel computes its value over the same window. One value in one provider changed both panels.

You can now place several panels with their own queries under one time range and refresh interval, and add a panel plugin the app did not use before. What remains is practice: the lab asks you to build a page like this from the guide's app, with panels and queries it names.

## Common pitfalls

> [!WARNING]
> - **Sharing one `DataQueriesProvider` between two panels.** Both panels then draw the results of the same queries.
> - **Using `StatChart` without adding it to the loader.** The import alone does nothing; `PluginRegistry` must list it.
> - **Leaving out `calculation` in a `StatChart` spec.** The panel cannot reduce a series to one number without it.
> - **A panel in a parent with no height.** The panel fills its parent; give the parent a height.

## Your mission: Embed Two Panels That Query Through Perses

You can now write a `DatasourceApi` for the Perses server and place several panels with their own queries. The graded lab starts from the guide's app with its hard-coded datasource, and asks for a page with two given panels that get their data from the Perses datasource through the proxy.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-110-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-110-lab-020-01
astrona start ats-110-playground-020-01
```

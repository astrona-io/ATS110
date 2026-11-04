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

function pick<T extends { metadata: { name: string }; spec: { default?: boolean } }>(
  datasources: T[],
  selector: DatasourceSelector,
): T | undefined {
  return datasources.find((datasource) =>
    selector.name ? datasource.metadata.name === selector.name : datasource.spec.default,
  );
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

  listDatasources = async (project: string, pluginKind?: string): Promise<DatasourceResource[]> => {
    const all = await getJson<DatasourceResource[]>(`/api/v1/projects/${encodeURIComponent(project)}/datasources`);
    return pluginKind ? all.filter((datasource) => datasource.spec.plugin.kind === pluginKind) : all;
  };

  getDatasource = async (project: string, selector: DatasourceSelector): Promise<DatasourceResource | undefined> => {
    return pick(await this.listDatasources(project, selector.kind), selector);
  };

  listGlobalDatasources = async (pluginKind?: string): Promise<GlobalDatasourceResource[]> => {
    const all = await getJson<GlobalDatasourceResource[]>('/api/v1/globaldatasources');
    return pluginKind ? all.filter((datasource) => datasource.spec.plugin.kind === pluginKind) : all;
  };

  getGlobalDatasource = async (selector: DatasourceSelector): Promise<GlobalDatasourceResource | undefined> => {
    return pick(await this.listGlobalDatasources(selector.kind), selector);
  };
}
SOURCEFILE
cat > "$WORK/App.tsx" <<'SOURCEFILE'
import { ReactElement, useEffect, useMemo, useState } from 'react';
import { ThemeProvider } from '@mui/material';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ChartsProvider, generateChartsTheme, getTheme, SnackbarProvider } from '@perses-dev/components';
import { dynamicImportPluginLoader, PluginRegistry, TimeRangeProvider } from '@perses-dev/plugin-system';
import { Dashboard, DashboardProvider, DatasourceStoreProvider, VariableProvider } from '@perses-dev/dashboards';
import { DashboardResource } from '@perses-dev/client';
import { DurationString, TimeRangeValue } from '@perses-dev/spec';
import * as prometheusPlugin from '@perses-dev/prometheus-plugin';
import * as timeseriesChartPlugin from '@perses-dev/timeseries-chart-plugin';
import * as statChartPlugin from '@perses-dev/stat-chart-plugin';
import { PersesDatasourceApi } from './datasource-api';

const datasourceApi = new PersesDatasourceApi();
// The saved dashboard that the page shows. nginx forwards /api/ to Perses.
const DASHBOARD_PATH = '/api/v1/projects/inventory/dashboards/overview';

const pluginLoader = dynamicImportPluginLoader([
  { resource: prometheusPlugin.getPluginModule(), importPlugin: () => Promise.resolve(prometheusPlugin) },
  { resource: timeseriesChartPlugin.getPluginModule(), importPlugin: () => Promise.resolve(timeseriesChartPlugin) },
  { resource: statChartPlugin.getPluginModule(), importPlugin: () => Promise.resolve(statChartPlugin) },
]);

const queryClient = new QueryClient({
  defaultOptions: { queries: { refetchOnWindowFocus: false, retry: 0 } },
});

function SavedDashboard(props: { dashboard: DashboardResource }): ReactElement {
  const { dashboard } = props;
  // The time range and the refresh interval start from the values saved in the dashboard.
  const [timeRange, setTimeRange] = useState<TimeRangeValue>({ pastDuration: dashboard.spec.duration });
  const [refreshInterval, setRefreshInterval] = useState<DurationString>(dashboard.spec.refreshInterval ?? '0s');

  return (
    <TimeRangeProvider
      timeRange={timeRange}
      refreshInterval={refreshInterval}
      setTimeRange={setTimeRange}
      setRefreshInterval={setRefreshInterval}
    >
      <VariableProvider initialVariableDefinitions={dashboard.spec.variables}>
        <DatasourceStoreProvider dashboardResource={dashboard} datasourceApi={datasourceApi}>
          <DashboardProvider initialState={{ dashboardResource: dashboard }}>
            <Dashboard />
          </DashboardProvider>
        </DatasourceStoreProvider>
      </VariableProvider>
    </TimeRangeProvider>
  );
}

export default function App(): ReactElement {
  const [dashboard, setDashboard] = useState<DashboardResource | undefined>(undefined);
  const [error, setError] = useState<string | undefined>(undefined);
  const muiTheme = useMemo(() => getTheme('light'), []);
  const chartsTheme = useMemo(() => generateChartsTheme(muiTheme, {}), [muiTheme]);

  useEffect(() => {
    fetch(DASHBOARD_PATH)
      .then((response) => {
        if (!response.ok) {
          throw new Error(`${DASHBOARD_PATH} answered ${response.status}`);
        }
        return response.json() as Promise<DashboardResource>;
      })
      .then(setDashboard)
      .catch((reason) => setError(String(reason)));
  }, []);

  return (
    <ThemeProvider theme={muiTheme}>
      <ChartsProvider chartsTheme={chartsTheme}>
        <SnackbarProvider anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} variant="default" content="">
          <PluginRegistry
            pluginLoader={pluginLoader}
            defaultPluginKinds={{ Panel: 'TimeSeriesChart', TimeSeriesQuery: 'PrometheusTimeSeriesQuery' }}
          >
            <QueryClientProvider client={queryClient}>
              {error && <p style={{ padding: 16 }}>Could not load the dashboard: {error}</p>}
              {!error && !dashboard && <p style={{ padding: 16 }}>Loading the dashboard...</p>}
              {dashboard && <SavedDashboard dashboard={dashboard} />}
            </QueryClientProvider>
          </PluginRegistry>
        </SnackbarProvider>
      </ChartsProvider>
    </ThemeProvider>
  );
}
SOURCEFILE
put_app_file "$WORK/datasource-api.ts" src/datasource-api.ts
put_app_file "$WORK/App.tsx" src/App.tsx
builder_sh "npm run build && npm run deploy"

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

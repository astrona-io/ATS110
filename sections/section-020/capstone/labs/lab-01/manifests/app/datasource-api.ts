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
    // Send queries straight to Prometheus.
    return 'http://prometheus.observability:9090';
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

# Datasources At Three Levels

A query in a saved dashboard names a datasource with a selector, and the selector does not say where the datasource is stored. Perses can store one in three places. This part shows the three, the order in which a lookup searches them, and what the `DatasourceApi` of the app has to provide for each.

## The three places

| Level | Stored as | Visible to |
| --- | --- | --- |
| Dashboard | In the dashboard, under `spec.datasources`, by name | That one dashboard |
| Project | A `Datasource` resource in a project | Every dashboard of the project |
| Global | A `GlobalDatasource` resource | Every dashboard of every project |

A dashboard-level datasource is a map entry:

```json
"datasources": {
  "local-prometheus": {
    "default": true,
    "plugin": { "kind": "PrometheusDatasource", "spec": { "directUrl": "http://prometheus:9090" } }
  }
}
```

A project datasource has its own resource and URL, under the project:

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://app.localtest.me:8081/api/v1/projects/inventory/datasources
```

A global datasource is the one the first module used, at `/api/v1/globaldatasources`.

## The search order

`DatasourceStoreProvider` resolves a selector in this order and stops at the first match:

1. **The dashboard.** It looks in `dashboardResource.spec.datasources` for an entry that matches the selector.
2. **The project.** If the dashboard has a project in its metadata, it calls `getDatasource(project, selector)` on the `DatasourceApi`.
3. **Global.** It calls `getGlobalDatasource(selector)`.

A match needs the right plugin kind, and then either the name from the selector, or, when the selector has no name, the datasource marked `default`. So a dashboard-level default shadows a project default, which shadows a global default. A selector with a name finds only that name, at the first level that has it.

The order lets a team override a shared datasource for one dashboard without changing the others.

## What each level needs in the app

The search runs in the browser, in the code of `DatasourceStoreProvider`. The data comes from the `DatasourceApi` you give it:

| Level | `DatasourceApi` member | Perses API path |
| --- | --- | --- |
| Dashboard | none; it is read from the dashboard | none |
| Project | `getDatasource(project, selector)` and `listDatasources(project, pluginKind?)` | `/api/v1/projects/<project>/datasources` |
| Global | `getGlobalDatasource(selector)` and `listGlobalDatasources(pluginKind?)` | `/api/v1/globaldatasources` |

The first module's class implemented the global pair, and returned nothing for the project pair. That is why a panel with the selector `{ kind: 'PrometheusDatasource', name: 'inventory-prometheus' }` finds no datasource: the global list has no such name.

The project pair has the same shape as the global pair, with the project in the path:

```ts
listDatasources = async (project: string, pluginKind?: string): Promise<DatasourceResource[]> => {
  const all = await getJson<DatasourceResource[]>(`/api/v1/projects/${encodeURIComponent(project)}/datasources`);
  return pluginKind ? all.filter((datasource) => datasource.spec.plugin.kind === pluginKind) : all;
};

getDatasource = async (project: string, selector: DatasourceSelector): Promise<DatasourceResource | undefined> => {
  const all = await this.listDatasources(project, selector.kind);
  return all.find((datasource) =>
    selector.name ? datasource.metadata.name === selector.name : datasource.spec.default,
  );
};
```

`DatasourceResource` comes from `@perses-dev/client`, as `GlobalDatasourceResource` does.

## The proxy URL for each level

After it finds a datasource, the store builds the proxy URL for it with `buildProxyUrl`. The parameters say which level it came from:

| Level | `project` | `dashboard` | URL |
| --- | --- | --- | --- |
| Dashboard | set | set | `/proxy/projects/inventory/dashboards/overview/datasources/local-prometheus` |
| Project | set | not set | `/proxy/projects/inventory/datasources/inventory-prometheus` |
| Global | not set | not set | `/proxy/globaldatasources/prometheus` |

These are the paths that the Perses server proxy serves. The function from the first module already builds all three, because it adds `projects/<project>/` and `dashboards/<dashboard>/` when it gets those parameters. A query then adds `/api/v1/query_range` after the proxy URL, and nginx forwards `/proxy/` to Perses.

Test the project path from the `tester` pod:

```sh
kubectl -n observability exec deploy/tester -- curl -s \
  "http://app.localtest.me:8081/proxy/projects/inventory/datasources/inventory-prometheus/api/v1/query?query=up"
```

The answer is Prometheus JSON with `"status":"success"`.

## Direct URLs

A datasource can have a `directUrl` in its plugin spec instead of a `proxy`. The browser then sends the query straight to that address, and does not use the Perses proxy. This works only if the browser can reach the address, and if the datasource server allows the page's origin. In a portal inside a network that cannot reach the datasource, use the proxy form.

## Try it

1. List the project datasources and the global datasources. Which names exist at each level?
2. Add the project methods to the `DatasourceApi`, rebuild, and reload the page with the saved dashboard.
3. In the network tab, find the first query request. Its path starts with the project proxy URL.
4. Change the selector name of one query in the dashboard to `prometheus`, which is global. Reload. The query now goes to the global proxy URL, and the panel still draws.

## Common pitfalls

> [!WARNING]
> - **Implementing only the global methods.** A dashboard that names a project datasource finds nothing.
> - **Returning the whole project list from `getDatasource`.** It must return one datasource, the one that matches the selector.
> - **Leaving out the plugin kind filter.** A project can hold datasources of other kinds, and a name can repeat across kinds.
> - **Using a `directUrl` datasource in a page the datasource cannot allow.** The browser blocks the request.

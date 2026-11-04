# Solution: Render A Saved Dashboard With A Project Datasource

Work the task yourself first. Running `astrona submit -c sections/section-020/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the dashboard and its project datasource are reachable at the app origin, `src/App.tsx` and `src/datasource-api.ts` have the changes, the built JavaScript holds the paths, and the build is newer than your last change to `App.tsx`.

## Step 1: Look at the dashboard and its datasource

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
kubectl -n observability exec deploy/tester -- \
  curl -s http://app.localtest.me:8081/api/v1/projects/inventory/dashboards/overview
kubectl -n observability exec deploy/tester -- \
  curl -s http://app.localtest.me:8081/api/v1/projects/inventory/datasources
```

The first answer is the dashboard as JSON. In each query you find `"datasource":{"kind":"PrometheusDatasource","name":"inventory-prometheus"}`. The second answer lists the datasources of the project, with `inventory-prometheus` in it. This is the list the `DatasourceApi` has to read.

## Step 2: Read project datasources

In `src/datasource-api.ts`, replace the two project methods that return nothing. `DatasourceStoreProvider` calls `getDatasource` with the project of the dashboard and the selector of the query:

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

`buildProxyUrl` already builds `/proxy/projects/inventory/datasources/inventory-prometheus` when it gets a project and a name, so nothing changes there.

## Step 3: Load the dashboard

In `src/App.tsx`, keep the theme, the plugin registry and the query client where they are. Add a state for the dashboard and for an error, and request the dashboard in an effect:

```tsx
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
```

`DASHBOARD_PATH` is the constant `'/api/v1/projects/inventory/dashboards/overview'`.

## Step 4: Render it

Move the time range, the variables, the datasource store and the dashboard into a component that receives the loaded dashboard. Its state starts from the saved values:

```tsx
const [timeRange, setTimeRange] = useState<TimeRangeValue>({ pastDuration: dashboard.spec.duration });
```

Inside `TimeRangeProvider`, the order is `VariableProvider`, `DatasourceStoreProvider`, `DashboardProvider`, then `<Dashboard />`:

```tsx
<VariableProvider initialVariableDefinitions={dashboard.spec.variables}>
  <DatasourceStoreProvider dashboardResource={dashboard} datasourceApi={datasourceApi}>
    <DashboardProvider initialState={{ dashboardResource: dashboard }}>
      <Dashboard />
    </DashboardProvider>
  </DatasourceStoreProvider>
</VariableProvider>
```

`DatasourceStoreProvider` reads the project name from `dashboard.metadata.project`, which is why a project datasource is found. The complete `src/App.tsx` and `src/datasource-api.ts` are in `solution/apply.sh`.

## Step 5: Build, deploy and look

```sh
builder "npm run typecheck"
builder "npm run build && npm run deploy"
kubectl -n embed port-forward svc/embed-app 8081:8081
```

Open `http://app.localtest.me:8081`. The dashboard group "Prometheus" shows a time series and a stat panel. In the network tab, the queries go to `/proxy/projects/inventory/datasources/inventory-prometheus/api/v1/query_range`.

## Step 6: Check

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

## If it fails

- **The page says it could not load the dashboard.** Read the status in the message. A 404 means the path or the project name is wrong.
- **The panels show an error about the datasource.** `getDatasource` returned nothing for the project. Check that the path ends in `/datasources` and that the filter uses `spec.plugin.kind`.
- **The page is blank and the console names a missing context.** A provider is missing or in the wrong order. `DashboardProvider` must be inside `DatasourceStoreProvider`'s children and `Dashboard` inside `DashboardProvider`.
- **The build fails on `variables`.** `dashboard.spec.variables` has the type `VariableDefinition[]`; keep the type from `DashboardResource`.

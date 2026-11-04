# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Render A Saved Dashboard

## Scenario

The operations team keeps its status dashboard in Perses and edits it there. The portal page in the namespace `embed` still has its two panels written into the code, so every change to the dashboard means a new build. The team wants the page to load the saved dashboard and show it.

Perses has the project `inventory` with the dashboard `overview`. Its panels name a datasource that exists only in that project: the project datasource `inventory-prometheus`. The app's `DatasourceApi` only knows global datasources, so the panels cannot find their datasource.

The app is in `/workspace/app` in the pod `app-builder`, and nginx serves it at `http://app.localtest.me:8081` and forwards `/api/` and `/proxy/` to Perses. The provider order in `src/App.tsx` is already correct for panels.

## Your task

1. In `src/datasource-api.ts`, implement `listDatasources` and `getDatasource` for a project. They read `/api/v1/projects/<project>/datasources` on the app's own origin. `getDatasource` returns the datasource with the selector's name, or the default datasource of the project if the selector has no name.
2. In `src/App.tsx`, replace the two hard-coded panels with the saved dashboard:
   - request `/api/v1/projects/inventory/dashboards/overview` when the page loads;
   - while it loads, show a short message, and show an error message if the request fails;
   - give the dashboard to `DatasourceStoreProvider` and to `DashboardProvider`, give `spec.variables` to `VariableProvider`, and render the `Dashboard` component;
   - start the time range from the dashboard's `spec.duration`.
3. Build the app and deploy it.

## Constraints

- No `directUrl` and no address of Prometheus in the app; every request goes through `/proxy/` or `/api/`.
- Do not change `package.json`; every package you need is already installed.
- Do not change the nginx configuration, the dashboard or the Perses datasources.

## Done when

- A request to `http://app.localtest.me:8081/api/v1/projects/inventory/dashboards/overview` returns the dashboard, and a query sent to `http://app.localtest.me:8081/proxy/projects/inventory/datasources/inventory-prometheus/api/v1/query` returns Prometheus data.
- `src/App.tsx` loads the dashboard and renders `DashboardProvider` and `Dashboard`, and `src/datasource-api.ts` reads project datasources.
- The built JavaScript contains the dashboard request and the project datasource paths.
- The page at `http://app.localtest.me:8081` loads a build made after your last change to `src/App.tsx`.

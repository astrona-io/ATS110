# Overview: Render A Saved Dashboard (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Perses and the example React application, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and `helm` and `percli` are on your PATH.
- **Perses v0.54.0** in the namespace `perses`, with the project `inventory`, the global datasource `prometheus`, the project datasource `inventory-prometheus` and the dashboard `overview`. The dashboard has a time series panel and a stat panel, and both use the project datasource.
- Prometheus and a `tester` pod in the namespace `observability`.
- In the namespace `embed`: the pod `app-builder` (Node.js 22) with the app in `/workspace/app`, already installed, built and deployed; and the nginx server `embed-app`. The app shows two panels written into the code, with a `DatasourceApi` that only knows global datasources.

## Helpers

Paste these once in each new terminal. `builder` runs a command in the app folder of the builder pod. `copy_to_builder` copies a file from your machine into the app folder, for example `copy_to_builder App.tsx src/App.tsx`.

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
copy_to_builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cat > /workspace/app/$2" < "$1"; }
```

To see the app, run `kubectl -n embed port-forward svc/embed-app 8081:8081` in a second terminal and open `http://app.localtest.me:8081`.

## Practice tasks

- Read the dashboard with `kubectl -n observability exec deploy/tester -- curl -s http://app.localtest.me:8081/api/v1/projects/inventory/dashboards/overview`, and find the panels, the layouts and the `$ref` that joins them.
- List the project datasources and the global datasources, and compare their `metadata`.
- Replace the two hard-coded panels with the saved dashboard, using `DashboardProvider` and `Dashboard`.
- Implement `getDatasource` and `listDatasources` for a project in `src/datasource-api.ts`, and see the panel errors disappear.
- Change a panel's query with `percli` or the Perses API, and reload the page: no build is needed.
- Add a dashboard variable with the Perses API and see it reach `VariableProvider`.
- Change `spec.duration` of the dashboard and see where the page's time range starts.

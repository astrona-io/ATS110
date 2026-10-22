# Overview: Embedding Panels In A React Application (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Perses and a small React application built the way the official embedding guide writes it, and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and `helm` and `percli` are on your PATH.
- **Perses v0.54.0** in the namespace `perses`, with the project `inventory` and the global datasource `prometheus`, the default, which forwards queries to Prometheus in the namespace `observability`.
- In the namespace `embed`: the pod `app-builder` (Node.js 22) with the app installed and built in `/workspace/app`, and the nginx server `embed-app`, which serves the app and forwards `/api/` and `/proxy/` to Perses.
- **The app uses a hard-coded datasource** with `directUrl` set to the public Prometheus demo server. Whether its panel shows data depends on your browser reaching that server.

## Helpers

Paste these once in each new terminal. `builder` runs a command in the app folder; `copy_to_builder` copies a file from your machine into it.

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
copy_to_builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cat > /workspace/app/$2" < "$1"; }
```

To see the app, run `kubectl -n embed port-forward svc/embed-app 8081:8081` in a second terminal and open `http://app.localtest.me:8081`.

## Practice tasks

- Move `DataQueriesProvider` outside `DatasourceStoreProvider` in `src/App.tsx`, build, deploy, and read the error the panel shows.
- Add a third panel of kind `TimeSeriesChart` with the query `prometheus_tsdb_head_chunks`.
- Set the refresh interval to `5s` and watch the requests in your browser's developer tools.
- Return `undefined` from `getGlobalDatasource` in your `DatasourceApi` and see how the panel reports a missing datasource.
- Create a second global datasource with `percli apply`, make it the default instead of `prometheus`, and see which one the panel uses.

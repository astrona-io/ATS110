# Overview: The Perses npm Packages (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Perses and a small React application built from the Perses npm packages, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and `helm` and `percli` are on your PATH.
- **Perses v0.54.0** in the namespace `perses`, with the project `inventory` and the global datasource `prometheus`, which forwards queries to Prometheus in the namespace `observability`.
- In the namespace `embed`: the pod `app-builder` (Node.js 22) with the app in `/workspace/app`, already installed, built and deployed; and the nginx server `embed-app`, which serves the app and forwards `/api/` and `/proxy/` to Perses.

## Helpers

Paste these once in each new terminal. `builder` runs a command in the app folder of the builder pod. `copy_to_builder` copies a file from your machine into the app folder, for example `copy_to_builder package.json package.json`.

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
copy_to_builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cat > /workspace/app/$2" < "$1"; }
```

To see the app, run `kubectl -n embed port-forward svc/embed-app 8081:8081` in a second terminal and open `http://app.localtest.me:8081`.

## Practice tasks

- Run `builder npm ls --depth=0` and match each top-level package with its layer.
- Change `"echarts": "5.5.0"` to `"5.6.0"` with `builder "sed -i 's/\"echarts\": \"5.5.0\"/\"echarts\": \"5.6.0\"/' package.json"`, run `builder npm install`, and read which package refuses it. Put it back afterwards.
- Run `builder npm view @perses-dev/timeseries-chart-plugin versions --json` and find the version that matches the `TimeSeriesChart` module Perses lists at `/api/v1/plugins`.
- Change the query in `src/App.tsx` to `prometheus_build_info`, then build and deploy, and see what the panel shows.
- Delete the builder pod with `kubectl -n embed delete pod -l app=app-builder` and check what is left in `/workspace/app` afterwards.

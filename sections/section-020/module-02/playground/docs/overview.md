# Overview: Variables And Time Controls (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Perses and the example React application, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and `helm` and `percli` are on your PATH.
- **Perses v0.54.0** in the namespace `perses`, with the project `inventory` and the global datasource `prometheus`.
- Prometheus in the namespace `observability`, scraping two jobs: `prometheus` and `prometheus-copy`. Both point at the same server, so each job has the same series under a different `job` label.
- In the namespace `embed`: the pod `app-builder` (Node.js 22) with the app in `/workspace/app`, already installed, built and deployed; and the nginx server `embed-app`. The app shows two panels with a `DatasourceApi` that uses the Perses proxy. It has no variable and no time controls yet.

## Helpers

Paste these once in each new terminal. `builder` runs a command in the app folder of the builder pod. `copy_to_builder` copies a file from your machine into the app folder, for example `copy_to_builder App.tsx src/App.tsx`.

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
copy_to_builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cat > /workspace/app/$2" < "$1"; }
```

To see the app, run `kubectl -n embed port-forward svc/embed-app 8081:8081` in a second terminal and open `http://app.localtest.me:8081`.

## Practice tasks

- Ask the proxy for the values of a label with `kubectl -n observability exec deploy/tester -- curl -s 'http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/label/job/values'`, then do the same for the label `instance`.
- Add a `ListVariable` named `job` with the `PrometheusLabelValuesVariable` plugin, render `VariableList`, and use `$job` in a query.
- Change `allowMultiple` to `false` and see which value the query gets. Then set it back to `true` and select two jobs.
- Use the formats `${job:regex}` and `${job:pipe}` in a query and compare the results.
- Add `TimeRangeControls` and a custom button that calls `setTimeRange({ pastDuration: '15m' })` from the `useTimeRange` hook.
- Write a query with `rate(prometheus_http_requests_total{job=~"$job"}[$__rate_interval])` and widen the time range.
- Add a `TextVariable` named `limit` with the value `5` and use `topk($limit, up)` in a query.

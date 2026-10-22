# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Embedding Panels In A React Application

## Scenario

The inventory status page, with the panels "HTTP requests per second" and "Targets up", was moved to a new cluster. The page loads, and the panel titles show, but both panels stay empty. During the move, someone "simplified" the app's datasource code, rewrote the nginx configuration, and tidied up the global datasources in Perses.

The app is in `/workspace/app` in the pod `app-builder` in the namespace `embed`. nginx in the pod `embed-app` reads its configuration from the ConfigMap `embed-app-nginx`. Perses runs in the namespace `perses`.

## Your task

1. Follow one query from the app's origin to Prometheus, and find every place it stops.
2. Fix each fault in the component where it is: the app, nginx, or Perses.
3. Build and deploy the app so both panels show data.

## Constraints

- Every query must go through the Perses proxy under `/proxy/`. Do not send the browser to Prometheus.
- Keep the global datasource `metrics` in Perses; other users rely on it.
- Do not change `package.json` or `src/App.tsx`.

## Done when

- The global datasource `prometheus` exists in Perses, is the default, and proxies to `http://prometheus.observability:9090`.
- nginx forwards `/proxy/` to Perses.
- A query sent to `http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/query` returns Prometheus data.
- The built JavaScript builds `/proxy/` URLs and contains no address of Prometheus, and was built after your last change to `src/datasource-api.ts`.

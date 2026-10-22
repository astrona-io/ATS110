# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Embedding Panels In A React Application

## Scenario

The operations team wants a small status page inside their portal, built from Perses panels. The first attempt, in the namespace `embed`, copies the official embedding guide: one panel, with a datasource written into the code that points at the public Prometheus demo server. The portal runs in a network that cannot reach that server, and the team wants the page to use the datasource Perses already has.

The app is in `/workspace/app` in the pod `app-builder`. nginx in the pod `embed-app` serves it at `http://app.localtest.me:8081` and forwards `/api/` and `/proxy/` to Perses. Perses has the global datasource `prometheus`, which is the default.

## Your task

1. Add `src/datasource-api.ts` with a class that implements `DatasourceApi` from `@perses-dev/client`: it reads global datasources from the Perses API on the app's own origin, and its `buildProxyUrl` returns URLs under `/proxy/` in the Perses proxy layout.
2. Change `src/App.tsx` to use that class instead of the hard-coded datasource, and to show two panels:
   - "HTTP requests per second", a `TimeSeriesChart` panel with the query `sum(rate(prometheus_http_requests_total[5m]))`;
   - "Targets up", a `StatChart` panel with the query `count(up == 1)` and the calculation `last-number`.
3. Build the app and deploy it.

## Constraints

- No `directUrl` and no address of Prometheus in the app: every query goes through `/proxy/`.
- Do not change the nginx configuration or the Perses datasources.
- Do not change `package.json`; every package you need is already installed.

## Done when

- A query sent to `http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/query` returns Prometheus data.
- The built JavaScript contains both panels and both queries, and no longer contains `prometheus.demo.do.prometheus.io`.
- The page at `http://app.localtest.me:8081` loads a build made after your last change to `src/App.tsx`.

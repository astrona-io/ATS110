# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Variables And Time Controls In An Embedded App

## Scenario

The operations team liked the status page with two panels. Now they want to choose which Prometheus jobs the panels show, and to change the time range without a rebuild. The Prometheus server in this cluster scrapes two jobs, `prometheus` and `prometheus-copy`. The app already reads its datasource from Perses through the proxy.

The app is in `/workspace/app` in the pod `app-builder` in the namespace `embed`, and nginx serves it at `http://app.localtest.me:8081`. Open the app source in `src/App.tsx`; the provider order and the `DatasourceApi` are already correct.

## Your task

1. In `src/App.tsx`, define one list variable and give it to `VariableProvider`:
   - kind `ListVariable`, name `job`, display name `Job`;
   - several values allowed and an "all" value allowed, with the default `$__all`;
   - the plugin `PrometheusLabelValuesVariable`, reading the label `job`.
2. Render the variable controls with `VariableList`, and the time controls with `TimeRangeControls` from `@perses-dev/plugin-system`. Show them above the panels.
3. Start the page with the time range `6h` and the refresh interval `1m`.
4. Change the two panels so they follow the variable:
   - "Targets up by job", a `TimeSeriesChart` panel with the query `up{job=~"$job"}`;
   - "Targets up", a `StatChart` panel with the query `count(up{job=~"$job"} == 1)` and the calculation `last-number`.
5. Build the app and deploy it.

## Constraints

- No `directUrl` and no address of Prometheus in the app; every request goes through `/proxy/` or `/api/`.
- Do not change `package.json`; every package you need is already installed.
- Do not change the nginx configuration or the Perses datasources.

## Done when

- A request to `http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/label/job/values` returns both jobs.
- `src/App.tsx` defines the variable, renders `VariableList` and `TimeRangeControls`, and starts with the time range `6h`.
- The built JavaScript contains the variable plugin and both queries with `$job`.
- The page at `http://app.localtest.me:8081` loads a build made after your last change to `src/App.tsx`.

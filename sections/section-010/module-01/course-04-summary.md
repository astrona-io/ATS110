# Summary

The Perses user interface is published as npm packages, so another React application can show the same panels Perses shows. The packages form layers. `@perses-dev/spec` holds the specification types and `@perses-dev/client` the API types, including `DatasourceApi`. `@perses-dev/components` holds shared components, `@perses-dev/plugin-system` loads plugins and keeps runtime state, and `@perses-dev/dashboards` provides the `Panel` component and the dashboard providers. Plugins such as `@perses-dev/prometheus-plugin` and `@perses-dev/timeseries-chart-plugin` do the actual querying and drawing. `@perses-dev/core` is deprecated; new code imports from `@perses-dev/spec` and `@perses-dev/client`.

Versions must fit the Perses server and each other. The shared packages take the server's version, here `0.54.0`. Plugins have their own version lines, and the server's own `/api/v1/plugins` list shows which ones ship with the release: `Prometheus` 0.58.0, `TimeSeriesChart` 0.13.0 and `StatChart` 0.13.0 for v0.54.0. A peer dependency is a package another package needs but expects the application to provide. When a provided version is outside the accepted range, npm stops with an `ERESOLVE` error that names the package, the range and the version it found. Forcing the install with `--legacy-peer-deps` only moves the failure to the browser. `npm ls` shows the installed tree and whether each package is installed once.

Building happens in the cluster. The builder pod runs `npm install`, then `vite build`, which bundles everything into `dist/`, then copies the result to a shared volume. nginx serves that volume and forwards `/api/` and `/proxy/` to Perses, so the browser talks to one origin only. A few facts to keep:

- Pin exact versions for every `@perses-dev` package, React, React DOM and ECharts.
- React must be 18 (or 17) and ECharts exactly 5.5.0 for the 0.54 packages.
- One copy of each shared package; two copies of `@perses-dev/plugin-system` means two plugin registries.
- Build, then deploy; nginx serves only what reached the shared volume.

<!-- astrona:playground:destroy -->

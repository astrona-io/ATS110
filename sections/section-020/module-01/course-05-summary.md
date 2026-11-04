# Summary

A Perses panel is a React component that needs a stack of providers around it. `ThemeProvider` and `ChartsProvider` supply the Material UI and ECharts themes, `SnackbarProvider` shows messages, and `PluginRegistry` knows the plugins from a plugin loader. `QueryClientProvider` runs and caches requests, and `TimeRangeProvider` holds the time range and refresh interval. `VariableProvider` holds dashboard variables, `DatasourceStoreProvider` finds datasources through a `DatasourceApi`, and `DataQueriesProvider` runs the queries of the panel inside it. The order follows what each one needs: queries need the time range and the datasources, so they sit inside both.

The `DatasourceApi` interface, exported by `@perses-dev/client`, decides where data comes from. An implementation for a Perses server reads `/api/v1/globaldatasources`, picks a datasource by name or by `spec.default`, and builds proxy URLs in the server's own layout, such as `/proxy/globaldatasources/prometheus`. A query then travels from the browser to the app's origin, through nginx to Perses, and through the Perses proxy to Prometheus. The browser never needs to reach Prometheus, and the datasource configuration and credentials stay on the Perses server. A `directUrl` does the opposite and sends the browser straight to the datasource.

Several panels share everything except their queries. Each panel gets its own `DataQueriesProvider` and its own height, and every panel plugin it uses must be both installed and listed in the plugin loader. `StatChart` reduces a series to one value with a `calculation` such as `last-number`. One `TimeRangeProvider` sets the window and the refresh interval for all panels at once. The key facts to remember are these:

- Import `DatasourceApi` from `@perses-dev/client`, and `DurationString` and `TimeRangeValue` from `@perses-dev/spec`.
- Serve the app and forward `/api/` and `/proxy/` from one origin.
- Without a name in the selector, the default datasource of the plugin kind is used.
- One `DataQueriesProvider` per panel; one `TimeRangeProvider` for the page.

<!-- astrona:playground:destroy -->

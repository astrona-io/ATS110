# Summary

A saved Perses dashboard is a JSON document at `/api/v1/projects/<project>/dashboards/<name>`. Its `metadata` holds the name and the project. Its `spec` holds the title, the starting `duration` and `refreshInterval`, the `variables`, the `panels` map, the `layouts` and the `datasources` defined inside the dashboard. A layout is a list of grid groups, and each grid item places a panel with a JSON reference such as `#/spec/panels/up`. A panel with no item in a layout is stored but not drawn.

To render it, the page loads the document first and then builds the providers. `TimeRangeProvider` gets its starting range from the saved duration, `VariableProvider` gets `spec.variables`, `DatasourceStoreProvider` gets the dashboard resource, and `DashboardProvider` gets `initialState={{ dashboardResource }}`. The `Dashboard` component draws one grid for each group and wraps each panel with its own queries. It draws no variable controls, time controls or toolbar; add `VariableList` and `TimeRangeControls` for those.

A query names a datasource with a selector, and `DatasourceStoreProvider` looks for it in the dashboard, then in the project, then globally. The project level needs `getDatasource` and `listDatasources` in the `DatasourceApi`, reading `/api/v1/projects/<project>/datasources`. The proxy URL changes with the level: `/proxy/projects/<project>/dashboards/<dashboard>/datasources/<name>`, `/proxy/projects/<project>/datasources/<name>` or `/proxy/globaldatasources/<name>`. The key facts to remember are these:

- Load the dashboard before the providers, because they read it once.
- Pass the saved duration on to `TimeRangeProvider`; `Dashboard` does not.
- A selector with no name finds the default datasource of its kind, at the first level that has one.
- A page that names a project datasource needs the project methods in the `DatasourceApi`.
- Test the three paths with `curl` through the app origin before changing code.

<!-- astrona:playground:destroy -->

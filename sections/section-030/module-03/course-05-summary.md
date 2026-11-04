# Summary

A panel draws data, a query plugin fetches it, and a datasource plugin knows how to reach the system that holds it. A `TimeSeriesQuery` plugin has a schema in package `model`, a TypeScript type for its spec, a function `getTimeSeriesData`, an editor, and a plugin object that assembles them. The function replaces variables in the query, asks the datasource store for a client by datasource kind, calls the client with the query and the time range, and returns time series data. `dependsOn` lists the variables the query uses, so that Perses re-runs the query when they change.

A datasource plugin creates the client. Its function `createClient` receives the datasource spec and the address of the Perses proxy, works out which address to use, and returns an object with the methods that queries call. Its schema usually reuses the Perses HTTP datasource definition. The query and the datasource connect only through a kind name, so the kind must be equal in the datasource plugin's name, the query schema, the query code and the datasource object that exists in Perses.

`percli plugin generate` adds a plugin to an existing module when it receives the same module flags and the module folder. It can generate datasource, query, panel and explore plugins, and it leaves placeholders and `TODO` comments that must be replaced, such as the placeholder datasource kind and the explore plugin's query type. It has no template for variable plugins, which are written by hand and declared in `package.json`. A module can hold several plugins and builds into one archive with one version.

Connection faults show at run time, not at build time. Checking the plugins declared in `package.json`, searching for the placeholder, comparing the kind in every place, and running schema tests with an invalid datasource kind find most of them without a build.

<!-- astrona:playground:destroy -->

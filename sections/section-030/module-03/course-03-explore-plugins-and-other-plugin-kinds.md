# Explore Plugins And Other Plugin Kinds

Panels, queries and datasources cover most extensions. Perses has more plugin kinds, and a module can hold several of them at once. This part looks at the explore plugin, which gives the Explore view a screen for a kind of data, then lists the query types a module can offer, and ends with the plugin kinds that `percli plugin generate` cannot create for you.

## The explore plugin

An explore plugin is a React component that Perses shows in its Explore view. The view lets a user write a query and look at the result without building a dashboard. The generated component, named from the plugin, does four things. It reads and writes its state with `useExplorerManagerContext` from `@perses-dev/explore`. It shows a `MultiQueryEditor` limited to the query types it supports. It wraps the result area in `DataQueriesProvider`, which runs the queries. And it reads the results with `useDataQueries` for one query type.

Generate one into the module to read it:

<!-- astrona:playground:renew -->

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
plugin_builder "cd demo-series && percli plugin generate --module.org=astrona --module.name=demo-series \
  --plugin.type=Explore --plugin.name=demo-explore --plugin.display-name='Demo Explore' ."
plugin_builder "cd demo-series && find src/explore -type f | sort"
```

The generated file has a constant `QUERY_TYPE` with a `TODO`. The template sets it to `TraceQuery`, and the code that checks for data reads a field that exists only in trace results. If your explore view is for time series, change the constant to `TimeSeriesQuery` and change the check that decides whether data was found. The value must be one of the query plugin types that the `@perses-dev/spec` package defines. The template ends with a placeholder where the panels or components that show the data belong.

An explore plugin has no CUE schema of its own in the way a panel has, because it stores no settings in a dashboard.

## The query types

A query plugin belongs to one of several types, and the type fixes the shape of the data it returns. The generator accepts `TimeSeriesQuery`, `TraceQuery`, `ProfileQuery` and `LogQuery`. A panel declares which types it can draw, and a query of another type is not offered for it. A `TimeSeriesChart` panel draws time series, so only `TimeSeriesQuery` plugins can feed it. A module that offers a new source of metrics therefore ships a `TimeSeriesQuery` plugin, and a module that offers traces ships a `TraceQuery` plugin plus a datasource.

The generated files differ per type. A `TimeSeriesQuery` plugin has `getTimeSeriesData`. The other types have the function for their own data shape. The structure is the same for all: a schema, a type, a function, an editor and the object that assembles them.

## What percli cannot generate

`percli plugin generate` accepts the plugin types `Datasource`, `TimeSeriesQuery`, `TraceQuery`, `ProfileQuery`, `LogQuery`, `Panel` and `Explore`. It has no template for a variable plugin. A variable plugin is a plugin that produces the values of a dashboard variable, such as a list of namespaces from a custom system.

The plugin type `Variable` exists in Perses, and a module can hold one. What is missing is only the generator. To write one, start from the source of a variable plugin that already exists in a module, and follow the same rules as for the other plugins: a schema in package `model`, a React side with an editor, and an entry in the `perses.plugins` list of `package.json`. Because `percli` does not write that entry, add it by hand and run `percli plugin lint` to check it.

The same is true for migration schemas, which convert a Grafana panel into a Perses panel. `percli plugin lint` and `percli plugin test-schemas` know about them, but no generator creates the files.

## Several plugins, one archive

A module can hold any mix of these plugins. The module builds into one archive, Perses installs it once, and every plugin in it is listed together. The usual design is to keep the plugins that belong together in one module: a datasource, the queries for it, and an explore view. They then share types and release together with one version number. A panel that is useful with many datasources belongs in its own module, so that it can be released on its own.

## Common pitfalls

> [!WARNING]
> - **Leaving `TraceQuery` in a generated explore plugin.** The view then offers trace queries and reads a field that time series results do not have.
> - **Looking for a `Variable` option in the generator.** It does not exist. Write the plugin by hand.
> - **Assuming a panel accepts every query type.** It accepts only the types it declares.
> - **Mixing unrelated plugins in one module.** One version number then covers changes that have nothing to do with each other.

You now know the set of plugin kinds and what the generator covers. What remains is the work that fails most often in practice: the connections between the parts.

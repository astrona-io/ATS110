# Query Plugins

A panel needs data, and in Perses the data comes from a query. The query is a block of settings in the panel, such as a PromQL expression. Something has to turn those settings into time series. That something is a query plugin. This part opens the generated `TimeSeriesQuery` plugin in the module `demo-series`, names its files, and follows what its main function receives and returns.

## What the generator wrote

The module in the builder pod was made with `percli plugin generate` and the plugin type `TimeSeriesQuery`. List its files:

<!-- astrona:playground:renew -->

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
plugin_builder "cd demo-series && find schemas src -type f | sort"
```

Besides the module files shared with every plugin (`src/index.ts`, `src/getPluginModule.ts`, `src/bootstrap.tsx`), the list shows the schema `schemas/queries/static-series/query.cue` and the folder `src/queries/static-series`. The folder holds five files that matter:

- `static-series-types.ts` declares the TypeScript type of the spec, with a `query` string and an optional `datasource` selector.
- `constants.ts` names the kind of datasource the query expects.
- `get-time-series-data.ts` holds the function that does the work.
- `StaticSeries.tsx` assembles the plugin object from the function and the other pieces.
- `StaticSeriesEditor.tsx` is the form the interface shows when someone edits the query.

The plugin is registered in the `perses` block of `package.json` as a plugin of kind `TimeSeriesQuery` with the name `StaticSeries`. A dashboard refers to it with the same two words: a panel query has `kind: TimeSeriesQuery` and, under `plugin`, `kind: StaticSeries`.

## The schema

Print the schema:

```sh
plugin_builder "cat demo-series/schemas/queries/static-series/query.cue"
```

It is the same kind of file as a panel schema: package `model`, a fixed `kind`, and a closed `spec`. The spec has a required `query` of at least one character and an optional `datasource` whose `kind` must equal one fixed string. In the generated file that string is the placeholder `YourDatasourceKind`. The placeholder is there on purpose: the generator cannot know which datasource your query talks to, so it leaves a value you must replace.

## The function that does the work

The query plugin object is built in `StaticSeries.tsx` from several parts. The first is `getTimeSeriesData`. Perses calls it whenever a panel needs data, with the query's `spec` and a `context`. The generated version, shortened, does these steps in order:

1. It returns an empty list of series when the query is empty.
2. It replaces variables in the query string with `replaceVariables(spec.query, context.variableState)`. A query written as `up{job="$job"}` becomes a plain string at this point.
3. It asks the datasource store for a client with `context.datasourceStore.getDatasourceClient(spec.datasource ?? DEFAULT_DATASOURCE)`. When the spec names no datasource, the code passes `{ kind: DATASOURCE_KIND }`, and the store picks a datasource of that kind.
4. It reads the time range from `context.timeRange`, which has a `start` and an `end` as dates, and calls the client's `query` method with the query text and the two times.
5. It maps the response to `TimeSeriesData`: an object with `series`, the `timeRange`, a `stepMs` and some `metadata`.

The context also carries the other things a query can need: the variable state, the datasource store and the time range. The function never reads the network itself. It asks for a client, and the datasource plugin decides how the client reaches the system.

The generated mapping function carries `TODO` comments where your data must be mapped to the series format the panels expect. The generated response type is also marked with a `TODO`: a real plugin imports it from its datasource plugin. These comments are the places to edit.

## The other parts of the plugin object

`StaticSeries.tsx` exports an object with more than the data function. `OptionsEditorComponent` is the editor form. `createInitialOptions` returns the spec a new query starts with, here `{ query: '' }`. `dependsOn` returns the variables the query uses, found with `parseVariables(spec.query)`. Perses uses that list to re-run the query when one of those variables changes, and to wait for a variable before it runs the query. A query plugin that forgets `dependsOn` runs with stale variable values.

## Common pitfalls

> [!WARNING]
> - **Leaving the placeholder datasource kind.** The generated schema refuses every real datasource kind, so a saved dashboard that names one is rejected.
> - **Calling `fetch` inside the query plugin.** The datasource plugin owns the connection. The query should ask the store for a client.
> - **Forgetting `dependsOn`.** A query that uses variables then ignores variable changes.
> - **Changing the schema and not the types.** The `spec` type in TypeScript and the CUE schema describe the same object. Edit them together.

You can now read a query plugin from the schema down to the function. What the function calls, the client, comes from a datasource plugin.

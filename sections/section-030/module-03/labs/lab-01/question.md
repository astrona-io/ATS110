# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Query And Datasource Plugins

## Scenario

A team keeps its numbers in an internal HTTP service and wants Perses to query it. A colleague ran `percli plugin generate` for a query plugin and left the template as it was. The module is `demo-series` and holds one `TimeSeriesQuery` plugin named `StaticSeries`. The query schema still points at the placeholder datasource kind `YourDatasourceKind`, and the module has no datasource plugin to point at.

The module is in `/workspace/demo-series` in the pod `plugin-builder` in the namespace `perses`. That pod has `percli` and `cue` on its PATH. No `npm install` has been run and none is needed for this task.

## Your task

1. Add a `Datasource` plugin to the same module with `percli plugin generate`: plugin name `demo-source`, display name `Demo Source`, so that its kind is `DemoSource`. Use the same module organisation and module name as the existing plugin.
2. Make the query plugin use that datasource. Replace the placeholder `YourDatasourceKind` with `DemoSource` in the query schema and in the query plugin's TypeScript constants, so that no copy of the placeholder remains in `schemas` or `src`.
3. Write schema tests for the query schema: at least two files in `tests/valid` and two in `tests/invalid`, next to the query schema, each with a complete `kind` and `spec`.
4. Run `percli plugin test-schemas` and `percli plugin lint` in the module until both pass.

## Constraints

- Keep the query plugin kind `StaticSeries` and keep both plugins in the one module.
- Keep `query` required, with at least one character, and keep the spec closed.
- Do not edit `package.json` by hand; `percli` writes the new plugin into it.

## Done when

- `package.json` declares the `TimeSeriesQuery` plugin `StaticSeries` and the `Datasource` plugin `DemoSource`, and their schema and source files exist.
- The placeholder `YourDatasourceKind` appears nowhere in `schemas` or `src`, and the query schema and `constants.ts` name `DemoSource`.
- The query schema has the tests, and `percli plugin test-schemas` passes.
- The query schema accepts and rejects a set of cases the grader holds back: a query with and without a `datasource` of kind `DemoSource`, an empty or missing query, a `datasource` of another kind, and an unknown field.
- `percli plugin lint` accepts the module.

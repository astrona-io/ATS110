# Query And Datasource Plugins

A panel draws data, but it does not fetch it. Queries fetch it, and queries talk to a datasource. Perses lets a plugin module add all three: a panel plugin for the drawing, a query plugin for the question, and a datasource plugin for the connection to a system that Perses does not support out of the box. This module builds the query and datasource plugins, because together they are how Perses reaches a new data source.

Keep one sentence in mind: **a query plugin asks the datasource store for a client by datasource kind, a datasource plugin creates that client, and the two only connect when the kind in the query schema and in the query code equals the name of the datasource plugin.**

The module has four parts. **Query Plugins** explains what a `TimeSeriesQuery` plugin contains and how to generate one. **Datasource Plugins** explains how a datasource plugin creates the client the query uses. **Explore Plugins And Other Plugin Kinds** covers the explore plugin, the other query types, and the plugin kinds that `percli` cannot generate. **When The Plugins Do Not Connect** reads the faults that leave a query without data. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Name the files of a generated `TimeSeriesQuery` plugin and say what each does.
- Explain what `getTimeSeriesData` receives and what it returns.
- Explain how a query finds its datasource, by kind, and how a default datasource is chosen.
- Generate a `Datasource` plugin into an existing module and say what `createClient` does.
- Name the query types an explore plugin can use, and say which plugin kinds `percli plugin generate` has no template for.
- Find the cause when a query plugin and a datasource plugin do not connect.

## Before you start

You should know how to generate a panel plugin and how a plugin schema is tested. The two earlier modules of this section cover that. You can read a TypeScript file with async functions. You do not need Node.js on your machine, and the exercises need no `npm install`.

Your playground has:

| Part | Where | What it is |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses` | The project `inventory` and the global datasource `prometheus` |
| Prometheus | namespace `observability` | The metrics server |
| `plugin-builder` | namespace `perses` | Node.js 22 with `percli` 0.54.0 and `cue` 0.17.1; workspace `/workspace` |
| `demo-series` | `/workspace/demo-series` in `plugin-builder` | A generated module with one `TimeSeriesQuery` plugin named `StaticSeries` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

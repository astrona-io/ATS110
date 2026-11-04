# What A Saved Dashboard Contains

Before the app can draw a dashboard it must read one. A dashboard is a JSON document stored by Perses, and every part of the page comes from a field in it. This part reads the document from the top down.

## Fetch it

The Perses API serves a dashboard at a path made of the project and the dashboard name. From the `tester` pod, ask for it through the app's origin, as the app will:

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://app.localtest.me:8081/api/v1/projects/inventory/dashboards/overview
```

The answer is one JSON object. Pipe it into `jq` to read it:

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://app.localtest.me:8081/api/v1/projects/inventory/dashboards/overview | jq "{kind, metadata, spec: (.spec | keys)}"'
```

The top level has three fields you rely on: `kind`, `metadata` and `spec`.

## Kind and metadata

`kind` is `Dashboard`. `metadata` names the dashboard and its project:

```json
{ "name": "overview", "project": "inventory" }
```

The server adds timestamps and a version to the metadata. The project name matters for rendering: it tells the datasource store which project to search for a datasource.

## The spec

`spec` holds everything that describes the page. These are its main fields:

| Field | Meaning |
| --- | --- |
| `display` | The title shown for the dashboard |
| `duration` | The initial time range, as a duration such as `1h` |
| `refreshInterval` | The initial automatic refresh interval, if the dashboard has one |
| `variables` | A list of variable definitions, the same shapes as in the previous module |
| `panels` | An object that maps a panel name to a panel definition |
| `layouts` | A list of panel groups, each with grid items that place panels |
| `datasources` | Datasources defined inside the dashboard, by name |
| `ttl` | A time to live for a short-lived dashboard |

## Panels

`panels` is a map. The key is a name that layouts refer to, and the value is a panel:

```json
"up": {
  "kind": "Panel",
  "spec": {
    "display": { "name": "Targets up by job" },
    "plugin": { "kind": "TimeSeriesChart", "spec": { "legend": { "position": "bottom", "size": "medium" } } },
    "queries": [
      {
        "kind": "TimeSeriesQuery",
        "spec": {
          "plugin": {
            "kind": "PrometheusTimeSeriesQuery",
            "spec": {
              "query": "up",
              "datasource": { "kind": "PrometheusDatasource", "name": "inventory-prometheus" }
            }
          }
        }
      }
    ]
  }
}
```

It is the panel you wrote in the first module, as data. `spec.plugin` chooses the panel plugin and its settings. `spec.queries` lists the queries, and each query has its own plugin. In the query spec, `datasource` is a **selector**: a `kind` and an optional `name`. Without a name, the default datasource of that kind is used.

## Layouts

A panel is not on the page until a layout places it. `layouts` is a list, and each item has the kind `Grid`:

```json
{
  "kind": "Grid",
  "spec": {
    "display": { "title": "Prometheus", "collapse": { "open": true } },
    "items": [
      { "x": 0, "y": 0, "width": 16, "height": 8, "content": { "$ref": "#/spec/panels/up" } },
      { "x": 16, "y": 0, "width": 8, "height": 8, "content": { "$ref": "#/spec/panels/count" } }
    ]
  }
}
```

Each Grid is a group with a title that can be collapsed. The grid has 24 columns, so `x` runs from 0 to 23 and `width` is a number of columns; `height` is in rows. The `content` of an item is a JSON reference: `"#/spec/panels/up"` means "the value at `spec.panels.up` in this document". That is how one panel definition can be placed once and edited in one place.

A panel with no item in a layout is stored but never drawn. An item that points at a name that is not in `panels` leaves a hole.

## Variables

`variables` holds the list from the previous module: text variables and list variables, with the plugin that finds the options. The saved dashboard keeps the definition and a default value; it does not keep what a viewer selected. The viewer's selection lives in the page.

## What the document does not hold

The document has no time zone setting for the viewer, no selected variable values and no theme. Those belong to the page that shows it, which is why the same dashboard can be embedded in pages with different looks.

## Try it

1. Fetch the dashboard and list the keys of `.spec.panels` and of `.spec.layouts[0].spec.items`.
2. Find the `$ref` of each item and check that it names a key of `panels`.
3. Find the `datasource` field in a query. Which kind of datasource does it select, and by which name?

## Common pitfalls

> [!WARNING]
> - **Reading `panels` as a list.** It is an object keyed by name.
> - **Expecting a panel to appear without a layout item.** Only items in `layouts` are drawn.
> - **Forgetting the project in the path.** A dashboard belongs to a project. `/api/v1/dashboards/overview` is not a path of the server.
> - **Assuming the saved document holds the viewer's choices.** It holds defaults.

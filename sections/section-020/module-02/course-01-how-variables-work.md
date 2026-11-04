# How Variables Work

A variable is a name with a current value. The name appears inside a query as `$job`, the reader picks a value, and the query that is sent to Prometheus contains the value and not the name. This part explains the two variable kinds, how the replacement is done, and the rules for what it produces.

## Two kinds of variable

A **text variable** holds one value that the reader types, or a constant that the author sets. Its definition has a name and a value:

```json
{ "kind": "TextVariable", "spec": { "name": "limit", "value": "5" } }
```

A **list variable** offers a list of options, and the reader chooses one or several. Where the options come from is decided by a **variable plugin**. The Prometheus plugin package provides three:

| Plugin kind | Options come from |
| --- | --- |
| `PrometheusLabelValuesVariable` | The values of one label, for example every `job` |
| `PrometheusLabelNamesVariable` | The names of the labels that exist |
| `PrometheusPromQLVariable` | The result of a PromQL expression; one label of the result gives the options |

A list variable definition adds fields around the plugin:

```json
{
  "kind": "ListVariable",
  "spec": {
    "name": "job",
    "display": { "name": "Job" },
    "allowMultiple": true,
    "allowAllValue": true,
    "defaultValue": "$__all",
    "plugin": { "kind": "PrometheusLabelValuesVariable", "spec": { "labelName": "job" } }
  }
}
```

`allowMultiple` lets the reader choose several options. `allowAllValue` adds an "All" choice. `defaultValue` is the choice at the start; `$__all` means "All". The plugin spec is specific to the plugin: `labelName` is required for label values, and an optional `matchers` list narrows the series that are searched.

A variable name may contain letters, digits and underscore. These are the characters the replacement code recognizes, so a name such as `my-job` does not work.

## Where the names are replaced

Plugins that send queries replace variable names in the text they receive. The Prometheus time series query plugin does it for the PromQL text, for the legend format and for the minimum step. The replacement uses the variable state that the provider holds, so a query in a `DataQueriesProvider` can use any variable defined above it in the tree.

Because the state is in the provider, every query that mentions `$job` is run again when the reader changes the value. You do not write any code for that.

## One value and many values

A variable that allows only one value is a string. A variable that allows several is a list of strings, and a list has to be written as text in some form. That form depends on the **format**, which you can add after the name with a colon: `${job:regex}`.

| Written as | One value `a` | Values `a` and `b` |
| --- | --- | --- |
| `$job` or `${job}` | `a` | `(a\|b)` |
| `${job:csv}` | `a` | `a,b` |
| `${job:pipe}` | `a` | `a\|b` |
| `${job:regex}` | `(a)` | `(a\|b)`, with regular expression characters escaped |
| `${job:singlequote}` | `'a'` | `'a','b'` |
| `${job:doublequote}` | `"a"` | `"a","b"` |
| `${job:json}` | `["a"]` | `["a","b"]` |
| `${job:raw}` | `a` | `a,b` |

The first row is the one to remember. A string value goes into the query as it is, and a list goes in as `(a|b)`, which is a regular expression alternative. That is why the selector `job=~"$job"` works for one value and for many: the operator `=~` matches a regular expression, and `(a|b)` is one. With the operator `=`, a list would not work, because Prometheus compares the label to the literal text `(a|b)`.

There are more formats, for example `lucene`, `glob` and `percentencode`, for datasources that are not Prometheus. Use `${name:format}` only when the default form does not fit the query language.

## The "All" value

When the reader chooses "All", the value is the special string `$__all`. Before the queries run, Perses changes it. If the definition has a `customAllValue`, that text is used, for example `.*`. If it does not, the value becomes the list of every option, which the default form writes as `(a|b|c)`.

A custom all value is useful when the list of options is long. A regular expression `.*` is shorter than a list of two hundred names, and Prometheus can match it faster.

## Built-in variables for Prometheus queries

The Prometheus query plugin also knows three names that you do not define:

| Name | Value |
| --- | --- |
| `$__interval` | The step between data points, as a duration such as `30s` |
| `$__interval_ms` | The same step in milliseconds |
| `$__rate_interval` | A window that is long enough for `rate()`: the step plus the minimum step, or four times the minimum step, whichever is larger |

The step depends on the time range and the width of the panel, so `rate(metric[$__rate_interval])` keeps working when the reader switches from fifteen minutes to a week. A fixed `[5m]` is too short for a long range and too long for a short one.

## Reading a variable in your own code

The state of the variables is available to any component below `VariableProvider`. The hook `useVariableValues` from `@perses-dev/plugin-system` returns a map from the variable name to its state, which holds `value`, `options` and `loading`:

```tsx
import { useVariableValues } from '@perses-dev/plugin-system';

function SelectedJobs(): ReactElement {
  const variables = useVariableValues(['job']);
  return <span>{JSON.stringify(variables['job']?.value)}</span>;
}
```

Use it to show the selection somewhere else on the page, or to build a link that carries it.

## Common pitfalls

> [!WARNING]
> - **Using `=` with a variable that allows several values.** The list becomes `(a|b)`, which only a regular expression match understands. Use `=~`.
> - **Choosing the name `$job` when another variable is called `$job2`.** The replacement is plain text, so `$job` also matches the start of `$job2`. Write `${job}` to mark where the name ends.
> - **Forgetting that "All" is not a single value.** It becomes every option, or the custom all value.
> - **Writing a name with a dash.** Only letters, digits and underscore are recognized.

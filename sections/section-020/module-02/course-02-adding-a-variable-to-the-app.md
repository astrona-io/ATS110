# Adding A Variable To The App

The app from the first module has two panels with fixed queries. This part changes it in three small steps: define a list variable, show it, and use it in the queries. Nothing else in the app changes.

## Step 1: define the variable

`VariableProvider` from `@perses-dev/dashboards` takes the variable definitions in the property `initialVariableDefinitions`. Define them as a constant outside the component, so the array is the same object on every render. The type `VariableDefinition` comes from `@perses-dev/spec`:

```tsx
import { VariableDefinition } from '@perses-dev/spec';

const variableDefinitions: VariableDefinition[] = [
  {
    kind: 'ListVariable',
    spec: {
      name: 'job',
      display: { name: 'Job' },
      allowMultiple: true,
      allowAllValue: true,
      defaultValue: '$__all',
      plugin: { kind: 'PrometheusLabelValuesVariable', spec: { labelName: 'job' } },
    },
  },
];
```

Then pass it to the provider:

```tsx
<VariableProvider initialVariableDefinitions={variableDefinitions}>
```

Without `initialVariableDefinitions` the provider starts empty, which is what the first module did.

The plugin kind `PrometheusLabelValuesVariable` is provided by `@perses-dev/prometheus-plugin`, which the app already lists in its plugin loader. If a variable plugin were missing from the loader, the variable would have no options.

## Step 2: show the variable

`VariableList`, also from `@perses-dev/dashboards`, draws one control for each variable that is not hidden. A list variable with `allowMultiple` is drawn as a multi-select. The component needs no properties:

```tsx
import { DatasourceStoreProvider, Panel, VariableList, VariableProvider } from '@perses-dev/dashboards';

<div style={{ padding: '16px 16px 0' }}>
  <VariableList />
</div>
```

It has to sit inside `VariableProvider`, and because the options of this variable come from Prometheus, inside `DatasourceStoreProvider` too. The plugin that loads the options asks the datasource store for the Prometheus client, in the same way a panel does. Place it above the panels, inside `DatasourceStoreProvider`.

## Step 3: use the variable in the queries

Change the selectors so that they contain the name:

```tsx
<EmbeddedPanel
  name="Targets up by job"
  query={'up{job=~"$job"}'}
  plugin={{ kind: 'TimeSeriesChart', spec: { legend: { position: 'bottom', size: 'medium' } } }}
/>
<EmbeddedPanel
  name="Targets up"
  query={'count(up{job=~"$job"} == 1)'}
  plugin={{ kind: 'StatChart', spec: { calculation: 'last-number' } }}
/>
```

The strings are written with single quotes in JavaScript because the PromQL has double quotes inside. A template string with backticks also works, and `$job` is not special there unless it is followed by a brace: in a template string `${job}` would be replaced by JavaScript before Perses ever saw it. Use single quotes for any query that contains a variable.

## What the reader sees

After the build, a "Job" control appears above the panels. At the start it shows "All". With the two scrape jobs of the playground, the options are `prometheus` and `prometheus-copy`. The query that is sent for "All" holds both names in a group, and each panel shows both series. When the reader chooses only `prometheus`, the query contains `job=~"prometheus"` and one series remains.

A short way to see what was sent is the network tab of the browser. The request goes to the Perses proxy path, and the query text is in the `query` or `query_range` parameter, already with the value in place of the name.

The options themselves come from a request to the label values endpoint of Prometheus through the same proxy. The path ends with `/api/v1/label/job/values`. That request is a second check you can make with `curl` from the playground: if it returns the two job names, the plugin has what it needs.

## Rebuild

The source is built with the pod `app-builder`, as in the first module. The commands are the same: copy `App.tsx` into the pod, run the build, and reload the page. If the build fails with a type error on `VariableDefinition`, the import from `@perses-dev/spec` is missing, or the installed version of `@perses-dev/spec` is older than the one the dashboards package expects; the lockfile checks from the second module of the previous section show how to see that.

## Try it

1. Add the constant and the property, and the `VariableList`, as shown. Rebuild.
2. Open the page. Choose only one job in the control and watch the panels change.
3. Change the second selector from `=~` to `=` and rebuild. Choose both jobs. The stat panel stops showing a value, because the query now compares `job` to the text `(prometheus|prometheus-copy)`. Change it back.

## Common pitfalls

> [!WARNING]
> - **Defining the array inside the component.** A new array on every render makes the provider see new definitions each time.
> - **Placing `VariableList` outside `DatasourceStoreProvider`.** The control loads but the options request cannot find a datasource.
> - **Using backticks around a query with `${name}`.** JavaScript replaces it first. Use single quotes.
> - **Naming a variable `job` while a query already uses a label also called `job` in `by (job)`.** This is fine for Prometheus, but it makes queries harder to read. Choose a name that tells the reader it is a variable if it helps.

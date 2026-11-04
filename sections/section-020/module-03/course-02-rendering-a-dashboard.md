# Rendering A Dashboard

The dashboard JSON is in the page's memory. This part gives it to the providers and draws it with the `Dashboard` component. Most of the stack is the one from the first module; two providers are new, and the panels move from your code into data.

## Two components from the dashboards package

`@perses-dev/dashboards` exports two components that do the work:

- `DashboardProvider` takes the dashboard resource and builds a store from it: the panel groups, the panels, the links, the duration and the refresh interval. It has one property, `initialState`, an object with `dashboardResource`.
- `Dashboard` reads that store and draws one grid for each panel group. It takes no dashboard of its own.

`Dashboard` also draws an empty state when the dashboard has no panel groups, so a dashboard with no layouts shows a message and not a blank page.

Each panel in the grid is drawn by the same `Panel` component you used before. The grid wraps it with its own `DataQueriesProvider`, built from the `queries` of the panel, so you do not write one for each panel.

## The order of the providers

The saved dashboard goes in two places: the datasource store, which needs it to find datasources, and the dashboard store, which needs it to draw.

```tsx
<TimeRangeProvider
  timeRange={timeRange}
  refreshInterval={refreshInterval}
  setTimeRange={setTimeRange}
  setRefreshInterval={setRefreshInterval}
>
  <VariableProvider initialVariableDefinitions={dashboard.spec.variables}>
    <DatasourceStoreProvider dashboardResource={dashboard} datasourceApi={datasourceApi}>
      <DashboardProvider initialState={{ dashboardResource: dashboard }}>
        <Dashboard />
      </DashboardProvider>
    </DatasourceStoreProvider>
  </VariableProvider>
</TimeRangeProvider>
```

Everything above `TimeRangeProvider` stays as in the first module: theme, charts, snackbar, plugin registry and query client. Panels need them all.

Compare it with the first module, where `DatasourceStoreProvider` got an empty dashboard resource, `{ kind: 'Dashboard', metadata: {}, spec: {} }`. Now it gets the real one, and that is what lets it see the project name and the dashboard-level datasources.

## Where the first values come from

The saved dashboard sets starting values, and your code passes them to the providers:

| Saved field | Goes to |
| --- | --- |
| `spec.duration` | The initial `timeRange`, as `{ pastDuration: dashboard.spec.duration }` |
| `spec.refreshInterval` | The initial refresh interval, with `'0s'` as the fallback |
| `spec.variables` | `initialVariableDefinitions` of `VariableProvider` |

`DashboardProvider` keeps its own copy of the duration and the refresh interval, but the time range the panels use is the one in `TimeRangeProvider`. The app must set it from the dashboard, or the saved duration has no effect.

## Load first, then render

The providers read the dashboard once, when they start. If you render them before the data arrives, they start with nothing. So the page loads the document first, and renders the providers only when it has one:

```tsx
const [dashboard, setDashboard] = useState<DashboardResource | undefined>(undefined);
const [error, setError] = useState<string | undefined>(undefined);

useEffect(() => {
  fetch('/api/v1/projects/inventory/dashboards/overview')
    .then((response) => {
      if (!response.ok) {
        throw new Error(`The dashboard request answered ${response.status}`);
      }
      return response.json() as Promise<DashboardResource>;
    })
    .then(setDashboard)
    .catch((reason) => setError(String(reason)));
}, []);
```

Then three states are shown: an error message, a loading message, or the providers with the dashboard. A separate component that receives the loaded dashboard as a property keeps the state of the time range simple, because `useState` there can start from `dashboard.spec.duration`.

The fetch uses the app's origin, so it goes through nginx to the Perses API, as in the first module.

## What Dashboard does not do

`Dashboard` draws the grid and nothing more. It does not draw the variable controls, the time range controls, the title, or a toolbar. Add `VariableList` and `TimeRangeControls`, which you know from the previous module, above it. The Perses interface adds a toolbar and edit mode on top of these same pieces.

It also does not save. The panels, the layout and the groups can change in the store if you turn on edit mode, but nothing is sent back to the server unless your code does it.

## Try it

1. Replace the two hard-coded panels of the app with the loading code and the `Dashboard` component.
2. Reload the page. It fails or shows errors, because the `DatasourceApi` does not know the project datasource yet. The datasource sections of this module explain how to add it.
3. Change the `duration` of the dashboard with the Perses API, reload the page, and watch the starting range change.

## Common pitfalls

> [!WARNING]
> - **Rendering the providers before the dashboard arrives.** They read the value once and keep it.
> - **Putting `Dashboard` outside `DashboardProvider`.** The component throws an error that says no dashboard context was found.
> - **Forgetting to pass `spec.duration` on.** The panels use the range of `TimeRangeProvider`.
> - **Keeping the panel container height at zero.** The grid sets its own heights from the layout items.

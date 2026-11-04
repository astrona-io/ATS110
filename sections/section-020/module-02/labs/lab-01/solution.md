# Solution: Add A Job Variable And Time Controls

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the label values are served through the proxy, `src/App.tsx` has the variable and both controls, the built JavaScript holds the plugin and the queries, and the build is newer than your last change to `App.tsx`.

## Step 1: See which values the variable will get

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
kubectl -n observability exec deploy/tester -- \
  curl -s 'http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/label/job/values'
```

The answer is Prometheus JSON with `"status":"success"` and the two job names. This is the request the `PrometheusLabelValuesVariable` plugin sends for the label `job`, so if it works here, the variable can fill its list.

## Step 2: Define the variable

Add the variable definitions above `queryClient` in `src/App.tsx`, and import `VariableDefinition` from `@perses-dev/spec`:

```tsx
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

Then give it to the provider: `<VariableProvider initialVariableDefinitions={variableDefinitions}>`. The Prometheus plugin that you already load in the plugin registry also provides this variable kind, so no new plugin is needed.

## Step 3: Show the controls

Import `VariableList` from `@perses-dev/dashboards` and `TimeRangeControls` from `@perses-dev/plugin-system`. `TimeRangeControls` needs a time zone and a function that changes it, so keep the zone in state:

```tsx
const [timeZone, setTimeZone] = useState<string>('local');
```

Render both controls inside `DatasourceStoreProvider`, above the panels:

```tsx
<div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, alignItems: 'center', padding: '16px 16px 0' }}>
  <TimeRangeControls timeZone={timeZone} onTimeZoneChange={(option) => setTimeZone(option.value)} />
</div>
<div style={{ padding: '16px 16px 0' }}>
  <VariableList />
</div>
```

`VariableList` must sit inside `VariableProvider`, and it loads the variable options through the datasource store, so it belongs inside `DatasourceStoreProvider` as well.

## Step 4: Start values and queries

Change the initial state to a time range of `6h` and a refresh interval of `1m`, and change the two panels to use `$job`:

```tsx
const [timeRange, setTimeRange] = useState<TimeRangeValue>({ pastDuration: '6h' });
const [refreshInterval, setRefreshInterval] = useState<DurationString>('1m');
```

The queries are `up{job=~"$job"}` and `count(up{job=~"$job"} == 1)`. In a TSX attribute a string with double quotes needs single quotes around it: `query={'up{job=~"$job"}'}`.

The complete `src/App.tsx` is in `solution/apply.sh`.

## Step 5: Build, deploy and look

```sh
builder "npm run typecheck"
builder "npm run build && npm run deploy"
kubectl -n embed port-forward svc/embed-app 8081:8081
```

Open `http://app.localtest.me:8081`. The page shows the time controls, a Job list with all jobs selected, and two panels. Remove one job from the list and watch the panels change; change the time range with the picker and watch them draw again.

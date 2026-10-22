# Solution: Align The Perses Package Versions

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the versions in `package.json`, a clean installed tree with one copy of each core Perses package, and a fresh build served by nginx.

## Step 1: Reproduce the failure

Define a helper for the builder, then try to install:

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
builder npm install --no-audit --no-fund
```

npm stops with an `ERESOLVE` error. The message names a package with a peer dependency, the range it wants, and the version the app provides. Here it involves the `@perses-dev` packages: one plugin wants `@perses-dev/components` in the `^0.55` range while the app pins an older release.

## Step 2: Find every version that is off

Print the `@perses-dev` lines of `package.json`:

```sh
builder "grep @perses-dev package.json"
```

Three lines do not belong to Perses v0.54.0: `@perses-dev/components` is `0.53.0`, `@perses-dev/dashboards` is `0.55.0`, and `@perses-dev/timeseries-chart-plugin` is `0.14.0`. The shared packages must all be `0.54.0`. For the plugin, ask the Perses server which version it runs:

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses.svc.cluster.local:8080/api/v1/plugins | jq -r ".[] | \"\(.metadata.name) \(.metadata.version)\""' | grep -E 'TimeSeriesChart|Prometheus|StatChart'
```

`TimeSeriesChart` is `0.13.0` in Perses v0.54.0, so the plugin package must be `0.13.0` too.

## Step 3: Fix the three versions

Change the three lines in place:

```sh
builder "sed -i -e 's/\"@perses-dev\/components\": \"0.53.0\"/\"@perses-dev\/components\": \"0.54.0\"/' \
  -e 's/\"@perses-dev\/dashboards\": \"0.55.0\"/\"@perses-dev\/dashboards\": \"0.54.0\"/' \
  -e 's/\"@perses-dev\/timeseries-chart-plugin\": \"0.14.0\"/\"@perses-dev\/timeseries-chart-plugin\": \"0.13.0\"/' package.json"
builder "grep @perses-dev package.json"
```

Every shared package now reads `0.54.0`, `@perses-dev/spec` reads `0.2.0`, and the plugins read `0.58.0`, `0.13.0` and `0.13.0`.

## Step 4: Install from a clean state

Remove anything a failed install left behind, then install again:

```sh
builder "rm -rf node_modules package-lock.json && npm install --no-audit --no-fund"
builder npm ls @perses-dev/plugin-system @perses-dev/components
```

The install finishes without an error. `npm ls` shows `0.54.0` for every line, with the repeated ones marked `deduped`.

## Step 5: Build, deploy and check

```sh
builder "npm run build && npm run deploy"
```

To see it, run `kubectl -n embed port-forward svc/embed-app 8081:8081` in a second terminal and open `http://app.localtest.me:8081`. The panel "Prometheus target up" shows a line at 1.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `npm install --legacy-peer-deps` | The install succeeds with mismatched packages; the grader rejects the tree and the flag |
| Upgrade everything to 0.55 | The packages no longer match the Perses v0.54.0 server or the plugins it runs |
| Add `@perses-dev/core` to fix a missing type | It is deprecated; the types live in `@perses-dev/spec` and `@perses-dev/client` |
| Build without deploying | nginx keeps serving the old, empty site |

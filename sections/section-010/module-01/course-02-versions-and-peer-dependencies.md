# Versions And Peer Dependencies

The example app pins `@perses-dev/dashboards` at `0.54.0`, `@perses-dev/prometheus-plugin` at `0.58.0` and `@perses-dev/spec` at `0.2.0`. Three different numbers can look like a mistake, but they are the one combination that fits Perses v0.54.0. This part shows where each number comes from, and what npm does when the numbers do not fit.

## Two kinds of version line

The packages from the `perses/shared` repository are released together with the Perses server: `@perses-dev/client`, `components`, `plugin-system`, `dashboards` and `explore`. Use the same version as your Perses server, here `0.54.0`. `@perses-dev/spec` has its own, slower line; the 0.54.0 packages depend on `0.2.0`.

The plugin packages come from the `perses/plugins` repository, and each plugin has its own version line. The safest way to choose them is to ask which plugin versions your Perses server itself runs. Perses lists its loaded plugin modules at the endpoint `/api/v1/plugins`. Send that request from the `tester` pod, and let `jq` print each module's name and version:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses.svc.cluster.local:8080/api/v1/plugins | jq -r ".[] | \"\(.metadata.name) \(.metadata.version)\""'
```

The list has about thirty modules. Look for three of them: `Prometheus` with version `0.58.0`, `TimeSeriesChart` with `0.13.0` and `StatChart` with `0.13.0`. Those are the plugins that ship inside the Perses v0.54.0 release, and the matching npm packages are `@perses-dev/prometheus-plugin@0.58.0`, `@perses-dev/timeseries-chart-plugin@0.13.0` and `@perses-dev/stat-chart-plugin@0.13.0`. Newer plugin versions exist on npm, but they are built for newer `@perses-dev` packages.

## What a peer dependency is

A normal dependency is something a package installs for itself. A **peer dependency** is something a package needs but expects the application to provide: one shared copy, in a version range the package accepts. React is the classic case. A page must have exactly one copy of React, so every library that uses React lists it as a peer dependency instead of bringing its own.

Ask npm for the peer dependencies of the time series chart plugin. The builder has internet access, so `npm view` reads the registry directly:

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
builder npm view @perses-dev/timeseries-chart-plugin@0.13.0 peerDependencies
```

The answer is a list of names and ranges. Three entries matter most. `react` accepts `^17.0.2 || ^18.0.0`, so React 19 is outside the range. `echarts` asks for exactly `5.5.0`, with no range at all. And the `@perses-dev` packages are listed with `^0.54.0`, so the plugin wants the 0.54 release of the shared packages. The app's `package.json` provides every one of those in a version inside the range.

## What npm does when a peer does not fit

npm checks every peer dependency while it installs. When the application provides a version outside a package's range, and npm cannot find a version that satisfies everyone, it stops with an error whose code is `ERESOLVE`. The message names the package that has the peer dependency, the range it wants, and the version it found instead. Read those three things; they tell you exactly which line of `package.json` to change.

npm offers a way around the check: the flag `--legacy-peer-deps` (or `--force`) installs anyway. That does not fix anything. It installs a tree in which, for example, a plugin built for `@perses-dev/components` 0.55 runs against 0.53, and the failure moves from install time to the browser, where it is much harder to read.

## Checking the installed tree

After a clean install, check that there is only one copy of each shared package. Two copies of `@perses-dev/plugin-system`, for example, means two plugin registries, and a panel then cannot find the plugins the other copy registered. `npm ls` prints where a package is installed and which package asked for it:

```sh
builder npm ls @perses-dev/plugin-system @perses-dev/components
```

The output is a small tree with the app at the top. Every line for `@perses-dev/plugin-system` and `@perses-dev/components` shows `0.54.0`. Lines marked `deduped` point at the same single copy, so this tree is healthy. A second version number, or a line marked `invalid`, would mean two copies or a broken peer range. If npm finds any problem at all in the tree, `npm ls` also ends with a non-zero exit code, which makes it a good check in a build pipeline.

> [!TIP]
> Pin exact versions, without `^`, for every `@perses-dev` package and for the peers the plugins care about (`react`, `react-dom`, `echarts`). A range lets the next `npm install` pick a newer release that no longer matches your Perses server.

You can now choose versions that fit a Perses release and check that npm installed one copy of each. The next question is practical: how the app is built from these packages and served to a browser.

## Common pitfalls

> [!WARNING]
> - **Using the newest version of every package.** The newest plugin versions are built for newer `@perses-dev` packages. Match the versions to your Perses server.
> - **Installing with `--legacy-peer-deps` or `--force`.** The install succeeds, and the app breaks in the browser instead.
> - **Upgrading React to 19.** The 0.54 packages accept React 17 and 18 only.
> - **Letting `echarts` float.** The plugins ask for exactly `5.5.0`; a range in your `package.json` lets npm pick another version.

# Solution: Rescue A Starter App That Never Built

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

There are three independent faults: React 19, ECharts 5.6.0, and a Vite base path that nginx does not serve.

## Step 1: Read the install error

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
builder npm install --no-audit --no-fund
```

npm stops with `ERESOLVE`. The first conflict it reports is a `@perses-dev` package whose peer range for `react` is `^17.0.2 || ^18.0.0`, while the app provides `19.1.0`. npm reports one conflict at a time, so fix all the peers you can find before you install again.

## Step 2: Compare every peer the plugins ask for

```sh
builder npm view @perses-dev/timeseries-chart-plugin@0.13.0 peerDependencies
builder "grep -E '\"(react|react-dom|echarts)\"' package.json"
```

The plugin asks for `react` 17 or 18 and for exactly `echarts` `5.5.0`. The app pins `react` and `react-dom` at `19.1.0` and `echarts` at `5.6.0`. All three must change.

## Step 3: Fix the versions and install

```sh
builder "sed -i -e 's/\"react\": \"19.1.0\"/\"react\": \"18.3.1\"/' -e 's/\"react-dom\": \"19.1.0\"/\"react-dom\": \"18.3.1\"/' \
  -e 's/\"echarts\": \"5.6.0\"/\"echarts\": \"5.5.0\"/' package.json"
builder "rm -rf node_modules package-lock.json && npm install --no-audit --no-fund"
builder npm ls react echarts @perses-dev/plugin-system
```

The install finishes, and `npm ls` shows one `react` at `18.3.1`, one `echarts` at `5.5.0` and `@perses-dev/plugin-system` at `0.54.0`.

## Step 4: Find why the page would be blank

Look at the build configuration:

```sh
builder cat vite.config.ts
```

It sets `base: '/app/'`. Vite writes that prefix into every script and style path in `index.html`, so the page asks for `/app/assets/...`. nginx serves the volume at the root of the site and falls back to `index.html` for paths it cannot find. The browser therefore gets HTML where it expected JavaScript, and the page stays blank. The task does not allow you to change nginx, so the base path must go back to `/`:

```sh
builder "sed -i \"s#base: '/app/'#base: '/'#\" vite.config.ts"
```

## Step 5: Build, deploy and check

```sh
builder "npm run build && npm run deploy"
builder "grep -o 'src=\"[^\"]*\"' /srv/dist/index.html"
```

The script path now starts with `/assets/`. Start `kubectl -n embed port-forward svc/embed-app 8081:8081` in a second terminal and open `http://app.localtest.me:8081`: the panel appears.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `npm install --force` | The install runs with React 19, which the Perses packages do not support; the grader rejects the tree |
| Keep ECharts 5.6.0 because it is newer | The plugins ask for exactly 5.5.0; npm installs a second copy or refuses |
| Add a `/app/` location to nginx | Not allowed here, and it hides a build setting that does not match where the app is served |

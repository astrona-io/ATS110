# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** The Perses npm Packages

## Scenario

A teammate wanted "the latest of everything" and changed a few versions in the inventory dashboard app before going on holiday. Now `npm install` in the builder pod fails, and nginx still serves an empty site. The Perses server in this cluster is **v0.54.0**.

The app is in `/workspace/app` in the pod `app-builder` in the namespace `embed`. Run commands there with:

```sh
kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && npm install"
```

## Your task

1. Find which entries in `package.json` do not fit Perses v0.54.0, from the npm error and from the versions Perses itself runs.
2. Fix `package.json` so every `@perses-dev` package matches the Perses v0.54.0 release, then install the packages.
3. Build the app and deploy it, so `http://app.localtest.me:8081` serves it.

## Constraints

- Do not use `--legacy-peer-deps` or `--force`, and do not add them to an `.npmrc` file.
- Do not add `@perses-dev/core`; it is deprecated.
- Keep exact versions (no `^` or `~`) for the packages you change.
- Do not change the app's source files under `src/`.

## Done when

- `package.json` pins `@perses-dev/client`, `components`, `plugin-system`, `dashboards` and `explore` at `0.54.0`, `@perses-dev/spec` at `0.2.0`, `@perses-dev/prometheus-plugin` at `0.58.0`, and the time series and stat chart plugins at `0.13.0`, with React 18.
- `npm ls` reports no problems, and each core `@perses-dev` package is installed once.
- The page at `http://app.localtest.me:8081` loads its JavaScript, built after your last change to `package.json`.

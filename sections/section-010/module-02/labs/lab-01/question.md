# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Keeping The Dependencies Reproducible

## Scenario

The inventory dashboard app builds on one laptop and fails on the next. Its `package.json` uses ranges (`^0.54.0`), the repository has no lockfile, and nobody has told npm to save exact versions. Each `npm install` can therefore pick different versions on different days. The Perses server in this cluster is **v0.54.0**.

The app is in `/workspace/app` in the pod `app-builder` in the namespace `embed`. Run commands there with:

```sh
kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && npm ls"
```

## Your task

1. Change every entry in `dependencies` and `devDependencies` to an exact version: the version each range resolves to at its lowest end, without the `^`.
2. Make npm save exact versions from now on, by adding a project `.npmrc` file in `/workspace/app`.
3. Create a lockfile with `npm install`, then prove that the lockfile alone rebuilds the tree by removing `node_modules` and running `npm ci`.
4. Build the app and deploy it, so `http://app.localtest.me:8081` serves it.

## Constraints

- Do not use `--legacy-peer-deps` or `--force`, and do not add them to an `.npmrc` file.
- Do not add `@perses-dev/core`; it is deprecated.
- Do not change the app's source files under `src/`.
- Do not edit `package-lock.json` by hand.

## Done when

- Every dependency in `package.json` is an exact version, and the `@perses-dev` packages are `0.54.0`, `spec` `0.2.0`, `prometheus-plugin` `0.58.0`, and the time series and stat chart plugins `0.13.0`.
- `/workspace/app/.npmrc` contains `save-exact=true`.
- `package-lock.json` is in step with `package.json`, and each core `@perses-dev` package appears once in it, at `0.54.0`.
- `npm ls` reports no problems, and the page at `http://app.localtest.me:8081` loads its JavaScript, built after your last change to `package.json`.

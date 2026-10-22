# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** The Perses npm Packages

## Scenario

The inventory dashboard app was started from a template. Since then, someone upgraded React and ECharts to their newest releases, and changed the Vite configuration so the app "lives under `/app/`". The install fails. Someone forced it through once, and the page at `http://app.localtest.me:8081` stayed blank. The Perses server is **v0.54.0**.

The app is in `/workspace/app` in the pod `app-builder` in the namespace `embed`. nginx in the pod `embed-app` serves the deployed build at the root of `http://app.localtest.me:8081`.

## Your task

1. Find every reason the app does not install, and every reason the built page would stay blank.
2. Fix the versions so the install succeeds with every peer check in place.
3. Fix the build configuration so nginx serves the page and its JavaScript from the root of the site.
4. Build and deploy the app.

## Constraints

- Do not use `--legacy-peer-deps` or `--force`, and do not add them to an `.npmrc` file.
- Do not change the nginx configuration; the app must work with it as it is.
- Do not add `@perses-dev/core`.
- Do not change the source files under `src/`.

## Done when

- `package.json` pins React and React DOM to `18.3.1`, ECharts to `5.5.0`, and the Perses packages to the versions of the Perses v0.54.0 release.
- `npm ls` reports no problems, and each core `@perses-dev` package is installed once.
- `vite.config.ts` builds for the root path `/`.
- The page at `http://app.localtest.me:8081` loads a script from `/assets/` that is JavaScript, built after your last change to `package.json`.

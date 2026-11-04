# Overview: Keeping The Dependencies Reproducible (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Perses and the example React application, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and `helm` and `percli` are on your PATH.
- **Perses v0.54.0** in the namespace `perses`, with the project `inventory` and the global datasource `prometheus`.
- In the namespace `embed`: the pod `app-builder` (Node.js 22) with the app in `/workspace/app`, already installed with `npm install`, built and deployed; and the nginx server `embed-app`.

## Helpers

Paste this once in each new terminal. `builder` runs a command in the app folder of the builder pod.

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
```

## Practice tasks

- Run `builder "ls -a"` and find `package-lock.json`. Run `builder "head -c 600 package-lock.json"` and read the `lockfileVersion` and the `packages` section.
- Run `builder "rm -rf node_modules && npm ci --no-audit --no-fund"` and compare how long it takes with `npm install`.
- Change one version in `package.json` with `builder "sed -i 's/\"echarts\": \"5.5.0\"/\"echarts\": \"5.6.0\"/' package.json"` and run `builder npm ci`. Read why npm refuses. Put the version back.
- Run `builder npm explain @perses-dev/plugin-system` and read every path that leads to the package.
- Add an `overrides` block with `builder npm pkg set overrides.lodash=4.18.1 --json=false` and run `builder npm install`; read what npm changes in the lockfile.
- Run `builder npm outdated` and read the three version columns.
- Run `builder "npm pkg get dependencies.react"` and `builder "npm view react@18 version"` and compare what a range allows with what is pinned.

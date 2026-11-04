# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl exec` to run a command in a pod.
- Read a short CUE schema and write schema tests with `percli plugin test-schemas`.
- Read a small TypeScript file and change one value in it.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, with the project `inventory` and the global datasource `prometheus`.
- Prometheus and a `tester` pod in the namespace `observability`.
- In the namespace `perses`: the pod `plugin-builder` (Node.js 22, `percli` and `cue`) with the generated module `/workspace/demo-series`.
- `helm` and `percli` on your PATH.

The task needs no `npm install`.

## Working rules

- Everything is graded on the **final state** of the module, so leave your changes in place.
- Change one thing at a time and run the checks after each change.

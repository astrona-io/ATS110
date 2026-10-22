# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl` to read pods, ConfigMaps and logs, and run `kubectl exec`.
- Read a short TypeScript or JSON file and change one value in it.
- Read a CUE schema and a small React component.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, with the project `inventory` and the global datasource `prometheus`.
- Prometheus and a `tester` pod in the namespace `observability`.
- In the namespace `perses`: the pod `plugin-builder` (Node.js 22, `percli` and `cue`) with the workspace `/workspace` and the volume `plugin-artifacts` at `/artifacts`.
- `helm` and `percli` on your PATH.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state**, so build, deploy or install
  again at the end and leave the result in place.
- Change one thing at a time and check the result before the next change.
- The first `npm install` downloads several hundred megabytes; it needs
  internet access and a few minutes.

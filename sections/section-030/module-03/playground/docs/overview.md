# Overview: Query And Datasource Plugins (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Perses and a builder pod for plugins, generates the module `demo-series` with a query plugin, and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and `helm` and `percli` are on your PATH.
- **Perses v0.54.0** in the namespace `perses`, with the project `inventory` and the global datasource `prometheus`.
- The pod `plugin-builder` in the namespace `perses`: Node.js 22 with `percli` 0.54.0 and `cue` 0.17.1 on its PATH, the generated module `/workspace/demo-series` (no `npm install` has been run), and the volume `plugin-artifacts` at `/artifacts`. The workspace is an `emptyDir`: a restart of the pod empties it.

## Helpers

Paste these once in each new terminal. `plugin_builder` runs a command in `/workspace` of the builder; `copy_to_plugin` copies a file from your machine into the module folder `/workspace/demo-series`.

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
copy_to_plugin() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cat > /workspace/demo-series/$2" < "$1"; }
```

To see Perses, run `kubectl -n perses port-forward svc/perses 8080:8080` in a second terminal and open `http://perses.localtest.me:8080`.

## Practice tasks

- Run `percli plugin generate --help` and generate a `Datasource` plugin and an `Explore` plugin into the same module.
- Read `src/queries/static-series/get-time-series-data.ts` and find where the datasource client is requested.
- Read `src/datasources/*/` after generating a datasource and find `createClient`.
- Change the datasource kind in the query schema and in `constants.ts`, then add tests and run `percli plugin test-schemas`.
- Run `percli plugin lint` and read what it says about a module with three plugins.

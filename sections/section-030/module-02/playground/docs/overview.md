# Overview: Constrain And Test Plugin Schemas (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Perses and a builder pod for plugins, generates the module `status-badge` with a permissive schema, and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and `helm` and `percli` are on your PATH.
- **Perses v0.54.0** in the namespace `perses`, with the project `inventory` and the global datasource `prometheus`.
- The pod `plugin-builder` in the namespace `perses`: Node.js 22 with `percli` 0.54.0 and `cue` 0.17.1 on its PATH, the generated module `/workspace/status-badge` (no `npm install` has been run), and the volume `plugin-artifacts` at `/artifacts`. The workspace is an `emptyDir`: a restart of the pod empties it.

## Helpers

Paste these once in each new terminal. `plugin_builder` runs a command in `/workspace` of the builder; `copy_to_plugin` copies a file from your machine into the module folder `/workspace/status-badge`.

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
copy_to_plugin() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cat > /workspace/status-badge/$2" < "$1"; }
```

To see Perses, run `kubectl -n perses port-forward svc/perses 8080:8080` in a second terminal and open `http://perses.localtest.me:8080`.

## Practice tasks

- Tighten `label` to 1 to 40 characters with `strings.MinRunes` and `strings.MaxRunes`, then write one valid and one invalid test for it and run `percli plugin test-schemas`.
- Make `warning` optional with `warning?: number` and add a test that leaves it out.
- Add a field with a default, such as `format?: *"number" | "percent"`, and test both values and a value outside the list.
- Remove `close(...)` around the spec, run the tests, and see which invalid test starts to fail.
- Run `cue vet` on one invalid test file from the schema folder and read the message.
- Run `percli plugin lint` after each change.

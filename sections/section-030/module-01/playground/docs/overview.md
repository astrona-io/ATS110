# Overview: Writing A Panel Plugin (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Perses and a builder pod for plugins, and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, and `helm` and `percli` are on your PATH.
- **Perses v0.54.0** in the namespace `perses`, with the project `inventory` and the global datasource `prometheus`.
- The pod `plugin-builder` in the namespace `perses`: Node.js 22 with `percli` 0.54.0 and `cue` 0.17.1 on its PATH, an empty workspace in `/workspace`, and the volume `plugin-artifacts` at `/artifacts`. The workspace is an `emptyDir`: a restart of the pod empties it.

## Helpers

Paste these once in each new terminal. `plugin_builder` runs a command in `/workspace` of the builder; `copy_to_plugin` copies a file from your machine into the module folder `/workspace/status-badge`.

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
copy_to_plugin() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cat > /workspace/status-badge/$2" < "$1"; }
```

To see Perses, run `kubectl -n perses port-forward svc/perses 8080:8080` in a second terminal and open `http://perses.localtest.me:8080`.

## Practice tasks

- Run `percli plugin generate --help` in the builder and generate a second plugin of type `Variable` into the same module.
- Make `warning` optional in the schema with `warning?: number`, rebuild, reinstall, and save a dashboard without it.
- Run `cue vet` on a JSON example that breaks the schema and read the message.
- Build the archive with `percli plugin build --archive-format zip` and compare its listing with the `.tar.gz` one.
- Fetch `/plugins/StatusBadge/mf-manifest.json` from the `tester` pod after you install the plugin.

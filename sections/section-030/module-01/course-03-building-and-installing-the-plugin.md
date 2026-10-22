# Building And Installing The Plugin

The `StatusBadge` module holds a schema and React code, but Perses cannot use source files. It needs an archive in its plugin archive folder, and it reads that folder only when it starts. This part builds the archive with `percli`, places it where the Perses pod can mount it, and restarts Perses with one extra file in the folder.

## Install the module's packages

A generated module has a `package.json` but no lockfile, the file `package-lock.json` that records exact installed versions. `percli plugin build` runs `npm ci` when `node_modules` is missing, and `npm ci` refuses to run without a lockfile. So install the packages once with `npm install`, which writes the lockfile. The first install downloads several hundred megabytes and takes a few minutes:

<!-- astrona:playground:renew -->

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
plugin_builder "cd status-badge && npm install --no-audit --no-fund"
```

npm installs the build tools (`rsbuild`, `swc`, TypeScript) and the peer dependencies from the module's `package.json`, including the `@perses-dev` packages at `0.54`.

## Build the archive

`percli plugin build` does three things in order. It runs `npm run build`, which builds the module federation files with `rsbuild` and the npm package files with `swc`, all into `dist/`. It runs `cue mod tidy`, which fetches the CUE modules the schemas may import; that is why the builder has `cue` on its PATH and needs internet access. Then it writes the archive into the module folder:

```sh
plugin_builder "cd status-badge && percli plugin build"
plugin_builder "ls status-badge/*.tar.gz && tar -tzf status-badge/StatusBadge-0.1.0.tar.gz | head -20"
```

The archive is `StatusBadge-0.1.0.tar.gz`: the module name from the module federation manifest, then the version from `package.json`. Its listing starts with `package.json`, `mf-manifest.json` and `mf-stats.json`, then the `__mf/` folder, and further down `schemas/panels/status-badge/status-badge.cue` and the `cue.mod/` folder: the layout Perses expects.

Copy the archive to the shared volume. The volume `plugin-artifacts` is mounted at `/artifacts` in the builder, and the Perses pod can mount it too:

```sh
plugin_builder "cp status-badge/StatusBadge-0.1.0.tar.gz /artifacts/ && ls -l /artifacts"
```

## Mount one file into the archive folder

The bundled plugins live in `/etc/perses/plugins-archive` inside the Perses image. Mounting the whole volume there would hide them. A `subPath` mount places one file from the volume at one path, and leaves the rest of the folder as it is. The Perses Helm chart accepts extra `volumes` and `volumeMounts` for its pod. Save this as `perses-plugin-values.yaml`:

```yaml
volumes:
  - name: plugin-artifacts
    persistentVolumeClaim:
      claimName: plugin-artifacts
      readOnly: true
volumeMounts:
  - name: plugin-artifacts
    mountPath: /etc/perses/plugins-archive/StatusBadge-0.1.0.tar.gz
    subPath: StatusBadge-0.1.0.tar.gz
    readOnly: true
```

Upgrade the release with this file on top of its current values. The change to the pod template makes Kubernetes replace the Perses pod, so Perses starts again and reads the archive folder:

```sh
helm upgrade perses perses/perses --version 0.23.3 --namespace perses --reuse-values \
  --values perses-plugin-values.yaml --wait
```

Then check the module list:

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses.svc.cluster.local:8080/api/v1/plugins | jq -r ".[].metadata.name"' | grep -E 'StatusBadge|TimeSeriesChart'
```

Both names are printed: Perses loaded `StatusBadge`, and the bundled `TimeSeriesChart` is still there.

## Use the panel in a dashboard

The schema now guards every dashboard that uses the panel. Here is a dashboard in the project `inventory` with one `StatusBadge` panel and one query, the number of Prometheus targets that are up. Save this as `dashboard-status.json`:

```json
{"kind":"Dashboard","metadata":{"name":"status","project":"inventory"},"spec":{"display":{"name":"status"},"duration":"1h","variables":[],"panels":{"badge":{"kind":"Panel","spec":{"display":{"name":"Badge"},"plugin":{"kind":"StatusBadge","spec":{"label":"Targets up","warning":1,"critical":0}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"count(up == 1)"}}}}]}}},"layouts":[{"kind":"Grid","spec":{"items":[{"x":0,"y":0,"width":6,"height":4,"content":{"$ref":"#/spec/panels/badge"}}]}}]}}
```

Start `kubectl -n perses port-forward svc/perses 8080:8080` in a second terminal, then apply the dashboard with `percli`:

```sh
percli login http://perses.localtest.me:8080
percli apply -f dashboard-status.json
```

`percli` reports that the dashboard `status` was created in the project `inventory`. Open `http://perses.localtest.me:8080/projects/inventory/dashboards/status`: the badge reads "Targets up: 1". The browser loaded the badge's code from `/plugins/StatusBadge/`, the same way it loads the bundled charts.

Now try a panel that breaks the schema. Change `"warning":1` to `"warning":"high"` in the file and apply it again. The Perses server refuses the dashboard with an error from schema validation, and the stored dashboard stays as it was. The server did that, with the CUE schema from the archive, before any browser saw the panel.

You can now build a plugin archive, install it without hiding the bundled plugins, and use the panel in a dashboard the server validates. That is the whole path a plugin takes from source to a running Perses.

## Common pitfalls

> [!WARNING]
> - **Running `percli plugin build` before `npm install`.** It falls back to `npm ci`, which fails without a lockfile.
> - **Running `helm upgrade` before the archive is on the volume.** The kubelet creates an empty folder at the `subPath`, and Perses finds no archive.
> - **Forgetting `--reuse-values`.** Helm then drops the values the release was installed with, and Perses comes back with the chart defaults.
> - **Changing the archive without a restart.** A new file under the same name is only read when the Perses pod starts again.

## Your mission: Build And Install The StatusBadge Panel Plugin

You can now write a panel plugin, build its archive, install it and use it. The graded lab gives you a freshly generated `status-badge` module with its packages installed, and asks you to turn it into the badge, install it next to the bundled plugins, and create the dashboard `status`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-110-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-110-lab-030-01
astrona start ats-110-playground-030-01
```

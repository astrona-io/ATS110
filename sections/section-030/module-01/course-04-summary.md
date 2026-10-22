# Summary

Every chart, query type and datasource type in Perses is a plugin, and a plugin you write is loaded the same way. Plugins come in five types: datasource, query, panel, variable and explore. One npm package, the plugin module, can hold several of them. The Perses server lists the loaded modules at `/api/v1/plugins` and serves each module's files under `/plugins/<module name>/`.

A plugin has two halves. The server uses a CUE schema, in package `model`, to check a plugin's settings every time a dashboard is saved; `close({...})` makes the schema refuse any field it does not list. The browser uses React code, built with `rsbuild` and loaded at run time through module federation. `percli plugin generate` creates a module from templates built into `percli`, with the schema in `schemas/panels/<name>/` and the code in `src/panels/<name>/`. The plugin's `kind` in a dashboard is the PascalCase name, such as `StatusBadge`, and the schema's `kind` must match it.

`percli plugin build` turns the module into an archive. It runs `npm run build`, then `cue mod tidy`, then writes `<module>-<version>.tar.gz` with `package.json`, the module federation files, the schemas and `cue.mod`. Install the packages with `npm install` first, because the generated module has no lockfile. Perses reads the archive folder only at start, and the bundled plugins live in the same folder, so the course adds one archive with a `subPath` mount through the Helm chart's `volumes` and `volumeMounts`, and a `helm upgrade --reuse-values` restarts the pod. The key facts to remember are these:

- The archive must be on the volume before the upgrade, or the `subPath` becomes an empty folder.
- Never mount over the whole archive folder; the bundled plugins disappear.
- A new archive is loaded only after Perses restarts.
- The server, not the browser, rejects a panel whose settings break the schema.

<!-- astrona:playground:destroy -->

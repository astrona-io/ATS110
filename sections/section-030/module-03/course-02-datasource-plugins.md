# Datasource Plugins

A query plugin asks for a client and gets one. This part is about where the client comes from. A datasource plugin holds the knowledge of how to reach one kind of system: the address, the headers, the request format and how to read the response. This part generates a datasource plugin into the existing module, reads its three pieces, and shows how the query finds it.

## Generate a datasource plugin into a module

`percli plugin generate` adds a plugin to an existing module when you pass the same module flags and the module folder. Run it in the module, with the plugin type `Datasource`:

<!-- astrona:playground:renew -->

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
plugin_builder "cd demo-series && percli plugin generate --module.org=astrona --module.name=demo-series \
  --plugin.type=Datasource --plugin.name=demo-source --plugin.display-name='Demo Source' ."
plugin_builder "cd demo-series && find schemas src -type f | sort"
```

The new files are the schema `schemas/datasources/demo-source/demo-source.cue`, a JSON example next to it, and the folder `src/datasources/demo-source`. The `perses.plugins` list in `package.json` now has two entries, the query and the datasource. From the name `demo-source` the plugin kind is `DemoSource`. This is the kind that dashboards and queries use.

## The schema of a datasource

Print it:

```sh
plugin_builder "cat demo-series/schemas/datasources/demo-source/demo-source.cue"
```

The generated schema sets `#kind` to the plugin kind, `kind` to `#kind`, and the `spec` to the Perses definition `datasource.#HTTPDatasourceSpec`. That definition describes a datasource reached over HTTP: an optional `directUrl` that the browser calls directly, or a `proxy` block that makes the Perses server call the system on the browser's behalf. It also defines `#selector`, the shape a query uses to name this kind of datasource.

Most HTTP systems need exactly this, so the generated schema is often kept as it is. A system that needs more settings, such as a database name, adds fields to the spec in the schema and in the TypeScript type.

## The client

The code in `src/datasources/demo-source` has a type file, an editor and the plugin object in `DemoSource.tsx`. The plugin object has a function `createClient(spec, options)`. Perses calls it with the datasource's `spec` and with `options` that carry `proxyUrl`, the address of the Perses proxy for this datasource. The generated version works out the address like this: it uses `spec.directUrl` when that is set, and the `proxyUrl` when it is not, and it throws an error when neither exists.

It returns an object, the client, with the methods the queries will call. The generated client has one method named `query`, which builds a URL from the address and the parameters, sends it with `fetch` from `@perses-dev/client`, and returns `{ status, data }`. That method is a template: its path `/api/search` and the shape of `data` belong to a made-up system and are meant to be replaced.

The client interface is shared with the query plugin through a TypeScript type: the datasource plugin declares `DemoSourceClient`, and the query plugin calls `getDatasourceClient<DemoSourceClient>`. The generated query plugin has its own placeholder copy of the interface with a `TODO` to import the real one.

## How the query finds its datasource

Three things must agree. The query asks for a datasource by kind: `DemoSource`. A datasource object in Perses exists with a plugin of that kind: for example a global datasource whose plugin `kind` is `DemoSource`. And the datasource plugin is installed, so the server and the browser know the kind.

When the query spec names no datasource, the datasource store looks for one of the requested kind. With a default datasource of that kind it returns that one. The datasource store searches the dashboard's own datasources first, then the project's, then the global ones. A query that names a datasource by `name` as well as `kind` picks exactly that one.

## Common pitfalls

> [!WARNING]
> - **Generating into the wrong folder.** Run the command with the existing module's folder, or `percli` writes a second module.
> - **Using other module flags.** The module organisation and name must match the existing ones.
> - **Keeping the template request.** The generated `query` method calls a path that exists in no real system.
> - **Expecting the plugin to appear before it is installed.** Perses lists a plugin only after its archive is installed and Perses has restarted.

A query can now reach a datasource in principle. Two questions remain: which other plugin kinds a module can hold, and which of them `percli` cannot generate.

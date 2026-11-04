# When The Plugins Do Not Connect

A query plugin and a datasource plugin are written separately and meet only at run time, through a kind name. That makes the connection easy to break without any error at build time. This part lists the faults that leave a query without data, says where each shows, and fixes them. The graded lab at the end asks you to build the connection yourself.

## Check the declared plugins first

Before you look at code, check what the module declares. `percli` writes one entry per plugin into the `perses.plugins` list of `package.json`:

<!-- astrona:playground:renew -->

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
plugin_builder "cd demo-series && node -e \"console.log(JSON.stringify(require('./package.json').perses.plugins, null, 2))\""
```

Each entry has a `kind` (the plugin type), and under `spec` a `name` (the plugin kind a dashboard uses) and a display name. A plugin that is missing here is not part of the archive. A name that differs by one letter from the name in a dashboard is the most common cause of "plugin not found".

## The placeholder was left in

The generated query schema and the generated `constants.ts` both name `YourDatasourceKind`. Search the module for it:

```sh
plugin_builder "cd demo-series && grep -rn YourDatasourceKind schemas src || echo none left"
```

Any match is a fault. If the schema still has it, Perses refuses a saved query that names the real datasource kind. If `constants.ts` still has it, the query asks the store for a datasource of a kind that does not exist, and the query fails at run time with an error that no datasource of that kind was found. The two places must change together, and both must equal the datasource plugin's name.

## The kinds do not match

The datasource kind appears in four places: the datasource plugin's name in `package.json`, the kind in the datasource's schema, the kind in the query schema, and `DATASOURCE_KIND` in the code. A single difference, such as `DemoSource` against `Demosource`, breaks the link. Compare the four values by eye or with `grep`. When they agree, the next suspect is the datasource object.

## No datasource of that kind exists

A plugin is a type. The query needs an instance: a datasource object in Perses with a plugin of that kind. Without one, the store has nothing to return. Create a global datasource or a project datasource whose plugin kind is the datasource plugin's kind. Without a default datasource of that kind, the query must name the datasource in its spec.

## The client does not match the query

The query plugin calls methods on the client. If the datasource plugin's client has a method named `query` and the query plugin calls `search`, the build may still pass when the type is loose. It then fails in the browser. Share one TypeScript type for the client and import it in both plugins, and remove the placeholder copy that the generator leaves in the query plugin.

## The generator was run in the wrong place

If `percli plugin generate` is run without the module folder, or with another module name, it writes a new module and the plugin never reaches the first one. A module folder with a second `package.json` inside it, or two folders in `/workspace` that both have plugins, shows it. Remove the extra module and run the command again with the right folder and flags.

## Run the checks that need no build

Schema faults are caught without a build. Write tests for the query schema, run `percli plugin test-schemas`, then `percli plugin lint`. A test with a datasource of another kind in `tests/invalid` proves that the schema refuses a placeholder or a wrong kind. Faults in the code, such as a method that does not exist, need the build or a type check. Those need `npm install`, which this module's exercises leave out to keep them fast.

## Common pitfalls

> [!WARNING]
> - **Fixing the schema and forgetting `constants.ts`.** Saving then works and running fails.
> - **Editing `package.json` by hand to add a plugin that `percli` can generate.** Let the generator write the entry and the files together.
> - **Testing only the valid case.** The test that a wrong datasource kind is refused is the one that catches the placeholder.
> - **Creating the plugin and no datasource object.** The plugin alone gives the query nothing to connect to.

## Your mission: Generate A Datasource Plugin And Connect A Query Plugin

You can now add a datasource plugin to a module, connect a query plugin to it by kind, and prove the connection with schema tests. The graded lab gives you a generated `demo-series` module with a query plugin that still has the placeholder, and asks you to generate the datasource plugin, replace the placeholder in the schema and the code, write the query tests, and make the tests and lint pass.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-110-playground-030-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-030/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-110-lab-030-03
astrona start ats-110-playground-030-03
```

# Solution: Generate A Datasource Plugin And Connect A Query Plugin

Work the task yourself first. Running `astrona submit -c sections/section-030/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: that the module declares both plugins, that the placeholder datasource kind is gone, that the query schema has tests and `percli plugin test-schemas` passes, that the query schema gives the right answer on cases the grader holds back, and that `percli plugin lint` passes.

## Step 1: Set up two helpers

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
copy_to_plugin() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "mkdir -p \"\$(dirname /workspace/demo-series/$2)\" && cat > /workspace/demo-series/$2" < "$1"; }
```

Look at what the module holds:

```sh
plugin_builder "cd demo-series && find schemas src -type f | sort"
```

## Step 2: Generate the datasource plugin into the same module

`percli plugin generate` adds a plugin to an existing module when you give it the same module flags and the module folder as its last argument:

```sh
plugin_builder "cd demo-series && percli plugin generate --module.org=astrona --module.name=demo-series \
  --plugin.type=Datasource --plugin.name=demo-source --plugin.display-name='Demo Source' ."
plugin_builder "cd demo-series && find schemas src -type f | sort"
```

The listing now has `schemas/datasources/demo-source/demo-source.cue` and the folder `src/datasources/demo-source`. The `perses` block of `package.json` lists both plugins.

## Step 3: Point the query plugin at the datasource

Save this as `query.cue`:

```cue
package model

import (
	"strings"
)

kind: "StaticSeries"
spec: close({
	datasource?: {
		kind: "DemoSource"
	}
	query: strings.MinRunes(1)
})
```

Save this as `constants.ts`:

```ts
export const DATASOURCE_KIND = 'DemoSource';
export const DEFAULT_DATASOURCE = { kind: DATASOURCE_KIND };
```

```sh
copy_to_plugin query.cue schemas/queries/static-series/query.cue
copy_to_plugin constants.ts src/queries/static-series/constants.ts
plugin_builder "cd demo-series && grep -rn YourDatasourceKind schemas src || echo none left"
```

## Step 4: Write the tests

The query schema is `schemas/queries/static-series/query.cue`, so the tests go in `schemas/queries/static-series/tests/valid` and `.../invalid`.

```sh
echo '{"kind":"StaticSeries","spec":{"query":"up"}}' > plain.json
echo '{"kind":"StaticSeries","spec":{"query":"up","datasource":{"kind":"DemoSource"}}}' > with-datasource.json
echo '{"kind":"StaticSeries","spec":{"query":""}}' > empty-query.json
echo '{"kind":"StaticSeries","spec":{"query":"up","datasource":{"kind":"PrometheusDatasource"}}}' > wrong-datasource.json
echo '{"kind":"StaticSeries","spec":{"query":"up","step":"15s"}}' > extra-field.json
copy_to_plugin plain.json schemas/queries/static-series/tests/valid/plain.json
copy_to_plugin with-datasource.json schemas/queries/static-series/tests/valid/with-datasource.json
copy_to_plugin empty-query.json schemas/queries/static-series/tests/invalid/empty-query.json
copy_to_plugin wrong-datasource.json schemas/queries/static-series/tests/invalid/wrong-datasource.json
copy_to_plugin extra-field.json schemas/queries/static-series/tests/invalid/extra-field.json
```

## Step 5: Run the checks and submit

```sh
plugin_builder "cd demo-series && percli plugin test-schemas"
plugin_builder "cd demo-series && percli plugin lint"
astrona submit -c sections/section-030/module-03/labs/lab-01
```

## Common mistakes

- Running `percli plugin generate` without the module flags or in the wrong folder, which creates a second module instead of adding a plugin.
- Changing the schema but not `constants.ts`. The schema then accepts `DemoSource` while the code asks the datasource store for the placeholder kind, and the query fails at run time.
- Editing `package.json` by hand to add the plugin. Let `percli` write it.
- Putting the tests under the datasource schema folder instead of the query schema folder.

# Solution: Constrain And Test The StatusBadge Schema

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: that the module holds enough test files, that `percli plugin test-schemas` passes, that the schema gives the right answer on cases the grader holds back, and that `percli plugin lint` passes.

## Step 1: Set up two helpers

Paste these in your terminal. `plugin_builder` runs a command in `/workspace` of the builder pod. `copy_to_plugin` copies a file from your machine into the module folder.

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
copy_to_plugin() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "mkdir -p \"\$(dirname /workspace/status-badge/$2)\" && cat > /workspace/status-badge/$2" < "$1"; }
```

Look at the schema you start from:

```sh
plugin_builder "cat status-badge/schemas/panels/status-badge/status-badge.cue"
```

## Step 2: Tighten the schema

Save this as `status-badge.cue` on your machine and copy it over the old one:

```cue
package model

import "strings"

kind: "StatusBadge"
spec: close({
	label:    strings.MinRunes(1) & strings.MaxRunes(40)
	warning:  number & >=0
	critical: number & >=0
	format?:  *"number" | "percent"
})
```

```sh
copy_to_plugin status-badge.cue schemas/panels/status-badge/status-badge.cue
```

What each change does:

- `import "strings"` makes the CUE standard package `strings` available.
- `strings.MinRunes(1) & strings.MaxRunes(40)` limits the label to between 1 and 40 characters. `&` means the value must satisfy both.
- `number & >=0` means a number that is 0 or more.
- `format?:` is an optional field. `*"number" | "percent"` lists the two allowed values and marks `"number"` as the default.
- `close({ ... })` is unchanged, so any other field is still refused.

## Step 3: Write the tests

Each test is a JSON file with a complete definition. Valid tests go in `tests/valid`, and invalid ones in `tests/invalid`, inside the schema folder. A test should change one thing, so that a failure points at one rule.

Valid cases:

```sh
echo '{"kind":"StatusBadge","spec":{"label":"Targets up","warning":1,"critical":0}}' > basic.json
echo '{"kind":"StatusBadge","spec":{"label":"Targets up","warning":0,"critical":0}}' > zero-limits.json
echo '{"kind":"StatusBadge","spec":{"label":"Targets up","warning":1,"critical":0,"format":"percent"}}' > percent.json
copy_to_plugin basic.json schemas/panels/status-badge/tests/valid/basic.json
copy_to_plugin zero-limits.json schemas/panels/status-badge/tests/valid/zero-limits.json
copy_to_plugin percent.json schemas/panels/status-badge/tests/valid/percent.json
```

Invalid cases:

```sh
echo '{"kind":"StatusBadge","spec":{"label":"","warning":1,"critical":0}}' > empty-label.json
echo '{"kind":"StatusBadge","spec":{"label":"Targets up","warning":-1,"critical":0}}' > negative-warning.json
echo '{"kind":"StatusBadge","spec":{"label":"Targets up","warning":1,"critical":0,"format":"bytes"}}' > bad-format.json
echo '{"kind":"StatusBadge","spec":{"label":"Targets up","warning":1,"critical":0,"colour":"red"}}' > extra-field.json
echo '{"kind":"StatusBadge","spec":{"label":"Targets up","warning":1}}' > missing-critical.json
copy_to_plugin empty-label.json schemas/panels/status-badge/tests/invalid/empty-label.json
copy_to_plugin negative-warning.json schemas/panels/status-badge/tests/invalid/negative-warning.json
copy_to_plugin bad-format.json schemas/panels/status-badge/tests/invalid/bad-format.json
copy_to_plugin extra-field.json schemas/panels/status-badge/tests/invalid/extra-field.json
copy_to_plugin missing-critical.json schemas/panels/status-badge/tests/invalid/missing-critical.json
```

## Step 4: Run the tests and the lint

```sh
plugin_builder "cd status-badge && percli plugin test-schemas"
plugin_builder "cd status-badge && percli plugin lint"
```

`test-schemas` prints one line per test file and ends with a line that says all tests passed. If a valid test fails, the schema is too strict or the test is wrong. If an invalid test fails, it was accepted by the schema, which means the rule it tests is missing from the schema.

To see why a case is refused, run `cue vet` on it. From the module folder:

```sh
plugin_builder "cd status-badge/schemas/panels/status-badge && cue vet status-badge.cue tests/invalid/empty-label.json"
```

`cue vet` is expected to report an error for an invalid file. The test passes because of that error.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the grader holds cases back

If the grader used only your tests, a schema that accepts everything would pass with tests that accept everything. The grader therefore copies your schema into a temporary folder, replaces your tests with its own, and runs `percli plugin test-schemas` there. It covers the length limits at 1, 40 and 41 characters, negative limits, a string where a number belongs, a `format` outside the list, an unknown field and each missing required field.

## Common mistakes

- Putting the tests in `schemas/panels/status-badge/` instead of `schemas/panels/status-badge/tests/valid` or `.../invalid`. Tests outside these folders are not run.
- Writing a test with only the `spec`. The file must hold the whole object with `kind` and `spec`.
- Forgetting `close`, which makes the spec accept an unknown field.
- Writing `warning: number & > 0`. That refuses 0, which the task allows. Use `>=0`.

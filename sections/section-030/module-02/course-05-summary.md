# Summary

The Perses server checks the settings of every panel against the CUE schema of its plugin when a dashboard is saved. The check runs on the server, so it protects every client, and the browser sees only settings that the schema allows. A schema file is in the CUE package `model`, fixes the plugin `kind`, and describes the `spec`. Wrapping the spec in `close` makes it refuse unknown fields, and a field name followed by `?` makes the field optional.

A generated schema checks only types, so an empty label or a negative limit still passes. CUE narrows a field by combining rules with `&`. `strings.MinRunes` and `strings.MaxRunes` limit the length of a string, comparisons such as `>=0` limit the range of a number, and `|` lists the allowed values. A star marks a default. A default does not change the stored dashboard, so the component must apply it as well. Imports from the CUE standard library need no entry in `cue.mod`; other imports do.

Schema tests keep the rules in place. Each test is a JSON file with a complete `kind` and `spec`, stored in `tests/valid` for files that must be accepted or in `tests/invalid` for files that must be refused, next to the schema. `percli plugin test-schemas` runs them all, prints one line per file and a summary, and exits with an error when a test fails. A good test changes one thing and covers the boundaries. A test that cannot fail proves nothing, so break a rule once to see its test fail.

A failed valid test means the schema is stricter than intended or the test is wrong. A failed invalid test means a rule is missing or too loose. `cue vet` with the schema and the file prints the reason for a refused file and nothing for an accepted one. `percli plugin lint` then confirms that the module is well formed.

<!-- astrona:playground:destroy -->

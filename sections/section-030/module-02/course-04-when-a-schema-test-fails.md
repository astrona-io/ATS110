# When A Schema Test Fails

A schema test has two ways to fail, and each points at a different fault. Either a file that should be accepted is refused, or a file that should be refused is accepted. This part shows how to tell them apart, how to see the reason with `cue vet`, and how to fix each. The graded lab at the end asks you to do all of it in one module.

## Read the failure first

The summary line of `percli plugin test-schemas` says that some tests failed, and the line for each failed file names it. The name tells you which folder it is in. That already tells you the kind of fault:

- A failed file in `tests/valid` was refused by the schema. Either the schema is stricter than intended, or the test file is wrong.
- A failed file in `tests/invalid` was accepted by the schema. A rule is missing, or it is written too loosely.

Start with the file, not the schema. Open it, read what it says, and decide which result you want.

## A valid test is refused

Take the valid file `zero-limits.json`, which has `warning` and `critical` set to 0. If the schema says `number & >0`, this file is refused, and the test fails. To see the reason, run `cue vet` with the schema and the file from the schema folder:

<!-- astrona:playground:renew -->

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
SCHEMA_DIR=status-badge/schemas/panels/status-badge
plugin_builder "cd $SCHEMA_DIR && cue vet status-badge.cue tests/valid/zero-limits.json"
```

The error names the field, here `spec.warning`, and says that the value 0 conflicts with the rule `>0`. The message points at the rule to change. Decide which side is right. If 0 is a legal limit, the schema is wrong: change `>0` to `>=0`. If 0 must be refused, the test is in the wrong folder: move it to `tests/invalid`.

Other causes of a refused valid file are a typo in a field name (the schema is closed, so `waring` is an unknown field) and JSON that is not valid JSON, such as a trailing comma. `cue vet` reports a syntax error for the second.

## An invalid test is accepted

Take the invalid file `extra-field.json`, with `"colour": "red"` in the spec. If the schema has lost `close`, this file is accepted, and the test fails. `cue vet` prints nothing for it, which is the clue: nothing refused the file. The reason is the absence of a rule, so it cannot be read from a message. Compare the schema with the requirement and look for the rule that should have refused the file.

The usual causes are a missing `close`, a field typed as `string` that should have a length rule, a range written with `>0` where `<0` was meant, and a list of choices that is not a list. Another cause is a field wrongly marked optional with `?`, so a file that leaves it out is accepted.

A related surprise is a file that fails to be accepted for a reason you did not intend. An invalid test for a missing `critical` field must contain nothing else wrong. If it also has a bad `format`, it is refused for two reasons, and it still passes when the required-field rule is gone. Keep each invalid file at one fault.

## Tests that do not run

If the summary reports fewer tests than you expect, a file is outside the folders `percli` reads. Check three things. The folder is named `tests`, with `valid` and `invalid` inside it. It sits next to the `.cue` file of the plugin and not in the module root. And the file name ends in `.json`. List the files from the module folder:

```sh
plugin_builder "cd status-badge && find schemas -name '*.json' | sort"
```

The list shows every JSON file under `schemas`, including the example file next to the schema. Compare it with the count in the summary.

## When lint fails after you edit the schema

`percli plugin lint` checks that the schema exists and is correct CUE for the plugin. A syntax error such as a missing brace or a field without a rule makes it fail. An `import` of a package that is not in `cue.mod` makes it fail too, and `cue mod tidy` run in the module fixes the missing entry. Run lint after the tests: tests tell you what the schema does, lint tells you whether the module can be built.

## Common pitfalls

> [!WARNING]
> - **Fixing the test to match the schema.** Decide first what the requirement says. A test changed to pass hides the fault it found.
> - **Reading a silent `cue vet` as a failure.** On a valid file, silence means success. On an invalid file, silence is the fault.
> - **Counting passed tests without counting files.** Compare the summary with the list of files to catch a test that never ran.
> - **Leaving `close` out of a scratch copy and forgetting to put it back.** Check the final schema before you submit.

## Your mission: Constrain And Test The StatusBadge Schema

You can now tighten a plugin schema and prove with tests that it keeps its rules. The graded lab gives you a generated `status-badge` module whose schema accepts anything, and asks you to add the length, range, format and closed-spec rules, write the valid and invalid tests, and make the tests and lint pass.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-110-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-110-lab-030-02
astrona start ats-110-playground-030-02
```

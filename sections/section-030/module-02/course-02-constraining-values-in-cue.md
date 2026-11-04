# Constraining Values In CUE

A schema that checks only types lets bad values through. A label of zero characters is still a string, and a negative limit is still a number. CUE lets you narrow a field by combining its type with rules about its value. This part covers the rules a plugin schema needs most: length, range, a fixed list of choices, optional fields and default values.

## Limit the length of a string

The CUE standard package `strings` has functions that work as rules. `strings.MinRunes(1)` accepts a string with at least one character, and `strings.MaxRunes(40)` accepts a string with at most 40. A rune is one Unicode character, so a label written with accented letters counts by letters, not by bytes. Import the package at the top of the file and join the two rules with `&`:

```cue
import "strings"

label: strings.MinRunes(1) & strings.MaxRunes(40)
```

The field now accepts a string with 1 to 40 characters. The empty string and a string of 41 characters are refused. `strings` is part of CUE itself, so the import needs no module download. Imports from other modules, such as the Perses schema packages, are different: they need an entry in `cue.mod/module.cue`, and `cue mod tidy` keeps that entry correct.

To require a pattern instead of a length, `=~` matches a regular expression. For example, `name: string & =~"^[a-z][a-z0-9-]*$"` accepts lowercase names with digits and hyphens.

## Limit the range of a number

A comparison is also a value in CUE. `>=0` accepts any number that is 0 or more, and `<=100` accepts any number that is 100 or less. Join one with `number`:

```cue
warning:  number & >=0
critical: number & >=0
percent:  number & >=0 & <=100
```

`>0` and `>=0` differ in one value. `>0` refuses 0. If a limit of 0 is meaningful, as it is for a badge that turns red as soon as the value is above zero, use `>=0`. The type `int` accepts only whole numbers, so `int & >=1` means a whole number of at least 1.

## List the allowed values

To allow a few fixed values, list them with `|`, which means "or". A field that accepts only two words looks like this:

```cue
format: "number" | "percent"
```

A value of `"bytes"` matches neither choice and is refused. This is how Perses plugins model options such as a legend position. A schema with a list of choices documents the options as well as enforcing them.

## Optional fields and defaults

A field name followed by `?` is optional. A spec without the field is valid, and a spec with the field must still satisfy the rule. `format?: "number" | "percent"` allows leaving `format` out.

A star in front of one choice marks it as the default: `format?: *"number" | "percent"`. The default has a narrow meaning. When CUE evaluates the schema and the field is present in the schema but absent from the data, the default is the value CUE would pick. A default does not change the stored dashboard, and Perses does not write it back. The plugin's React code must still handle a missing `format` itself, usually by applying the same default. Write the default in both places and keep them equal.

## A complete schema

Put the rules together. This is the schema the lab asks for. Save it as `status-badge.cue`:

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

Read it from the top. The package is `model`. The import brings in `strings`. The kind is fixed. The spec is closed, so only four fields are allowed. Three are required and have value rules, and `format` is optional with two choices and a default.

Check the file in the playground with a sample that should fail. Save this as `long-label.json`, where the label has 41 letters:

```json
{
  "kind": "StatusBadge",
  "spec": {
    "label": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "warning": 1,
    "critical": 0
  }
}
```

Copy the schema to `/workspace/status-badge/schemas/panels/status-badge/status-badge.cue` and the sample to `/workspace/long-label.json`, then run `cue vet`:

<!-- astrona:playground:renew -->

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cat > /workspace/status-badge/schemas/panels/status-badge/status-badge.cue" < status-badge.cue
kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cat > /workspace/long-label.json" < long-label.json
plugin_builder "cd status-badge/schemas/panels/status-badge && cue vet status-badge.cue /workspace/long-label.json"
```

The command reports an error on the field `spec.label`, because the string is longer than the 40 characters that `strings.MaxRunes(40)` allows. Change the label to 40 letters and run it again: the command prints nothing.

## What a schema cannot express

A schema checks one panel's settings in isolation. It cannot check that `warning` is lower than `critical`, because the rule would need to compare two fields. CUE can express such a rule in other places, but a plugin schema is normally kept to field-level rules, and the component handles the relation between two fields. If the order matters, say so in the plugin's settings editor and handle the reverse order safely in the component.

## Common pitfalls

> [!WARNING]
> - **Using `>0` when 0 is allowed.** The comparison refuses exactly the value you meant to allow.
> - **Thinking a default fills the stored dashboard.** Perses does not write it back. The component must apply the default too.
> - **Putting a long list of options in prose and not in the schema.** If a field accepts a few words, list them with `|` so that the server enforces them.
> - **Importing a package that is not in `cue.mod`.** Only the CUE standard packages, such as `strings`, need no entry. Other imports need one, and `cue mod tidy` adds it.

The schema now says what it should. What is still missing is proof that it keeps saying it after the next edit, which is what tests give.

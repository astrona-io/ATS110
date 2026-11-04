# What A Plugin Schema Checks

A dashboard is saved as JSON, and each panel in it carries a block of settings for its plugin. Something has to decide whether those settings make sense. That job belongs to the CUE schema in the plugin module. This part shows where the decision is made, what a CUE schema looks like, and how to read the schema of the `status-badge` module.

## Where the schema is used

CUE is a language for describing data and the rules it must follow. A Perses plugin module holds one schema file for each plugin, in the CUE package `model`. When someone saves a dashboard, the Perses server reads every panel, finds the plugin by its `kind` and checks the panel's `spec` against that plugin's schema. If the check fails, the server answers with an error and does not store the dashboard.

Two facts follow from this. The check runs on the server, so it protects every client: the Perses interface, `percli`, and your own application that calls the API. And the browser never sees a refused panel, so the React component only has to handle settings the schema allows. A rule moved from the component into the schema is checked once, in one place.

The schema does not run in the browser, and it does not check the query results. It checks only the settings the author typed.

## What a schema file looks like

Look at the schema of the generated module. The first command defines a helper for running commands in the builder pod, and the second prints the file:

<!-- astrona:playground:renew -->

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
plugin_builder "cat status-badge/schemas/panels/status-badge/status-badge.cue"
```

The file you see has four parts. `package model` declares the CUE package. Perses and `percli` look for exactly this package name, so it must not change. `kind: "StatusBadge"` fixes the plugin kind: a panel whose `kind` has any other value does not match this schema. `spec:` describes the settings. `close({ ... })` wraps the fields and means that the spec may contain only the fields listed. Without `close`, CUE accepts extra fields.

Inside the braces, each line is a field and a rule for its value. `label: string` says the field `label` is required and must be a string. `warning: number` says the field is required and must be a number. A field is required unless its name ends with a question mark.

## Types and values are the same thing in CUE

In most schema languages, a type and a value are different things. In CUE they are both values, ordered by how much they allow. `string` allows every string. `"Targets up"` allows one string. `number` allows every number. A schema narrows a field by combining values with `&`, which means both rules must hold. `string & "ok"` leaves only the string `"ok"`.

This is why the rest of the module is short. To limit a label's length or a number's range, you combine `string` or `number` with another rule. The rules CUE offers for this are covered next.

You can check a JSON file against a schema by hand with `cue vet`, which prints nothing when the file is valid and prints the reason when it is not. The schema file and the data file go on one command line. Save this as `refused.json`, copy it into the module, and check it:

```json
{
  "kind": "StatusBadge",
  "spec": {
    "label": "Targets up",
    "warning": "high",
    "critical": 0
  }
}
```

```sh
kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cat > /workspace/refused.json" < refused.json
plugin_builder "cd status-badge/schemas/panels/status-badge && cue vet status-badge.cue /workspace/refused.json"
```

The command reports an error that names the field `spec.warning` and says the string `"high"` does not match `number`. That message is what the Perses server turns into the answer to a save.

Now check a file with an extra field, such as `"colour": "red"` in the spec. Because of `close`, `cue vet` refuses it too. Remove `close` from a scratch copy of the schema and the same file passes. That difference is the reason this module treats `close` as part of the schema's job.

## What this schema does not stop

The generated schema of `status-badge` accepts an empty label, a label of a thousand characters, and a negative warning limit. Each of those is a string or a number, so each matches. The schema checks the type of each field and nothing about its value. Value rules fix this, and tests make sure the rules stay in place.

## Common pitfalls

> [!WARNING]
> - **Changing the package name.** `percli` and Perses look for the package `model`. A different name makes the schema invisible.
> - **Forgetting `close`.** Without it, an unknown field or a misspelled field name is accepted.
> - **Thinking the browser checks the schema.** The server checks it when the dashboard is saved. A dashboard that was stored before a stricter schema was installed is not checked again until it is saved.
> - **Reading a type as a promise about the data.** `number` accepts `-5` and `0.0001`. If a value must be positive, the schema must say so.

You now know where the schema works and how to read one. What is left open is how to say more than "string" and "number".

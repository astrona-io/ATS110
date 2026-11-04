# Constrain And Test Plugin Schemas

A panel plugin is only as safe as its schema. The schema is the file the Perses server uses to check the settings of every panel of that plugin when a dashboard is saved. A schema that accepts anything lets an empty label, a negative limit or a misspelled field into saved dashboards, and the browser then has to cope with them. A schema that is too strict refuses settings that are fine. The way to know which one you have is to test it.

Keep one sentence in mind: **a CUE schema is a set of rules about the shape and the values of a plugin's settings, and `percli plugin test-schemas` runs those rules against example files that must be accepted and example files that must be refused.**

The module has four parts. **What A Plugin Schema Checks** shows where the server uses the schema and how a CUE schema is built. **Constraining Values In CUE** adds length limits, number ranges, allowed values, defaults and optional fields. **Testing Schemas With percli** puts valid and invalid examples next to the schema and runs them. **When A Schema Test Fails** reads the failures you will meet and fixes them. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Say when and where Perses validates the settings of a plugin.
- Write a CUE schema in package `model` with required fields, optional fields and `close`.
- Limit a string by length, limit a number by range, and list the allowed values of a field.
- Set a default value with `*` and explain what it does and does not do.
- Place tests in `tests/valid` and `tests/invalid` and run `percli plugin test-schemas`.
- Explain why an invalid test that passes is a fault in the schema.
- Find the cause of a failed schema test with `cue vet`.

## Before you start

You should know what a plugin module is and where its schema lives. The module on writing a panel plugin covers that. CUE is explained here as far as a schema needs it. You do not need Node.js on your machine, and the exercises need no `npm install`.

Your playground has:

| Part | Where | What it is |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses` | The project `inventory` and the global datasource `prometheus` |
| Prometheus | namespace `observability` | The metrics server |
| `plugin-builder` | namespace `perses` | Node.js 22 with `percli` 0.54.0 and `cue` 0.17.1; workspace `/workspace` |
| `status-badge` | `/workspace/status-badge` in `plugin-builder` | A generated module with a permissive schema and no tests |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

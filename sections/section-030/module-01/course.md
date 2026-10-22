# Write And Install A Panel Plugin

A team wants one value on its dashboards as a coloured badge: green while it is fine, orange above a warning limit, red above a critical limit. No built-in panel does exactly that. A Perses plugin can, and once it is installed, it is used like any other panel, saved in dashboards and validated by the server.

Keep one sentence in mind: **a plugin has two halves, a CUE schema the server uses to check settings and a React component the browser uses to draw, and Perses loads both from one archive.**

The module has three parts. **Plugin Modules And Archives** explains the plugin types, the module that groups them, and how Perses loads archives at start. **Writing The StatusBadge Plugin** generates a module with `percli` and writes the schema and the component. **Building And Installing The Plugin** builds the archive, mounts it into Perses with Helm, and uses the panel in a dashboard. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Name the plugin types and explain what a plugin module is.
- List what a plugin archive contains and where Perses reads archives from.
- Generate a panel plugin with `percli plugin generate`.
- Write a CUE schema in package `model` and a matching React component.
- Build an archive with `percli plugin build`, and explain what it runs.
- Install an archive into Perses with a Helm values file, without hiding the bundled plugins.
- Prove a plugin works with `/api/v1/plugins` and a dashboard that uses it.

## Before you start

You should be able to read TypeScript and a small React component, and to run `kubectl exec` and `helm upgrade`. CUE is explained as far as the schema needs it. You do not need Node.js on your machine.

Your playground has:

| Part | Where | What it is |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses` | The project `inventory` and the global datasource `prometheus` |
| Prometheus | namespace `observability` | The metrics server |
| `plugin-builder` | namespace `perses` | Node.js 22 with `percli` 0.54.0 and `cue` 0.17.1; workspace `/workspace`; the volume `plugin-artifacts` at `/artifacts` |

The workspace starts empty: you generate the plugin module yourself. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

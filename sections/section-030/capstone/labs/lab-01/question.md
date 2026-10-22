# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Writing A Panel Plugin

## Scenario

`StatusBadge` 0.1.0 runs in Perses, and the dashboard `status` in the project `inventory` uses it. The on-call team now wants a unit after the value, for example "Targets up: 1 targets". The module is in `/workspace/status-badge` in the pod `plugin-builder` in the namespace `perses`, with its packages installed, and the 0.1.0 archive is on the volume `plugin-artifacts` and mounted into Perses.

## Your task

1. Add an optional field `unit` (string) to the plugin: to the schema, to the TypeScript types, and to the component, which shows it after the value when it is set.
2. Release it as version `0.2.0`: build the archive `StatusBadge-0.2.0.tar.gz` and put it on the volume.
3. Make Perses load 0.2.0 instead of 0.1.0.
4. Update the dashboard `status` so its badge has `unit: "targets"`.

## Constraints

- `unit` must be optional: dashboards without it stay valid.
- Perses must load exactly one `StatusBadge` module, at version `0.2.0`, next to the plugins that ship with Perses.
- Do not reinstall Perses from scratch.

## Done when

- `/artifacts/StatusBadge-0.2.0.tar.gz` holds the frontend files and the schema.
- `/api/v1/plugins` lists `StatusBadge` once, at `0.2.0`, and still lists `TimeSeriesChart`.
- Perses accepts a `StatusBadge` spec with `unit` and still refuses `warning: "high"`.
- The dashboard `status` uses `unit: "targets"`.

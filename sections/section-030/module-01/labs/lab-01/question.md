# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Writing A Panel Plugin

## Scenario

The on-call team wants one value per dashboard as a coloured badge: a label, the current value, green below a warning limit, orange from the warning limit, red from the critical limit. A colleague already ran `percli plugin generate` and `npm install` for a module called `status-badge`, then left the generated template files as they were.

The module is in `/workspace/status-badge` in the pod `plugin-builder` in the namespace `perses`. That pod has `percli` and `cue` on its PATH and the volume `plugin-artifacts` at `/artifacts`. Perses v0.54.0 runs in the namespace `perses` as the Helm release `perses` (chart `perses/perses`, version `0.23.3`).

## Your task

1. Turn the generated panel into the `StatusBadge` panel:
   - its schema allows exactly the fields `label` (string), `warning` (number) and `critical` (number), all required;
   - its component shows the label and the last value of the first query's first series, coloured by the two limits.
2. Build the plugin archive and put `StatusBadge-0.1.0.tar.gz` on the volume `plugin-artifacts`.
3. Install it into Perses so Perses loads it next to the plugins that ship with Perses.
4. Create the dashboard `status` in the project `inventory`, with one `StatusBadge` panel labelled `Targets up` and the query `count(up == 1)`.

## Constraints

- Keep the plugin kind `StatusBadge` and the module version `0.1.0`.
- Do not remove or replace the plugins that ship with Perses.
- Do not reinstall Perses from scratch; change the existing release.

## Done when

- `/artifacts/StatusBadge-0.1.0.tar.gz` holds the frontend files and the schema `status-badge.cue`.
- `/api/v1/plugins` lists `StatusBadge` at version `0.1.0`, and still lists `TimeSeriesChart`.
- Perses accepts a dashboard with a valid `StatusBadge` spec and refuses one with `warning: "high"`.
- The dashboard `status` in the project `inventory` uses a `StatusBadge` panel.

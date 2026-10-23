# Writing The StatusBadge Plugin

Perses ships charts, tables and gauges, but sometimes a team wants one specific view: a single coloured badge that turns orange or red when a value crosses a limit. That is a panel plugin. This part generates a plugin module with `percli`, and writes the two pieces every panel plugin has: a CUE schema the Perses server uses to check the panel's settings, and a React component the browser uses to draw it.

## Generate the module

`percli plugin generate` writes a complete plugin module from templates built into `percli`, so it needs no network. It writes the files into the directory named as its last argument, and that directory must already exist. Create it and run the command in the builder pod, in `/workspace`:

<!-- astrona:playground:renew -->

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
plugin_builder "mkdir -p status-badge && percli plugin generate --module.org=astrona --module.name=status-badge \
  --plugin.type=Panel --plugin.name=status-badge --plugin.display-name='Status Badge' status-badge"
plugin_builder "find status-badge -path '*/node_modules' -prune -o -type f -print | sort"
```

The flags name the npm organisation (`astrona`), the module (`status-badge`), the plugin type (`Panel`) and the plugin (`status-badge`, shown as "Status Badge"). From the kebab-case name, `percli` also makes the PascalCase name `StatusBadge`, which is the plugin's `kind` in a dashboard. The file list shows the module files at the top (`package.json`, `rsbuild.config.ts`, `cue.mod/module.cue`, `tsconfig.json`), the schema in `schemas/panels/status-badge/`, and the React code in `src/panels/status-badge/`.

Look at the `perses` block of `package.json`, which tells Perses what the module holds:

```sh
plugin_builder "node -e \"console.log(JSON.stringify(require('./status-badge/package.json').perses, null, 2))\""
```

It names the module `StatusBadge` in the organisation `astrona`, points at the `schemas` folder, and lists one plugin of kind `Panel` with the name `StatusBadge` and the display name "Status Badge".

## The schema

The generated schema is a template for a chart with a legend and thresholds. The badge needs three settings: a label, a warning limit and a critical limit. The file must stay in the CUE package `model`, and its `kind` must match the plugin name. Save this as `status-badge.cue`:

```cue
package model

kind: "StatusBadge"
spec: close({
	label:    string
	warning:  number
	critical: number
})
```

`close({...})` means the spec may contain only these fields: a panel with any other field is refused. `label: string` and the two `number` fields are required, because none of them has a `?`. When a dashboard is saved, the Perses server validates every `StatusBadge` panel against this schema, so a panel with `warning: "high"` never reaches the browser.

Each schema folder also holds a JSON example of a valid spec. Save this as `status-badge.json`:

```json
{
  "kind": "StatusBadge",
  "spec": {
    "label": "Targets up",
    "warning": 1,
    "critical": 0
  }
}
```

## The types and the component

The React side starts with the TypeScript type of the spec, which must match the schema. Save this as `status-badge-types.ts`:

```typescript
import { TimeSeriesData } from '@perses-dev/spec';
import { PanelProps } from '@perses-dev/plugin-system';

export type QueryData = TimeSeriesData;

export interface StatusBadgeOptions {
  label: string;
  warning: number;
  critical: number;
}

export type StatusBadgeProps = PanelProps<StatusBadgeOptions, QueryData>;
```

The component receives two properties from Perses: `spec`, the panel's settings, and `queryResults`, one entry per query with its data. For a time series query, the data is a list of series, and each series has `values`, a list of `[timestamp, value]` pairs. The badge takes the last value of the first series and picks a colour. Save this as `StatusBadgeComponent.tsx`:

```tsx
import { ReactElement } from 'react';
import { StatusBadgeProps } from './status-badge-types';

// The last value of the first series of the first query decides the colour.
export function StatusBadgeComponent(props: StatusBadgeProps): ReactElement {
  const { queryResults, spec } = props;
  const series = queryResults[0]?.data.series[0];
  const lastPoint = series?.values[series.values.length - 1];
  const value = lastPoint ? lastPoint[1] : null;

  let colour = '#2e7d32';
  if (value === null) {
    colour = '#757575';
  } else if (value >= spec.critical) {
    colour = '#c62828';
  } else if (value >= spec.warning) {
    colour = '#ef6c00';
  }

  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' }}>
      <span style={{ background: colour, color: '#ffffff', borderRadius: 16, padding: '8px 16px', fontWeight: 600 }}>
        {spec.label}: {value === null ? 'no data' : value}
      </span>
    </div>
  );
}
```

The settings editor is what the Perses dashboard editor shows when someone edits the panel. It uses plain HTML inputs, so the plugin needs no extra UI library. Save this as `StatusBadgeSettingsEditor.tsx`:

```tsx
import { ReactElement } from 'react';
import { OptionsEditorProps } from '@perses-dev/plugin-system';
import { StatusBadgeOptions } from './status-badge-types';

// Plain inputs keep the plugin free of extra UI libraries.
export function StatusBadgeSettingsEditor(props: OptionsEditorProps<StatusBadgeOptions>): ReactElement {
  const { value, onChange } = props;
  return (
    <div style={{ display: 'grid', gap: 8, maxWidth: 320 }}>
      <label>
        Label <input value={value.label} onChange={(event) => onChange({ ...value, label: event.target.value })} />
      </label>
      <label>
        Warning at{' '}
        <input type="number" value={value.warning}
          onChange={(event) => onChange({ ...value, warning: Number(event.target.value) })} />
      </label>
      <label>
        Critical at{' '}
        <input type="number" value={value.critical}
          onChange={(event) => onChange({ ...value, critical: Number(event.target.value) })} />
      </label>
    </div>
  );
}
```

Last, the plugin object ties the pieces together. `supportedQueryTypes` says the badge accepts time series queries, and `createInitialOptions` gives a new panel valid settings. Save this as `StatusBadge.tsx`:

```tsx
import { PanelPlugin } from '@perses-dev/plugin-system';
import { StatusBadgeComponent } from './StatusBadgeComponent';
import { StatusBadgeSettingsEditor } from './StatusBadgeSettingsEditor';
import { StatusBadgeOptions, StatusBadgeProps } from './status-badge-types';

export const StatusBadge: PanelPlugin<StatusBadgeOptions, StatusBadgeProps> = {
  PanelComponent: StatusBadgeComponent,
  panelOptionsEditorComponents: [{ label: 'Settings', content: StatusBadgeSettingsEditor }],
  supportedQueryTypes: ['TimeSeriesQuery'],
  createInitialOptions: () => ({ label: 'Status', warning: 80, critical: 90 }),
};
```

## Put the files in place

A helper copies one file from your machine into the module:

```sh
copy_to_plugin() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cat > /workspace/status-badge/$2" < "$1"; }
copy_to_plugin status-badge.cue schemas/panels/status-badge/status-badge.cue
copy_to_plugin status-badge.json schemas/panels/status-badge/status-badge.json
copy_to_plugin status-badge-types.ts src/panels/status-badge/status-badge-types.ts
copy_to_plugin StatusBadgeComponent.tsx src/panels/status-badge/StatusBadgeComponent.tsx
copy_to_plugin StatusBadgeSettingsEditor.tsx src/panels/status-badge/StatusBadgeSettingsEditor.tsx
copy_to_plugin StatusBadge.tsx src/panels/status-badge/StatusBadge.tsx
```

The schema can be checked before anything is built. `cue vet` validates the JSON example against the schema; it reports nothing when they fit:

```sh
plugin_builder "cd status-badge/schemas/panels/status-badge && cue vet status-badge.cue status-badge.json"
```

You have now written a panel plugin: a schema the server enforces, and a component, editor and plugin object the browser runs. They are still only source files. The open question is how to turn them into an archive and get Perses to load it.

## Common pitfalls

> [!WARNING]
> - **Generating into a directory that does not exist.** `percli plugin generate` stops with `destination directory ... does not exists`. Create the directory first.
> - **A schema `kind` that differs from the plugin name.** Perses matches the panel's `kind` with the schema's `kind`; `StatusBadge` must be the same in both.
> - **Moving the schema out of package `model`.** Perses only reads schemas in that package.
> - **Types that do not match the schema.** The schema decides what the server accepts; the types only help the compiler.
> - **Importing a UI library the module does not declare.** It ends up bundled into the plugin, or missing at run time.

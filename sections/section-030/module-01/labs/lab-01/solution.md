# Solution: Build And Install The StatusBadge Panel Plugin

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the archive on the volume, the plugin in `/api/v1/plugins` next to the bundled plugins, the schema enforced on save, and the dashboard `status`.

## Step 1: Write the plugin files

The module `status-badge` is already generated in `/workspace/status-badge`, with its npm packages installed. Replace the generated schema and component with the badge. Save these six files.

`status-badge.cue`:

```cue
package model

kind: "StatusBadge"
spec: close({
	label:    string
	warning:  number
	critical: number
})
```

`status-badge.json`:

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

`status-badge-types.ts`:

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

`StatusBadgeComponent.tsx`:

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

`StatusBadgeSettingsEditor.tsx`:

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

`StatusBadge.tsx`:

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

Copy them into the module:

```sh
copy_to_plugin() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cat > /workspace/status-badge/$2" < "$1"; }
copy_to_plugin status-badge.cue schemas/panels/status-badge/status-badge.cue
copy_to_plugin status-badge.json schemas/panels/status-badge/status-badge.json
copy_to_plugin status-badge-types.ts src/panels/status-badge/status-badge-types.ts
copy_to_plugin StatusBadgeComponent.tsx src/panels/status-badge/StatusBadgeComponent.tsx
copy_to_plugin StatusBadgeSettingsEditor.tsx src/panels/status-badge/StatusBadgeSettingsEditor.tsx
copy_to_plugin StatusBadge.tsx src/panels/status-badge/StatusBadge.tsx
```

## Step 2: Build the archive and put it on the volume

```sh
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
plugin_builder "cd status-badge && cue mod tidy && percli plugin build"
plugin_builder "cp status-badge/StatusBadge-0.1.0.tar.gz /artifacts/ && tar -tzf /artifacts/StatusBadge-0.1.0.tar.gz | head -20"
```

The listing shows `package.json`, `mf-manifest.json`, the `__mf` folder and `schemas/panels/status-badge/status-badge.cue`.

## Step 3: Mount the archive into Perses

Save this as `perses-plugin-values.yaml`:

```yaml
volumes:
  - name: plugin-artifacts
    persistentVolumeClaim:
      claimName: plugin-artifacts
      readOnly: true
volumeMounts:
  - name: plugin-artifacts
    mountPath: /etc/perses/plugins-archive/StatusBadge-0.1.0.tar.gz
    subPath: StatusBadge-0.1.0.tar.gz
    readOnly: true
```

```sh
helm upgrade perses perses/perses --version 0.23.3 --namespace perses --reuse-values \
  --values perses-plugin-values.yaml --wait
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses.svc.cluster.local:8080/api/v1/plugins | jq -r ".[].metadata.name"' | grep -E 'StatusBadge|TimeSeriesChart'
```

Both `StatusBadge` and `TimeSeriesChart` are listed.

## Step 4: Create the dashboard

Save this as `dashboard-status.json`:

```json
{"kind":"Dashboard","metadata":{"name":"status","project":"inventory"},"spec":{"display":{"name":"status"},"duration":"1h","variables":[],"panels":{"badge":{"kind":"Panel","spec":{"display":{"name":"Badge"},"plugin":{"kind":"StatusBadge","spec":{"label":"Targets up","warning":1,"critical":0}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"count(up == 1)"}}}}]}}},"layouts":[{"kind":"Grid","spec":{"items":[{"x":0,"y":0,"width":6,"height":4,"content":{"$ref":"#/spec/panels/badge"}}]}}]}}
```

With `kubectl -n perses port-forward svc/perses 8080:8080` running in a second terminal:

```sh
percli login http://perses.localtest.me:8080
percli apply -f dashboard-status.json
```

`percli` answers that the dashboard `status` was created in the project `inventory`. Open `http://perses.localtest.me:8080/projects/inventory/dashboards/status`: the badge reads "Targets up: 1".

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Mount the whole volume at `/etc/perses/plugins-archive` | The bundled plugin archives disappear; `TimeSeriesChart` and the Prometheus plugin are gone |
| Upgrade Helm before copying the archive | The `subPath` does not exist yet, so the kubelet creates an empty folder with the archive's name |
| A schema with `spec: {...}` and no fields | Every panel passes; the grader checks that a wrong `warning` is refused |

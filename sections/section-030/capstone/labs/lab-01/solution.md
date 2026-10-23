# Solution: Ship Version 0.2.0 Of A Panel Plugin

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The change has three layers: the schema the server checks, the code the browser runs, and the archive Perses loads. All three must move to 0.2.0 together.

## Step 1: Add the field to the schema and the types

Save this as `status-badge.cue`:

```cue
package model

kind: "StatusBadge"
spec: close({
	label:    string
	warning:  number
	critical: number
	unit?:    string
})
```

Save this as `status-badge-types.ts`:

```typescript
import { TimeSeriesData } from '@perses-dev/spec';
import { PanelProps } from '@perses-dev/plugin-system';

export type QueryData = TimeSeriesData;

export interface StatusBadgeOptions {
  label: string;
  warning: number;
  critical: number;
  unit?: string;
}

export type StatusBadgeProps = PanelProps<StatusBadgeOptions, QueryData>;
```

## Step 2: Show the unit in the component

Save this as `StatusBadgeComponent.tsx`:

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
        {value !== null && spec.unit ? ` ${spec.unit}` : ''}
      </span>
    </div>
  );
}
```

Copy the three files in and raise the version:

```sh
copy_to_plugin() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cat > /workspace/status-badge/$2" < "$1"; }
plugin_builder() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $*"; }
copy_to_plugin status-badge.cue schemas/panels/status-badge/status-badge.cue
copy_to_plugin status-badge-types.ts src/panels/status-badge/status-badge-types.ts
copy_to_plugin StatusBadgeComponent.tsx src/panels/status-badge/StatusBadgeComponent.tsx
plugin_builder "cd status-badge && npm pkg set version=0.2.0 && grep '\"version\"' package.json"
```

## Step 3: Build and publish the new archive

```sh
plugin_builder "cd status-badge && cue mod tidy && percli plugin build && cp StatusBadge-0.2.0.tar.gz /artifacts/"
plugin_builder "ls -l /artifacts"
```

Both `StatusBadge-0.1.0.tar.gz` and `StatusBadge-0.2.0.tar.gz` are on the volume now. That is fine: Perses only loads the file that is mounted.

## Step 4: Mount 0.2.0 instead of 0.1.0

Save this as `perses-plugin-values.yaml`:

```yaml
volumes:
  - name: plugin-artifacts
    persistentVolumeClaim:
      claimName: plugin-artifacts
      readOnly: true
volumeMounts:
  - name: plugin-artifacts
    mountPath: /etc/perses/plugins-archive/StatusBadge-0.2.0.tar.gz
    subPath: StatusBadge-0.2.0.tar.gz
    readOnly: true
```

The list replaces the old mount; `--reuse-values` takes the new lists from this file, so the 0.1.0 mount is gone:

```sh
helm upgrade perses perses/perses --version 0.23.3 --namespace perses --reuse-values \
  --values perses-plugin-values.yaml --wait
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses.svc.cluster.local:8080/api/v1/plugins | jq -r ".[] | select(.metadata.name == \"StatusBadge\") | .metadata.version"'
```

The answer is one line: `0.2.0`.

## Step 5: Use the unit in the dashboard

Save this as `dashboard-status.json`:

```json
{"kind":"Dashboard","metadata":{"name":"status","project":"inventory"},"spec":{"display":{"name":"status"},"duration":"1h","variables":[],"panels":{"badge":{"kind":"Panel","spec":{"display":{"name":"Badge"},"plugin":{"kind":"StatusBadge","spec":{"label":"Targets up","warning":1,"critical":0,"unit":"targets"}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"count(up == 1)"}}}}]}}},"layouts":[{"kind":"Grid","spec":{"items":[{"x":0,"y":0,"width":6,"height":4,"content":{"$ref":"#/spec/panels/badge"}}]}}]}}
```

With `kubectl -n perses port-forward svc/perses 8080:8080` running:

```sh
percli login http://perses.localtest.me:8080
percli apply -f dashboard-status.json
```

`percli` reports the dashboard as updated. The badge reads "Targets up: 1 targets".

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add a second mount for 0.2.0 and keep 0.1.0 | Perses finds two modules with the same plugin; the grader expects exactly one, at 0.2.0 |
| Make `unit` required | The existing dashboard without `unit` fails validation the next time anyone saves it |
| Rebuild without raising the version | The archive is still named `StatusBadge-0.1.0.tar.gz`, and nobody can tell the two builds apart |

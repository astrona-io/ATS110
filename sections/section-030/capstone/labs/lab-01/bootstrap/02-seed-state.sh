#!/usr/bin/env bash
# Creates the starting state for ats-110-capstone-030.
#
# The fix is NOT applied here: producing it is the task.
set -euo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

HELM_VERSION="3.22.1"
PERSES_VERSION="0.54.0"
PERSES_CHART_VERSION="0.23.3"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT


perses_call() {
  # perses_call METHOD PATH [JSON]: calls the Perses API from the tester pod.
  # Prints the response body, then the HTTP status code on the last line.
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | kubectl -n observability exec -i deploy/tester -- \
      curl -s -w '\n%{http_code}' -X "$method" -H 'Content-Type: application/json' \
      --data-binary @- "http://perses.perses.svc.cluster.local:8080$path"
  else
    kubectl -n observability exec deploy/tester -- \
      curl -s -w '\n%{http_code}' -X "$method" "http://perses.perses.svc.cluster.local:8080$path"
  fi
}
http_code() { tail -n 1; }
builder_sh() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $1"; }
put_app_file() {
  # put_app_file LOCAL_FILE PATH_IN_APP
  kubectl -n embed exec -i deploy/app-builder -- sh -c "mkdir -p \"\$(dirname '/workspace/app/$2')\" && cat > '/workspace/app/$2'" < "$1"
}
plugin_sh() { kubectl -n perses exec -i deploy/plugin-builder -- sh -c "cd /workspace && $1"; }
put_plugin_file() {
  # put_plugin_file LOCAL_FILE PATH_IN_MODULE
  kubectl -n perses exec -i deploy/plugin-builder -- sh -c "mkdir -p \"\$(dirname '/workspace/status-badge/$2')\" && cat > '/workspace/status-badge/$2'" < "$1"
}
app_get() { kubectl -n observability exec deploy/tester -- curl -s "http://app.localtest.me:8081$1"; }

echo "[env] Generating the plugin module status-badge and installing its npm packages (several minutes)..."
# percli writes the module into the directory it is given, which must exist.
plugin_sh "test -f status-badge/package.json || { mkdir -p status-badge && percli plugin generate --module.org=astrona --module.name=status-badge \
  --plugin.type=Panel --plugin.name=status-badge --plugin.display-name='Status Badge' status-badge; }"
plugin_sh "cd status-badge && npm install --no-audit --no-fund"

cat > "$WORK/status-badge.cue" <<'SOURCEFILE'
package model

kind: "StatusBadge"
spec: close({
	label:    string
	warning:  number
	critical: number
})
SOURCEFILE
cat > "$WORK/status-badge.json" <<'SOURCEFILE'
{
  "kind": "StatusBadge",
  "spec": {
    "label": "Targets up",
    "warning": 1,
    "critical": 0
  }
}
SOURCEFILE
cat > "$WORK/status-badge-types.ts" <<'SOURCEFILE'
import { TimeSeriesData } from '@perses-dev/spec';
import { PanelProps } from '@perses-dev/plugin-system';

export type QueryData = TimeSeriesData;

export interface StatusBadgeOptions {
  label: string;
  warning: number;
  critical: number;
}

export type StatusBadgeProps = PanelProps<StatusBadgeOptions, QueryData>;
SOURCEFILE
cat > "$WORK/StatusBadgeComponent.tsx" <<'SOURCEFILE'
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
SOURCEFILE
cat > "$WORK/StatusBadgeSettingsEditor.tsx" <<'SOURCEFILE'
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
SOURCEFILE
cat > "$WORK/StatusBadge.tsx" <<'SOURCEFILE'
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
SOURCEFILE
cat > "$WORK/perses-plugin-values.yaml" <<'SOURCEFILE'
# Mounts one plugin archive from the volume plugin-artifacts into the folder
# Perses reads plugin archives from. subPath mounts only that file, so the
# plugins that ship with Perses in the same folder stay visible.
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
SOURCEFILE
put_plugin_file "$WORK/status-badge.cue" schemas/panels/status-badge/status-badge.cue
put_plugin_file "$WORK/status-badge.json" schemas/panels/status-badge/status-badge.json
put_plugin_file "$WORK/status-badge-types.ts" src/panels/status-badge/status-badge-types.ts
put_plugin_file "$WORK/StatusBadgeComponent.tsx" src/panels/status-badge/StatusBadgeComponent.tsx
put_plugin_file "$WORK/StatusBadgeSettingsEditor.tsx" src/panels/status-badge/StatusBadgeSettingsEditor.tsx
put_plugin_file "$WORK/StatusBadge.tsx" src/panels/status-badge/StatusBadge.tsx
echo "[lab] Building and installing StatusBadge 0.1.0..."
plugin_sh "cd status-badge && percli plugin build && cp StatusBadge-0.1.0.tar.gz /artifacts/"
helm upgrade perses perses/perses --version "$PERSES_CHART_VERSION" --namespace perses --reuse-values \
  --values "$WORK/perses-plugin-values.yaml" --wait --timeout 10m
for _ in $(seq 1 60); do
  perses_call GET /api/v1/plugins | grep -q '"StatusBadge"' && break
  sleep 5
done
perses_call POST /api/v1/projects/inventory/dashboards '{"kind":"Dashboard","metadata":{"name":"status","project":"inventory"},"spec":{"display":{"name":"status"},"duration":"1h","variables":[],"panels":{"badge":{"kind":"Panel","spec":{"display":{"name":"Badge"},"plugin":{"kind":"StatusBadge","spec":{"label":"Targets up","warning":1,"critical":0}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"count(up == 1)"}}}}]}}},"layouts":[{"kind":"Grid","spec":{"items":[{"x":0,"y":0,"width":6,"height":4,"content":{"$ref":"#/spec/panels/badge"}}]}}]}}' >/dev/null || true

echo "[lab] Starting state ready."

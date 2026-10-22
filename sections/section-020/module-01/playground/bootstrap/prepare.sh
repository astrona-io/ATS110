#!/usr/bin/env bash
# OS prep for the "Embedding Panels In A React Application" playground (`ats-110-playground-020-01`).
#
# Environment preparation only. There is no task and no grading.
set -euo pipefail

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

# Pin the tools rather than accepting whatever is on the machine.
have_helm=""
command -v helm >/dev/null 2>&1 && have_helm=$(helm version --template '{{.Version}}' 2>/dev/null | sed 's/^v//')
if [ "$have_helm" != "$HELM_VERSION" ]; then
  echo "[env] Downloading Helm ${HELM_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$WORK"
  install -m 0755 "$WORK/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
fi
# percli ships in the Perses release archive, next to the server binary.
have_percli=""
command -v percli >/dev/null 2>&1 && have_percli=$(percli version 2>/dev/null | awk '/[Vv]ersion/{print $NF; exit}' | sed 's/^v//')
if [ "$have_percli" != "$PERSES_VERSION" ]; then
  echo "[env] Downloading percli ${PERSES_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://github.com/perses/perses/releases/download/v${PERSES_VERSION}/perses_${PERSES_VERSION}_${OS}_${ARCH}.tar.gz" \
    | tar -xz -C "$WORK" percli
  install -m 0755 "$WORK/percli" "$BIN_DIR/percli"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

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

add_coredns_rewrite() {
  # add_coredns_rewrite HOST TARGET: appends a rewrite block to $COREFILE.
  local host="$1" target="$2"
  printf '%s' "$COREFILE" | grep -q "$host" && return 0
  COREFILE="$(printf '%s\n' "$COREFILE" | \
    HOST_RE="$(printf '%s' "$host" | sed 's/\./\\./g')" \
    TARGET_RE="$(printf '%s' "$target" | sed 's/\./\\./g')" \
    HOST="$host" TARGET="$target" awk '
      /^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print "        name regex " ENVIRON["HOST_RE"] " " ENVIRON["TARGET"]
        print "        answer name " ENVIRON["TARGET_RE"] " " ENVIRON["HOST"]
        print "    }"
        done=1
      } {print}')"
}
COREFILE="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}')"
ORIGINAL_COREFILE="$COREFILE"
add_coredns_rewrite perses.localtest.me perses.perses.svc.cluster.local
add_coredns_rewrite app.localtest.me embed-app.embed.svc.cluster.local
if [ "$COREFILE" != "$ORIGINAL_COREFILE" ]; then
  echo "[env] Updating CoreDNS..."
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$COREFILE" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
fi

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
echo "[env] Starting Prometheus and the tester pod..."
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
kubectl -n observability rollout status deployment/prometheus --timeout=300s
kubectl -n observability rollout status deployment/tester --timeout=300s

echo "[env] Installing Perses (chart ${PERSES_CHART_VERSION})..."
helm repo add perses https://perses.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update perses >/dev/null
helm upgrade --install perses perses/perses --version "$PERSES_CHART_VERSION" \
  --namespace perses --create-namespace \
  --values "$MANIFEST_DIR/perses-values.yaml" \
  --wait --timeout 10m

for _ in $(seq 1 60); do
  [ "$(perses_call GET /api/v1/health | http_code)" = "200" ] && break
  sleep 5
done

echo "[env] Creating the project inventory and the global datasource prometheus..."
perses_call POST /api/v1/projects '{"kind":"Project","metadata":{"name":"inventory"},"spec":{}}' >/dev/null || true
GLOBAL_DATASOURCE='{"kind":"GlobalDatasource","metadata":{"name":"prometheus"},"spec":{"default":true,"plugin":{"kind":"PrometheusDatasource","spec":{"proxy":{"kind":"HTTPProxy","spec":{"url":"http://prometheus.observability:9090"}}}}}}'
if [ "$(perses_call GET /api/v1/globaldatasources/prometheus | http_code)" != "200" ]; then
  perses_call POST /api/v1/globaldatasources "$GLOBAL_DATASOURCE" >/dev/null
fi

echo "[env] Starting the app builder and the nginx server for the app..."
kubectl apply -f "$MANIFEST_DIR/embed.yaml"
kubectl -n embed create configmap app-source --from-file="$MANIFEST_DIR/app" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n embed create configmap embed-app-nginx --from-file=default.conf="$MANIFEST_DIR/nginx-default.conf" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n embed rollout restart deployment/app-builder deployment/embed-app >/dev/null
kubectl -n embed rollout status deployment/app-builder --timeout=600s
kubectl -n embed rollout status deployment/embed-app --timeout=300s

echo "[env] Installing the app's npm packages and building it (several minutes)..."
builder_sh "npm install --no-audit --no-fund"
builder_sh "npm run build && npm run deploy"

echo "[playground] Ready."
echo "[playground] Start the port-forwards in a second terminal:"
echo "  kubectl -n perses port-forward svc/perses 8080:8080"
echo "  kubectl -n embed port-forward svc/embed-app 8081:8081"

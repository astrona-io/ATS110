#!/usr/bin/env bash
# Runs before the reference solution: waits until Perses answers and the
# builder pod is ready, so the solution never races the environment.
set -eu
kubectl -n embed rollout status deployment/app-builder --timeout=600s
for _ in $(seq 1 60); do
  CODE="$(kubectl -n observability exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}' \
    http://perses.perses.svc.cluster.local:8080/api/v1/health 2>/dev/null || true)"
  [ "$CODE" = "200" ] && exit 0
  sleep 5
done
echo "Perses did not become healthy in time." >&2
exit 1

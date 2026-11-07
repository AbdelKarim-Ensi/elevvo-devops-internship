#!/usr/bin/env bash
set -euo pipefail
IMAGE="${1:-todo-app:latest}"
OPTS=(image --scanners vuln --severity HIGH,CRITICAL --exit-code 1 --timeout 15m)

if command -v trivy >/dev/null 2>&1; then
  trivy "${OPTS[@]}" "$IMAGE"
else
  mkdir -p "$HOME/.cache/trivy"
  docker run --rm --network host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$HOME/.cache/trivy:/root/.cache/trivy" \
    aquasec/trivy:latest "${OPTS[@]}" "$IMAGE"
fi
echo "No HIGH/CRITICAL CVEs found: safe to run."

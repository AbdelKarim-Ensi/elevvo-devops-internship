#!/usr/bin/env bash
set -euo pipefail
IMAGE="${1:-todo-app:latest}"

if ! command -v trivy >/dev/null 2>&1; then
  echo "Trivy not found, running it via Docker..."
  docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:latest image --severity HIGH,CRITICAL --exit-code 1 "$IMAGE"
else
  trivy image --severity HIGH,CRITICAL --exit-code 1 "$IMAGE"
fi
echo "No HIGH/CRITICAL CVEs found: safe to run."

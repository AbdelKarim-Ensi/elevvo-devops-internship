#!/usr/bin/env bash
# Bonus: scan the image with Trivy and fail on HIGH/CRITICAL CVEs
set -euo pipefail
docker build -t elevvo-api:1.0 "$(dirname "$0")"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest \
  image --severity HIGH,CRITICAL --exit-code 1 elevvo-api:1.0

#!/usr/bin/env bash
# Demo helper for the screen recording
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p demo_logs
for i in 1 2 3; do seq 1 2000 | sed "s/^/app log line /" > demo_logs/app$i.log; done
cat > .env <<ENV
LOG_DIR=$PWD/demo_logs
BACKUP_DIR=$PWD/backups
RETENTION_DAYS=7
WEBHOOK_URL=${WEBHOOK_URL:-}
ENV
bash ./backup.sh
echo; ls -lh backups/; echo; tail -n 5 backup.log
echo; echo "Is .env tracked by git?"; git ls-files 2>/dev/null | grep -x '.env' || echo "No - .env is ignored"

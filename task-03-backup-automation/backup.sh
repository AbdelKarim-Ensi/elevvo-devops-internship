#!/usr/bin/env bash
# Task 3 - Automated log backup: compress, verify, rotate, notify (webhook optional).
# All configuration comes from environment variables / .env (never hardcoded).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.env"
  set +a
fi

: "${LOG_DIR:?LOG_DIR is required (set it in .env)}"
BACKUP_DIR="${BACKUP_DIR:-$SCRIPT_DIR/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
WEBHOOK_URL="${WEBHOOK_URL:-}"
LOG_FILE="${LOG_FILE:-$SCRIPT_DIR/backup.log}"
HOST="$(hostname)"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG_FILE"; }

notify() {
  [[ -z "$WEBHOOK_URL" ]] && return 0
  curl -fsS -m 10 -X POST -H 'Content-Type: application/json' \
    -d "{\"text\":\"[$HOST] $1\"}" "$WEBHOOK_URL" >/dev/null \
    || log WARN "Webhook notification failed"
}

on_error() {
  log ERROR "Backup failed (line $1)"
  notify "Backup FAILED on line $1"
  exit 1
}
trap 'on_error $LINENO' ERR

# Prevent overlapping runs
exec 9>"/tmp/backup_logs.lock"
if ! flock -n 9; then
  log WARN "Another backup is already running, exiting"
  exit 0
fi

[[ -d "$LOG_DIR" ]] || { log ERROR "LOG_DIR '$LOG_DIR' does not exist"; exit 1; }
mkdir -p "$BACKUP_DIR"

ARCHIVE="$BACKUP_DIR/logs_$(date '+%Y%m%d_%H%M%S').tar.gz"
log INFO "Archiving $LOG_DIR -> $ARCHIVE"
tar -czf "$ARCHIVE" -C "$(dirname "$LOG_DIR")" "$(basename "$LOG_DIR")"
tar -tzf "$ARCHIVE" >/dev/null   # integrity check

SIZE="$(du -h "$ARCHIVE" | cut -f1)"
log INFO "Archive OK ($SIZE)"

DELETED="$(find "$BACKUP_DIR" -name 'logs_*.tar.gz' -mtime +"$RETENTION_DAYS" -print -delete | wc -l)"
log INFO "Rotation: $DELETED old archive(s) removed (retention ${RETENTION_DAYS}d)"

notify "Backup OK: $(basename "$ARCHIVE") ($SIZE)"

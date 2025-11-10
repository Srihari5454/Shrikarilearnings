#!/usr/bin/env bash
# backup.sh — automated backup script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/backup.config"
LOG_FILE="$SCRIPT_DIR/logs/backup.log"
BACKUP_DIR="$SCRIPT_DIR/backups"
RESTORE_DIR="$SCRIPT_DIR/restore"

mkdir -p "$BACKUP_DIR/daily" "$BACKUP_DIR/weekly" "$BACKUP_DIR/monthly" "$RESTORE_DIR" "$(dirname "$LOG_FILE")"

# Logging helper
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Modes
DRYRUN=false
if [[ "${1:-}" == "--dry-run" ]]; then DRYRUN=true; shift; fi

# Usage
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 [--dry-run|--list|--restore <file> --to <folder>] <source_dir>"
  exit 1
fi

# List backups
if [[ "$1" == "--list" ]]; then
  echo "Available backups:"
  ls -lh "$BACKUP_DIR"/* || echo "No backups found."
  exit 0
fi

# Restore
if [[ "$1" == "--restore" ]]; then
  BACKUP_FILE="$2"; shift 2
  if [[ "${1:-}" == "--to" ]]; then
    RESTORE_TARGET="$2"
  else
    RESTORE_TARGET="$RESTORE_DIR"
  fi
  mkdir -p "$RESTORE_TARGET"
  log "Restoring $BACKUP_FILE to $RESTORE_TARGET ..."
  if [[ "$DRYRUN" == "true" ]]; then
    log "[DRYRUN] Would extract $BACKUP_FILE into $RESTORE_TARGET"
  else
    tar -xzf "$BACKUP_FILE" -C "$RESTORE_TARGET"
    log "Restore completed!"
  fi
  exit 0
fi

# Perform backup
SOURCE="$1"
if [[ ! -d "$SOURCE" ]]; then
  echo "Error: Source directory not found: $SOURCE"
  exit 1
fi

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
DAY_OF_WEEK=$(date +%u)
DAY_OF_MONTH=$(date +%d)

if [[ "$DAY_OF_MONTH" -eq 1 ]]; then
  BACKUP_TYPE="monthly"
elif [[ "$DAY_OF_WEEK" -eq 7 ]]; then
  BACKUP_TYPE="weekly"
else
  BACKUP_TYPE="daily"
fi

BACKUP_PATH="$BACKUP_DIR/$BACKUP_TYPE/backup-${TIMESTAMP}.tar.gz"
log "Starting $BACKUP_TYPE backup for $SOURCE ..."

if [[ "$DRYRUN" == "true" ]]; then
  log "[DRYRUN] Would create: $BACKUP_PATH"
else
  tar -czf "$BACKUP_PATH" -C "$(dirname "$SOURCE")" "$(basename "$SOURCE")"
  log "Backup created: $BACKUP_PATH"
fi

log "Backup finished successfully."

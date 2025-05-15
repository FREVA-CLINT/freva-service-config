#!/usr/bin/env bash
set -o nounset -o pipefail -o errexit

SRC_DIR=${SRC_DIR:-/backup}
BACKUP_DIR=${BACKUP_DIR:-/backup}
NUM_BACKUPS=${NUM_BACKUPS:-6}

print_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Create and rotate data backups.

Options:
  -s  <dir>   Source dir to back up (e.g. /data/db)
  -b  <dir>   Backup destination dir.
  -h, --help  Show this help message and exit
EOF
}

# Trap to catch unexpected failures
trap 'echo "❌ Backup script failed unexpectedly at line $LINENO" >&2' ERR

# --- Parse CLI args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s) SRC_DIR="$2"; shift 2 ;;
    -b) BACKUP_DIR="$2"; shift 2 ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "❌ Unknown argument: $1" >&2; print_help; exit 1 ;;
  esac
done

main() {
    # --- Create backup ---
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_file="backup-${timestamp}.tar.gz"
    # Archive only contents of SRC_DIR, not SRC_DIR itself
    if ! tar --directory="${SRC_DIR}" --use-compress-program="gzip -9" -cf "${BACKUP_DIR}/${backup_file}" .; then
        echo "❌ Backup failed: ${SRC_DIR} → ${BACKUP_DIR}/${backup_file}" >&2
        rm -f "${BACKUP_DIR}/${backup_file}" || true
        exit 1
    fi

    # --- Rotate old backups ---
    # List backups sorted by modification time, skip newest N files, delete the rest
    mapfile -t old_backups < <(find "${BACKUP_DIR}" -maxdepth 1 -name "backup-*.tar.gz" -type f -printf "%T@ %p\n" | sort -nr | tail -n +$((NUM_BACKUPS + 1)) | awk '{print $2}')

    for old_file in "${old_backups[@]}"; do
        rm -f "$old_file"
    done
}

# --- Run main and silence stdout (cron-safe) ---
main > /dev/null

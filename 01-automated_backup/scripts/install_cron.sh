#!/usr/bin/env bash
# install_cron.sh — Install the daily backup cron job
# Usage: ./scripts/install_cron.sh [--email your@email.com]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="${SCRIPT_DIR}/backup.sh"
EMAIL_FLAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --email) EMAIL_FLAG="--email $2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

chmod +x "${BACKUP_SCRIPT}"

# 2:00 AM every day
CRON_LINE="0 2 * * * ${BACKUP_SCRIPT} --source \${HOME} --dest \${HOME}/backups --retain 7 ${EMAIL_FLAG} >> ${SCRIPT_DIR}/../logs/cron.log 2>&1"

if crontab -l 2>/dev/null | grep -qF "${BACKUP_SCRIPT}"; then
  echo "Cron job already installed."
else
  (crontab -l 2>/dev/null; echo "${CRON_LINE}") | crontab -
  echo "Cron job installed: daily at 2:00 AM"
fi

echo ""
echo "Current crontab:"
crontab -l

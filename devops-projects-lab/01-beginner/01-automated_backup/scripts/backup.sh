#!/usr/bin/env bash
# backup.sh — Automated directory backup with retention and email alerts
# Usage: ./scripts/backup.sh [--source DIR] [--dest DIR] [--retain N] [--email ADDR]

# exit the script if any error occurs
set -euo pipefail

SOURCE_DIR="${HOME}"
BACKUP_DEST="/tmp/backups"
RETAIN_DAYS=7
ALERT_EMAIL=""
LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/logs"
LOG_FILE="${LOG_DIR}/backup_$(date +%Y%m%d).log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
HOSTNAME=$(hostname -s)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

mkdir -p "${LOG_DIR}"
log()  { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  $*" | tee -a "${LOG_FILE}" >&2; }
warn() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}[WARN]${NC}  $*" | tee -a "${LOG_FILE}" >&2; }
err()  { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}[ERROR]${NC} $*" | tee -a "${LOG_FILE}" >&2; }
ok()   { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}[OK]${NC}    $*" | tee -a "${LOG_FILE}" >&2; }

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "  -s, --source  DIR   Source directory (default: \$HOME)"
  echo "  -d, --dest    DIR   Backup destination (default: /tmp/backups)"
  echo "  -r, --retain  N     Retention days (default: 7)"
  echo "  -e, --email   ADDR  Alert email address"
  echo "  -h, --help          Show this help"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--source)  SOURCE_DIR="$2";  shift 2 ;;
    -d|--dest)    BACKUP_DEST="$2"; shift 2 ;;
    -r|--retain)  RETAIN_DAYS="$2"; shift 2 ;;
    -e|--email)   ALERT_EMAIL="$2"; shift 2 ;;
    -h|--help)    usage ;;
    *) err "Unknown option: $1"; exit 1 ;;
  esac
done

preflight() {
  log "Running pre-flight checks..."
  if [[ ! -d "${SOURCE_DIR}" ]]; then err "Source directory does not exist: ${SOURCE_DIR}"; return 1; fi
  if [[ ! -r "${SOURCE_DIR}" ]]; then err "Source directory is not readable: ${SOURCE_DIR}"; return 1; fi
  mkdir -p "${BACKUP_DEST}" || { err "Cannot create destination: ${BACKUP_DEST}"; return 1; }
  local avail
  avail=$(df -m "${BACKUP_DEST}" | awk 'NR==2 {print $4}')
  if [[ "${avail}" -lt 100 ]]; then warn "Low disk space: ${avail}MB free"; fi
  ok "Pre-flight checks passed"
}

create_backup() {
  local name="backup_${HOSTNAME}_${TIMESTAMP}.tar.gz"
  local path="${BACKUP_DEST}/${name}"
  log "Creating archive: ${path}"
  tar --create --gzip --file="${path}" \
    --exclude='*.log' --exclude='*.tmp' --exclude='.git' \
    --exclude='node_modules' --exclude='__pycache__' --exclude='.DS_Store' \
    "${SOURCE_DIR}" 2>>"${LOG_FILE}" || { err "tar failed"; return 1; }
  sha256sum "${path}" > "${path}.sha256"
  local size; size=$(du -sh "${path}" | cut -f1)
  ok "Archive created: ${name} (${size})"
  echo "${path}"
}

verify_backup() {
  log "Verifying integrity of $1..."
  tar -tzf "$1" > /dev/null 2>>"${LOG_FILE}" || { err "Verification failed"; return 1; }
  ok "Integrity check passed"
}

rotate_backups() {
  log "Rotating backups older than ${RETAIN_DAYS} days..."
  local count=0
  while IFS= read -r f; do
    rm -f "${f}" "${f}.sha256"
    log "Removed: $(basename "${f}")"
    ((count++)) || true
  done < <(find "${BACKUP_DEST}" -name "backup_*.tar.gz" -mtime "+${RETAIN_DAYS}" 2>/dev/null)
  [[ "${count}" -gt 0 ]] && ok "Rotated ${count} backup(s)" || log "No old backups to rotate"
}

send_alert() {
  [[ -z "${ALERT_EMAIL}" ]] && return 0
  if command -v mail &>/dev/null; then
    echo "$2" | mail -s "$1" "${ALERT_EMAIL}"
    log "Alert sent to ${ALERT_EMAIL}"
  else
    warn "mail not found — skipping alert"
  fi
}

print_summary() {
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Status    : $1"
  echo "  Source    : ${SOURCE_DIR}"
  echo "  Dest      : ${BACKUP_DEST}"
  echo "  Timestamp : ${TIMESTAMP}"
  echo "  Duration  : $3s"
  [[ -n "$2" ]] && echo "  Archive   : $(basename "$2")"
  echo "  Log       : ${LOG_FILE}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo ""
}

main() {
  local t0; t0=$(date +%s)
  log "=== Backup started on ${HOSTNAME} ==="

  # Exit if any command fails
  trap 'dur=$(( $(date +%s) - t0 ))
        err "Backup FAILED after ${dur}s"
        send_alert "[BACKUP FAILED] ${HOSTNAME}" "Backup of ${SOURCE_DIR} failed. Log: ${LOG_FILE}"
        print_summary "FAILED" "" "${dur}"
        exit 1' ERR

  preflight
  local archive; archive=$(create_backup)
  verify_backup "${archive}"
  rotate_backups

  local dur=$(( $(date +%s) - t0 ))
  ok "Done in ${dur}s"
  send_alert "[BACKUP OK] ${HOSTNAME}" "Backup of ${SOURCE_DIR} complete. Archive: ${archive}"
  print_summary "SUCCESS" "${archive}" "${dur}"
}

main "$@"

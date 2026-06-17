#!/usr/bin/env bash
# test_backup.sh — Test suite for backup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_SCRIPT="${SCRIPT_DIR}/scripts/backup.sh"
PASS=0; FAIL=0

pass() { echo "  PASS: $1"; ((PASS++)) || true; }
fail() { echo "  FAIL: $1 — $2"; ((FAIL++)) || true; }

echo "Running backup.sh tests..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

chmod +x "${BACKUP_SCRIPT}"
[[ -x "${BACKUP_SCRIPT}" ]] && pass "Script is executable" || fail "Script is executable" "not found"

"${BACKUP_SCRIPT}" --help &>/dev/null && pass "--help flag exits 0" || fail "--help flag exits 0" "non-zero exit"

TSRC=$(mktemp -d); TDST=$(mktemp -d)
echo "hello world" > "${TSRC}/test.txt"
mkdir -p "${TSRC}/subdir"; echo "nested" > "${TSRC}/subdir/data.txt"

"${BACKUP_SCRIPT}" --source "${TSRC}" --dest "${TDST}" --retain 30 &>/dev/null \
  && pass "Backup exits 0" || fail "Backup exits 0" "non-zero exit"

ARCHIVE=$(find "${TDST}" -name "*.tar.gz" | head -1)
[[ -n "${ARCHIVE}" ]] && pass "Archive created"       || fail "Archive created" "no .tar.gz found"
[[ -f "${ARCHIVE}.sha256" ]] && pass "Checksum created" || fail "Checksum created" "no .sha256"

tar -tzf "${ARCHIVE}" > /dev/null &>/dev/null \
  && pass "Archive passes integrity check" \
  || fail "Archive passes integrity check" "tar --test-file failed"

tar --list --file="${ARCHIVE}" 2>/dev/null | grep -q "test.txt" \
  && pass "Archive contains source files" \
  || fail "Archive contains source files" "test.txt missing"

"${BACKUP_SCRIPT}" --source /this_does_not_exist_xyz --dest "${TDST}" &>/dev/null \
  && fail "Rejects invalid source" "should exit non-zero" \
  || pass "Rejects invalid source"

rm -rf "${TSRC}" "${TDST}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]] && echo "All tests passed!" && exit 0 || exit 1

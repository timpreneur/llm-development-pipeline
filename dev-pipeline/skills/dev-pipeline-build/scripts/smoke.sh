#!/usr/bin/env bash
#
# dev-pipeline-build smoke test
#
# Run check-build-notes.sh against three fixtures:
#   - good: expect exit 0 (pass)
#   - bad-no-ac-status: expect exit 1 (red — no AC rows)
#   - bad-missing-sections: expect exit 1 (red — missing Preview URL + Legal findings)
#
# Usage:
#   smoke.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$SKILL_DIR/scripts"
FIXTURES_DIR="$SKILL_DIR/fixtures"
CHECK="$SCRIPTS_DIR/check-build-notes.sh"

assert_exit() {
  local label="$1"
  local notes="$2"
  local expected_rc="$3"

  echo
  echo "=== smoke: $label ==="
  set +e
  bash "$CHECK" "$notes"
  local rc=$?
  set -e
  if (( rc != expected_rc )); then
    echo "FAIL: $label expected rc=$expected_rc but got rc=$rc"
    exit 1
  fi
  echo "  assert: $label rc=$rc ✓"
}

assert_exit "good fixture (expect rc=0)" \
  "$FIXTURES_DIR/good/03-build-notes.md" 0

assert_exit "bad-no-ac-status (expect RED, rc=1)" \
  "$FIXTURES_DIR/bad-no-ac-status/03-build-notes.md" 1

assert_exit "bad-missing-sections (expect RED, rc=1)" \
  "$FIXTURES_DIR/bad-missing-sections/03-build-notes.md" 1

echo
echo "=== smoke: PASS ==="

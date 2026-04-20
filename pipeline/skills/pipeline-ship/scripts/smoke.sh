#!/usr/bin/env bash
#
# pipeline-ship smoke test
#
# Run check-ship.sh against three fixtures:
#   - good: expect exit 0 (pass)
#   - bad-no-deploy-state: expect exit 1 (red — missing READY verification + empty observability)
#   - bad-missing-sections: expect exit 1 (red — missing required H2s)
#
# Usage:
#   smoke.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$SKILL_DIR/scripts"
FIXTURES_DIR="$SKILL_DIR/fixtures"
CHECK="$SCRIPTS_DIR/check-ship.sh"

assert_exit() {
  local label="$1"
  local ship="$2"
  local expected_rc="$3"

  echo
  echo "=== smoke: $label ==="
  set +e
  bash "$CHECK" "$ship"
  local rc=$?
  set -e
  if (( rc != expected_rc )); then
    echo "FAIL: $label expected rc=$expected_rc but got rc=$rc"
    exit 1
  fi
  echo "  assert: $label rc=$rc ✓"
}

assert_exit "good fixture (expect rc=0)" \
  "$FIXTURES_DIR/good/04-ship.md" 0

assert_exit "bad-no-deploy-state (expect RED, rc=1)" \
  "$FIXTURES_DIR/bad-no-deploy-state/04-ship.md" 1

assert_exit "bad-missing-sections (expect RED, rc=1)" \
  "$FIXTURES_DIR/bad-missing-sections/04-ship.md" 1

echo
echo "=== smoke: PASS ==="

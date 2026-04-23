#!/usr/bin/env bash
#
# dev-pipeline-plan smoke test
#
# Run check-plan.sh against three fixtures:
#   - good: expect exit 0 (pass, no red)
#   - bad-no-verification: expect exit 1 (red — Verification has no rows)
#   - bad-missing-sections: expect exit 1 (red — missing Side-effects + Rollback)
#
# Usage:
#   smoke.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$SKILL_DIR/scripts"
FIXTURES_DIR="$SKILL_DIR/fixtures"
CHECK="$SCRIPTS_DIR/check-plan.sh"

assert_exit() {
  local label="$1"
  local plan="$2"
  local expected_rc="$3"

  echo
  echo "=== smoke: $label ==="
  set +e
  bash "$CHECK" "$plan"
  local rc=$?
  set -e
  if (( rc != expected_rc )); then
    echo "FAIL: $label expected rc=$expected_rc but got rc=$rc"
    exit 1
  fi
  echo "  assert: $label rc=$rc ✓"
}

assert_exit "good fixture (expect rc=0)" \
  "$FIXTURES_DIR/good/02-plan.md" 0

assert_exit "bad-no-verification (expect RED, rc=1)" \
  "$FIXTURES_DIR/bad-no-verification/02-plan.md" 1

assert_exit "bad-missing-sections (expect RED, rc=1)" \
  "$FIXTURES_DIR/bad-missing-sections/02-plan.md" 1

echo
echo "=== smoke: PASS ==="

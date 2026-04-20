#!/usr/bin/env bash
#
# pipeline-research smoke test
#
# Run check-research.sh against three fixtures:
#   - good: expect exit 0 (pass)
#   - bad-no-evidence: expect exit 1 (red — candidate with no evidence bullets + strong candidate missing inbox seed)
#   - bad-missing-sections: expect exit 1 (red — missing required H2s)
#
# Usage:
#   smoke.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$SKILL_DIR/scripts"
FIXTURES_DIR="$SKILL_DIR/fixtures"
CHECK="$SCRIPTS_DIR/check-research.sh"

assert_exit() {
  local label="$1"
  local rep="$2"
  local expected_rc="$3"

  echo
  echo "=== smoke: $label ==="
  set +e
  bash "$CHECK" "$rep"
  local rc=$?
  set -e
  if (( rc != expected_rc )); then
    echo "FAIL: $label expected rc=$expected_rc but got rc=$rc"
    exit 1
  fi
  echo "  assert: $label rc=$rc ✓"
}

assert_exit "good fixture (expect rc=0)" \
  "$FIXTURES_DIR/good/05-research.md" 0

assert_exit "bad-no-evidence (expect RED, rc=1)" \
  "$FIXTURES_DIR/bad-no-evidence/05-research.md" 1

assert_exit "bad-missing-sections (expect RED, rc=1)" \
  "$FIXTURES_DIR/bad-missing-sections/05-research.md" 1

echo
echo "=== smoke: PASS ==="

#!/usr/bin/env bash
#
# pipeline-ideate smoke test
#
# Run check-brief.sh against three fixtures:
#   - good: expect exit 0 (pass, no red)
#   - bad-no-pressure-test: expect exit 1 (red — only 1 alternative)
#   - bad-missing-flags: expect exit 1 (red — frontmatter missing flags)
#
# Usage:
#   smoke.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$SKILL_DIR/scripts"
FIXTURES_DIR="$SKILL_DIR/fixtures"
CHECK="$SCRIPTS_DIR/check-brief.sh"

assert_exit() {
  local label="$1"
  local brief="$2"
  local expected_rc="$3"

  echo
  echo "=== smoke: $label ==="
  set +e
  bash "$CHECK" "$brief"
  local rc=$?
  set -e
  if (( rc != expected_rc )); then
    echo "FAIL: $label expected rc=$expected_rc but got rc=$rc"
    exit 1
  fi
  echo "  assert: $label rc=$rc ✓"
}

assert_exit "good fixture (expect GREEN, rc=0)" \
  "$FIXTURES_DIR/good/01-brief.md" 0

assert_exit "bad-no-pressure-test (expect RED, rc=1)" \
  "$FIXTURES_DIR/bad-no-pressure-test/01-brief.md" 1

assert_exit "bad-missing-flags (expect RED, rc=1)" \
  "$FIXTURES_DIR/bad-missing-flags/01-brief.md" 1

echo
echo "=== smoke: PASS ==="

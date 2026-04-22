#!/usr/bin/env bash
#
# pipeline-ship smoke test
#
# Run check-ship.sh against five fixtures:
#   - good                    → expect exit 0 (includes valid 04-punchlist.json)
#   - bad-no-deploy-state     → expect exit 1 (missing READY + empty observability + missing agentic/punchlist)
#   - bad-missing-sections    → expect exit 1 (missing H2s + missing agentic/punchlist)
#   - bad-no-agentic-pass     → expect exit 1 (no `## Agentic QA`, no agentic_qa_coverage_pct, no sibling JSON)
#   - bad-open-blocking       → expect exit 1 (ship.md structurally OK, but sibling 04-punchlist.json has open blocking finding — bubbled from check-punchlist.sh)
#
# Also directly exercises check-punchlist.sh against the two fixtures that ship a JSON file.
#
# Usage:
#   smoke.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$SKILL_DIR/scripts"
FIXTURES_DIR="$SKILL_DIR/fixtures"
CHECK_SHIP="$SCRIPTS_DIR/check-ship.sh"
CHECK_PL="$SCRIPTS_DIR/check-punchlist.sh"

assert_rc() {
  local label="$1"
  local cmd="$2"
  local arg="$3"
  local expected_rc="$4"

  echo
  echo "=== smoke: $label ==="
  set +e
  bash "$cmd" "$arg"
  local rc=$?
  set -e
  if (( rc != expected_rc )); then
    echo "FAIL: $label expected rc=$expected_rc but got rc=$rc"
    exit 1
  fi
  echo "  assert: $label rc=$rc ✓"
}

# --- check-ship.sh against all 5 fixtures -----------------------------------

assert_rc "good fixture (expect rc=0)" \
  "$CHECK_SHIP" "$FIXTURES_DIR/good/04-ship.md" 0

assert_rc "bad-no-deploy-state (expect RED, rc=1)" \
  "$CHECK_SHIP" "$FIXTURES_DIR/bad-no-deploy-state/04-ship.md" 1

assert_rc "bad-missing-sections (expect RED, rc=1)" \
  "$CHECK_SHIP" "$FIXTURES_DIR/bad-missing-sections/04-ship.md" 1

assert_rc "bad-no-agentic-pass (expect RED, rc=1)" \
  "$CHECK_SHIP" "$FIXTURES_DIR/bad-no-agentic-pass/04-ship.md" 1

assert_rc "bad-open-blocking (expect RED, rc=1 — bubbled from check-punchlist.sh)" \
  "$CHECK_SHIP" "$FIXTURES_DIR/bad-open-blocking/04-ship.md" 1

# --- check-punchlist.sh direct exercises ------------------------------------

assert_rc "good/04-punchlist.json (expect rc=0)" \
  "$CHECK_PL" "$FIXTURES_DIR/good/04-punchlist.json" 0

assert_rc "bad-open-blocking/04-punchlist.json (expect rc=1 — open blocking finding)" \
  "$CHECK_PL" "$FIXTURES_DIR/bad-open-blocking/04-punchlist.json" 1

echo
echo "=== smoke: PASS ==="

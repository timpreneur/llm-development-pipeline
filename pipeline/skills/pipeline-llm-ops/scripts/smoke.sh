#!/usr/bin/env bash
# smoke.sh — smoke test for pipeline-llm-ops check-run-log.sh
#
# Expected:
#   good-drift-check          → rc 0
#   bad-missing-sections      → rc 1
#   bad-no-in-flight-check    → rc 1

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
SKILL="$(dirname "$HERE")"
CHECK="$HERE/check-run-log.sh"

pass=0
fail=0

run_case() {
  local label="$1"
  local path="$2"
  local expect="$3"

  if [[ ! -f "$path" ]]; then
    echo "FAIL: $label — fixture not found: $path"
    fail=$((fail + 1))
    return
  fi

  bash "$CHECK" "$path" > /tmp/llm-ops-smoke.out 2>&1
  local rc=$?

  if [[ "$rc" -eq "$expect" ]]; then
    echo "PASS: $label (rc=$rc)"
    pass=$((pass + 1))
  else
    echo "FAIL: $label — expected rc=$expect, got rc=$rc"
    cat /tmp/llm-ops-smoke.out | sed 's/^/    /'
    fail=$((fail + 1))
  fi
}

run_case "good-drift-check"         "$SKILL/fixtures/good-drift-check/2026-04-19T09-00-drift-check.md"       0
run_case "bad-missing-sections"     "$SKILL/fixtures/bad-missing-sections/2026-04-19T10-15-lesson-reconciliation.md" 1
run_case "bad-no-in-flight-check"   "$SKILL/fixtures/bad-no-in-flight-check/2026-05-04T15-45-fix-session.md" 1

echo
echo "smoke summary: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]] && exit 0 || exit 1

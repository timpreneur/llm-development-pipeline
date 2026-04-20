#!/usr/bin/env bash
#
# pipeline-substrate smoke test
#
# Stages the bundled fixture into a temp dir, runs bootstrap, then validate.
# Expected: bootstrap creates all three _meta/ files, validate returns GREEN.
#
# Usage:
#   smoke.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_SRC="$SKILL_DIR/fixtures/pipeline"
SCRIPTS_DIR="$SKILL_DIR/scripts"

if [[ ! -d "$FIXTURE_SRC" ]]; then
  echo "FAIL: fixture source missing at $FIXTURE_SRC"
  exit 1
fi

TMP_ROOT=$(mktemp -d -t pipeline-substrate-smoke.XXXXXX)
trap 'rm -rf "$TMP_ROOT"' EXIT

# Stage the fixture feature dirs into a fresh pipeline root (no _meta yet).
STAGED_ROOT="$TMP_ROOT/pipeline"
mkdir -p "$STAGED_ROOT"
cp -R "$FIXTURE_SRC"/* "$STAGED_ROOT/"

echo "=== smoke: stage ==="
echo "  staged fixture to $STAGED_ROOT"
find "$STAGED_ROOT" -type f | sed "s|$STAGED_ROOT/|    |"

echo
echo "=== smoke: bootstrap (run 1 — fresh) ==="
bash "$SCRIPTS_DIR/bootstrap.sh" "$STAGED_ROOT"

# Assert all three _meta/ files now exist.
for f in skill-hashes.json CHANGELOG.md metrics.md; do
  if [[ ! -f "$STAGED_ROOT/_meta/$f" ]]; then
    echo "FAIL: bootstrap did not create _meta/$f"
    exit 1
  fi
done
echo "  assert: _meta/ seeded with all three files ✓"

# Snapshot skill-hashes.json to assert idempotency on run 2.
HASH_BEFORE=$(python3 -c "import hashlib,sys; print(hashlib.sha256(open('$STAGED_ROOT/_meta/skill-hashes.json','rb').read()).hexdigest())")

echo
echo "=== smoke: bootstrap (run 2 — idempotent) ==="
bash "$SCRIPTS_DIR/bootstrap.sh" "$STAGED_ROOT"

HASH_AFTER=$(python3 -c "import hashlib,sys; print(hashlib.sha256(open('$STAGED_ROOT/_meta/skill-hashes.json','rb').read()).hexdigest())")
if [[ "$HASH_BEFORE" != "$HASH_AFTER" ]]; then
  echo "FAIL: skill-hashes.json content changed on re-run (bootstrap should be idempotent for seed data)"
  exit 1
fi
echo "  assert: skill-hashes.json unchanged on re-run ✓"

# CHANGELOG gets a re-run line appended; that's expected behavior.
CHANGELOG_LINES=$(wc -l < "$STAGED_ROOT/_meta/CHANGELOG.md")
if (( CHANGELOG_LINES < 5 )); then
  echo "FAIL: CHANGELOG.md shorter than expected after re-run"
  exit 1
fi
echo "  assert: CHANGELOG.md has re-run entry ✓"

echo
echo "=== smoke: validate ==="
set +e
bash "$SCRIPTS_DIR/validate.sh" "$STAGED_ROOT"
VALIDATE_RC=$?
set -e
if (( VALIDATE_RC != 0 )); then
  echo "FAIL: validate returned $VALIDATE_RC (expected 0 = GREEN)"
  exit 1
fi
echo "  assert: validate GREEN ✓"

echo
echo "=== smoke: PASS ==="

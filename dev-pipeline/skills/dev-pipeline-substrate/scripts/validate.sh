#!/usr/bin/env bash
#
# dev-pipeline-substrate validate
#
# Read-only pass. Walks a pipeline root, checks every feature dir for:
#   - 00-manifest.md exists, parses, has expected frontmatter
#   - each referenced artifact exists with valid frontmatter
#   - _meta/ files exist and have the right top-level shape
#
# Usage:
#   validate.sh <pipeline-root>
#
# Exit 0 on green, 1 on red, 2 on yellow-only issues.

set -euo pipefail

PIPELINE_ROOT="${1:-}"
if [[ -z "$PIPELINE_ROOT" ]]; then
  echo "ERROR: pipeline root required" >&2
  echo "Usage: validate.sh <pipeline-root>" >&2
  exit 2
fi

RED=()
YELLOW=()

record_red()    { RED+=("$1"); }
record_yellow() { YELLOW+=("$1"); }

# --- _meta/ -----------------------------------------------------------------

META_DIR="$PIPELINE_ROOT/_meta"
if [[ ! -d "$META_DIR" ]]; then
  record_red "_meta/ missing — run bootstrap.sh"
else
  for f in skill-hashes.json CHANGELOG.md metrics.md; do
    if [[ ! -f "$META_DIR/$f" ]]; then
      record_red "_meta/$f missing — run bootstrap.sh"
    fi
  done

  # skill-hashes.json must be valid JSON with a version and entries array.
  if [[ -f "$META_DIR/skill-hashes.json" ]]; then
    if ! python3 -c "import json,sys; d=json.load(open('$META_DIR/skill-hashes.json')); assert d.get('version')==1 and isinstance(d.get('entries'), list)" 2>/dev/null; then
      record_red "_meta/skill-hashes.json malformed — expected {version: 1, entries: [...]}"
    fi
  fi
fi

# --- feature dirs -----------------------------------------------------------

# Match project dirs (anything under pipeline root that isn't _meta/_archive).
# For each project dir, scan feature dirs (YYYY-MM-DD-slug pattern) and cohort
# dirs (YYYY-Www or YYYY-MM).

REQUIRED_FRONTMATTER_FIELDS=(session feature_id project owner status inputs updated regulated customer_facing_launch)

lint_frontmatter() {
  local file="$1"
  local expected_session="$2"
  local content
  content=$(awk 'BEGIN{in_fm=0} /^---$/{in_fm++; next} in_fm==1{print}' "$file")
  if [[ -z "$content" ]]; then
    record_red "$file: no YAML frontmatter block"
    return
  fi
  for field in "${REQUIRED_FRONTMATTER_FIELDS[@]}"; do
    if ! grep -qE "^${field}:" <<< "$content"; then
      record_red "$file: frontmatter missing required field '$field'"
    fi
  done
  local actual_session
  actual_session=$(grep -E "^session:" <<< "$content" | head -1 | sed 's/^session:[[:space:]]*//')
  if [[ "$actual_session" != "$expected_session" ]]; then
    record_red "$file: frontmatter session='$actual_session' but filename expects '$expected_session'"
  fi
}

scan_feature_dir() {
  local feat_dir="$1"
  local manifest="$feat_dir/00-manifest.md"
  if [[ ! -f "$manifest" ]]; then
    record_red "$feat_dir: 00-manifest.md missing"
    return
  fi
  lint_frontmatter "$manifest" "00-manifest"

  # Scan every NN-<name>.md file.
  for artifact in "$feat_dir"/*.md; do
    [[ -f "$artifact" ]] || continue
    local base
    base=$(basename "$artifact" .md)
    case "$base" in
      00-manifest)  ;;  # already linted
      01-brief)     lint_frontmatter "$artifact" "01-ideate" ;;
      02-plan)      lint_frontmatter "$artifact" "02-plan" ;;
      03-build-notes) lint_frontmatter "$artifact" "03-build" ;;
      04-ship)      lint_frontmatter "$artifact" "04-ship" ;;
      05-research)  lint_frontmatter "$artifact" "05-research" ;;
      *)            record_yellow "$artifact: unrecognized artifact name (expected NN-<session>.md)" ;;
    esac
  done

  # Manifest status table rows — loose check: every session row named.
  for session in 01-ideate 02-plan 03-build 04-ship 05-research; do
    if ! grep -qE "^\|[[:space:]]*${session}[[:space:]]*\|" "$manifest"; then
      record_red "$manifest: status table missing row for '$session'"
    fi
  done
}

if [[ -d "$PIPELINE_ROOT" ]]; then
  # Iterate project dirs.
  for project_dir in "$PIPELINE_ROOT"/*/; do
    [[ -d "$project_dir" ]] || continue
    project_name=$(basename "$project_dir")
    case "$project_name" in
      _meta|_archive) continue ;;
    esac
    # Feature dirs match YYYY-MM-DD-*.
    for feat_dir in "$project_dir"/????-??-??-*/; do
      [[ -d "$feat_dir" ]] || continue
      scan_feature_dir "${feat_dir%/}"
    done
  done
else
  record_red "pipeline root $PIPELINE_ROOT does not exist"
fi

# --- report -----------------------------------------------------------------

echo "dev-pipeline-substrate validate @ $PIPELINE_ROOT"
if (( ${#RED[@]} == 0 && ${#YELLOW[@]} == 0 )); then
  echo "  GREEN — no issues found"
  exit 0
fi
if (( ${#RED[@]} )); then
  echo "  RED (${#RED[@]}):"
  for m in "${RED[@]}"; do echo "    - $m"; done
fi
if (( ${#YELLOW[@]} )); then
  echo "  YELLOW (${#YELLOW[@]}):"
  for m in "${YELLOW[@]}"; do echo "    - $m"; done
fi
if (( ${#RED[@]} )); then
  exit 1
else
  exit 2
fi

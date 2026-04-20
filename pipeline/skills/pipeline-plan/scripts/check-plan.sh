#!/usr/bin/env bash
#
# pipeline-plan check-plan
#
# Validate a 02-plan.md against the Plan output contract.
#
# Usage:
#   check-plan.sh <path-to-02-plan.md>
#
# Exit 0 = contract-compliant (possibly with yellow warnings).
# Exit 1 = red failures (must be fixed before handoff).
# Exit 2 = usage error.

set -euo pipefail

PLAN="${1:-}"
if [[ -z "$PLAN" ]]; then
  echo "ERROR: path to 02-plan.md required" >&2
  echo "Usage: check-plan.sh <path-to-02-plan.md>" >&2
  exit 2
fi
if [[ ! -f "$PLAN" ]]; then
  echo "ERROR: file not found: $PLAN" >&2
  exit 2
fi

RED=()
YELLOW=()

record_red()    { RED+=("$1"); }
record_yellow() { YELLOW+=("$1"); }

# --- split frontmatter / body -----------------------------------------------

FRONTMATTER=$(awk 'BEGIN{in_fm=0} /^---$/{in_fm++; if(in_fm==2) exit; next} in_fm==1{print}' "$PLAN")
BODY=$(awk 'BEGIN{past_fm=0; seen=0} /^---$/{seen++; if(seen==2){past_fm=1; next}} past_fm==1{print}' "$PLAN")

if [[ -z "$FRONTMATTER" ]]; then
  record_red "no YAML frontmatter block"
fi
if [[ -z "$BODY" ]]; then
  record_red "no body"
fi

# --- frontmatter fields ------------------------------------------------------

REQUIRED_FIELDS=(session feature_id project owner status inputs updated regulated customer_facing_launch)
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! grep -qE "^${field}:" <<< "$FRONTMATTER"; then
    record_red "frontmatter missing required field: $field"
  fi
done

# session must be 02-plan
actual_session=$( (grep -E "^session:" <<< "$FRONTMATTER" || true) | head -1 | sed 's/^session:[[:space:]]*//' )
if [[ -n "$actual_session" && "$actual_session" != "02-plan" ]]; then
  record_red "frontmatter session='$actual_session' but expected '02-plan'"
fi

# regulated / customer_facing_launch must be explicit true|false
for flag in regulated customer_facing_launch; do
  val=$( (grep -E "^${flag}:" <<< "$FRONTMATTER" || true) | head -1 | sed "s/^${flag}:[[:space:]]*//" | tr -d '[:space:]' )
  if [[ -n "$val" && "$val" != "true" && "$val" != "false" ]]; then
    record_red "frontmatter flag ${flag}='$val' must be literally 'true' or 'false'"
  fi
done

# --- required body sections --------------------------------------------------

require_h2() {
  local heading="$1"
  if ! grep -qE "^## ${heading}([[:space:]]|$)" <<< "$BODY"; then
    record_red "body missing required H2 section: '## ${heading}'"
  fi
}

require_h2 "Summary"
require_h2 "Task list"
require_h2 "Files touched"
require_h2 "Reuse anchors"
require_h2 "Risk callouts"
require_h2 "Side-effects"
require_h2 "Test strategy"
require_h2 "Verification"
require_h2 "Rollback"
require_h2 "Open questions"

# --- Verification must not be empty -----------------------------------------
#
# "Empty" = the heading is present but there's no content rows. Heuristic:
# extract the lines from "## Verification" up to the next H2, and require at
# least one line that starts with '|' (table row) or '-' (bullet) and contains
# some alphanumeric after the marker.

VERIF_BLOCK=$(awk '
  BEGIN{in_sec=0}
  /^## Verification([[:space:]]|$)/{in_sec=1; next}
  in_sec==1 && /^## /{in_sec=0}
  in_sec==1{print}
' <<< "$BODY")

# Count rows: table data rows (pipe-prefixed, not separator) or bullets.
VERIF_ROW_COUNT=$(awk '
  /^\|[[:space:]]*[^|-]/ && $0 !~ /^\|[[:space:]]*-+/ && $0 !~ /^\|[[:space:]]*#[[:space:]]*\|/ {
    # skip header separator and header row
    count++
  }
  /^[[:space:]]*-[[:space:]]+[^[:space:]]/ {
    count++
  }
  END{print count+0}
' <<< "$VERIF_BLOCK")

if (( VERIF_ROW_COUNT < 1 )); then
  record_red "Verification section has no data rows (need at least one grep+result)"
elif (( VERIF_ROW_COUNT < 3 )); then
  record_yellow "Verification section has only $VERIF_ROW_COUNT row(s); plan may be under-researched (expect 5+ for typical feature)"
fi

# --- Task list row count (yellow only) --------------------------------------

TASK_BLOCK=$(awk '
  BEGIN{in_sec=0}
  /^## Task list([[:space:]]|$)/{in_sec=1; next}
  in_sec==1 && /^## /{in_sec=0}
  in_sec==1{print}
' <<< "$BODY")

TASK_ROW_COUNT=$(awk '
  /^[[:space:]]*[0-9]+\.[[:space:]]+[^[:space:]]/ {count++}
  END{print count+0}
' <<< "$TASK_BLOCK")

if (( TASK_ROW_COUNT < 2 )); then
  record_yellow "Task list has $TASK_ROW_COUNT numbered task(s); feature may be too small to need a plan"
fi

# --- Rollback body check ----------------------------------------------------
#
# Body under ## Rollback must have at least one non-blank line that's either
# substantive or explicitly "N/A" with reason.

ROLLBACK_BLOCK=$(awk '
  BEGIN{in_sec=0}
  /^## Rollback([[:space:]]|$)/{in_sec=1; next}
  in_sec==1 && /^## /{in_sec=0}
  in_sec==1{print}
' <<< "$BODY")

ROLLBACK_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$ROLLBACK_BLOCK" || true)
if [[ -z "$ROLLBACK_CONTENT" ]]; then
  record_red "Rollback section is empty (write steps or 'N/A — <reason>')"
elif grep -qiE '^[[:space:]]*N/A' <<< "$ROLLBACK_CONTENT" && ! grep -qE 'N/A.*—.*' <<< "$ROLLBACK_CONTENT" && ! grep -qE 'N/A.*-.*' <<< "$ROLLBACK_CONTENT"; then
  record_yellow "Rollback says N/A but lacks a reason (expected 'N/A — <reason>')"
fi

# --- report -----------------------------------------------------------------

echo "check-plan @ $PLAN"
if (( ${#RED[@]} == 0 && ${#YELLOW[@]} == 0 )); then
  echo "  GREEN — plan is contract-compliant"
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
  exit 0
fi

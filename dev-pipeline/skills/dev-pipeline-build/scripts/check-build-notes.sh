#!/usr/bin/env bash
#
# dev-pipeline-build check-build-notes
#
# Validate a 03-build-notes.md against the Build output contract.
# Accepts v0.1.0 deferred-wrapper patterns for Legal and Marketing sections.
#
# Usage:
#   check-build-notes.sh <path-to-03-build-notes.md>
#
# Exit 0 = contract-compliant (possibly with yellow warnings).
# Exit 1 = red failures (must be fixed before close).
# Exit 2 = usage error.

set -euo pipefail

NOTES="${1:-}"
if [[ -z "$NOTES" ]]; then
  echo "ERROR: path to 03-build-notes.md required" >&2
  echo "Usage: check-build-notes.sh <path-to-03-build-notes.md>" >&2
  exit 2
fi
if [[ ! -f "$NOTES" ]]; then
  echo "ERROR: file not found: $NOTES" >&2
  exit 2
fi

RED=()
YELLOW=()

record_red()    { RED+=("$1"); }
record_yellow() { YELLOW+=("$1"); }

# --- split frontmatter / body -----------------------------------------------

FRONTMATTER=$(awk 'BEGIN{in_fm=0} /^---$/{in_fm++; if(in_fm==2) exit; next} in_fm==1{print}' "$NOTES")
BODY=$(awk 'BEGIN{past_fm=0; seen=0} /^---$/{seen++; if(seen==2){past_fm=1; next}} past_fm==1{print}' "$NOTES")

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

# session must be 03-build
actual_session=$( (grep -E "^session:" <<< "$FRONTMATTER" || true) | head -1 | sed 's/^session:[[:space:]]*//' )
if [[ -n "$actual_session" && "$actual_session" != "03-build" ]]; then
  record_red "frontmatter session='$actual_session' but expected '03-build'"
fi

# regulated / customer_facing_launch must be explicit true|false
regulated_val=$( (grep -E "^regulated:" <<< "$FRONTMATTER" || true) | head -1 | sed "s/^regulated:[[:space:]]*//" | tr -d '[:space:]' )
cfl_val=$( (grep -E "^customer_facing_launch:" <<< "$FRONTMATTER" || true) | head -1 | sed "s/^customer_facing_launch:[[:space:]]*//" | tr -d '[:space:]' )
for pair in "regulated:$regulated_val" "customer_facing_launch:$cfl_val"; do
  flag="${pair%:*}"
  val="${pair#*:}"
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

require_h2 "Commit range"
require_h2 "AC status"
require_h2 "Code-opt findings"
require_h2 "Security findings"
require_h2 "Accessibility findings"
require_h2 "UX findings"
require_h2 "QA report"
require_h2 "Legal findings"
require_h2 "Marketing draft"
require_h2 "Lessons captured"
require_h2 "Preview URL"

# --- section body helpers ----------------------------------------------------

section_body() {
  local heading="$1"
  awk -v h="^## ${heading}([[:space:]]|\$)" '
    BEGIN{in_sec=0}
    $0 ~ h {in_sec=1; next}
    in_sec==1 && /^## /{in_sec=0}
    in_sec==1{print}
  ' <<< "$BODY"
}

# --- AC status row count ----------------------------------------------------

AC_BLOCK=$(section_body "AC status")
AC_ROW_COUNT=$(grep -cE '^[[:space:]]*-[[:space:]]*AC[[:space:]]+[0-9]+' <<< "$AC_BLOCK" || true)
if (( AC_ROW_COUNT < 1 )); then
  record_red "AC status has no '- AC <N>:' rows (every AC from brief must appear)"
fi

# --- Preview URL body -------------------------------------------------------

PREVIEW_BLOCK=$(section_body "Preview URL")
PREVIEW_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$PREVIEW_BLOCK" || true)
if [[ -z "$PREVIEW_CONTENT" ]]; then
  record_red "Preview URL section is empty (need URL + state, or 'N/A — no deploy integration')"
fi

# --- Legal / Marketing (v0.1.0 deferred-wrapper behavior) -------------------

LEGAL_BLOCK=$(section_body "Legal findings")
LEGAL_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$LEGAL_BLOCK" || true)
if [[ -z "$LEGAL_CONTENT" ]]; then
  record_red "Legal findings section is empty (v0.1.0: write 'N/A — wrapper deferred (...)' or 'N/A — trigger conditions not met (...)')"
elif [[ "$regulated_val" == "true" ]] && ! grep -qiE 'wrapper deferred|escalation flag' <<< "$LEGAL_BLOCK"; then
  record_yellow "regulated=true but Legal findings missing 'wrapper deferred' marker and/or escalation flag (v0.1.0 behavior)"
fi

MARKETING_BLOCK=$(section_body "Marketing draft")
MARKETING_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$MARKETING_BLOCK" || true)
if [[ -z "$MARKETING_CONTENT" ]]; then
  record_red "Marketing draft section is empty (v0.1.0: write 'N/A — wrapper deferred (...)' or 'N/A — trigger condition not met (...)')"
elif [[ "$cfl_val" == "true" ]] && ! grep -qiE 'wrapper deferred' <<< "$MARKETING_BLOCK"; then
  record_yellow "customer_facing_launch=true but Marketing draft missing 'wrapper deferred' marker (v0.1.0 behavior)"
fi

# --- Commit range + AC sanity (yellow) --------------------------------------

COMMIT_BLOCK=$(section_body "Commit range")
if grep -qiE 'N/A.*no commits' <<< "$COMMIT_BLOCK"; then
  # No commits but some AC claim PASS → warn.
  if grep -qE '^[[:space:]]*-[[:space:]]*AC[[:space:]]+[0-9]+:[[:space:]]*PASS' <<< "$AC_BLOCK"; then
    record_yellow "Commit range is 'N/A — no commits' but AC status claims PASS — verify this isn't a false green"
  fi
fi

# --- Accessibility + UX N/A consistency (yellow) ----------------------------

A11Y_BLOCK=$(section_body "Accessibility findings")
UX_BLOCK=$(section_body "UX findings")
A11Y_NA=$(grep -qiE '^[[:space:]]*N/A' <<< "$A11Y_BLOCK" && echo yes || echo no)
UX_NA=$(grep -qiE '^[[:space:]]*N/A' <<< "$UX_BLOCK" && echo yes || echo no)
if [[ "$A11Y_NA" != "$UX_NA" ]]; then
  record_yellow "Accessibility findings and UX findings disagree on UI-touched (one says N/A, the other doesn't) — verify scope"
fi

# --- report -----------------------------------------------------------------

echo "check-build-notes @ $NOTES"
if (( ${#RED[@]} == 0 && ${#YELLOW[@]} == 0 )); then
  echo "  GREEN — build-notes is contract-compliant"
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

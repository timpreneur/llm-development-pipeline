#!/usr/bin/env bash
#
# dev-pipeline-ideate check-brief
#
# Validate a 01-brief.md against the Ideate output contract.
#
# Usage:
#   check-brief.sh <path-to-01-brief.md>
#
# Exit 0 = contract-compliant (possibly with yellow warnings).
# Exit 1 = red failures (must be fixed before close).
# Exit 2 = usage error.

set -euo pipefail

BRIEF="${1:-}"
if [[ -z "$BRIEF" ]]; then
  echo "ERROR: path to 01-brief.md required" >&2
  echo "Usage: check-brief.sh <path-to-01-brief.md>" >&2
  exit 2
fi
if [[ ! -f "$BRIEF" ]]; then
  echo "ERROR: file not found: $BRIEF" >&2
  exit 2
fi

RED=()
YELLOW=()

record_red()    { RED+=("$1"); }
record_yellow() { YELLOW+=("$1"); }

# --- split frontmatter / body -----------------------------------------------

# Frontmatter = first YAML block between --- markers.
FRONTMATTER=$(awk 'BEGIN{in_fm=0} /^---$/{in_fm++; if(in_fm==2) exit; next} in_fm==1{print}' "$BRIEF")
BODY=$(awk 'BEGIN{past_fm=0; seen=0} /^---$/{seen++; if(seen==2){past_fm=1; next}} past_fm==1{print}' "$BRIEF")

if [[ -z "$FRONTMATTER" ]]; then
  record_red "no YAML frontmatter block"
fi
if [[ -z "$BODY" ]]; then
  record_red "no body (everything after frontmatter is empty)"
fi

# --- frontmatter fields ------------------------------------------------------

REQUIRED_FIELDS=(session feature_id project owner status inputs updated regulated customer_facing_launch)
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! grep -qE "^${field}:" <<< "$FRONTMATTER"; then
    record_red "frontmatter missing required field: $field"
  fi
done

# session must be 01-ideate
actual_session=$( (grep -E "^session:" <<< "$FRONTMATTER" || true) | head -1 | sed 's/^session:[[:space:]]*//' )
if [[ -n "$actual_session" && "$actual_session" != "01-ideate" ]]; then
  record_red "frontmatter session='$actual_session' but expected '01-ideate'"
fi

# regulated / customer_facing_launch must be explicit true|false
for flag in regulated customer_facing_launch; do
  val=$( (grep -E "^${flag}:" <<< "$FRONTMATTER" || true) | head -1 | sed "s/^${flag}:[[:space:]]*//" | tr -d '[:space:]' )
  if [[ -n "$val" && "$val" != "true" && "$val" != "false" ]]; then
    record_red "frontmatter flag ${flag}='$val' must be literally 'true' or 'false'"
  fi
done

# --- body sections -----------------------------------------------------------

require_h2() {
  local heading="$1"
  if ! grep -qE "^## ${heading}([[:space:]]|$)" <<< "$BODY"; then
    record_red "body missing required H2 section: '## ${heading}'"
  fi
}

require_h2 "Vision"
require_h2 "Pressure-test"
require_h2 "Brief"
require_h2 "Flags"

# Sub-sections under ## Brief
for sub in "Scope" "Acceptance criteria" "Non-goals" "Decisions needed"; do
  if ! grep -qE "^### ${sub}([[:space:]]|$)" <<< "$BODY"; then
    record_red "body missing required H3 sub-section: '### ${sub}'"
  fi
done

# Pressure-test must have ≥2 ### Alternative entries
ALT_COUNT=$(grep -cE "^### Alternative" <<< "$BODY" || true)
if (( ALT_COUNT < 2 )); then
  record_red "Pressure-test must have ≥2 '### Alternative' subheadings (found $ALT_COUNT)"
fi

# --- yellow warnings: solutioning / implementation leaks --------------------
#
# Extract body "clean" = strip fenced code blocks and markdown links, since
# example blocks and linked paths are legitimate.

CLEAN_BODY=$(awk '
  BEGIN{in_fence=0}
  /^```/{in_fence = !in_fence; next}
  in_fence==0{print}
' <<< "$BODY")

# Also strip inline/link markdown so "(`path/to/thing.md`)" doesn't trip us.
CLEAN_BODY=$(sed 's/\[[^]]*\]([^)]*)//g; s/`[^`]*`//g' <<< "$CLEAN_BODY")

# Flag file-extension-looking strings.
if grep -qE '\.(md|ts|tsx|py|json|yaml|yml|sql|sh|jsx|vue|go|rb|rs)\b' <<< "$CLEAN_BODY"; then
  record_yellow "body contains file-extension-looking strings — brief should not specify file paths"
fi

# Flag endpoint signatures.
if grep -qE '\b(POST|GET|PUT|PATCH|DELETE)[[:space:]]+/' <<< "$CLEAN_BODY"; then
  record_yellow "body contains HTTP endpoint signatures — brief should not specify API shape"
fi

# Flag component-name-looking strings (<FooBar/> or <FooBar>).
if grep -qE '<[A-Z][A-Za-z0-9]*[[:space:]]*/?>' <<< "$CLEAN_BODY"; then
  record_yellow "body contains component-name-looking strings — brief should not name components"
fi

# --- report -----------------------------------------------------------------

echo "check-brief @ $BRIEF"
if (( ${#RED[@]} == 0 && ${#YELLOW[@]} == 0 )); then
  echo "  GREEN — brief is contract-compliant"
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
  # yellow-only → still ok to close, but surface to Timm
  exit 0
fi

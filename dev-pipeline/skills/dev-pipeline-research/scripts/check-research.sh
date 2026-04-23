#!/usr/bin/env bash
#
# dev-pipeline-research check-research
#
# Validate a 05-research.md against the Research output contract.
# v0.1.0 behavior: enforces per-feature coverage + candidate evidence +
# strong-signal-must-have-inbox-seed + cohort cap.
#
# Usage:
#   check-research.sh <path-to-05-research.md>
#
# Exit 0 = contract-compliant (possibly with yellow warnings).
# Exit 1 = red failures (must be fixed before surface).
# Exit 2 = usage error.

set -euo pipefail

REP="${1:-}"
if [[ -z "$REP" ]]; then
  echo "ERROR: path to 05-research.md required" >&2
  echo "Usage: check-research.sh <path-to-05-research.md>" >&2
  exit 2
fi
if [[ ! -f "$REP" ]]; then
  echo "ERROR: file not found: $REP" >&2
  exit 2
fi

RED=()
YELLOW=()

record_red()    { RED+=("$1"); }
record_yellow() { YELLOW+=("$1"); }

# --- split frontmatter / body -----------------------------------------------

FRONTMATTER=$(awk 'BEGIN{in_fm=0} /^---$/{in_fm++; if(in_fm==2) exit; next} in_fm==1{print}' "$REP")
BODY=$(awk 'BEGIN{past_fm=0; seen=0} /^---$/{seen++; if(seen==2){past_fm=1; next}} past_fm==1{print}' "$REP")

if [[ -z "$FRONTMATTER" ]]; then
  record_red "no YAML frontmatter block"
fi
if [[ -z "$BODY" ]]; then
  record_red "no body"
fi

# --- frontmatter fields ------------------------------------------------------

REQUIRED_FIELDS=(session cohort_id project owner status features inputs_per_feature updated inbox_seeds)
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! grep -qE "^${field}:" <<< "$FRONTMATTER"; then
    record_red "frontmatter missing required field: $field"
  fi
done

# session must be 05-research
actual_session=$( (grep -E "^session:" <<< "$FRONTMATTER" || true) | head -1 | sed 's/^session:[[:space:]]*//' )
if [[ -n "$actual_session" && "$actual_session" != "05-research" ]]; then
  record_red "frontmatter session='$actual_session' but expected '05-research'"
fi

# status must be ready-for-review or reviewed
actual_status=$( (grep -E "^status:" <<< "$FRONTMATTER" || true) | head -1 | sed 's/^status:[[:space:]]*//' | tr -d '[:space:]' )
if [[ -n "$actual_status" && "$actual_status" != "ready-for-review" && "$actual_status" != "reviewed" ]]; then
  record_red "frontmatter status='$actual_status' must be 'ready-for-review' or 'reviewed'"
fi

# cohort_id must look like YYYY-Www or YYYY-MM
cohort_val=$( (grep -E "^cohort_id:" <<< "$FRONTMATTER" || true) | head -1 | sed 's/^cohort_id:[[:space:]]*//' | tr -d '[:space:]' )
if [[ -n "$cohort_val" && ! "$cohort_val" =~ ^[0-9]{4}-(W[0-9]{2}|[0-9]{2})$ ]]; then
  record_red "frontmatter cohort_id='$cohort_val' must be 'YYYY-Www' or 'YYYY-MM'"
fi

# features list must be non-empty
features_line=$( (grep -E "^features:" <<< "$FRONTMATTER" || true) | head -1 | sed 's/^features:[[:space:]]*//' )
if [[ -n "$features_line" ]]; then
  # strip brackets + commas, then split on whitespace
  clean=$(echo "$features_line" | tr -d '[]' | tr ',' ' ')
  feat_count=0
  for f in $clean; do
    feat_count=$((feat_count+1))
  done
  if (( feat_count == 0 )); then
    record_red "frontmatter features list is empty — cohort must contain ≥1 feature"
  fi
  if (( feat_count > 5 )); then
    record_red "frontmatter features list has $feat_count items — cap is 5 features per cohort session (split into per-surface runs)"
  fi
fi

# --- required body sections --------------------------------------------------

require_h2() {
  local heading="$1"
  if ! grep -qE "^## ${heading}([[:space:]]|$)" <<< "$BODY"; then
    record_red "body missing required H2 section: '## ${heading}'"
  fi
}

require_h2 "Cohort scope"
require_h2 "Per-feature findings"
require_h2 "Cohort themes"
require_h2 "Candidates"
require_h2 "Metrics summary"
require_h2 "Surfaces for Timm"
require_h2 "References"

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

# --- Per-feature findings: one H3 per listed feature ------------------------

PF_BLOCK=$(section_body "Per-feature findings")
H3_COUNT=$(grep -cE '^### ' <<< "$PF_BLOCK" || true)
if [[ -n "$features_line" ]]; then
  clean=$(echo "$features_line" | tr -d '[]' | tr ',' ' ')
  for f in $clean; do
    # strip whitespace + quotes
    ff=$(echo "$f" | sed -e 's/[[:space:]]//g' -e 's/"//g' -e "s/'//g")
    if [[ -n "$ff" ]]; then
      if ! grep -qE "^### ${ff}([[:space:]]|$)" <<< "$PF_BLOCK"; then
        record_red "Per-feature findings missing '### ${ff}' subsection (feature listed in frontmatter)"
      fi
    fi
  done
fi
if (( H3_COUNT < 1 )); then
  record_red "Per-feature findings has no '### <feature_id>' subsections"
fi

# --- Cohort themes: non-empty -----------------------------------------------

THEMES_BLOCK=$(section_body "Cohort themes")
THEMES_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$THEMES_BLOCK" || true)
if [[ -z "$THEMES_CONTENT" ]]; then
  record_red "Cohort themes section is empty (design:research-synthesis must run)"
fi

# --- Candidates: each has Problem + Evidence + Signal + Routing -------------

CAND_BLOCK=$(section_body "Candidates")
CAND_COUNT=$(grep -cE '^### ' <<< "$CAND_BLOCK" || true)
if (( CAND_COUNT < 1 )); then
  record_red "Candidates section has no '### <candidate>' subsections — must list ≥1 candidate (or explicitly say 'N/A — no candidates emerged' with one H3 stub explaining why)"
fi

# Per-candidate field enforcement: for every H3 in Candidates, we expect
# Problem, Evidence, Signal, Routing (and Inbox seed if Signal=strong).
# All done in a single awk pass that emits RED:<msg> lines for each failure.
CAND_RED=$(awk '
  function flush_candidate(   sline, sval, sstrong, seed_seen, seed_is_na) {
    if (name == "") return
    if (!have_problem)  print "RED:Candidate '\''" name "'\'' missing **Problem** field"
    if (!have_evidence) print "RED:Candidate '\''" name "'\'' missing **Evidence** field"
    if (!have_signal)   print "RED:Candidate '\''" name "'\'' missing **Signal** field"
    if (!have_routing)  print "RED:Candidate '\''" name "'\'' missing **Routing** field"

    # Signal value check
    sline = signal_line
    sstrong = 0
    if (sline != "") {
      if (tolower(sline) ~ /strong/)      sstrong = 1
      else if (tolower(sline) ~ /moderate/);
      else if (tolower(sline) ~ /weak/);
      else print "RED:Candidate '\''" name "'\'' Signal field value not recognized (must be strong|moderate|weak)"
    }

    # Evidence bullet count
    if (have_evidence && ev_bullet_count < 1)
      print "RED:Candidate '\''" name "'\'' Evidence has no citation bullets (need >=1 '\''- <ref>: <observation>'\'' line)"

    # Strong signal => inbox seed required, non-N/A
    if (sstrong) {
      if (!have_inbox_seed) {
        print "RED:Candidate '\''" name "'\'' is signal=strong but missing **Inbox seed** field"
      } else if (inbox_seed_is_na) {
        print "RED:Candidate '\''" name "'\'' is signal=strong but Inbox seed is N/A - strong-signal candidates must be seeded to _inbox/"
      }
    }
  }

  BEGIN {
    name = ""; have_problem=0; have_evidence=0; have_signal=0; have_routing=0
    have_inbox_seed=0; inbox_seed_is_na=0; signal_line=""; ev_bullet_count=0
    in_evidence=0
  }

  /^### / {
    flush_candidate()
    name = $0
    sub(/^### [[:space:]]*/, "", name)
    have_problem=0; have_evidence=0; have_signal=0; have_routing=0
    have_inbox_seed=0; inbox_seed_is_na=0; signal_line=""; ev_bullet_count=0
    in_evidence=0
    next
  }

  {
    line = $0
    lower = tolower(line)

    # Field detectors
    if (lower ~ /\*\*problem[\.]?\*\*/ || lower ~ /\*\*problem statement[\.]?\*\*/) {
      have_problem=1
      in_evidence=0
    }
    if (lower ~ /\*\*evidence[\.]?\*\*/) {
      have_evidence=1
      in_evidence=1
      next
    }
    if (lower ~ /\*\*signal[\.]?\*\*/) {
      have_signal=1
      signal_line = line
      in_evidence=0
    }
    if (lower ~ /\*\*routing[\.]?\*\*/) {
      have_routing=1
      in_evidence=0
    }
    if (lower ~ /\*\*inbox seed[\.]?\*\*/) {
      have_inbox_seed=1
      if (line ~ /N\/A/) inbox_seed_is_na=1
      in_evidence=0
    }

    # Evidence bullet counting: any "- " bulleted line while in_evidence,
    # until we hit another bold-field marker (handled above by in_evidence=0).
    if (in_evidence && line ~ /^[[:space:]]*-[[:space:]]+[^[:space:]]/) {
      ev_bullet_count++
    }
  }

  END { flush_candidate() }
' <<< "$CAND_BLOCK")

# Turn each RED:... line into a record_red call.
if [[ -n "$CAND_RED" ]]; then
  while IFS= read -r rline; do
    [[ -z "$rline" ]] && continue
    msg="${rline#RED:}"
    record_red "$msg"
  done <<< "$CAND_RED"
fi

# --- Metrics summary: non-empty table ---------------------------------------

METRICS_BLOCK=$(section_body "Metrics summary")
METRICS_ROWS=$(grep -cE '^\|[[:space:]]*[A-Za-z]' <<< "$METRICS_BLOCK" || true)
# Rows include the header row + divider + data. We want at least 2 data-ish rows.
METRICS_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$METRICS_BLOCK" || true)
if [[ -z "$METRICS_CONTENT" ]]; then
  record_red "Metrics summary section is empty (LLM-Ops reads this)"
elif (( METRICS_ROWS < 2 )); then
  record_yellow "Metrics summary table has very few rows — verify the per-cohort numbers are populated"
fi

# --- Surfaces for Timm: non-empty -------------------------------------------

SURF_BLOCK=$(section_body "Surfaces for Timm")
SURF_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$SURF_BLOCK" || true)
if [[ -z "$SURF_CONTENT" ]]; then
  record_red "Surfaces for Timm section is empty (write 'None — clean cohort.' or list items)"
fi

# --- References: non-empty --------------------------------------------------

REFS_BLOCK=$(section_body "References")
REFS_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$REFS_BLOCK" || true)
if [[ -z "$REFS_CONTENT" ]]; then
  record_red "References section is empty (list dashboards + support tools + direct feedback channels consulted)"
fi

# --- Confound note heuristic (yellow) ---------------------------------------

# If body uses causal language, we want at least one confound note.
if grep -qiE '\b(caused|causes|driv(e|ed|es)|led to|resulted in|because of)\b' <<< "$BODY"; then
  if ! grep -qiE 'confound' <<< "$BODY"; then
    record_yellow "Body uses causal language but no 'confound' note found — verify data:statistical-analysis was applied"
  fi
fi

# --- report -----------------------------------------------------------------

echo "check-research @ $REP"
if (( ${#RED[@]} == 0 && ${#YELLOW[@]} == 0 )); then
  echo "  GREEN — research artifact is contract-compliant"
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

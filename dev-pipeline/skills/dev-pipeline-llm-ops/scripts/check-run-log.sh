#!/usr/bin/env bash
# check-run-log.sh — validate a dev-pipeline-llm-ops run log
#
# Usage: bash check-run-log.sh <path-to-run-log.md>
#
# Exit codes:
#   0 — GREEN (no REDs; YELLOWs allowed)
#   1 — RED (validator errors)
#   2 — usage / input error
#
# Convention: AWK-emits-verdict-lines. Per-subsection validation happens inside a
# single awk pass that emits `RED:<msg>` / `YELLOW:<msg>` lines; bash reads them
# back and routes them to record_red / record_yellow. See
# dev-pipeline-research/lessons.md 2026-04-19 for the bug this pattern avoids.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <run-log.md>" >&2
  exit 2
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
  echo "error: file not found: $FILE" >&2
  exit 2
fi

REDS=()
YELLOWS=()

record_red()    { REDS+=("$1"); }
record_yellow() { YELLOWS+=("$1"); }

# -------------------------------------------------------------------- frontmatter

# Extract frontmatter block (between first two `---` lines)
FRONTMATTER="$(awk '/^---$/{c++; next} c==1' "$FILE" || true)"

if [[ -z "${FRONTMATTER:-}" ]]; then
  record_red "missing YAML frontmatter block (--- ... ---) at top of file"
fi

get_field() {
  local key="$1"
  echo "$FRONTMATTER" | grep -E "^${key}:" | head -1 | sed -E "s/^${key}:[[:space:]]*//" | sed -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//" || true
}

SESSION="$(get_field session)"
MODE="$(get_field mode)"
RUN_ID="$(get_field run_id)"
OWNER="$(get_field owner)"
STATUS="$(get_field status)"
UPDATED="$(get_field updated)"

[[ "$SESSION" == "llm-ops" ]] || record_red "frontmatter: session must be 'llm-ops' (got '${SESSION:-}')"

case "$MODE" in
  drift-check|lesson-reconciliation|metric-aggregation|fix-session) : ;;
  "") record_red "frontmatter: mode is required" ;;
  *) record_red "frontmatter: mode must be drift-check|lesson-reconciliation|metric-aggregation|fix-session (got '$MODE')" ;;
esac

if [[ -z "$RUN_ID" ]]; then
  record_red "frontmatter: run_id is required"
elif ! echo "$RUN_ID" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}-[0-9]{2}$'; then
  record_red "frontmatter: run_id must match YYYY-MM-DDTHH-MM (got '$RUN_ID')"
fi

[[ -n "$OWNER" ]] || record_red "frontmatter: owner is required"

case "$STATUS" in
  complete|applied|rejected|deferred) : ;;
  "") record_red "frontmatter: status is required" ;;
  *) record_red "frontmatter: status must be complete|applied|rejected|deferred (got '$STATUS')" ;;
esac

# fix-session status constraint
if [[ "$MODE" == "fix-session" ]] && [[ "$STATUS" == "complete" ]]; then
  record_red "frontmatter: fix-session cannot use status=complete (use applied|rejected|deferred)"
fi

if [[ -z "$UPDATED" ]]; then
  record_red "frontmatter: updated is required"
elif ! echo "$UPDATED" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
  record_red "frontmatter: updated must match YYYY-MM-DD (got '$UPDATED')"
fi

# -------------------------------------------------------------------- body H2 sections

h2_present() {
  grep -qE "^## $1\$" "$FILE"
}

# Common H2s (all modes)
h2_present "Pre-flight" || record_red "missing ## Pre-flight section"
h2_present "CHANGELOG line" || record_red "missing ## CHANGELOG line section"

# Mode-specific H2s
case "$MODE" in
  drift-check)
    h2_present "Hashes" || record_red "drift-check: missing ## Hashes section"
    h2_present "Assessments" || record_red "drift-check: missing ## Assessments section"
    h2_present "Hash update" || record_red "drift-check: missing ## Hash update section"
    ;;
  lesson-reconciliation)
    h2_present "Wrappers scanned" || record_red "lesson-reconciliation: missing ## Wrappers scanned section"
    h2_present "Dispositions" || record_red "lesson-reconciliation: missing ## Dispositions section"
    h2_present "Threshold checks" || record_red "lesson-reconciliation: missing ## Threshold checks section"
    ;;
  metric-aggregation)
    h2_present "Cohort source" || record_red "metric-aggregation: missing ## Cohort source section"
    h2_present "Aggregated metrics" || record_red "metric-aggregation: missing ## Aggregated metrics section"
    h2_present "Threshold checks" || record_red "metric-aggregation: missing ## Threshold checks section"
    h2_present "metrics.md update" || record_red "metric-aggregation: missing ## metrics.md update section"
    ;;
  fix-session)
    h2_present "Trigger" || record_red "fix-session: missing ## Trigger section"
    h2_present "Proposed change" || record_red "fix-session: missing ## Proposed change section"
    h2_present "Brief delta" || record_red "fix-session: missing ## Brief delta section"
    h2_present "Approval" || record_red "fix-session: missing ## Approval section"
    ;;
esac

# -------------------------------------------------------------------- Pre-flight body

# Extract the body of ## Pre-flight (until next H2 or EOF) in a single awk pass.
PREFLIGHT_BODY="$(awk '
  /^## Pre-flight$/ { in_section=1; next }
  /^## / && in_section { in_section=0 }
  in_section { print }
' "$FILE" || true)"

if [[ -z "${PREFLIGHT_BODY// }" ]]; then
  # Already recorded missing section above; skip further pre-flight checks.
  :
else
  # 24h-in-flight check evidence — require an explicit verdict, not just a mention
  if ! echo "$PREFLIGHT_BODY" | grep -qiE 'In-flight manifest check.*:.*(passed|blocked|clean|ok)'; then
    if [[ "$MODE" == "fix-session" ]]; then
      record_red "fix-session: ## Pre-flight must document a 24h-in-flight manifest check with verdict (passed|blocked|clean)"
    else
      record_yellow "## Pre-flight: 24h-in-flight manifest check verdict not found"
    fi
  fi

  # _meta state read
  if ! echo "$PREFLIGHT_BODY" | grep -qiE '_meta/'; then
    record_yellow "## Pre-flight: _meta/ state read not documented"
  fi
fi

# -------------------------------------------------------------------- CHANGELOG line body

CHANGELOG_BODY="$(awk '
  /^## CHANGELOG line$/ { in_section=1; next }
  /^## / && in_section { in_section=0 }
  in_section { print }
' "$FILE" || true)"

# Strip blank lines and fenced markers
CHANGELOG_CLEAN="$(echo "$CHANGELOG_BODY" | grep -vE '^\s*$|^\s*```' || true)"
if [[ -z "${CHANGELOG_CLEAN// }" ]]; then
  record_red "## CHANGELOG line section is empty — must contain the appended one-liner"
else
  # Expect the line to start with a YYYY-MM-DD date and include the mode tag
  if ! echo "$CHANGELOG_CLEAN" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]*[—-]'; then
    record_yellow "## CHANGELOG line: no YYYY-MM-DD prefix found on any line"
  fi
  if [[ -n "$MODE" ]] && ! echo "$CHANGELOG_CLEAN" | grep -qE "$MODE"; then
    record_yellow "## CHANGELOG line: does not mention mode '$MODE'"
  fi
fi

# -------------------------------------------------------------------- Mode: drift-check per-subsection

if [[ "$MODE" == "drift-check" ]]; then
  AWK_OUT="$(awk '
    BEGIN { in_assess=0; assess_count=0; ok_count=0 }
    /^## Assessments$/ { in_assess=1; next }
    /^## / && in_assess { in_assess=0 }
    in_assess {
      # Count bulleted assessments that mention Verdict:
      if ($0 ~ /^[[:space:]]*-[[:space:]]/ && $0 ~ /Verdict:/) {
        assess_count++
        if ($0 ~ /Verdict:[[:space:]]*(OK|Review|Block)/) ok_count++
      }
    }
    END {
      if (assess_count == 0) print "YELLOW:drift-check: ## Assessments has no bulleted verdict entries"
      if (assess_count > 0 && ok_count < assess_count) {
        print "RED:drift-check: every Assessment must state Verdict: OK|Review|Block (" (assess_count - ok_count) " missing)"
      }
    }

    # Hashes table — require at least one row with "yes"/"YES" or "no" in drifted column
    /^## Hashes$/ { in_hashes=1; next }
    /^## / && in_hashes { in_hashes=0 }
    in_hashes && /^\|/ { hash_rows++ }
    END {
      if (hash_rows < 3) print "RED:drift-check: ## Hashes table must have a header row + separator + at least one data row"
    }
  ' "$FILE" || true)"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    case "$line" in
      RED:*)    record_red    "${line#RED:}" ;;
      YELLOW:*) record_yellow "${line#YELLOW:}" ;;
    esac
  done <<< "$AWK_OUT"
fi

# -------------------------------------------------------------------- Mode: lesson-reconciliation per-subsection

if [[ "$MODE" == "lesson-reconciliation" ]]; then
  AWK_OUT="$(awk '
    /^## Dispositions$/ { in_disp=1; next }
    /^## / && in_disp { in_disp=0 }
    in_disp && /^### / { disp_count++; cur=$0; has_decision[cur]=0; next }
    in_disp && cur != "" && /^-[[:space:]]+Decision:[[:space:]]*(Promote|Retire|Discard)/ { has_decision[cur]=1 }

    /^## Threshold checks$/ { in_thresh=1; next }
    /^## / && in_thresh { in_thresh=0 }
    in_thresh { thresh_nonempty=1 }

    END {
      if (disp_count == 0) print "RED:lesson-reconciliation: ## Dispositions has no H3 entries"
      for (k in has_decision) {
        if (has_decision[k] == 0) print "RED:lesson-reconciliation: " k " missing Decision: Promote|Retire|Discard"
      }
      if (thresh_nonempty != 1) print "RED:lesson-reconciliation: ## Threshold checks section is empty"
    }
  ' "$FILE" || true)"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    case "$line" in
      RED:*)    record_red    "${line#RED:}" ;;
      YELLOW:*) record_yellow "${line#YELLOW:}" ;;
    esac
  done <<< "$AWK_OUT"
fi

# -------------------------------------------------------------------- Mode: metric-aggregation per-subsection

if [[ "$MODE" == "metric-aggregation" ]]; then
  AWK_OUT="$(awk '
    /^## Aggregated metrics$/ { in_agg=1; next }
    /^## / && in_agg { in_agg=0 }
    in_agg && /^\|/ { agg_rows++ }

    /^## Cohort source$/ { in_src=1; next }
    /^## / && in_src { in_src=0 }
    in_src && /cohort_id/i { cohort_mentioned=1 }
    in_src && /[Cc]ohort id/ { cohort_mentioned=1 }

    END {
      if (agg_rows < 3) print "RED:metric-aggregation: ## Aggregated metrics table must have header + separator + at least one metric row"
      if (cohort_mentioned != 1) print "RED:metric-aggregation: ## Cohort source must identify the cohort id"
    }
  ' "$FILE" || true)"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    case "$line" in
      RED:*)    record_red    "${line#RED:}" ;;
      YELLOW:*) record_yellow "${line#YELLOW:}" ;;
    esac
  done <<< "$AWK_OUT"
fi

# -------------------------------------------------------------------- Mode: fix-session per-subsection

if [[ "$MODE" == "fix-session" ]]; then
  AWK_OUT="$(awk '
    /^## Trigger$/ { in_trig=1; next }
    /^## / && in_trig { in_trig=0 }
    in_trig {
      if ($0 ~ /Source:/ || $0 ~ /source:/) trigger_source=1
      if ($0 ~ /Specific signal:/ || $0 ~ /signal:/) trigger_signal=1
    }

    /^## Proposed change$/ { in_prop=1; next }
    /^## / && in_prop { in_prop=0 }
    in_prop && /Rationale:/ { has_rationale=1 }
    in_prop && /Expected metric effect:/ { has_effect=1 }

    /^## Approval$/ { in_app=1; next }
    /^## / && in_app { in_app=0 }
    in_app && /[Tt]imm response/ { has_response=1 }

    END {
      if (trigger_source != 1) print "RED:fix-session: ## Trigger must cite a Source (metric-aggregation run_id / drift-check run_id / Timm request date)"
      if (trigger_signal != 1) print "RED:fix-session: ## Trigger must include the Specific signal line"
      if (has_rationale != 1) print "RED:fix-session: ## Proposed change must include a Rationale line"
      if (has_effect != 1) print "RED:fix-session: ## Proposed change must include Expected metric effect line"
      if (has_response != 1) print "RED:fix-session: ## Approval must record Timm response"
    }
  ' "$FILE" || true)"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    case "$line" in
      RED:*)    record_red    "${line#RED:}" ;;
      YELLOW:*) record_yellow "${line#YELLOW:}" ;;
    esac
  done <<< "$AWK_OUT"

  # Status-specific section requirements
  if [[ "$STATUS" == "applied" ]]; then
    h2_present "Applied changes" || record_red "fix-session status=applied: missing ## Applied changes section"
  fi
  if [[ "$STATUS" == "rejected" ]]; then
    h2_present "Rejection notes" || record_red "fix-session status=rejected: missing ## Rejection notes section"
  fi
fi

# -------------------------------------------------------------------- Report

echo "== check-run-log: $FILE =="
echo "mode: ${MODE:-?}  status: ${STATUS:-?}  run_id: ${RUN_ID:-?}"

if [[ ${#YELLOWS[@]} -gt 0 ]]; then
  echo
  echo "YELLOW (${#YELLOWS[@]}):"
  for y in "${YELLOWS[@]}"; do echo "  - $y"; done
fi

if [[ ${#REDS[@]} -gt 0 ]]; then
  echo
  echo "RED (${#REDS[@]}):"
  for r in "${REDS[@]}"; do echo "  - $r"; done
  echo
  echo "RESULT: RED"
  exit 1
fi

echo
echo "RESULT: GREEN"
exit 0

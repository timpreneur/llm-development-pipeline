#!/usr/bin/env bash
#
# pipeline-ship check-ship
#
# Validate a 04-ship.md against the Ship output contract.
# v0.1.0 behavior: accepts manual customer-facing release notes when Build's
# Marketing wrapper is deferred; voice-check is advisory, not gating.
#
# Also validates the sibling 04-punchlist.json if present, by shelling out to
# check-punchlist.sh. Any RED from the punchlist checker bubbles up to RED here.
#
# Usage:
#   check-ship.sh <path-to-04-ship.md>
#
# Exit 0 = contract-compliant (possibly with yellow warnings).
# Exit 1 = red failures (must be fixed before sign-off surface).
# Exit 2 = usage error.

set -euo pipefail

SHIP="${1:-}"
if [[ -z "$SHIP" ]]; then
  echo "ERROR: path to 04-ship.md required" >&2
  echo "Usage: check-ship.sh <path-to-04-ship.md>" >&2
  exit 2
fi
if [[ ! -f "$SHIP" ]]; then
  echo "ERROR: file not found: $SHIP" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_PUNCHLIST="$SCRIPT_DIR/check-punchlist.sh"

RED=()
YELLOW=()

record_red()    { RED+=("$1"); }
record_yellow() { YELLOW+=("$1"); }

# --- split frontmatter / body -----------------------------------------------

FRONTMATTER=$(awk 'BEGIN{in_fm=0} /^---$/{in_fm++; if(in_fm==2) exit; next} in_fm==1{print}' "$SHIP")
BODY=$(awk 'BEGIN{past_fm=0; seen=0} /^---$/{seen++; if(seen==2){past_fm=1; next}} past_fm==1{print}' "$SHIP")

if [[ -z "$FRONTMATTER" ]]; then
  record_red "no YAML frontmatter block"
fi
if [[ -z "$BODY" ]]; then
  record_red "no body"
fi

# --- frontmatter fields ------------------------------------------------------

REQUIRED_FIELDS=(
  session feature_id project owner status inputs updated
  regulated customer_facing_launch
  deploy_url deploy_state
  agentic_qa_coverage_pct punchlist_blocking_open punchlist_url
  watch_window_task_id
)
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! grep -qE "^${field}:" <<< "$FRONTMATTER"; then
    record_red "frontmatter missing required field: $field"
  fi
done

# session must be 04-ship
actual_session=$( (grep -E "^session:" <<< "$FRONTMATTER" || true) | head -1 | sed 's/^session:[[:space:]]*//' )
if [[ -n "$actual_session" && "$actual_session" != "04-ship" ]]; then
  record_red "frontmatter session='$actual_session' but expected '04-ship'"
fi

# status must be ready-for-signoff or shipped
actual_status=$( (grep -E "^status:" <<< "$FRONTMATTER" || true) | head -1 | sed 's/^status:[[:space:]]*//' | tr -d '[:space:]' )
if [[ -n "$actual_status" && "$actual_status" != "ready-for-signoff" && "$actual_status" != "shipped" ]]; then
  record_red "frontmatter status='$actual_status' must be 'ready-for-signoff' or 'shipped'"
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

# deploy_state must be READY (v0.1.0: we don't ship other states)
deploy_state_val=$( (grep -E "^deploy_state:" <<< "$FRONTMATTER" || true) | head -1 | sed "s/^deploy_state:[[:space:]]*//" | tr -d '[:space:]' )
if [[ -n "$deploy_state_val" && "$deploy_state_val" != "READY" ]]; then
  record_red "frontmatter deploy_state='$deploy_state_val' must be 'READY' (v0.1.0 does not ship other states)"
fi

# deploy_url must look URL-ish
deploy_url_val=$( (grep -E "^deploy_url:" <<< "$FRONTMATTER" || true) | head -1 | sed "s/^deploy_url:[[:space:]]*//" | tr -d '[:space:]' )
if [[ -n "$deploy_url_val" && ! "$deploy_url_val" =~ ^https?:// ]]; then
  record_red "frontmatter deploy_url='$deploy_url_val' must start with http:// or https://"
fi

# agentic_qa_coverage_pct must be integer 0-100
aqa_val=$( (grep -E "^agentic_qa_coverage_pct:" <<< "$FRONTMATTER" || true) | head -1 | sed "s/^agentic_qa_coverage_pct:[[:space:]]*//" | tr -d '[:space:]' )
if [[ -n "$aqa_val" ]]; then
  if ! [[ "$aqa_val" =~ ^[0-9]+$ ]]; then
    record_red "frontmatter agentic_qa_coverage_pct='$aqa_val' must be a non-negative integer"
  elif (( aqa_val > 100 )); then
    record_red "frontmatter agentic_qa_coverage_pct='$aqa_val' must be ≤ 100"
  elif (( aqa_val < 50 )); then
    record_yellow "frontmatter agentic_qa_coverage_pct=$aqa_val is below 50% — review whether agentic pass is under-configured or feature is under-specified"
  fi
fi

# punchlist_blocking_open must be non-negative integer
pbo_val=$( (grep -E "^punchlist_blocking_open:" <<< "$FRONTMATTER" || true) | head -1 | sed "s/^punchlist_blocking_open:[[:space:]]*//" | tr -d '[:space:]' )
if [[ -n "$pbo_val" ]] && ! [[ "$pbo_val" =~ ^[0-9]+$ ]]; then
  record_red "frontmatter punchlist_blocking_open='$pbo_val' must be a non-negative integer"
fi

# punchlist_url must be URL-ish and point at the web app
purl_val=$( (grep -E "^punchlist_url:" <<< "$FRONTMATTER" || true) | head -1 | sed "s/^punchlist_url:[[:space:]]*//" | tr -d '[:space:]' )
if [[ -n "$purl_val" && ! "$purl_val" =~ ^https?:// ]]; then
  record_red "frontmatter punchlist_url='$purl_val' must start with http:// or https://"
fi

# watch_window_task_id must be non-empty
wwid_val=$( (grep -E "^watch_window_task_id:" <<< "$FRONTMATTER" || true) | head -1 | sed "s/^watch_window_task_id:[[:space:]]*//" | tr -d '[:space:]' )
if [[ -z "$wwid_val" ]]; then
  record_red "frontmatter watch_window_task_id is empty — schedule skill must return a task_id"
fi

# --- required body sections --------------------------------------------------

require_h2() {
  local heading="$1"
  if ! grep -qE "^## ${heading}([[:space:]]|$)" <<< "$BODY"; then
    record_red "body missing required H2 section: '## ${heading}'"
  fi
}

require_h2 "Preflight"
require_h2 "Migrations"
require_h2 "Deploy"
require_h2 "Smoke"
require_h2 "Agentic QA"
require_h2 "Punchlist"
require_h2 "Observability"
require_h2 "Watch window"
require_h2 "Rollback"
require_h2 "Release notes"
require_h2 "Promotion"
require_h2 "Sign-off"

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

# --- Deploy section: must record state verification + URL -------------------

DEPLOY_BLOCK=$(section_body "Deploy")
DEPLOY_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$DEPLOY_BLOCK" || true)
if [[ -z "$DEPLOY_CONTENT" ]]; then
  record_red "Deploy section is empty (need deploy URL + explicit state verification via platform MCP)"
else
  if ! grep -qiE 'READY' <<< "$DEPLOY_BLOCK"; then
    record_red "Deploy section missing deploy-state verification — must record 'state: READY' (or equivalent) from the platform MCP"
  fi
  if ! grep -qiE 'https?://' <<< "$DEPLOY_BLOCK"; then
    record_red "Deploy section missing a deploy URL (http(s)://…)"
  fi
fi

# --- Smoke section: non-empty ------------------------------------------------

SMOKE_BLOCK=$(section_body "Smoke")
SMOKE_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$SMOKE_BLOCK" || true)
if [[ -z "$SMOKE_CONTENT" ]]; then
  record_red "Smoke section is empty (need at least a read path + a write path with timestamps)"
fi

# --- Agentic QA section: required inner markers -----------------------------

AQA_BLOCK=$(section_body "Agentic QA")
AQA_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$AQA_BLOCK" || true)
if [[ -z "$AQA_CONTENT" ]]; then
  record_red "Agentic QA section is empty (need checks_run, AC coverage table, autonomous coverage %)"
else
  # Autonomous coverage percentage stated
  grep -qiE 'autonomous coverage|coverage:.*%|coverage.*[0-9]+%' <<< "$AQA_BLOCK" \
    || record_red "Agentic QA section missing 'Autonomous coverage' percentage"
  # Checks run list
  grep -qiE 'checks run|checks_run' <<< "$AQA_BLOCK" \
    || record_red "Agentic QA section missing 'Checks run' list"
  # AC coverage — require a table header with 'AC' + 'status' (or at least 'AC coverage')
  grep -qiE 'ac coverage|ac[[:space:]]*id|\| AC' <<< "$AQA_BLOCK" \
    || record_red "Agentic QA section missing AC coverage table"
  # Findings (table or 'None — ...')
  grep -qiE 'findings|None — agentic pass produced no findings' <<< "$AQA_BLOCK" \
    || record_red "Agentic QA section missing 'Findings' block (use 'None — agentic pass produced no findings.' if truly zero)"
fi

# --- Punchlist section: required inner markers ------------------------------

PL_BLOCK=$(section_body "Punchlist")
PL_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$PL_BLOCK" || true)
if [[ -z "$PL_CONTENT" ]]; then
  record_red "Punchlist section is empty (need source path, web app URL, summary, schema check, gating)"
else
  grep -qiE '04-punchlist\.json' <<< "$PL_BLOCK" \
    || record_red "Punchlist section missing source-of-truth path reference to 04-punchlist.json"
  grep -qiE 'ship-punchlist-web\.vercel\.app|punchlist_url' <<< "$PL_BLOCK" \
    || record_red "Punchlist section missing web app URL (ship-punchlist-web.vercel.app/...)"
  grep -qiE 'blocking|watch|agent verified all AC' <<< "$PL_BLOCK" \
    || record_red "Punchlist section missing blocking/watch summary"
  grep -qiE 'schema check|check-punchlist' <<< "$PL_BLOCK" \
    || record_yellow "Punchlist section doesn't record a schema check — run check-punchlist.sh and note the result"
  grep -qiE 'gating|punchlist_gating|strict|advisory' <<< "$PL_BLOCK" \
    || record_red "Punchlist section missing gating mode (strict|advisory)"
fi

# --- Observability section: required inner markers --------------------------

OBS_BLOCK=$(section_body "Observability")
OBS_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$OBS_BLOCK" || true)
if [[ -z "$OBS_CONTENT" ]]; then
  record_red "Observability section is empty (need critical path + metrics + alerts + dashboard URL)"
else
  grep -qiE 'metric' <<< "$OBS_BLOCK" || record_yellow "Observability section does not mention 'metric' — verify metrics are named"
  grep -qiE 'alert'  <<< "$OBS_BLOCK" || record_red    "Observability section missing an alert — at least one alert on the critical path is required"
  grep -qiE 'dashboard' <<< "$OBS_BLOCK" || record_red "Observability section missing dashboard URL reference"
  grep -qiE 'https?://' <<< "$OBS_BLOCK" || record_yellow "Observability section has no URL — confirm dashboard link is present"
fi

# --- Watch window: task_id + cohort_id --------------------------------------

WATCH_BLOCK=$(section_body "Watch window")
WATCH_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$WATCH_BLOCK" || true)
if [[ -z "$WATCH_CONTENT" ]]; then
  record_red "Watch window section is empty"
else
  grep -qiE 'task[_[:space:]-]?id' <<< "$WATCH_BLOCK" || record_red "Watch window section missing 'task_id' (schedule skill return value)"
  grep -qiE 'cohort[_[:space:]-]?id' <<< "$WATCH_BLOCK" || record_red "Watch window section missing 'cohort_id'"
fi

# --- Rollback: non-empty + trigger + steps ----------------------------------

ROLLBACK_BLOCK=$(section_body "Rollback")
ROLLBACK_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$ROLLBACK_BLOCK" || true)
if [[ -z "$ROLLBACK_CONTENT" ]]; then
  record_red "Rollback section is empty (need trigger + steps + ETA + owner)"
else
  grep -qiE 'trigger' <<< "$ROLLBACK_BLOCK" || record_yellow "Rollback section doesn't name a trigger condition"
  grep -qiE 'step|^[[:space:]]*[0-9]+\.' <<< "$ROLLBACK_BLOCK" || record_yellow "Rollback section doesn't list concrete steps"
fi

# --- Release notes: internal + customer-facing ------------------------------

RN_BLOCK=$(section_body "Release notes")
RN_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$RN_BLOCK" || true)
if [[ -z "$RN_CONTENT" ]]; then
  record_red "Release notes section is empty"
else
  grep -qiE 'internal' <<< "$RN_BLOCK" || record_red "Release notes missing **Internal** draft marker"
  grep -qiE 'customer' <<< "$RN_BLOCK" || record_red "Release notes missing **Customer-facing** marker (even if N/A)"
  # If customer_facing_launch=true, customer-facing draft must be non-trivial (not blanket N/A)
  if [[ "$cfl_val" == "true" ]] && grep -qiE 'N/A — not a customer-facing launch' <<< "$RN_BLOCK"; then
    record_red "customer_facing_launch=true but Release notes says 'N/A — not a customer-facing launch' — inconsistent"
  fi
fi

# --- Promotion: all three fields addressed ----------------------------------

PROM_BLOCK=$(section_body "Promotion")
PROM_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$PROM_BLOCK" || true)
if [[ -z "$PROM_CONTENT" ]]; then
  record_red "Promotion section is empty (must address repo_brief_dir + changelog_path + punchlist mirror)"
else
  grep -qiE 'repo_brief_dir|brief' <<< "$PROM_BLOCK" || record_red "Promotion section does not address brief promotion (pipeline.repo_brief_dir)"
  grep -qiE 'changelog' <<< "$PROM_BLOCK" || record_red "Promotion section does not address changelog append (pipeline.changelog_path)"
  grep -qiE 'punchlist.*mirror|\.punchlist/|mirror.*punchlist' <<< "$PROM_BLOCK" \
    || record_red "Promotion section does not record punchlist mirror (always written, not optional)"
  grep -qiE 'v1 pointer|short_sha|pointer' <<< "$PROM_BLOCK" \
    || record_red "Promotion section does not record V1 pointer file (always written for pre-push hook compat)"
fi

# --- Sign-off: non-empty ----------------------------------------------------

SO_BLOCK=$(section_body "Sign-off")
SO_CONTENT=$(grep -vE '^[[:space:]]*$' <<< "$SO_BLOCK" || true)
if [[ -z "$SO_CONTENT" ]]; then
  record_red "Sign-off section is empty (must record surface-to-Timm timestamp)"
fi

# --- Regulated / customer-facing consistency (yellow) -----------------------

if [[ "$regulated_val" == "true" ]]; then
  if ! grep -qiE 'regulated|escalat' <<< "$BODY"; then
    record_yellow "regulated=true but body never mentions 'regulated' or 'escalat' — verify Legal context is preserved from build-notes"
  fi
fi

# --- Sibling punchlist.json validation --------------------------------------

SHIP_DIR=$(cd "$(dirname "$SHIP")" && pwd)
PUNCHLIST_PATH="$SHIP_DIR/04-punchlist.json"
if [[ -f "$PUNCHLIST_PATH" ]]; then
  if [[ -x "$CHECK_PUNCHLIST" ]]; then
    echo "--- running check-punchlist.sh on sibling 04-punchlist.json ---"
    set +e
    bash "$CHECK_PUNCHLIST" "$PUNCHLIST_PATH"
    pl_rc=$?
    set -e
    echo "--- check-punchlist.sh exit=$pl_rc ---"
    if (( pl_rc == 1 )); then
      record_red "sibling 04-punchlist.json failed check-punchlist.sh (see output above)"
    elif (( pl_rc == 2 )); then
      record_red "check-punchlist.sh usage error on $PUNCHLIST_PATH"
    fi
  else
    record_yellow "check-punchlist.sh not found or not executable at $CHECK_PUNCHLIST — skipping sibling JSON validation"
  fi
else
  record_red "sibling 04-punchlist.json not found at $PUNCHLIST_PATH — Phase 4 must always write this file (use items: [] if nothing residual)"
fi

# --- report -----------------------------------------------------------------

echo "check-ship @ $SHIP"
if (( ${#RED[@]} == 0 && ${#YELLOW[@]} == 0 )); then
  echo "  GREEN — ship artifact is contract-compliant"
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

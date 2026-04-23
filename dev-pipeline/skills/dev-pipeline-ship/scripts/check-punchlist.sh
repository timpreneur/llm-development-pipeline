#!/usr/bin/env bash
#
# dev-pipeline-ship check-punchlist
#
# Validate a 04-punchlist.json against the schema-v2 contract documented in
# references/punchlist-schema.md. Uses python3 for JSON parsing.
#
# Usage:
#   check-punchlist.sh <path-to-04-punchlist.json>
#
# Exit 0 = schema-compliant (possibly with yellow warnings).
# Exit 1 = red failures (must be fixed before sign-off surface).
# Exit 2 = usage error.

set -uo pipefail  # NOT -e — we want python's exit to propagate

PL="${1:-}"
if [[ -z "$PL" ]]; then
  echo "ERROR: path to 04-punchlist.json required" >&2
  echo "Usage: check-punchlist.sh <path-to-04-punchlist.json>" >&2
  exit 2
fi
if [[ ! -f "$PL" ]]; then
  echo "ERROR: file not found: $PL" >&2
  exit 2
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 not available — required for JSON parsing" >&2
  exit 2
fi

echo "check-punchlist @ $PL"

python3 - "$PL" <<'PY'
import json
import re
import sys

path = sys.argv[1]
red = []
yellow = []

def r(msg): red.append(msg)
def y(msg): yellow.append(msg)

# --- Parse JSON -------------------------------------------------------------

try:
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except json.JSONDecodeError as e:
    print(f"  RED: invalid JSON: {e}")
    print("  RED (1):")
    sys.exit(1)
except Exception as e:
    print(f"  RED: could not read file: {e}")
    sys.exit(1)

if not isinstance(data, dict):
    print("  RED (1):\n    - top-level JSON must be an object")
    sys.exit(1)

# --- Root-level required fields --------------------------------------------

REQUIRED_ROOT = [
    "schema_version",
    "schema",
    "feature_id",
    "project",
    "short_sha",
    "full_sha",
    "deploy_url",
    "deploy_state",
    "title",
    "created_at",
    "agentic_pass",
    "items",
]

for field in REQUIRED_ROOT:
    if field not in data:
        r(f"root missing required field: {field}")

# schema_version must be "2"
sv = data.get("schema_version")
if sv is not None and sv != "2":
    r(f"schema_version must be '2' for pipeline-authored punchlists (got {sv!r})")

# schema.generator required, format dev-pipeline-ship@<version>
schema_obj = data.get("schema")
if isinstance(schema_obj, dict):
    gen = schema_obj.get("generator")
    if not gen:
        r("schema.generator missing")
    elif not isinstance(gen, str) or not gen.startswith("dev-pipeline-ship@"):
        r(f"schema.generator must match 'dev-pipeline-ship@<version>' (got {gen!r})")
elif "schema" in data:
    r("schema must be an object with at least a 'generator' field")

# feature_id format YYYY-MM-DD-slug (loose check)
fid = data.get("feature_id")
if isinstance(fid, str) and not re.match(r"^\d{4}-\d{2}-\d{2}-[a-z0-9][a-z0-9-]*$", fid):
    y(f"feature_id {fid!r} does not match YYYY-MM-DD-slug convention")

# deploy_state should be READY
ds = data.get("deploy_state")
if ds is not None and ds != "READY":
    r(f"deploy_state must be 'READY' when punchlist is written (got {ds!r})")

# deploy_url URL-ish
du = data.get("deploy_url")
if isinstance(du, str) and not (du.startswith("http://") or du.startswith("https://")):
    r(f"deploy_url must start with http:// or https:// (got {du!r})")

# --- agentic_pass block -----------------------------------------------------

ap = data.get("agentic_pass")
ac_ids_by_status = {"verified": set(), "partial": set(), "human_required": set()}

if ap is None:
    r("agentic_pass missing — Phase 3 must record its work here")
elif not isinstance(ap, dict):
    r("agentic_pass must be an object")
else:
    if not ap.get("completed_at"):
        r("agentic_pass.completed_at missing")

    cov = ap.get("autonomous_coverage_pct")
    if cov is None:
        r("agentic_pass.autonomous_coverage_pct missing")
    elif not isinstance(cov, int) or isinstance(cov, bool):
        r(f"agentic_pass.autonomous_coverage_pct must be an integer (got {type(cov).__name__})")
    elif cov < 0 or cov > 100:
        r(f"agentic_pass.autonomous_coverage_pct={cov} out of range [0, 100]")
    elif cov < 50:
        y(f"agentic_pass.autonomous_coverage_pct={cov} is below 50% — review whether agentic pass is under-configured or feature under-specified")

    checks = ap.get("checks_run")
    if checks is None:
        r("agentic_pass.checks_run missing")
    elif not isinstance(checks, list) or not all(isinstance(c, str) for c in checks):
        r("agentic_pass.checks_run must be an array of strings")
    elif len(checks) == 0:
        r("agentic_pass.checks_run is empty — core pass must always include chrome_navigate/console/network at minimum")

    acs = ap.get("ac_coverage")
    if acs is None:
        r("agentic_pass.ac_coverage missing")
    elif not isinstance(acs, list):
        r("agentic_pass.ac_coverage must be an array")
    else:
        for i, ac in enumerate(acs):
            if not isinstance(ac, dict):
                r(f"agentic_pass.ac_coverage[{i}] must be an object")
                continue
            ac_id = ac.get("ac_id")
            status = ac.get("status")
            if not ac_id:
                r(f"agentic_pass.ac_coverage[{i}].ac_id missing")
            if status not in ("verified", "partial", "human_required"):
                r(f"agentic_pass.ac_coverage[{i}].status must be one of verified|partial|human_required (got {status!r})")
            if status == "verified" and not ac.get("evidence"):
                r(f"agentic_pass.ac_coverage[{i}] (ac_id={ac_id}) status=verified requires 'evidence'")
            if status in ("partial", "human_required") and not ac.get("reason"):
                r(f"agentic_pass.ac_coverage[{i}] (ac_id={ac_id}) status={status} requires 'reason'")
            if ac_id and status in ac_ids_by_status:
                ac_ids_by_status[status].add(ac_id)

    findings = ap.get("findings")
    if findings is None:
        r("agentic_pass.findings missing (use [] if zero)")
    elif not isinstance(findings, list):
        r("agentic_pass.findings must be an array")
    else:
        for i, fnd in enumerate(findings):
            if not isinstance(fnd, dict):
                r(f"agentic_pass.findings[{i}] must be an object")
                continue
            sev = fnd.get("severity")
            st = fnd.get("status")
            if sev not in ("blocking", "watch"):
                r(f"agentic_pass.findings[{i}].severity must be blocking|watch (got {sev!r})")
            if st not in ("open", "resolved"):
                r(f"agentic_pass.findings[{i}].status must be open|resolved (got {st!r})")
            if sev == "blocking" and st == "open":
                r(f"agentic_pass.findings[{i}] has severity=blocking AND status=open — Phase 3 should have paused (contract break)")

# --- items block ------------------------------------------------------------

items = data.get("items")
blocking_count = 0
watch_count = 0

if items is None:
    r("items missing (use [] if zero — empty array is valid)")
elif not isinstance(items, list):
    r("items must be an array")
else:
    if len(items) > 10:
        y(f"items.length={len(items)} > 10 — likely padding; prune to real residuals")

    human_touchable = ac_ids_by_status["partial"] | ac_ids_by_status["human_required"]

    for i, item in enumerate(items):
        if not isinstance(item, dict):
            r(f"items[{i}] must be an object")
            continue
        for field in ("id", "severity", "text", "surface", "rationale"):
            if not item.get(field):
                r(f"items[{i}].{field} missing or empty")
        sev = item.get("severity")
        if sev not in ("blocking", "watch"):
            r(f"items[{i}].severity must be blocking|watch (got {sev!r})")
        elif sev == "blocking":
            blocking_count += 1
            ac_ref = item.get("ac_ref")
            if not ac_ref:
                r(f"items[{i}] severity=blocking requires ac_ref pointing at an AC marked human_required or partial")
            elif ac_ref not in human_touchable:
                r(f"items[{i}] severity=blocking ac_ref={ac_ref!r} does not match any ac_coverage entry with status=human_required|partial")
        elif sev == "watch":
            watch_count += 1

# --- report -----------------------------------------------------------------

print(f"  INFO: blocking={blocking_count} watch={watch_count}")

if not red and not yellow:
    print("  GREEN — punchlist is schema-compliant")
    sys.exit(0)

if red:
    print(f"  RED ({len(red)}):")
    for m in red: print(f"    - {m}")
if yellow:
    print(f"  YELLOW ({len(yellow)}):")
    for m in yellow: print(f"    - {m}")

sys.exit(1 if red else 0)
PY

rc=$?
exit $rc

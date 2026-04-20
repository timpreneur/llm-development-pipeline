# pipeline-llm-ops — close checklist

Run this at the end of **every** LLM-Ops session, regardless of mode. Items marked (mode) apply only to that mode.

## Universal (all modes)

1. Run log written to `Code/pipeline/_meta/runs/YYYY-MM-DDTHH-MM-<mode>.md` per `references/run-log-template.md § <mode>`.
2. `## Pre-flight` section includes the 24h-in-flight manifest check result.
3. `## CHANGELOG line` section contains the exact one-liner that will be appended to `_meta/CHANGELOG.md`.
4. Validator: `bash scripts/check-run-log.sh <run-log-path>` → zero REDs. Fix any RED before closing.
5. Append the CHANGELOG line to `Code/pipeline/_meta/CHANGELOG.md`.
6. Set `status:` in the run log frontmatter (`complete` for read-only modes; `applied | rejected | deferred` for fix-session).

## drift-check only

7. Update `Code/pipeline/_meta/skill-hashes.json` with new hashes — **after** the assessment is logged, not before.
8. If any wrapper verdict was `Block`: include it explicitly in the surface-to-Timm message so a fix-session is scheduled.

## lesson-reconciliation only

7. Each reviewed entry has an appended `disposition:` line in its wrapper's `lessons.md`. Do not rewrite the entry body.
8. If median disposition age this run > 14 days: surface to Timm with the breach + next action (fix-session).

## metric-aggregation only

7. Cohort row appended to `Code/pipeline/_meta/metrics.md` (append-only — never overwrite).
8. If any threshold breached: surface to Timm with the breach + which metric + which session type + next action (fix-session).

## fix-session only

7. Trigger is cited explicitly in `## Trigger` (metric-aggregation run_id, drift-check run_id, or Timm quote + date). No freelancing.
8. In-flight 24h block check was re-verified at session start and is clean. If any manifest was in_progress: run log `status: deferred`, no edits, stop.
9. On approved: plugin source edits + brief delta edits both applied; CHANGELOG line appended; run log `status: applied`.
10. On rejected: `## Rejection notes` captures why + next action; run log `status: rejected`; no edits made.

## Surface-to-Timm messages (verbatim templates)

### drift-check

```
LLM-Ops drift-check — <run_id>

Checked <N> marketplace skills. <M> drifted.
<for each drifted skill: - <skill>: verdict <OK|Review|Block>, affects <wrapper(s)>>

Run log: Code/pipeline/_meta/runs/<file>
CHANGELOG: appended.
<if any Block: "Block verdict on <wrapper> — scheduling fix-session.">
```

### lesson-reconciliation

```
LLM-Ops lesson-reconciliation — <run_id>

Reviewed <N> un-reconciled entries across <W> wrappers.
Promoted: <P>. Retired: <R>. Discarded: <D>.
Median disposition age: <N> days (threshold 14).

Run log: Code/pipeline/_meta/runs/<file>
<if breach: "Median age exceeds threshold — scheduling fix-session.">
```

### metric-aggregation

```
LLM-Ops metric-aggregation — cohort <cohort_id>

Features in cohort: <count>.
Threshold breaches: <none | list>.

Run log: Code/pipeline/_meta/runs/<file>
metrics.md: row appended.
<if breach: "Breaches logged — scheduling fix-session on <metric>.">
```

### fix-session (surface for approval — ONE message)

```
LLM-Ops fix-session — proposed change

Trigger: <metric breach run_id / drift Block run_id / Timm request on DATE>
Fixes metric: <metric name + current value + target>

Proposed diff:
  - <plugin source file>: <one-line diff summary>
  - <plugin source file>: <one-line diff summary>
Brief delta: <file + section> | N/A

Approve to apply? (yes / changes / no)
```

### fix-session (post-close, approved)

```
LLM-Ops fix-session — applied.

Files edited:
  - <file list>
Brief delta: <applied to section X | N/A>
CHANGELOG: appended.
Run log: Code/pipeline/_meta/runs/<file>
```

---
name: dev-pipeline-llm-ops
description: 'Cross-cutting — LLM Ops. NOT a per-feature session. Maintains the pipeline itself: prompts, wrappers, overrides, lessons, marketplace-skill drift, per-cohort metrics. Use when the user says "run LLM Ops", "drift check", "reconcile lessons", "aggregate metrics", "fix wrapper", "propose a pipeline change", or a scheduled maintenance task fires. The one role that may edit pipeline plugin source. Blocks edits if any feature manifest is in_progress within the last 24h. Writes to Code/pipeline/_meta/runs/ and appends to _meta/CHANGELOG.md. Four modes: drift-check, lesson-reconciliation, metric-aggregation, fix-session.'
---

# dev-pipeline-llm-ops — Cross-cutting (Cowork, owner: timm, plugin-source editor)

Wrapper around the LLM Ops maintenance session. Not per-feature; runs on cadence or on trigger. The only session allowed to edit pipeline plugin source + `Code/.templates/llm-native-dev-pipeline-brief.md`.

## When this fires

- User says: "run LLM Ops", "LLM-Ops drift check", "reconcile lessons", "aggregate metrics", "fix <wrapper-name>", "propose a pipeline change".
- A scheduled maintenance task fires (weekly drift + lesson cadence).
- A per-cohort Research session closes (triggers metric-aggregation).
- A metric threshold breach (see thresholds below) triggers a fix-session.

## Modes

Pick **one** mode per session. Do not batch modes.

| Mode | Cadence | Trigger | Writes to |
|------|---------|---------|-----------|
| `drift-check` | Weekly + pre-feature | `_meta/skill-hashes.json` hash mismatch vs live marketplace SKILL.md | `_meta/runs/*-drift-check.md` |
| `lesson-reconciliation` | Weekly | All wrapper `lessons.md` files reviewed together | `_meta/runs/*-lesson-reconciliation.md` |
| `metric-aggregation` | After every cohort Research session closes | `05-research.md § Metrics summary` ready | `_meta/runs/*-metric-aggregation.md` + `_meta/metrics.md` |
| `fix-session` | On threshold breach or Timm request | See Metric thresholds | `_meta/runs/*-fix-session.md` + plugin source edits + brief delta (if any) |

## Pre-flight (all modes)

Before any action — especially any plugin-source edit — check that **no feature manifest is `in_progress`** in any project under `Code/pipeline/<project>/` within the last 24 hours. If anything is in-flight:

- For `drift-check`, `lesson-reconciliation`, `metric-aggregation` — OK to proceed; these are read-only or write-only-to-`_meta/`.
- For `fix-session` — **block** the plugin-source edit. Log the in-flight manifests, schedule the fix for after they close, and write a run log explaining the deferral.

Record the 24h-in-flight check result under `## Pre-flight` in every run log. Missing = validator RED for `fix-session`; validator YELLOW for the other modes.

## Pre-reads (non-negotiable)

1. `Code/.templates/llm-native-dev-pipeline-brief.md` — the contract you're maintaining
2. `Code/pipeline/_meta/` — every file (`skill-hashes.json`, `metrics.md`, `CHANGELOG.md`, `runs/`)
3. Last 10 features' `00-manifest.md` across all projects — for in-flight check + context
4. Every wrapper skill's `lessons.md` sidecar in `pipeline-plugin/skills/*/`

## Mode 1 — drift-check

1. For each marketplace skill referenced by any pipeline wrapper (scan wrapper SKILL.md `description:` + `references/` for `marketplace:skill-name` mentions), compute the SHA256 of the live marketplace SKILL.md.
2. Compare against `_meta/skill-hashes.json` (create the file on first run with an empty object).
3. For each drift, open the corresponding wrapper's contract and assess: does the marketplace change affect our wrapper's assumptions? Three outcomes:
   - **OK** — marketplace change is additive / compatible.
   - **Review** — flag for Timm; wrapper may need a small edit.
   - **Block** — wrapper's contract broken; fix before next feature.
4. Update `_meta/skill-hashes.json` with the new hashes **only after the assessment is logged** (we want the drift recorded even if the assessment is "Review").
5. Write the run log per `references/run-log-template.md § drift-check` shape.
6. Append to `_meta/CHANGELOG.md`: `YYYY-MM-DD — drift-check — <N> drifts, <M> need review, <K> blocked`.

## Mode 2 — lesson-reconciliation

1. Read every wrapper skill's `lessons.md` sidecar.
2. For each entry that hasn't been reconciled yet (no `disposition:` line), decide:
   - **Promote** — write as an override into the relevant project's `CLAUDE.md § pipeline.overrides` block (if project-specific) OR into the wrapper's default contract (if pipeline-wide). Record the destination.
   - **Retire** — the marketplace skill now handles what the lesson wanted. Note which marketplace change obviated it.
   - **Discard** — one-off noise, not a signal. Explain why.
3. Append a `disposition:` line inline under the lesson entry (keep the original entry intact). Example:
   ```
   disposition: promoted to example-fixture/CLAUDE.md pipeline.overrides.build.ux_polish.required_reuse on 2026-04-19
   ```
4. If disposition takes >14 days (median across this run's reconciled entries): flag in the run log's `## Threshold checks` as `override promotion latency breach` → implies a fix-session next.
5. Write the run log per `references/run-log-template.md § lesson-reconciliation` shape.
6. Append to `_meta/CHANGELOG.md`: `YYYY-MM-DD — lesson-reconciliation — <N> entries, <P> promoted, <R> retired, <D> discarded`.

## Mode 3 — metric-aggregation

1. Find the latest cohort's `05-research.md` (across all projects).
2. Parse its `## Metrics summary` table.
3. Update `_meta/metrics.md` with the cohort's row (append; don't overwrite history).
4. Run threshold checks per the table below. For any breach, the run log notes which metric + session type + triggers a fix-session.
5. Write the run log per `references/run-log-template.md § metric-aggregation` shape.
6. Append to `_meta/CHANGELOG.md`: `YYYY-MM-DD — metric-aggregation — cohort <cohort_id>, breaches: <list or none>`.

### Metric thresholds

| Metric | Threshold |
|--------|-----------|
| First-pass done-signal rate (per session type) | <80% across 3 features = fix |
| Re-entry count per feature (per session type) | >2 across 3 features = fix |
| Cross-session re-interview count | >1 per feature across 3 = fix |
| Promotion success rate | <100% = fix |
| Marketplace-skill drift rate (wrappers needing review) | >30% of wrappers drifting per quarter = fix |
| Override promotion latency (lesson → CLAUDE.md) | median >14 days = fix |

## Mode 4 — fix-session

1. **Confirm trigger.** Either a threshold breach logged in an earlier metric-aggregation or drift-check run, or a Timm-requested change. Record the trigger source explicitly in the run log — no freelancing. Validator checks for a trigger citation.
2. **In-flight block check.** Re-verify no manifest in any project is `in_progress` within 24h. If any: defer, log, stop.
3. **Propose the change** in the run log's `## Proposed change` section: what file(s) change, diff summary, rationale, expected effect on metric that triggered the fix.
4. **Brief delta.** If the change touches anything in the pipeline brief's contract shape (session spec, output contract, marketplace-skill list), edit `Code/.templates/llm-native-dev-pipeline-brief.md` in the same session. One edit = both files. Record the brief delta under `## Brief delta`.
5. **Surface to Timm** for approval. One message. Include the diff summary + brief delta + which metric this fixes.
6. **On approval**: apply the edit to plugin source + brief in one commit-shaped change, log to `_meta/CHANGELOG.md`, mark run log `status: applied`.
7. **On changes-requested**: cycle within the session.
8. **On rejection**: mark run log `status: rejected`, capture why, do not edit.

Write the run log per `references/run-log-template.md § fix-session` shape.

## Close (all modes)

1. Write `Code/pipeline/_meta/runs/YYYY-MM-DDTHH-MM-<mode>.md` per the template.
2. Run `scripts/check-run-log.sh <path>` — fix every RED before close.
3. Append to `Code/pipeline/_meta/CHANGELOG.md` (single dated line per mode, format above).
4. For `drift-check`: update `_meta/skill-hashes.json` only after the assessment is logged.
5. For `metric-aggregation`: update `_meta/metrics.md` append row.
6. For `fix-session` (approved): plugin source edits + brief edits applied. No other session may do this.

## Deferred in v0.1.0

- **Cross-cohort trending in `_meta/metrics.md`.** First version: flat append-only table. Trending added in v0.1.x.
- **Auto-PR for `fix-session` edits.** First version: edits are applied locally; Timm commits by hand. Auto-PR added when we have a CI signal.

## Files you touch

- `Code/pipeline/_meta/runs/<timestamp>-<mode>.md` (create)
- `Code/pipeline/_meta/CHANGELOG.md` (append)
- `Code/pipeline/_meta/skill-hashes.json` (drift-check only)
- `Code/pipeline/_meta/metrics.md` (metric-aggregation only)
- Pipeline plugin skill source (`pipeline-plugin/skills/*`) — **fix-session only, after approval**
- `Code/.templates/llm-native-dev-pipeline-brief.md` — **fix-session only, after approval**
- Project `<PROJECT>/CLAUDE.md` (lesson-reconciliation promote action only)
- `lessons.md` in this skill (append on notable patterns — meta-lessons)

## Files you must not touch

- Any feature directory (`Code/pipeline/<project>/<FEATURE_DIR>/`) — always read-only
- Any wrapper's `lessons.md` body — only append a `disposition:` line, never rewrite the entry
- Plugin source in any mode other than fix-session-after-approval

## Smoke test

`bash scripts/smoke.sh` runs `check-run-log.sh` against three fixtures. Expected: good-drift-check=rc0, bad-missing-sections=rc1, bad-no-in-flight-check=rc1 (fix-session missing pre-flight 24h check).

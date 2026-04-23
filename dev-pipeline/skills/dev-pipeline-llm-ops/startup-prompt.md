# dev-pipeline-llm-ops — Cowork startup prompt

Paste this into a fresh Cowork session (or fire via scheduled task) to start an LLM-Ops maintenance session.

---

```
Starting a Cowork session from Code/. Cross-cutting — LLM Ops.
NOT a per-feature session.

Your role is pipeline maintainer. Pick ONE mode per session:
 - drift-check
 - lesson-reconciliation
 - metric-aggregation
 - fix-session

Do not batch modes. If you're tempted to combine, stop and split into
separate sessions — the run log shape is mode-specific.

Marketplace skills loaded:
 - skill-creator
 - cowork-plugin-management:cowork-plugin-customizer
 - consolidate-memory

Read first:
 1. Code/.templates/llm-native-dev-pipeline-brief.md (the contract)
 2. Code/pipeline/_meta/ (all files: skill-hashes.json, metrics.md,
    CHANGELOG.md, runs/)
 3. Last 10 features' 00-manifest.md across all projects
 4. Every wrapper skill's lessons.md sidecar in pipeline-plugin/skills/*/

PRE-FLIGHT (all modes):
 - Check no feature manifest is status=in_progress within last 24h
   across any project under Code/pipeline/<project>/.
 - For drift-check / lesson-reconciliation / metric-aggregation: record
   the check result in ## Pre-flight; OK to proceed.
 - For fix-session: if anything is in-flight, BLOCK the plugin-source
   edit, log the deferral, stop.

MODE: DRIFT-CHECK
 1. For each marketplace skill referenced by any pipeline wrapper,
    compute SHA256 of the live marketplace SKILL.md.
 2. Compare against _meta/skill-hashes.json. Create empty {} on first run.
 3. For each drift, assess the wrapper's contract: OK | Review | Block.
 4. Update _meta/skill-hashes.json AFTER assessment is logged.
 5. Write run log per references/run-log-template.md § drift-check.
 6. Append to _meta/CHANGELOG.md: "YYYY-MM-DD — drift-check — <N> drifts,
    <M> need review, <K> blocked".

MODE: LESSON-RECONCILIATION
 1. Read every wrapper's lessons.md sidecar.
 2. For each entry without a `disposition:` line, decide:
    - Promote → write to project CLAUDE.md pipeline.overrides OR
      wrapper default contract. Record destination.
    - Retire → marketplace skill now handles it. Note which change.
    - Discard → one-off noise. Explain why.
 3. Append a `disposition:` line inline under the entry. Do NOT rewrite
    the entry body.
 4. If median disposition age this run >14 days, flag in
    ## Threshold checks → triggers fix-session next.
 5. Write run log per references/run-log-template.md § lesson-reconciliation.
 6. Append to _meta/CHANGELOG.md: "YYYY-MM-DD — lesson-reconciliation —
    <N> entries, <P> promoted, <R> retired, <D> discarded".

MODE: METRIC-AGGREGATION
 1. Find the latest cohort's 05-research.md across all projects.
 2. Parse its ## Metrics summary table.
 3. Append cohort's row to _meta/metrics.md (don't overwrite history).
 4. Run threshold checks (table in SKILL.md). For any breach: log
    which metric + session type + trigger fix-session next.
 5. Write run log per references/run-log-template.md § metric-aggregation.
 6. Append to _meta/CHANGELOG.md: "YYYY-MM-DD — metric-aggregation —
    cohort <cohort_id>, breaches: <list or none>".

MODE: FIX-SESSION
 1. Confirm trigger source (earlier metric breach OR drift-check block
    OR Timm request). Cite it explicitly. No freelancing.
 2. Re-verify in-flight block check (24h). If any feature in_progress:
    defer, log, stop.
 3. Propose the change under ## Proposed change: files, diff summary,
    rationale, expected metric effect.
 4. Brief delta: if the change touches the pipeline brief's contract
    shape, edit Code/.templates/llm-native-dev-pipeline-brief.md in the
    SAME session. One edit = both files. Record under ## Brief delta.
 5. Surface to Timm ONCE for approval. Include diff summary + brief
    delta + which metric this fixes.
 6. On "approved": apply the edits to plugin source + brief, log to
    _meta/CHANGELOG.md, mark run log `status: applied`.
 7. On "changes requested": cycle within the session.
 8. On "rejected": mark `status: rejected`, capture why, do not edit.

 Write run log per references/run-log-template.md § fix-session.

CLOSE (all modes):
 1. Write Code/pipeline/_meta/runs/YYYY-MM-DDTHH-MM-<mode>.md.
 2. Run `bash scripts/check-run-log.sh <path>` — fix every RED.
 3. Append to Code/pipeline/_meta/CHANGELOG.md.
 4. drift-check only: update _meta/skill-hashes.json AFTER log is
    written.
 5. metric-aggregation only: append row to _meta/metrics.md.
 6. fix-session (approved only): apply plugin source + brief edits.

Deferred in v0.1.0:
 - Cross-cohort trending in _meta/metrics.md (flat append-only for now)
 - Auto-PR for fix-session edits (Timm commits by hand for now)
```

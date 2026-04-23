---
description: Cross-cutting — run LLM Ops (drift check, lesson reconciliation, metric aggregation, or fix session)
argument-hint: "<mode: drift-check | lesson-reconciliation | metric-aggregation | fix-session>"
---

Open an LLM Ops session.

Follow the `dev-pipeline-llm-ops` skill. NOT a per-feature session — this maintains the pipeline itself: prompts, wrappers, overrides, lessons, marketplace-skill drift, per-cohort metrics.

If `$ARGUMENTS` is set, treat it as the mode. Otherwise, ask which mode to run. Four modes:
- `drift-check` — hash each referenced marketplace `SKILL.md` and flag drift
- `lesson-reconciliation` — review accumulated lessons; promote, watch, or retire
- `metric-aggregation` — per-cohort metrics roll-up
- `fix-session` — propose + apply a pipeline change

Blocks edits if any feature manifest is `in_progress` within the last 24h. Writes to `Code/pipeline/_meta/runs/` and appends to `_meta/CHANGELOG.md`. The one role that may edit pipeline plugin source.

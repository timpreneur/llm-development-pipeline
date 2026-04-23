---
description: Session 02 — convert an approved brief into a file-level plan (Claude Code, plan mode)
argument-hint: "<FEATURE_ID>"
---

Open a Plan session (Session 02 of the dev pipeline).

Follow the `dev-pipeline-plan` skill end-to-end. Must run in Claude Code **plan mode**. Converts the approved `01-brief.md` into a file-level, task-ordered `02-plan.md` that Build can execute without re-planning.

If `$ARGUMENTS` is set, treat it as the `FEATURE_ID` (directory name under `<PROJECT>/`, format `YYYY-MM-DD-slug`). Otherwise, ask which feature to plan.

Required output: `<FEATURE_DIR>/02-plan.md` via `ExitPlanMode`, validated by `scripts/check-plan.sh` (Task list, Files touched, Reuse anchors, Risk callouts, Side-effects, Test strategy, Verification, Rollback — Verification must list every grep performed plus result, empty Verification = reject). Done when Timm explicitly approves the plan. Hand off to `dev-pipeline-build` on close.

# pipeline

The LLM-native development pipeline as Cowork skills. Implements the brief at `Code/.templates/llm-native-dev-pipeline-brief.md`.

## What ships in v0.1.0

Seven skills (six sessions + one substrate):

| Skill | Role | Surface |
|-------|------|---------|
| `dev-pipeline-substrate` | Convention + templates + `_meta/` seed | runs first, once per workspace |
| `dev-pipeline-ideate` | Session 01 — raw idea → `01-brief.md` | Cowork |
| `dev-pipeline-plan` | Session 02 — brief → `02-plan.md` | Claude Code, plan mode |
| `dev-pipeline-build` | Session 03 — plan → `03-build-notes.md` + preview | Claude Code, execution |
| `dev-pipeline-ship` | Session 04 — build → `04-ship.md` + production | Cowork + platform MCPs |
| `dev-pipeline-research` | Session 05 — cohort → `05-research.md` + `_inbox/` seeds | Cowork, per-cohort |
| `dev-pipeline-llm-ops` | Cross-cutting — drift, lessons, metrics, fixes | Cowork, continuous |

## Deferred to later passes

- `dev-pipeline-build`'s Legal and Marketing conditional wrappers — authored when the first feature flags `regulated: true` or `customer_facing_launch: true`.
- The greenfield Architect-Strategy pre-session — authored when the next greenfield project kicks off.

## Composition model

Every review mode inside `dev-pipeline-build` (and review-style steps elsewhere) composes three layers:

1. **Marketplace skill** — the engine. Referenced by name. Never forked.
2. **Pipeline wrapper** — the contract. Defines when to invoke, what inputs, where output lands, resolution policy. Lives in this plugin.
3. **Project overrides** — the lessons. Lives in each project's `CLAUDE.md` under `pipeline.overrides`.

`dev-pipeline-llm-ops` hashes each referenced marketplace `SKILL.md` and flags drift weekly. Lessons captured by any wrapper get reviewed and promoted (or retired) during reconciliation.

## Feature unit

One directory per feature: `Code/pipeline/<project>/<YYYY-MM-DD-slug>/`. Five artifacts inside, one manifest. Every session's last action before closing is a manifest update. See `dev-pipeline-substrate/references/pipeline-dir-convention.md` for the authoritative layout.

## Install

Drop the `.plugin` file into Cowork. `dev-pipeline-substrate`'s bootstrap runs once to seed `Code/pipeline/_meta/` and validate the workspace — after that, the session skills are ready to invoke per feature.

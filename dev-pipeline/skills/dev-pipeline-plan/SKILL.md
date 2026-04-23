---
name: dev-pipeline-plan
description: Session 02 of the LLM-native dev pipeline. Run this skill in Claude Code plan mode to convert an approved 01-brief.md into a file-level, task-ordered implementation plan (02-plan.md) that Build can execute without re-planning. MUST be used when Timm says "start a Plan session", "plan this feature", "run session 02", "let's plan <feature>", "open Claude Code in plan mode for <feature>", "create the plan for <FEATURE_ID>", or pastes the dev-pipeline-plan startup prompt. Owns producing `<FEATURE_DIR>/02-plan.md` via ExitPlanMode and updating the manifest. Output contract enforced by `scripts/check-plan.sh` — required sections (Task list, Files touched, Reuse anchors, Risk callouts, Side-effects, Test strategy, Verification, Rollback). Verification section must list every grep performed plus result — empty Verification = reject. Done signal is Timm's explicit approval of the plan. Hands off to dev-pipeline-build (new Claude Code session) on close. Do not use this skill for ideation, execution, ship, or research — those are dev-pipeline-ideate, dev-pipeline-build, dev-pipeline-ship, dev-pipeline-research. Greenfield Strategy pre-session is deferred in v0.1.0; brownfield default only.
---

# dev-pipeline-plan

Session 02 of the pipeline. Claude Code, plan mode. One session: read inputs → grep the repo → write `02-plan.md` via ExitPlanMode.

Touchpoint: **Timm approves the plan.** That's the done-signal — no Build session opens until he says so.

## When to invoke

This skill has two modes.

**Mode 1 — New plan** (the default). Invoke when Timm opens Claude Code in plan mode to plan an approved feature. Typical triggers:

- "Start a Plan session for `<FEATURE_ID>`."
- "Plan this feature." (after Ideate closed)
- "Run session 02."
- "Open Claude Code in plan mode for `<FEATURE_ID>`."
- The startup prompt in `startup-prompt.md` is pasted in.

**Mode 2 — Diagnose a Plan Issue.** Invoke when `<FEATURE_DIR>/02-plan-issue.md` exists with `status: open` and Timm hands it to you. Typical triggers:

- "Diagnose the plan issue for `<FEATURE_ID>`."
- "Build hit a blocker, triage it."
- "Run plan-issue diagnosis."
- Timm pastes the contents of `02-plan-issue.md` or references the filename.

In Mode 2, skip Phase 2 (grep verification) except targeted re-greps tied to the issue. The full flow is in `references/plan-issue-diagnosis.md`.

Don't invoke for: ideation (`dev-pipeline-ideate`), execution (`dev-pipeline-build`), ship, or research. Plan mode means **no writes** until ExitPlanMode — if Timm wants execution, this is the wrong skill.

**Greenfield projects:** the brief allows a Cowork "Architect-Strategy" pre-session that seeds `02-plan.md` with a Strategy section. **That pre-session is deferred in pipeline v0.1.0.** Brownfield default only — if the project is greenfield and needs strategy work, do it in conversation outside this skill, then enter Plan mode.

## Inputs required

The skill will refuse to start if any are missing:

1. **`<PROJECT>`** — project name.
2. **`<FEATURE_ID>`** — slug (matches `<FEATURE_DIR>` basename).
3. **`<FEATURE_DIR>`** — full path to the feature dir under `Code/pipeline/<PROJECT>/`.
4. An existing **`<FEATURE_DIR>/01-brief.md`** with `status: done` and Timm's prior approval.

If `01-brief.md` is missing or has `status: pending|in_progress|blocked`, surface to Timm: "No approved brief at `<FEATURE_DIR>/01-brief.md`. Run dev-pipeline-ideate first."

## Before you start

Read in this order:

1. `<FEATURE_DIR>/00-manifest.md` — confirm Plan row is `pending` (or `in_progress` if Timm is restarting).
2. `<FEATURE_DIR>/01-brief.md` in full — every section, especially `### Decisions needed` and `## Flags`.
3. `<PROJECT>/CLAUDE.md` — including `pipeline.overrides` (Plan must respect overrides like `forbidden_patterns`, `required_reuse`).
4. Reference docs named in the brief's `## Context` section.
5. `references/plan-template.md` — the `02-plan.md` structure.
6. `references/verification-grep-guide.md` — what to grep for and how to log it.
7. `references/close-checklist.md` — what must be true before ExitPlanMode.

## Flow

### Mode 2 — Diagnose a Plan Issue

If `<FEATURE_DIR>/02-plan-issue.md` exists with `status: open`, run the diagnosis flow in `references/plan-issue-diagnosis.md` instead of Mode 1. Summary:

1. Read `02-plan-issue.md`, `02-plan.md`, `01-brief.md`, `03-build-notes.md` (if present).
2. Classify the root cause (A/B/C/D/E). Apply the Clarity Test before finalizing D.
3. Write a three-part diagnosis (classification, proposed revision, impact assessment). **Do not write to `02-plan.md` yet.** Show Timm the proposal first.
4. On approval, update `02-plan.md`, append to `## Plan Revisions`, bump frontmatter `revision` + `updated`, delete `02-plan-issue.md`.
5. Category C bounces to `01-brief-issue.md` (do not revise `02-plan.md`). Category D clears the issue without plan change.

The diagnosis reference has the full protocol, the Clarity Test rules, and the templates for both `## Plan Revisions` entries and `01-brief-issue.md`.

### Mode 1 — New plan

#### Phase 1 — Read inputs in full

No skimming. Decisions-needed entries from the brief are inputs to the plan, not afterthoughts. Each `[Plan]`-tagged decision must be resolved (or explicitly deferred to Open Questions) in this session.

#### Phase 2 — Grep verification

For every pattern, primitive, file, component, table, route, or library the brief references or implies — **grep the repo and confirm it exists as expected.**

This is the heart of plan-mode work. The `## Verification` section in `02-plan.md` lists every grep performed, the command (or natural-language pattern), and the result. Empty Verification = the plan is unverified guesses → `check-plan.sh` rejects.

If a referenced thing doesn't exist or doesn't match the brief's assumption, **flag as brief-drift** in `## Open questions`. Don't silently work around it. Plan with the truth as it is.

See `references/verification-grep-guide.md` for the grep checklist (what to look for) and the log format.

#### Phase 3 — Produce the plan

Per `references/plan-template.md`. Required sections:

- `## Task list` — execution order, one numbered task per line.
- `## Files touched` — per task, which files create/modify/delete.
- `## Reuse anchors` — existing components, utilities, marketplace skills the build should use instead of re-inventing.
- `## Risk callouts` — migrations, cross-package types, tier-visibility cascades, inlined-utility sync, rate limits, env vars, secrets, anything that could regress production.
- `## Side-effects` — nav entries, type updates, changelog lines, doc updates, generated files. Anything Build would otherwise miss.
- `## Test strategy` — what tests exist, what new tests Build adds, how AC are verified.
- `## Verification` — every grep + result from Phase 2. **Required.**
- `## Rollback` — how to undo if Ship reveals a defect. Required for production-affecting changes; "N/A — no production surface touched" is acceptable for internal-only changes if explicitly stated.
- `## Open questions` — anything Plan couldn't resolve. Tag entries `[Timm]` (decision needed) or `[Build-discover]` (something Build needs to grep further).

#### Phase 4 — Show Timm, iterate

Present the draft plan in Plan mode (no writes yet). Timm approves or asks for revisions. Loop until approved.

#### Phase 5 — ExitPlanMode → close

On approval:

1. ExitPlanMode writes `02-plan.md` to `<FEATURE_DIR>` with frontmatter (`session: 02-plan`, `status: done`, `inputs: [00-manifest.md, 01-brief.md, <PROJECT>/CLAUDE.md]`, etc.).
2. Update `<FEATURE_DIR>/00-manifest.md`: Plan row → `done`, `updated: <today>`. Aggregate stays `in_progress`.
3. Run `scripts/check-plan.sh <FEATURE_DIR>/02-plan.md`. If non-zero, this is a contract violation — re-enter plan mode, fix, re-ExitPlanMode.
4. Confirm next step to Timm: "Open a NEW Claude Code session on `<PROJECT>` (NOT plan mode — execution mode). Paste `dev-pipeline-build/startup-prompt.md` with `<FEATURE_ID>` = `<actual>` and `<FEATURE_DIR>` = `<actual>`. Build is a new session — context does not carry over."

## Tone

Direct, technical. Timm knows the codebase; the plan should read like an engineer's working notes, not a tutorial. No filler.

## Guardrails (enforced)

| Failure mode | Guardrail |
|--------------|-----------|
| Plan assumes patterns without verifying | `check-plan.sh` requires a non-empty `## Verification` section. Empty = reject. |
| Plan leaks into execution | Plan mode enforces no-writes at tool level. Wrapper rejects if any write tool fires before ExitPlanMode (this is enforced by Claude Code itself; this skill just notes it). |
| Plan omits side-effects | `check-plan.sh` requires a `## Side-effects` section. Absent = reject. |
| Decisions-needed entries from brief are dropped | Each `[Plan]`-tagged entry in brief must appear in `02-plan.md` either resolved (in body) or escalated to `## Open questions`. Validator does a presence check. |
| Plan touches production paths without rollback | `check-plan.sh` requires a `## Rollback` section. Body may say "N/A — internal only" if true. |

## Lessons capture

If a pattern surfaces during planning (e.g., the same kind of grep keeps returning surprises in this project; a particular `pipeline.overrides` is repeatedly violated; the brief keeps under-specifying the same thing), append a dated entry to `lessons.md`. Don't auto-promote.

## What this skill does not do

- Execute any code or modify any file outside ExitPlanMode's `02-plan.md` write and the manifest update.
- Make solutioning decisions Timm hasn't seen — those go to Open questions.
- Open the Build session itself — Timm opens a new Claude Code session.
- Greenfield Architect-Strategy pre-session (deferred in v0.1.0).

## References (progressive disclosure)

- `references/plan-template.md` — canonical `02-plan.md` shape with frontmatter and inline guidance per section.
- `references/verification-grep-guide.md` — the grep checklist and log format.
- `references/close-checklist.md` — step-by-step close procedure plus the full guardrail list.
- `references/plan-issue-diagnosis.md` — Mode 2 diagnosis protocol: A/B/C/D/E categories, Clarity Test, Plan Revisions log format, `01-brief-issue.md` template for Category C escalation.
- `../../ENGINEERING_STANDARDS.md` — shared coding floors. Planners respect these when specifying interfaces and constraints; Build enforces them at code time.

## Scripts

- `scripts/check-plan.sh <path-to-02-plan.md>` — validator. Exit 0 = compliant (yellow ok), exit 1 = red failures.
- `scripts/smoke.sh` — runs validator against good fixture (expect 0) and bad fixtures (expect 1).

## Smoke test

```bash
bash skills/dev-pipeline-plan/scripts/smoke.sh
```

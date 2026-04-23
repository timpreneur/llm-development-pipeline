---
name: pipeline-build
description: Session 03 of the LLM-native dev pipeline. Run this skill in a NEW Claude Code session (execution mode, not plan mode) to execute an approved 02-plan.md for a feature, running internal review modes (code-optimizer, security, accessibility, UX polish, QA) at checkpoints and writing all findings to a single 03-build-notes.md. MUST be used when Timm says "start a Build session", "build this feature", "run session 03", "execute the plan for <FEATURE_ID>", "open Claude Code to build <feature>", or pastes the pipeline-build startup prompt. Build is deliberately silent — Timm touches it only at the preview URL (touchpoint #3). Owns writing `<FEATURE_DIR>/03-build-notes.md` with every mode output as a named section, plus the preview deploy URL. Output contract enforced by `scripts/check-build-notes.sh` — required sections (Commit range, AC status, Code-opt, Security, Accessibility, UX, QA, Legal, Marketing, Lessons, Preview URL). Legal and Marketing conditional wrappers are DEFERRED in v0.1.0 — those sections accept "N/A — wrapper deferred". Done signal is all AC pass + build green + tests pass + preview URL live + `check-build-notes.sh` green. Hands off to pipeline-ship on close. Do not use this skill for ideation, planning, ship, or research — those are pipeline-ideate, pipeline-plan, pipeline-ship, pipeline-research.
---

# pipeline-build

Session 03 of the pipeline. Claude Code, **execution mode** — not plan mode. A new session, not a continuation of Plan.

This is the most substantive session. Most of Timm's leverage lives here. He does not watch — he reviews the preview when it lands.

Touchpoint: **Timm reviews the preview URL.** Nothing surfaces to him before that unless it's critical (see Escalation rules).

## When to invoke

Invoke when Timm opens a new Claude Code session on a project in execution mode to build an approved-and-planned feature. Typical triggers:

- "Start a Build session for `<FEATURE_ID>`."
- "Build this feature."
- "Run session 03."
- "Execute the plan for `<FEATURE_ID>`."
- The startup prompt in `startup-prompt.md` is pasted in.

Don't invoke for: ideation, planning (Plan mode is a different tool surface), ship, or research.

## Inputs required

The skill will refuse to start if any are missing:

1. **`<PROJECT>`** — project name.
2. **`<FEATURE_ID>`** — matches `<FEATURE_DIR>` basename.
3. **`<FEATURE_DIR>`** — full path.
4. **`<FEATURE_DIR>/00-manifest.md`** exists.
5. **`<FEATURE_DIR>/01-brief.md`** with `status: done`.
6. **`<FEATURE_DIR>/02-plan.md`** with `status: done` and Timm's prior approval.
7. **`<PROJECT>/CLAUDE.md`** (may be empty, but the file should exist — this skill respects `pipeline.overrides`).

If any are missing, surface: "Prerequisite missing: `<file>`. Run pipeline-<ideate|plan> first."

## Before you start — safety check

Read in this order, in full:

1. `<FEATURE_DIR>/00-manifest.md` — confirm Plan row is `done` and Build row is `pending`.
2. `<FEATURE_DIR>/01-brief.md` — every `Decisions-needed` entry, both flags.
3. `<FEATURE_DIR>/02-plan.md` — every task, every verification row, every open question.
4. `<PROJECT>/CLAUDE.md` — `pipeline.overrides` (`forbidden_patterns`, `required_reuse`, `ux_polish`, `repo_brief_dir`, `changelog_path`).
5. For every file the plan's `## Files touched` references, **read it before editing**. Drift check: has the file changed materially since the plan's `updated:` date? If yes and the change affects a planned task, **pause and flag** to Timm.

If drift is detected that blocks execution, surface: "Codebase drifted since plan date — <one-line summary>. Need re-plan or Timm decision." Do not proceed.

## Flow

Single session, internal checkpoints scheduled by this skill. See `references/mode-checkpoints.md` for the full flow diagram and invocation order.

### Phase 1 — Execute tasks

Proceed task by task from `02-plan.md § Task list`. For each task:

1. Read the files it touches (if not already in context).
2. Make the change as planned.
3. Run relevant tests.
4. Move to next task.

**Do not re-plan mid-execution.** If a task can't be executed as planned, either:
- The deviation is small (an obvious micro-refactor, an extra import, a tighter type) → note it inline in the task's notes and continue.
- The deviation is material (a planned reuse anchor doesn't work, the file layout differs from plan's `## Files touched`, an AC becomes unmeetable) → **file a Plan Issue and stop.** See `references/plan-issue-template.md` for when-to-file rules and the five-field structure. Do not attempt a workaround. Do not partially implement.

### Phase 2 — Internal checkpoints

Self-invoke review modes at these triggers (see `references/mode-checkpoints.md` for invocation detail):

| Trigger | Mode | Marketplace skill |
|---------|------|-------------------|
| After first major component is implemented | Code-optimizer | `review` (built-in) |
| After test suite passes on full diff | Security | `security-review` (built-in) |
| After tests pass, UI was touched | Accessibility | `design:accessibility-review` |
| After tests pass, UI was touched | UX polish | `design:design-critique`, `design:ux-writing` |
| Before preview deploy | QA | `data:data-validation`, `customer-support:ticket-triage` |
| Conditional: `regulated: true` OR security mode escalates | Legal | **DEFERRED in v0.1.0** — write `N/A — wrapper deferred (regulated=<flag>)` |
| Conditional: `customer_facing_launch: true` | Marketing | **DEFERRED in v0.1.0** — write `N/A — wrapper deferred (cfl=<flag>)` |

Each mode writes its output to a **named section** of `03-build-notes.md` (not a separate file). See `references/build-notes-template.md` for the section names and shapes.

If Legal and Marketing wrappers ship in a later version, they'll live as separate skills (`pipeline-build:legal-mode`, `pipeline-build:marketing-mode`). This skill documents the hook points but does not invoke them in v0.1.0.

### Phase 3 — Preview deploy

After all non-blocking checks are clean:

1. Preview deploy via Vercel MCP (or project-specific deploy hook declared in `<PROJECT>/CLAUDE.md`).
2. Verify deployment state (e.g., `vercel get_deployment` returns `state: READY`).
3. Capture preview URL into `03-build-notes.md § Preview URL`.

If the project has no deploy integration declared, write `Preview URL: N/A — no deploy integration` and surface the URL capture to Timm manually.

### Phase 4 — Close

1. Write `03-build-notes.md` frontmatter with `status: done`, `inputs: [00-manifest.md, 01-brief.md, 02-plan.md]`.
2. Update manifest: Build row → `done`, `updated: <today>`. Aggregate stays `in_progress`.
3. Run `scripts/check-build-notes.sh <FEATURE_DIR>/03-build-notes.md`. Fix any RED before surfacing.
4. Surface to Timm: "Preview live at `<URL>`. `03-build-notes.md` written. Next: open a new Cowork session and paste `pipeline-ship/startup-prompt.md` with `<FEATURE_ID>` = `<actual>` and `<FEATURE_DIR>` = `<actual>`."

## Escalation rules (surface to Timm immediately)

Surface **only** if:

1. A **critical security or legal finding blocks progress** (cannot deploy preview without Timm's call).
2. An **acceptance criterion cannot be met as written** — file `02-plan-issue.md` with category guess C (if brief is ambiguous) or B (if plan is silent). See below.
3. The **plan is drifting materially** from what the codebase now supports — file `02-plan-issue.md` with category guess A (plan error) or E (external change).

For cases 2 and 3, the escalation channel is `02-plan-issue.md`, not a direct message. The structured file captures the context Plan needs to diagnose without Build re-explaining; Timm reads it and routes to pipeline-plan. See `references/plan-issue-template.md`.

Everything else — code-opt findings, non-critical security, accessibility, UX polish, QA regressions you can fix — stays internal. Fix it, note it, continue.

## When the plan has a problem — file a Plan Issue

If during execution you find the plan is wrong, silent on something you need, or inconsistent with reality, **stop and file `02-plan-issue.md`.** Do not work around it. Do not make a judgment call.

Filing protocol:

1. Write `02-plan-issue.md` to `<FEATURE_DIR>` per `references/plan-issue-template.md`. Include your best category guess (A/B/C/D/E or "uncertain").
2. Update `<FEATURE_DIR>/00-manifest.md`: Build row status → `blocked`, `blocked_on: 02-plan-issue.md`.
3. Surface to Timm: "Blocked on `<FEATURE_DIR>/02-plan-issue.md`. Not proceeding until resolved."
4. Stop. Wait for Timm to either hand you a revised `02-plan.md` (via a pipeline-plan diagnosis session) or a direct instruction.

On resume, log the resolution in your next `03-build-notes.md § Commit range` entry and delete `02-plan-issue.md`. See the template for the resume protocol.

**Why the hard-stop.** Silent workarounds surface at Ship time as preview-URL regressions that are expensive to unwind. A false-positive Plan Issue is cheap: Timm reads it, tells you to proceed. File when in doubt.

## Commit policy

Per `<PROJECT>/CLAUDE.md`. If CLAUDE.md says don't commit without asking, **do not commit without asking**. If CLAUDE.md is silent, ask once at session start: "Commit policy for this feature — auto-commit per task, one commit at end, or wait for Timm?"

## Lessons capture

If a finding reveals a repeatable pattern — not a one-off — append a dated entry to `lessons.md` in this skill dir, tagged by mode:

```
## 2026-04-19 — <project> — UX polish
Pattern: <what repeats>
Evidence: <which features>
Promotion candidate: yes | no | watch
```

One `lessons.md` for the whole skill. Entries tagged by mode in the heading. Do **not** auto-promote to project CLAUDE.md — that's LLM Ops.

## What this skill does not do

- Plan. If execution reveals the plan is wrong in a material way, surface and stop — don't silently re-plan.
- Invoke Legal or Marketing wrappers (deferred in v0.1.0 — sections get `N/A — wrapper deferred`).
- Ship. Preview deploy ≠ production deploy. Ship session handles rollout.
- Promote lessons. LLM Ops only.

## Regulated / customer-facing handling in v0.1.0

- `regulated: true` — Build writes `Legal findings: N/A — wrapper deferred (regulated=true). **Escalation flag: review needed before Ship.**` to build-notes. Ship session is responsible for flagging that Legal review is outstanding before production. Wrapper will land in a later plugin version.
- `customer_facing_launch: true` — Build writes `Marketing draft: N/A — wrapper deferred (customer_facing_launch=true).` Timm authors customer-facing copy in Ship until the Marketing wrapper ships.

Both cases: the validator accepts the `N/A — wrapper deferred` pattern so the smoke test is green, but the escalation text for `regulated=true` is preserved so Ship sees it.

## References (progressive disclosure)

- `references/build-notes-template.md` — canonical `03-build-notes.md` shape with every required section.
- `references/mode-checkpoints.md` — the internal flow diagram, invocation order, and per-mode scope.
- `references/close-checklist.md` — step-by-step close procedure plus the full guardrail list.
- `references/plan-issue-template.md` — when to file `02-plan-issue.md`, the five-field structure, and resume protocol.
- `../../ENGINEERING_STANDARDS.md` — shared coding floors and optimization targets. Read once at session start.

## Scripts

- `scripts/check-build-notes.sh <path-to-03-build-notes.md>` — validator. Exit 0 = compliant, exit 1 = red failures.
- `scripts/smoke.sh` — runs validator against good fixture (expect 0) and bad fixtures (expect 1).

## Smoke test

```bash
bash skills/pipeline-build/scripts/smoke.sh
```

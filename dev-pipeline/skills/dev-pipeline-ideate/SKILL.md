---
name: dev-pipeline-ideate
description: Session 01 of the LLM-native dev pipeline. Run this skill to convert a raw idea into an approved brief an LLM coding agent can plan against — one Cowork session that combines interview, pressure-test, and brief-drafting. MUST be used when Timm says "start an Ideate session", "I have a new idea for <project>", "kick off ideate for <feature>", "let's brief a new feature", "write a brief for this", "start a new feature on the pipeline", "run session 01", or any variation of opening session 01 for a pipeline project. Owns writing `<FEATURE_DIR>/01-brief.md` and creating `<FEATURE_DIR>/00-manifest.md`. Output contract is enforced by `scripts/check-brief.sh` — ≥2 pressure-test alternatives, no solutioning in the body, both flags set. Done signal is Timm's explicit in-session approval. Hands off to dev-pipeline-plan (Claude Code, plan mode) on close. Do not use this skill for planning, execution, ship, or research sessions — those are dev-pipeline-plan, dev-pipeline-build, dev-pipeline-ship, dev-pipeline-research.
---

# dev-pipeline-ideate

Session 01 of the pipeline. Cowork, conversational. One session: interview → pressure-test → brief.

Touchpoint: **Timm approves the brief.** That's the done-signal — nothing closes until he says so.

## When to invoke

Invoke when Timm opens a Cowork session to work on a new idea for a pipeline project. Typical triggers:

- "Start an Ideate session for <project>."
- "I have a new idea — let's run session 01."
- "Kick off Ideate for <feature>."
- "Write a brief for <thing>."
- The startup prompt in `startup-prompt.md` is pasted in.

Don't invoke for: planning (that's `dev-pipeline-plan`, Claude Code plan mode), execution (`dev-pipeline-build`), ship, or research. If Timm says "ship" or "plan" or "build", those are different skills.

## Inputs required

The skill will ask if any are missing:

1. **`<PROJECT>`** — the project name (directory under `Code/pipeline/`).
2. **`<FEATURE_ID>`** — slug for the feature (will be prefixed with today's date to form `<YYYY-MM-DD-slug>`).
3. **A raw idea dump** from Timm.

Derived:
- `<FEATURE_DIR>` = `Code/pipeline/<PROJECT>/<YYYY-MM-DD-<slug>>/`

## Before you start

Read in this order (substrate contract):

1. `Code/MEMORY.md` — project-scoped entries under `## <PROJECT>`.
2. `<PROJECT>/CLAUDE.md` if it exists — including `pipeline.overrides`.
3. Last 3 items in `<PROJECT>/docs/briefs/archive/` if that path is declared in `pipeline.repo_brief_dir` — just for orientation, not to copy.
4. Latest `05-research.md` under any cohort dir for this project — it may contain inbox candidates that seeded this idea.
5. `references/brief-template.md` — the `01-brief.md` structure.
6. `references/pressure-test-guide.md` — how the pressure-test runs.
7. `references/close-checklist.md` — what must be true before close.

## Flow

The session runs four phases. Stay conversational — don't perform the phase boundaries at Timm.

### Phase 1 — Interview

Timm dumps the idea. Run **one batch** of scoping questions, short. Name users by role or persona (not "customers"). Push back on vague problem statements. If the idea names a solution before a problem, surface the gap.

### Phase 2 — Pressure-test

Find **≥2 existing alternatives** (internal tools, external products, or a "do nothing" path). For each, ask Timm what's wrong with it. Use `design:user-research` if the question is behavioral, and `research-analyzer` if it's about market/prior art.

If Timm can't name what's wrong with the alternatives, **the problem isn't real yet**. Flag this in the brief's Pressure-test section (include the note `⚠ weak problem signal — Timm couldn't differentiate from <alternative>`), but **continue** — don't stall the session.

### Phase 3 — Draft brief

Produce the draft in-session. Show Timm. He approves or revises. Loop on revisions until he approves.

**Critical guardrail — no solutioning.** The brief describes *what, who, why, observable behaviors.* It does not describe *file paths, column names, endpoint signatures, component names, or which library to use.* Those are Plan's job. If you catch yourself writing `apps/web/src/...` or `POST /api/v1/foo` or "use React Query" — cut it.

Use `brand-voice:brand-voice-enforcement` only if `customer_facing_launch` is going to be true — it enforces voice on the customer-facing framing (e.g., the "who benefits" paragraph).

### Phase 4 — Close

Only on explicit approval. Then:

1. Create `<FEATURE_DIR>` (make parent project dir if needed; ask before creating a new project dir).
2. Write `<FEATURE_DIR>/00-manifest.md` using the template in `dev-pipeline-substrate/references/manifest-template.md`. Status row for `01-ideate` = `done`, rest `pending`, aggregate = `in_progress`.
3. Write `<FEATURE_DIR>/01-brief.md` with frontmatter per `references/brief-template.md`.
4. Set both flags in frontmatter explicitly:
   - `regulated: true|false` — touches user data, billing, PII, regulated industry surfaces, or legal review territory?
   - `customer_facing_launch: true|false` — external users see the result?
5. Run `scripts/check-brief.sh <FEATURE_DIR>/01-brief.md`. If it returns non-zero, show Timm the failures, fix in-session, re-run. Don't close with a failing brief.
6. Confirm next step to Timm: "Open Claude Code on `<PROJECT>` in plan mode. Paste `dev-pipeline-plan/startup-prompt.md` with `<FEATURE_ID>`=`<actual>` and `<FEATURE_DIR>`=`<actual>`."

## Tone

Sharp. Direct. Push back on handwaving. No emojis. Match Timm's register from `Code/MEMORY.md` and his personal-preferences block.

## Guardrails (enforced)

| Failure mode | Guardrail |
|--------------|-----------|
| Brief dictates implementation | `check-brief.sh` flags file extensions, path-looking strings, column-style names, endpoint signatures. Rewrite before close. |
| Pressure-test skipped | `check-brief.sh` requires the `## Pressure-test` section to have ≥2 alternatives. Empty = reject. |
| Scope is a theme, not a feature | Before closing, ask: "Is this one feature or a theme?" If theme, offer to split into child feature dirs. Don't force — Timm calls it. |
| Flags missing | `check-brief.sh` requires both `regulated` and `customer_facing_launch` in frontmatter. Absent = reject. |

## Lessons capture

If a pattern surfaces during the session (e.g., Timm keeps inventing users who don't exist; every idea for this project collapses into the same theme; pressure-test keeps coming up weak in the same way), append a dated entry to `lessons.md` in this skill dir. **Don't** auto-promote to project CLAUDE.md — that's an LLM Ops decision.

Entry format: `## YYYY-MM-DD — <project>` then a short note, then "Promotion candidate: yes / no / watch." See `lessons.md` header for the full schema.

## What this skill does not do

- Plan implementation (that's `dev-pipeline-plan`).
- Write or modify any file outside the feature dir or this skill's own `lessons.md`.
- Ship or deploy anything.
- Promote lessons to project CLAUDE.md (LLM Ops only).
- Split themes unilaterally — Timm decides.

## References (progressive disclosure)

- `references/brief-template.md` — the canonical `01-brief.md` shape with frontmatter, sections, and inline guidance for each.
- `references/pressure-test-guide.md` — how to run the pressure-test, what counts as an "alternative," what to do when Timm can't differentiate.
- `references/close-checklist.md` — step-by-step close procedure plus the full guardrail enforcement list.

## Scripts

- `scripts/check-brief.sh <path-to-01-brief.md>` — validator. Exit 0 = brief is contract-compliant, exit 1 = failures listed on stderr.
- `scripts/smoke.sh` — runs the validator against a good fixture (expect 0) and a bad fixture (expect 1). Run after changing this skill.

## Smoke test

```bash
bash skills/dev-pipeline-ideate/scripts/smoke.sh
```

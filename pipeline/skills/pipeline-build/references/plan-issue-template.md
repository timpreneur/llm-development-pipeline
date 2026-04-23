# 02-plan-issue.md template

Filed by `pipeline-build` when execution hits a problem that cannot be resolved without either a plan revision, a scope clarification, or a direct Timm decision. One file at a time. Deleted by `pipeline-plan` once resolved.

## When to file (vs. continue)

File `02-plan-issue.md` when **any** of these is true:

- A planned reuse anchor does not work as specified and a workaround would silently change behavior.
- A planned interface signature cannot be implemented given the library's actual API.
- An acceptance criterion conflicts with another requirement and both cannot be satisfied.
- An external service referenced by the plan has changed (deprecation, breaking change, sunset).
- The plan is silent on something you need to decide and the decision has non-trivial blast radius.

Do **not** file for:

- Cosmetic deviations you can note inline in `03-build-notes.md` (extra import, tighter type, obvious micro-refactor).
- Gaps within a single task that you can resolve by reading adjacent code and confirming your read.
- Things you could fix by re-reading the plan more carefully. Re-read first.

When in doubt, file. The cost of a false-positive issue is low (Timm glances at it, tells you to proceed). The cost of a silent workaround surfaces at Ship time and is expensive to unwind.

## Structure

```markdown
---
session: 02-plan-issue
status: open
filed_by: pipeline-build
filed_at: <YYYY-MM-DDTHH-MM>
feature_id: <FEATURE_ID>
plan_ref: <02-plan.md section or task number>
category_guess: A | B | C | D | E | uncertain
---

## Plan reference

Which `02-plan.md` section or task. Quote the exact requirement you were executing.

## Likely category

A | B | C | D | E | uncertain. One sentence of rationale. The Planner will confirm or correct. Do not skip this field. Even a guess surfaces useful information.

Categories (defined fully in `pipeline-plan/references/plan-issue-diagnosis.md`):

- **A**: plan error (plan specified something internally inconsistent or technically impossible)
- **B**: plan gap (plan is silent on something within scope that Build needs to proceed)
- **C**: scope ambiguity (problem traces back to `01-brief.md`, not the plan)
- **D**: Coder misinterpretation (plan is correct and complete, I read it wrong)
- **E**: external change (API/library/service changed since the plan was written)

## What I was trying to do

The step you were on. One paragraph.

## Problem encountered

Specific technical or specification issue, with evidence:
- Error messages (full text, not summarized).
- Library docs (link or quote).
- Conflicting requirements (quote both).

## Why the current plan does not work

Direct explanation of the gap between the plan and reality.

## Options I can see

2 or 3 possible resolutions, with trade-offs for each. **Do not recommend one.** Surface the options, let Plan/Timm decide.

## What I need to proceed

One of: a plan revision, a scope clarification, or a user decision between options.
```

## After filing

1. Write `02-plan-issue.md` to `<FEATURE_DIR>`.
2. Update `<FEATURE_DIR>/00-manifest.md`: Build row status → `blocked`, with `blocked_on: 02-plan-issue.md`.
3. Surface to Timm: "Blocked on `<FEATURE_DIR>/02-plan-issue.md`. Need Plan diagnosis or direct decision. Not proceeding until resolved."
4. Stop. Do not attempt a workaround. Do not partially implement.

## When work resumes

Timm will either hand you an updated `02-plan.md` (via a pipeline-plan diagnosis session) or a direct instruction that supersedes the plan for this specific issue.

On resume:
- Log what changed in the next `03-build-notes.md § Commit range` entry.
- Reference the resolved issue: "Resumed after `02-plan-issue.md` resolution (category `<X>`, plan revision `<N>` or direct instruction)."
- Delete `02-plan-issue.md` once you have confirmed the resolution matches what you understand.

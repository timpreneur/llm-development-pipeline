# Plan Issue diagnosis

Reference for `pipeline-plan` Mode 2: diagnosing a `02-plan-issue.md` filed by `pipeline-build`.

## When this mode runs

Timm hands you `02-plan-issue.md`. Your job is to diagnose root cause, propose a revision, and assess impact. **Do not unilaterally revise the plan.** Show Timm the proposed change; wait for approval before writing.

## Input requirements

- `<FEATURE_DIR>/02-plan-issue.md` exists with `status: open`.
- `<FEATURE_DIR>/02-plan.md` exists with `status: done` (the original plan).
- `<FEATURE_DIR>/01-brief.md` exists.
- `<FEATURE_DIR>/03-build-notes.md` may or may not exist (depends on how far Build got).

If `02-plan-issue.md` is missing or has `status: resolved`, surface: "No open plan issue at `<FEATURE_DIR>/02-plan-issue.md`." and stop.

## Diagnosis flow

### Step 1 — Read everything

1. `02-plan-issue.md` in full. Every field.
2. `02-plan.md` — focus on the section the issue references, but read the whole document to catch cross-section interactions.
3. `01-brief.md` — specifically for Category C assessment.
4. `03-build-notes.md` if present — to see what was already built.

### Step 2 — Classify

Every issue falls into one of five categories. Identify which. The category determines who fixes the problem.

**Category A: Plan error.**
The plan specified something internally inconsistent, technically impossible, or based on incorrect assumptions about a library, API, or system.
- *Example*: plan specifies a function signature that cannot be implemented given the library's actual behavior.
- *Resolution path*: Plan revises `02-plan.md`. Timm approves.

**Category B: Plan gap.**
The plan is not wrong, but it is silent on something Build needs to proceed. The gap is within the project's defined scope.
- *Example*: plan specifies "handle errors gracefully" without specifying retry behavior for a critical external call.
- *Resolution path*: Plan fills the gap in `02-plan.md`. Timm approves.

**Category C: Scope ambiguity.**
The plan's gap or problem traces back to `01-brief.md` itself. The brief did not specify something it needed to.
- *Example*: brief says "sync with GoHighLevel" but never specified which direction is source of truth on conflicts.
- *Resolution path*: **do not revise `02-plan.md`.** File `01-brief-issue.md` instead and stop. Bounce back to `pipeline-ideate` for brief revision. Once brief is updated, re-run this diagnosis with the new brief context.

**Category D: Coder misinterpretation.**
The plan is correct and complete, but Build read it wrong.
- *Example*: Build built against an outdated interface spec because they missed a later section of the plan.
- *Resolution path*: no plan change. Clarify interpretation in the diagnosis response and direct Build to re-read the relevant section.

**Category E: External change.**
The world changed since the plan was written. API deprecated, library breaking change, service behavior changed.
- *Example*: the plan specified a third-party endpoint that has since been sunset.
- *Resolution path*: Plan revises `02-plan.md` to adapt. Timm approves. If the change is large enough it invalidates the brief's scope (e.g., the whole integration target is gone), escalate to Category C.

### Step 3 — The Clarity Test (before finalizing D)

Before finalizing a diagnosis of Category D, apply this test: **would a different competent Build session reading the same plan section likely have made the same misinterpretation?**

- If yes: the plan is unclear even if technically correct. **Reclassify as Category B** and improve the plan's phrasing, structure, or examples in the affected section.
- If no: it is true Category D. Proceed with clarification-only response.

True Category D is rare. It looks like Build ignoring explicit instructions, skipping a clearly-marked section, or building against a superseded version of the plan when a later revision was clearly in effect.

Most "misinterpretations" are Category B in disguise: the plan was technically correct but phrased in a way that admitted more than one reading. When you correctly identify these, fix the plan. A plan that is correct-but-confusing will keep producing `02-plan-issue.md` filings from every Build instance that touches it.

When you reclassify D to B, note it explicitly in the Plan Revisions log entry. If you find yourself reclassifying D to B across more than one feature in a month, that is a drift signal: flag it for `pipeline-llm-ops` to consume (the plan-writing protocol itself needs tightening).

### Step 4 — Write the diagnosis response

Show Timm a response with three parts. **Do not write the revision to `02-plan.md` yet.**

#### Part 1: Root cause classification

State the category and one-paragraph rationale. If you reclassified D to B via the Clarity Test, say so and explain which phrasing was ambiguous.

#### Part 2: Proposed plan revision

Show the specific changes to `02-plan.md` as a diff or clearly marked before/after sections. Scope the diff tightly: only the sections that actually need to change. Do not rewrite unaffected sections.

For Category C, skip this part. Instead, show the proposed `01-brief-issue.md` content.

For Category D, skip this part. Instead, quote the plan section Build misread and explain the correct reading.

#### Part 3: Impact assessment

- What else in the plan changes as a result of the revision (if any).
- What already-completed work (per `03-build-notes.md` if present) is affected. Does any existing code need rework?
- Does the revision push any risk/side-effect that was not previously flagged?

### Step 5 — Wait for Timm's call

Timm responds with approve / revise / reject. Do not write until approved.

## Writing the revision (on approval)

For Categories A, B, E (or B-from-reclassified-D):

1. Update `02-plan.md` with the approved changes.
2. Append an entry to `02-plan.md`'s `## Plan Revisions` section (create the section if absent, at the bottom of the document before the closing frontmatter marker if any):

```markdown
## Plan Revisions

### Revision <N>: <YYYY-MM-DD>
**Triggered by:** <02-plan-issue.md summary, one line>
**Root cause:** <category and diagnosis, one paragraph>
**Changes:** <what sections were modified, bullet list>
**Impact on completed work:** <what needs rework, if anything. "None" is valid.>
```

3. Bump `02-plan.md` frontmatter: `revision: <N>`, `updated: <today>`.
4. Update `<FEATURE_DIR>/00-manifest.md`: Plan row `updated: <today>`. Build row stays `blocked` until Build confirms it can resume.
5. Delete `02-plan-issue.md` (or move to `<FEATURE_DIR>/_archive/02-plan-issue-<revision-N>.md` if Timm wants an archive — default is delete).
6. Surface to Timm: "`02-plan.md` revised (revision `<N>`, category `<X>`). `02-plan-issue.md` cleared. Build can resume."

For Category C (escalation to brief revision):

1. **Do not touch `02-plan.md`.** A plan revision before the brief is updated would build on ambiguous foundations.
2. Write `01-brief-issue.md` to `<FEATURE_DIR>` with the structure below.
3. Update `00-manifest.md`: Plan row → `blocked`, `blocked_on: 01-brief-issue.md`. Build row stays `blocked`.
4. Surface: "Issue traces back to `01-brief.md` scope ambiguity. Filed `01-brief-issue.md`. Need brief revision via `pipeline-ideate` before plan can be revised."

For Category D (misinterpretation confirmed after Clarity Test):

1. Do not revise `02-plan.md`.
2. Write a short clarification response directly to Timm. No artifact change.
3. Update `00-manifest.md`: note the D resolution in a comment (does not change any row's status).
4. Delete `02-plan-issue.md`.
5. Surface: "Category D. No plan change. Build should re-read `<02-plan.md § X>` and resume from task `<N>`."

## 01-brief-issue.md structure (Category C escalation)

```markdown
---
session: 01-brief-issue
status: open
filed_by: pipeline-plan
filed_at: <YYYY-MM-DDTHH-MM>
feature_id: <FEATURE_ID>
brief_ref: <01-brief.md section>
triggered_by: 02-plan-issue.md (category C diagnosis)
---

## Plan section affected

Where the scope gap surfaced in `02-plan.md`.

## Brief section at issue

The area of `01-brief.md` that is ambiguous or silent.

## Specific question for Timm

A direct, answerable question. Not "what should we do" but "should conflicts on contact sync be resolved by GHL-wins, SiFly-wins, or timestamp-latest."

## Options with implications

2 or 3 viable answers, each with:
- What it means for the plan.
- What it means for the build.
- What downstream features it constrains or enables.
```

Hand `01-brief-issue.md` off to Timm. He resolves via `pipeline-ideate` (brief revision) or direct decision. Once the brief is updated, `pipeline-plan` re-runs this diagnosis with the new brief context.

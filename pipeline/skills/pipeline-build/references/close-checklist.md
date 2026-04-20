# Close checklist — pipeline-build

Run through this **only after all internal checkpoints are clean and the preview is verified live.**

## Step 1 — Confirm done-signal components

- [ ] Every task in `02-plan.md § Task list` is executed or explicitly deferred with Timm's sign-off.
- [ ] Every AC in `01-brief.md § Acceptance criteria` is PASS, or a FAIL is surfaced to Timm.
- [ ] Build green (build command exits clean).
- [ ] Tests pass (full suite).
- [ ] Preview deploy live and verified (deployment state = READY or equivalent).

If any are not true, **do not close**. Either fix or surface to Timm.

## Step 2 — Write `03-build-notes.md`

Per `references/build-notes-template.md`. Every section present:

- Commit range
- AC status
- Code-opt findings
- Security findings (with Legal-escalation text if regulated surface touched)
- Accessibility findings (or `N/A — no UI surface`)
- UX findings (or `N/A — no UI surface`)
- QA report
- Legal findings (`N/A — wrapper deferred` in v0.1.0)
- Marketing draft (`N/A — wrapper deferred` in v0.1.0)
- Lessons captured (or `None.`)
- Preview URL

Frontmatter: `status: done`, `inputs: [00-manifest.md, 01-brief.md, 02-plan.md]`, both flags copied from brief, `updated: <today>`.

## Step 3 — Update manifest

Edit `<FEATURE_DIR>/00-manifest.md`. Build row:

| Session   | Status | Owner | Updated     | Artifact            |
|-----------|--------|-------|-------------|---------------------|
| 03-build  | done   | cc    | YYYY-MM-DD  | 03-build-notes.md   |

Aggregate stays `in_progress` (Ship and Research rows still `pending`).

## Step 4 — Run the validator

```bash
bash skills/pipeline-build/scripts/check-build-notes.sh <FEATURE_DIR>/03-build-notes.md
```

- Exit 0 → continue.
- Non-zero (RED) → fix flagged sections, re-run. Do not surface to Timm with a failing check.

## Step 5 — Append to `lessons.md` (if applicable)

For every entry listed in `## Lessons captured` with promotion candidate `watch` or `yes`, append a dated entry to `skills/pipeline-build/lessons.md`. Tag by mode. One append per lesson.

Example:

```
## 2026-04-19 — example-fixture — UX polish — empty-state-cta-pattern
Pattern: Empty states in owner-only views consistently need a concrete CTA, not just a headline.
Evidence: 2026-04-19-document-share-link (first occurrence).
Promotion candidate: watch
```

Do not promote to project CLAUDE.md — LLM Ops only.

## Step 6 — Surface to Timm

Tell Timm verbatim:

> "Build done. Preview live: `<URL>` (state: READY). `03-build-notes.md` at `<FEATURE_DIR>`. All AC PASS (or: AC `<N>` FAIL — surfaced above). Lessons: `<N>` appended to lessons.md. Next: review the preview, and when you're ready, open a new Cowork session and paste `pipeline-ship/startup-prompt.md` with `<FEATURE_ID>` = `<actual>` and `<FEATURE_DIR>` = `<actual>`."

If regulated=true: append:

> "**Heads up: Legal review flag preserved in build-notes.** Legal wrapper is deferred in v0.1.0 — Ship must confirm review before production."

If customer_facing_launch=true: append:

> "**Heads up: Marketing copy is your job in Ship for v0.1.0** — wrapper deferred."

## Guardrail summary

The validator (`scripts/check-build-notes.sh`) enforces:

| Check | Enforced by |
|-------|-------------|
| Frontmatter has `session: 03-build` | regex |
| Frontmatter has all 9 required fields | field-by-field grep |
| `regulated` / `customer_facing_launch` are boolean | regex |
| Body has H1 | grep |
| Body has all 11 required H2 sections | grep per section |
| `## AC status` has ≥1 `- AC <N>:` row | row count |
| `## Preview URL` has non-empty body | content presence |
| `## Legal findings` says `N/A` (v0.1.0 — wrapper deferred ok) | content check (warning if missing "wrapper deferred" when regulated=true) |
| `## Marketing draft` says `N/A` (v0.1.0 — wrapper deferred ok) | content check (warning if missing "wrapper deferred" when cfl=true) |

Yellow (warnings, not blocking):
- Lessons captured is empty but Build took multiple mode passes → "worth a silent check that no pattern really emerged"
- Commit range is `N/A — no commits` but non-empty AC status → "AC claim PASS without commits is suspicious"

# Close checklist — pipeline-ideate

Run through this **only after Timm explicitly approves the brief**. Don't pre-create files.

## Step 1 — Confirm one feature, not a theme

Ask: "Is this one feature or a theme?"

- **One feature** → continue.
- **Theme** → offer to split into 2–N child feature dirs, each with its own brief. Don't split unilaterally — Timm picks. If he splits, run a separate Ideate (or quick mini-ideate per child) for each.

## Step 2 — Determine `<FEATURE_DIR>`

`<FEATURE_DIR>` = `Code/pipeline/<PROJECT>/<YYYY-MM-DD>-<slug>/`

- `<YYYY-MM-DD>` = today, UTC.
- `<slug>` = short kebab-case derived from feature title (e.g., `document-share-link`).

If `Code/pipeline/<PROJECT>/` doesn't exist, ask Timm before creating it. New project dirs may need `pipeline.overrides` set in `<PROJECT>/CLAUDE.md` — flag that as a Decision-needed if so.

## Step 3 — Write `00-manifest.md`

Use the template at `pipeline-substrate/references/manifest-template.md`. Status table:

| Session | Status | Owner | Updated | Artifact |
|---------|--------|-------|---------|----------|
| 01-ideate | done | timm | YYYY-MM-DD | 01-brief.md |
| 02-plan | pending | cc | — | 02-plan.md |
| 03-build | pending | cc | — | 03-build-notes.md |
| 04-ship | pending | cc | — | 04-ship.md |
| 05-research | pending | cc | — | 05-research.md (cohort) |

Aggregate status (per substrate rules) = `in_progress` because at least one row is not `done`.

## Step 4 — Write `01-brief.md`

Per `references/brief-template.md`. Frontmatter `status: done`. Both flags set explicitly.

## Step 5 — Run the validator

```bash
bash skills/pipeline-ideate/scripts/check-brief.sh <FEATURE_DIR>/01-brief.md
```

Exit 0 → continue. Non-zero → show Timm the failure list, fix in-session, re-run.

## Step 6 — Confirm the handoff to Plan

Tell Timm verbatim:

> "Brief approved. Feature dir at `<FEATURE_DIR>`. Next: open Claude Code on `<PROJECT>` in plan mode and paste `pipeline-plan/startup-prompt.md` with `<FEATURE_ID>` = `<actual>` and `<FEATURE_DIR>` = `<actual>`."

## Step 7 — Lessons check (silent)

Did this session reveal a pattern (not a one-off)? If yes, append a dated entry to `lessons.md`. If no, skip — don't fabricate lessons.

## Guardrail summary

The validator (`scripts/check-brief.sh`) enforces:

| Check | Enforced by |
|-------|-------------|
| Frontmatter has `session: 01-ideate` | regex on file |
| Frontmatter has all 9 required fields | field-by-field grep |
| Frontmatter `regulated` is `true` or `false` | regex |
| Frontmatter `customer_facing_launch` is `true` or `false` | regex |
| Body has `## Vision` heading | grep |
| Body has `## Pressure-test` heading with ≥2 `### Alternative` subheadings | grep + count |
| Body has `## Brief` heading with `### Scope`, `### Acceptance criteria`, `### Non-goals`, `### Decisions needed` | grep |
| Body has `## Flags` heading | grep |
| No file-extension-looking strings in body (`.md`, `.ts`, `.tsx`, `.py`, `.json`, `.yaml`) outside fenced code or links | regex (warning, not blocking) |
| No endpoint signatures (`POST /`, `GET /`, `PUT /`, `DELETE /`) outside fenced code | regex (warning, not blocking) |

Warnings (yellow) don't block close, but Timm should see them and make a call. Blocking failures (red) must be fixed.

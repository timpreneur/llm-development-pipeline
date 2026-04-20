# 00-manifest.md — template

Every feature dir starts with a `00-manifest.md`. Created by `pipeline-ideate` when the brief lands; updated by every subsequent session as its last action before close.

## Template

```markdown
---
session: 00-manifest
feature_id: <YYYY-MM-DD-slug>
project: <project>
owner: timm
status: in_progress
inputs: []
updated: <YYYY-MM-DD>
regulated: <true|false>
customer_facing_launch: <true|false>
---

# Feature: <Title>
- Project: <project>
- Feature ID: <YYYY-MM-DD-slug>
- Regulated: <true|false> · Customer-facing launch: <true|false>
- Involves: <comma-separated list, if multi-repo; omit the line otherwise>

| Session     | Status      | Owner  | Updated    | Artifact             |
|-------------|-------------|--------|------------|----------------------|
| 01-ideate   | <status>    | <owner>| <date>     | 01-brief.md          |
| 02-plan     | <status>    | <owner>| <date>     | 02-plan.md           |
| 03-build    | <status>    | <owner>| <date>     | 03-build-notes.md    |
| 04-ship     | <status>    | <owner>| <date>     | 04-ship.md           |
| 05-research | <status>    | <owner>| <date>     | (cohort)             |
```

## Field vocabulary

**`status`** in the frontmatter — aggregate feature state. One of:

- `in_progress` — any session in the table is `in_progress`.
- `done` — every session row is `done` (including Research).
- `blocked` — any session row is `blocked`.
- `shipped_watching` — 04-ship is `done`, 05-research is `pending` (watch window open).

**`status`** in the table — per-session state:

- `pending` — not started.
- `in_progress` — active.
- `done` — completed; artifact written; manifest updated by that session.
- `blocked` — can't proceed; see session artifact for why.
- `skipped` — intentionally not run (e.g., marketing for internal-only feature).

**`owner`**:

- `timm` — a human session where Timm is running it.
- `cc` — Claude Code session (plan, build).
- `auto` — autonomous Cowork session (research, llm-ops).
- `—` — not assigned yet (pending row).

**`updated`** — ISO date (`YYYY-MM-DD`) the row was last changed. Not a timestamp.

**Artifact column** — the filename of the artifact that session produces. Research's artifact lives in the cohort dir, so the column reads `(cohort)`.

## Row update semantics

- A session's last action before closing is to rewrite its row: status → `done`, owner → actual, updated → today, artifact → filename.
- If the session blocks, status → `blocked`, artifact stays blank or partial.
- If the session skips (e.g., marketing mode on internal feature), status → `skipped` with a one-line reason in the session's artifact if applicable.
- No session updates another session's row. If a row is wrong, that's a repair pass, not a cross-session write.

## Aggregate status rules

When any session updates its row, it recomputes the frontmatter `status`:

- Any row `in_progress` → aggregate `in_progress`.
- Any row `blocked` → aggregate `blocked` (overrides in_progress).
- All rows `done` → aggregate `done`.
- 04-ship is `done` and 05-research is `pending` → aggregate `shipped_watching`.

Write the aggregate once per session close. Don't flip it mid-session.

## Multi-repo variant

When the feature touches multiple projects, the body includes an `Involves:` line listing each one. The frontmatter's `project:` is still a single value — the *primary* project that owns the feature dir on disk. Promotion runs once per involved project.

## Example (from the brief)

```markdown
---
session: 00-manifest
feature_id: 2026-04-19-sample-feature
project: example-fixture
owner: timm
status: in_progress
inputs: []
updated: 2026-04-19
regulated: false
customer_facing_launch: true
---

# Feature: Sample Feature
- Project: example-fixture
- Feature ID: 2026-04-19-sample-feature
- Regulated: false · Customer-facing launch: true

| Session     | Status      | Owner | Updated    | Artifact             |
|-------------|-------------|-------|------------|----------------------|
| 01-ideate   | done        | timm  | 2026-04-18 | 01-brief.md          |
| 02-plan     | done        | cc    | 2026-04-19 | 02-plan.md           |
| 03-build    | in_progress | cc    | 2026-04-19 | 03-build-notes.md    |
| 04-ship     | pending     | —     | —          | —                    |
| 05-research | pending     | —     | —          | (cohort)             |
```

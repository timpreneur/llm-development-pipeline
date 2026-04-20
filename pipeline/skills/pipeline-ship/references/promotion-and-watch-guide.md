# Promotion + watch-window guide

How to run promotion and the watch window inside Ship. Two small flows; both are easy to skip silently and both are validated by `check-ship.sh`.

## Promotion

Promotion is the step that moves artifacts out of the pipeline's working dir and into the project's repo so the project maintainers (and future Researchers) can find them in the same place as the rest of the codebase.

### 1. Read the project's declared paths

In `<PROJECT>/CLAUDE.md`, look for a `pipeline.*` block. Two fields matter here:

- `pipeline.repo_brief_dir` — destination for promoted briefs
  - Example: `docs/briefs/archive/`
- `pipeline.changelog_path` — file to append the changelog entry to
  - Example: `CHANGELOG.md`

Both are optional. A project can declare one, both, or neither.

### 2. Brief promotion

If `pipeline.repo_brief_dir` is declared:

1. Copy `<FEATURE_DIR>/01-brief.md` → `<pipeline.repo_brief_dir>/<feature_id>.md` (the feature_id is the directory name, `YYYY-MM-DD-slug`).
2. Keep frontmatter intact. Do not edit body.
3. Record destination path under `## Promotion` in `04-ship.md`.

If not declared: record `N/A — not declared`. Don't fabricate a path.

### 3. Changelog append

If `pipeline.changelog_path` is declared:

1. Open the file.
2. Append a single dated line **without rewriting the rest of the file**. Use the internal release note as the source of truth for the summary.
   ```
   YYYY-MM-DD — <feature_id> — <one-line summary>
   ```
3. Preserve existing whitespace conventions. If the file uses reverse-chronological sections (e.g. "## [Unreleased]" on top, "## [0.12.0]" below), append under the most recent section; don't invent new section headers unless there's a pattern in the file.
4. Record the appended line under `## Promotion` in `04-ship.md`.

If not declared: record `N/A — not declared`.

### 4. Failure handling

- Declared path doesn't exist (missing directory) → do NOT `mkdir -p` silently. Surface to Timm with the specific path. The project intended this destination to exist; missing = a project-level drift worth a conversation.
- Write fails (permissions, mount) → surface to Timm. Never swallow.

## Watch window

The watch window tells the Researcher when to run for this feature's cohort. No watch window = feature never gets retrospected. This is a first-class output of Ship, not a nice-to-have.

### 1. Compute the cohort_id

- Default cohort granularity: ISO week → `YYYY-Www` (e.g. `2026-W16`)
- Override via `<PROJECT>/CLAUDE.md` field `pipeline.cohort_granularity: month` → `YYYY-MM`
- Cohort is determined from `closes_at`, not `opens_at`.

### 2. Choose the window length

| Feature profile | Window | Why |
|-----------------|--------|-----|
| Default | 14 days | Enough cycles to detect breakage + emergent feedback |
| Regulated (`regulated: true`) | 30 days | Compliance signals often late-arriving |
| High-risk (first deploy of a pattern, payment path, large migration) | 30 days | Tail of issues |
| Tiny internal tooling (non-customer-facing, single-team) | 7 days | Faster retrospection; low blast radius |
| Project override `pipeline.watch_window_default_days: <N>` | `<N>` | Project has tuned its own default |

Record the chosen length + the reason if it's not default.

### 3. Schedule via the `schedule` marketplace skill

Call the `schedule` skill with:

- trigger: at `closes_at`
- task: "Run pipeline-research for cohort `<cohort_id>`, feature `<feature_id>`"
- return: task_id

If the skill does not return a task_id → surface to Timm. Do not silently proceed — validator will reject anyway (Watch window section with no task_id is RED).

### 4. Record in `04-ship.md`

Under `## Watch window`:

- `task_id: <returned>`
- `cohort_id: <YYYY-Www or YYYY-MM>`
- `opens_at: <deploy-verified timestamp>`
- `closes_at: <opens_at + length>`
- `length: <N> days (reason: <default | regulated | high-risk | tiny-internal | project-override>)`

### 5. Cohort collision

Multiple features ship in the same cohort window (normal). That's fine — the Researcher session reads all feature dirs whose `closes_at` falls in the cohort. No dedupe needed at Ship time. Just record the `cohort_id` honestly.

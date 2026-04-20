# Pipeline directory convention

The authoritative layout. Any skill that contradicts this file has a bug.

## Root

```
Code/pipeline/
├── _meta/                       ← LLM Ops' home
├── <project-a>/                 ← one dir per project that uses the pipeline
├── <project-b>/
└── ...
```

`Code/pipeline/` lives at the root of the Cowork workspace (`Code/` is the Cowork-mounted folder). Never nest the pipeline inside a project's repo — the whole point of the hybrid artifact home is that the pipeline dir is tooling-owned, and promotion (see below) is what lands anything in the repo.

## Project dir

```
Code/pipeline/<project>/
├── <YYYY-MM-DD-slug>/           ← feature dir, one per feature
├── <YYYY-MM-DD-slug>/
├── <COHORT_ID>/                 ← cohort dir, one per Research cohort
├── _inbox/                      ← Research seeds next Ideate
├── _archive/                    ← feature dirs moved here 180 days post-ship (deferred; see §Lifecycle)
└── (no other files at this level)
```

- `<project>` is kebab-case, matching the project's directory name in `Code/`. E.g., `example-fixture`, `invoice-dashboard`.
- `_inbox/` and `_archive/` are underscore-prefixed so they sort outside feature dirs in `ls`.
- Feature dirs are `YYYY-MM-DD-<slug>`. Slugs are kebab-case, descriptive, short. Date is the Ideate session's date.

## Feature dir — five artifacts + manifest

```
Code/pipeline/<project>/<YYYY-MM-DD-slug>/
├── 00-manifest.md               ← status table, one row per session
├── 01-brief.md                  ← Ideate output
├── 02-plan.md                   ← Plan output
├── 03-build-notes.md            ← Build output (all mode findings as sections)
└── 04-ship.md                   ← Ship output
```

`05-research.md` does **not** live in the feature dir — it lives in the cohort dir (see below).

Session artifacts are created in order; earlier artifacts may not exist while a later session hasn't started yet. The manifest tracks which are present and their status.

## Cohort dir — Research's home

```
Code/pipeline/<project>/<COHORT_ID>/
└── 05-research.md               ← Research output
```

- `COHORT_ID` is either `YYYY-Www` (ISO week, e.g., `2026-W17`) or `YYYY-MM`. Pick one per project and stay consistent.
- A cohort covers ≥3 features from the same project whose watch windows have closed, or 14 days from the oldest watch-window close (max-wait), whichever comes first.
- Cohorts cap at ~5 features; larger groups split into multiple cohorts (usually by surface area).
- The cohort dir is created by `pipeline-research` when it starts. It doesn't exist ahead of time.

## `_inbox/`

```
Code/pipeline/<project>/_inbox/
├── <YYYY-MM-DD-slug>.md         ← Research seed for next Ideate
└── ...
```

- One file per strong-signal candidate surfaced by Research.
- Filename is `<YYYY-MM-DD-slug>.md` where the date is the Research session date and the slug is the candidate's proposed feature slug.
- Seed format is specified in `pipeline-research/references/inbox-stub-format.md`.
- Timm picks these up to start the next Ideate. Ideate may delete the seed or keep it for reference when it opens a new feature dir for the candidate.

## `_archive/` (lifecycle — deferred)

```
Code/pipeline/<project>/_archive/<YYYY>/
└── <YYYY-MM-DD-slug>/           ← archived feature dir
```

Recommendation: move feature dirs here 180 days post-ship. Not implemented in v0.1.0 — deferred as Brief Open Question #5. When implemented, owned by `pipeline-llm-ops` via a scheduled task.

## `_meta/`

```
Code/pipeline/_meta/
├── skill-hashes.json            ← marketplace SKILL.md hash snapshot, for drift checks
├── CHANGELOG.md                 ← pipeline-level change log (substrate, LLM Ops, brief-deltas)
└── metrics.md                   ← per-cohort aggregated metrics (done-signal rates, re-entry counts, etc.)
```

See `meta-contract.md` for contents and write policy.

## Promotion

When `pipeline-ship` closes with `deploy_state: READY`, it reads the project's `CLAUDE.md` for a `pipeline` block:

```yaml
pipeline:
  repo_brief_dir: docs/briefs/archive/
  changelog_path: docs/CHANGELOG.md
```

If declared:

- `01-brief.md` is copied into `<project>/<repo_brief_dir>/<feature-id>.md`.
- The release note is appended to `<project>/<changelog_path>`.
- The feature dir under `Code/pipeline/<project>/` **stays**. Promotion doesn't delete. Archive is a separate lifecycle action.

If not declared, promotion is explicitly N/A and `pipeline-ship` notes this in `04-ship.md`.

## Multi-repo features

Per Brief Decision #5, multi-repo features share one feature dir. The manifest's frontmatter includes `project:` (primary) and the manifest body lists all involved projects:

```markdown
# Feature: <title>
- Project: <primary-project>
- Involves: <project-a>, <project-b>
- Feature ID: <YYYY-MM-DD-slug>
```

The feature dir lives under the primary project's dir. Promotion runs once per involved project (each project's CLAUDE.md controls its own promotion paths).

## ExitPlanMode alternative path

Per Brief Open Question #2, if `ExitPlanMode` can only write inside the repo (to be verified at implementation time), `pipeline-plan` may instead write `02-plan.md` to `<project>/.pipeline/<feature-id>/02-plan.md` and the manifest parser treats that path as equivalent to `Code/pipeline/<project>/<feature-id>/02-plan.md`. Default is pipeline-dir; repo fallback only if plan mode refuses.

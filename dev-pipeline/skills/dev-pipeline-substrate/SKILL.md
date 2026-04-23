---
name: dev-pipeline-substrate
description: >
  The pipeline plugin's foundation layer — directory convention, artifact templates (manifest + session files), and `_meta/` seed (skill-hashes, changelog, metrics).
  Invoke when setting up the pipeline workspace for the first time, when a session skill needs to consult the canonical manifest or session-file template, when repairing a broken manifest, or whenever a skill has to resolve "where does this artifact go."
  Also triggers on "bootstrap pipeline," "seed pipeline meta," "set up pipeline workspace," "validate pipeline convention," "check pipeline dir," "fix pipeline manifest," or when any of the session skills (`dev-pipeline-ideate`, `dev-pipeline-plan`, `dev-pipeline-build`, `dev-pipeline-ship`, `dev-pipeline-research`, `dev-pipeline-llm-ops`) need the authoritative path / template / flag contract.
---

# dev-pipeline-substrate

The foundation for the rest of the plugin. Everything else references this for:

- Where feature directories live on disk (`Code/pipeline/<project>/<YYYY-MM-DD-slug>/`).
- The manifest shape (`00-manifest.md`) and how session rows update.
- The session-file frontmatter contract (`NN-<session>.md`, used by all five artifacts).
- What `_meta/` contains and how to seed it.

No session orchestration happens here. This skill is *convention*. Other skills call out to the reference files; this skill's bootstrap step writes the workspace's foundational directories and `_meta/` files on first run.

## When to invoke

- First time setting up the pipeline on a workspace — run the bootstrap.
- A session skill hit a missing directory or malformed manifest — validate and repair.
- `dev-pipeline-llm-ops` is about to run a drift check and needs `_meta/skill-hashes.json` to exist.
- Someone asks "where does X artifact live" or "what flags go in the frontmatter" — answer from the references.

## What this skill does

1. **Bootstraps the pipeline workspace** — idempotent. Creates `Code/pipeline/` if missing, seeds `_meta/` with `skill-hashes.json`, `CHANGELOG.md`, `metrics.md`. Safe to run repeatedly; never overwrites existing `_meta/` content without an explicit repair request.
2. **Holds the canonical templates** — `references/manifest-template.md` and `references/session-file-template.md`. Session skills read these to produce valid artifacts.
3. **Documents the layout** — `references/pipeline-dir-convention.md` is the single source of truth for the directory tree. If any skill's behavior contradicts this file, the convention wins and the skill has a bug.
4. **Defines the `_meta/` contract** — `references/meta-contract.md` specifies what each `_meta/` file contains, who writes to it, and why. `dev-pipeline-llm-ops` operates against this contract.
5. **Lints frontmatter + manifest shape** — validation is a read-only pass. Reports malformed artifacts; doesn't modify unless the caller asks for repair.

## Bootstrap flow

Run on first install or when the user says "bootstrap the pipeline."

1. Resolve the pipeline root: `Code/pipeline/` relative to the Cowork workspace root. If the workspace root is ambiguous, ask.
2. Create `Code/pipeline/` if missing.
3. Create `Code/pipeline/_meta/` if missing.
4. For each of the three `_meta/` files, check existence:
   - **Missing** → write the seed (see shapes in `references/meta-contract.md`).
   - **Present** → leave alone. Bootstrap never overwrites.
5. Append a single dated line to `_meta/CHANGELOG.md`: `- <YYYY-MM-DD>: dev-pipeline-substrate bootstrap (version <plugin-version>)`.
6. Report what was created vs left alone.

Bootstrap is the only time substrate writes outside `_meta/`. Every other path operation is read-only.

## Validation flow

Run when a session skill hands off a feature dir, when `dev-pipeline-llm-ops` audits state, or when the user asks "is my pipeline OK."

1. Enumerate `Code/pipeline/<project>/*` directories.
2. For each feature dir: confirm `00-manifest.md` exists; parse its status table; check every referenced artifact file exists; check frontmatter on each artifact matches the contract in `references/session-file-template.md`.
3. For each cohort dir (matches `YYYY-Www` or `YYYY-MM`): confirm `05-research.md` exists if the dir is not empty.
4. Check `_meta/` files all exist and have the right top-level shape.
5. Emit a report: green (all pass), yellow (missing optional, non-blocking), red (malformed — which file, which field).

Validation does not modify anything unless the caller explicitly says "repair." Repair is a separate operation — it rewrites frontmatter to the template, seeds missing manifest rows as `pending`, and logs every change to `_meta/CHANGELOG.md`.

## How other skills use substrate

Session skills reference the template files and the convention directly:

- `dev-pipeline-ideate` reads `references/session-file-template.md` before writing `01-brief.md` and `00-manifest.md`.
- `dev-pipeline-plan` reads `references/manifest-template.md` when it inserts the `02-plan` row.
- `dev-pipeline-build` reads `references/session-file-template.md` for the frontmatter it writes on `03-build-notes.md`, and consults `references/pipeline-dir-convention.md` for promotion paths.
- `dev-pipeline-ship` reads the promotion-path rules in `references/pipeline-dir-convention.md` + the manifest-close rules.
- `dev-pipeline-research` reads the cohort-dir rules.
- `dev-pipeline-llm-ops` reads `references/meta-contract.md` end to end — it's LLM Ops' home.

If a session skill is tempted to inline a different convention, stop. Update the reference file in substrate instead, and the skill will pick it up.

## Reference files

Read the relevant one when you need the authoritative answer:

- `references/pipeline-dir-convention.md` — directory tree, path semantics, cohort + inbox + archive rules, promotion behavior.
- `references/manifest-template.md` — `00-manifest.md` shape, every session row, status vocabulary.
- `references/session-file-template.md` — `NN-<session>.md` frontmatter + section shape, flag decision tree.
- `references/meta-contract.md` — `_meta/skill-hashes.json` schema, `_meta/CHANGELOG.md` entry format, `_meta/metrics.md` table shape.

## Lessons

Append dated entries to `lessons.md` when substrate itself reveals a gap — e.g., a convention that didn't survive contact with a real feature, a `_meta/` shape that `dev-pipeline-llm-ops` couldn't parse. LLM Ops reconciles.

## Smoke test

See `fixtures/pipeline/example-fixture/`. The fixture is a complete feature directory with all five artifacts stubbed, wired through a fixture `00-manifest.md`. Running the bootstrap + validation against the fixture verifies: `_meta/` seeds correctly, manifest parses, every stub artifact passes frontmatter lint. The validation script lives at `fixtures/run-smoke.sh`.

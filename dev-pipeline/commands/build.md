---
description: Session 03 — execute an approved plan (Claude Code, execution mode)
argument-hint: "<FEATURE_ID>"
---

Open a Build session (Session 03 of the dev pipeline).

Follow the `dev-pipeline-build` skill end-to-end. Must run in Claude Code **execution mode** (not plan mode). Executes the approved `02-plan.md` for the feature, running internal review modes (code-optimizer, security, accessibility, UX polish, QA) at checkpoints and writing all findings to a single `03-build-notes.md`.

If `$ARGUMENTS` is set, treat it as the `FEATURE_ID`. Otherwise, ask which feature to build.

Build is deliberately silent — Timm touches it only at the preview URL (touchpoint #3). Required output: `<FEATURE_DIR>/03-build-notes.md` with every mode output as a named section, plus the preview deploy URL. Validated by `scripts/check-build-notes.sh`. Legal and Marketing conditional wrappers are DEFERRED — those sections accept `N/A — wrapper deferred`. Done signal is all AC pass + build green + tests pass + preview URL live + `check-build-notes.sh` green. Hand off to `dev-pipeline-ship` on close.

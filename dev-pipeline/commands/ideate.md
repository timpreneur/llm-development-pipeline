---
description: Session 01 — convert a raw idea into an approved brief
argument-hint: "<project-slug-or-description>"
---

Open an Ideate session (Session 01 of the dev pipeline).

Follow the `dev-pipeline-ideate` skill end-to-end: interview → pressure-test → draft `01-brief.md`. Runs in Cowork, conversational. One session, one brief.

If `$ARGUMENTS` is set, treat it as the starting project/idea context. Otherwise, open with the interview and ask.

Required output: `<FEATURE_DIR>/01-brief.md` + `<FEATURE_DIR>/00-manifest.md`, validated by `scripts/check-brief.sh` (≥2 pressure-test alternatives, no solutioning in the body, both flags set). Done when Timm explicitly approves the brief. Hand off to `dev-pipeline-plan` on close.

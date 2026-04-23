---
description: Session 05 — research a shipped cohort (what shipped, what broke, what's next)
argument-hint: "<COHORT_ID>"
---

Open a Research session (Session 05 of the dev pipeline).

Follow the `dev-pipeline-research` skill end-to-end. Autonomous Cowork session that surfaces what shipped features actually did, what broke, and what users ask for next. Runs per-cohort when the cohort's watch windows have closed.

If `$ARGUMENTS` is set, treat it as the `COHORT_ID`. Otherwise, ask which cohort to research (or let the `schedule` skill fire one automatically on cohort-close).

Requires ≥1 feature in the cohort with `04-ship.md` and closed watch window. Writes `<COHORT_DIR>/05-research.md` and seeds `<PROJECT>/_inbox/<YYYY-MM-DD-slug>.md` stubs for strong-signal candidates. Autonomous — no mid-session stops; surfaces clearly at end.

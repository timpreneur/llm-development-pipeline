---
description: Session 04 — deploy to prod, run agentic QA, write the human punchlist, sign off
argument-hint: "<FEATURE_ID>"
---

Open a Ship session (Session 04 of the dev pipeline).

Follow the `dev-pipeline-ship` skill end-to-end. Deploys to production, verifies deploy state via platform MCP, runs the Phase 3 agentic QA pass against the live URL, writes the Phase 4 human punchlist (`04-punchlist.json`, schema v2), wires observability, schedules the watch window, drafts release notes, and promotes artifacts into the project repo.

If `$ARGUMENTS` is set, treat it as the `FEATURE_ID`. Otherwise, ask which feature to ship.

Runs in a Cowork session. Requires `03-build-notes.md` present and preview green. Writes `<FEATURE_DIR>/04-ship.md` and `<FEATURE_DIR>/04-punchlist.json`, updates the manifest. Ends with Timm's final sign-off (pipeline touchpoint #4). Do NOT use for writing customer-facing marketing copy from scratch without a Build § Marketing draft — author manually in v0.1.x.

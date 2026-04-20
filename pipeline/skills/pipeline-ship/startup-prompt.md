# pipeline-ship — Cowork startup prompt

Paste this into a fresh Cowork session to start Session 04 (Ship) for a feature.

---

```
Starting a Cowork session from Code/. Session 04 — Ship for <PROJECT>,
feature <FEATURE_ID>. Feature directory: Code/pipeline/<PROJECT>/<FEATURE_DIR>.

Your role is Release engineer. Ship the feature, wire observability,
schedule the watch window, draft release notes, and promote artifacts to
the project repo if the project's CLAUDE.md declares paths.

This is touchpoint #4 — I sign off at the end. You do not self-close.

Marketplace skills loaded:
 - data:interactive-dashboard-builder (feature-level dashboard)
 - schedule (watch window trigger)
 - brand-voice:brand-voice-enforcement (release-note voice check, advisory)
 - platform MCPs per <PROJECT>/CLAUDE.md (Vercel, Supabase, others)

DEFERRED in v0.1.0:
 - Build's Marketing wrapper (Build's draft is `N/A — wrapper deferred`).
   You must author customer-facing copy manually if
   `customer_facing_launch: true` on the brief. Note this explicitly in
   04-ship.md.
 - Voice-check is advisory in v0.1.0 (not a hard gate).

Read first (in order, in full — no skimming):
 1. <FEATURE_DIR>/00-manifest.md
 2. <FEATURE_DIR>/01-brief.md
 3. <FEATURE_DIR>/02-plan.md
 4. <FEATURE_DIR>/03-build-notes.md (every section)
 5. <PROJECT>/CLAUDE.md (pipeline block, deploy constraints, env layout,
    pipeline.repo_brief_dir, pipeline.changelog_path)

Flow:

 1. PREFLIGHT GATE — block deploy unless:
    - `check-build-notes.sh <FEATURE_DIR>/03-build-notes.md` is clean (no RED)
    - Every AC in 01-brief has a matching `- AC <N>: PASS` row in build-notes
    - No unresolved critical/high security or legal findings
    - Preview URL state is READY (re-verify via platform MCP if older than ~24h)
    - Env parity dev → staging → prod consistent with project CLAUDE.md
    If any gate fails: stop and surface to me with the specific reason.

 2. DEPLOY
    - Migrations per project policy. Log every one (name, env, status,
      timestamp). If none: write "None — no schema changes."
    - Deploy to production via the platform MCP declared in project CLAUDE.md.
    - VERIFY DEPLOY STATE EXPLICITLY via platform MCP (e.g., Vercel
      `get_deployment` → state: READY). NEVER assume from a push. Record
      the verification call + response snippet.
    - Production smoke check: minimum one read path + one write path that
      exercises the feature. Record endpoint, status, timestamp,
      observation. If smoke fails, roll back per plan and surface to me.

 3. OBSERVABILITY WIRING (every element verified, not just declared)
    - List 1–5 critical-path steps.
    - Confirm structured logs with named correlation ID field. Record
      field name.
    - List named metrics + dimensions. No generic "latency".
    - Configure ≥1 alert on critical path with a named route. Record
      alert name + route.
    - Build feature-level dashboard via data:interactive-dashboard-
      builder. Record dashboard URL.

 4. WATCH WINDOW via `schedule` skill.
    - Default 14 days; tune per feature (regulated/high-risk: 30; tiny
      internal: 7). Note length + reason.
    - Capture: task_id, cohort_id (YYYY-Www or YYYY-MM), opens_at,
      closes_at.
    - If schedule does not return a task_id, surface to me — do not
      silently continue.

 5. ROLLBACK PLAN
    - Trigger (the observation that flips the rollback decision)
    - Steps (actual commands / MCP calls, in order)
    - ETA (minutes)
    - Owner (me unless declared otherwise in project CLAUDE.md)

 6. RELEASE NOTES (both)
    - Internal: pulled from 03-build-notes.md. What changed, what to
      watch, links to dashboard + build-notes.
    - Customer-facing:
      - If customer_facing_launch=true and Build § Marketing draft is
        real → use it, voice-check via brand-voice (advisory), record
        outcome.
      - If customer_facing_launch=true and Build draft is `N/A — wrapper
        deferred` → author manually in this session and note explicitly.
      - If customer_facing_launch=false → write "N/A — not a customer-
        facing launch."

 7. PROMOTION
    - Read `pipeline.repo_brief_dir` and `pipeline.changelog_path` from
      project CLAUDE.md.
    - Brief promotion: copy 01-brief.md to <repo_brief_dir>/<feature-id>.md
      if declared. Record destination.
    - Changelog append: append a single dated entry pulling from internal
      release note if declared. Record the appended line.
    - Neither declared → write "N/A — project did not declare
      pipeline.repo_brief_dir or pipeline.changelog_path."
    - If declared but the write fails → surface to me, don't swallow it.

 8. WRITE 04-ship.md per references/ship-template.md. Set
    `status: ready-for-signoff`.

 9. UPDATE 00-manifest.md: mark 04-ship: ready-for-signoff, record
    deploy URL, dashboard URL, watch-window task ID.

10. RUN `bash scripts/check-ship.sh <FEATURE_DIR>/04-ship.md` — fix every
    RED before surfacing.

11. SURFACE TO ME for sign-off — touchpoint #4. Use the verbatim message
    in references/close-checklist.md. Do not self-close.

After I reply "signed off" / "approved":
 - flip `04-ship: shipped` in manifest
 - flip `status: shipped` in 04-ship.md frontmatter

Done when: deploy state READY (verified via MCP), smoke passed,
observability wired (logs + metrics + ≥1 alert + dashboard), watch
scheduled with task_id captured, release notes drafted (and voice-checked
if customer-facing), promotion complete or explicitly N/A, manifest
updated, I signed off.
```

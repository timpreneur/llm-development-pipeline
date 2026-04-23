# dev-pipeline-ship — Cowork startup prompt

Paste this into a fresh Cowork session to start Session 04 (Ship) for a feature.

---

```
Starting a Cowork session from Code/. Session 04 — Ship for <PROJECT>,
feature <FEATURE_ID>. Feature directory: Code/pipeline/<PROJECT>/<FEATURE_DIR>.

Your role is Release engineer. Deploy the feature, run the agentic QA pass
against the live URL, write the residual human punchlist, wire
observability, schedule the watch window, draft release notes, and promote
artifacts to the project repo if the project's CLAUDE.md declares paths.

This is touchpoint #4 — I sign off at the end. You do not self-close.

Marketplace skills loaded:
 - data:interactive-dashboard-builder (feature-level dashboard)
 - schedule (watch window trigger)
 - brand-voice:brand-voice-enforcement (release-note voice check, advisory)

Required connectors (MCPs):
 - Platform MCP per <PROJECT>/CLAUDE.md (Vercel, Supabase, others) — for
   deploy, state verification, runtime logs, build logs.
 - Claude in Chrome — for the Phase 3 live-URL pass (navigate, console,
   network, JS injection, resize).
 - GitHub (for Phase 9 punchlist mirror into <project-repo>/.punchlist/).

DEFERRED in v0.1.0:
 - Build's Marketing wrapper (Build's draft is `N/A — wrapper deferred`).
   You must author customer-facing copy manually if
   `customer_facing_launch: true` on the brief. Note this explicitly in
   04-ship.md.
 - Voice-check is advisory in v0.1.0 (not a hard gate).
 - V1 punchlist schema — you always write v2. The V1 `<short_sha>.json`
   pointer is a thin redirect in Phase 9 so the installed pre-push hook
   keeps passing.

Read first (in order, in full — no skimming):
 1. <FEATURE_DIR>/00-manifest.md
 2. <FEATURE_DIR>/01-brief.md
 3. <FEATURE_DIR>/02-plan.md — including any `## Checks` override block
 4. <FEATURE_DIR>/03-build-notes.md (every section)
 5. <PROJECT>/CLAUDE.md (pipeline block, deploy constraints, env layout,
    pipeline.repo_brief_dir, pipeline.changelog_path,
    pipeline.punchlist_dir, pipeline.punchlist_gating)
 6. references/agentic-qa-playbook.md (Phase 3 check menu)
 7. references/punchlist-schema.md (Phase 4 output contract)

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

 3. AGENTIC QA (live-URL pass; follow references/agentic-qa-playbook.md)
    - Core pass (every ship): navigate → console → network → HTTP smoke
      on read + write → Vercel runtime + build logs → AC walk tagging
      each AC as verified / partial / human_required with evidence or
      reason.
    - Conditional passes (auto-detected from brief/plan flags):
      a11y + responsive + screenshot critique if customer_facing_launch;
      auth-boundary check if auth/middleware/session files touched;
      extended API smoke if api/ or DB migration touched; Playwright
      specs if present in repo.
    - Honor `02-plan.md § Checks` include/skip. Skip requires a one-line
      reason — record it.
    - STOP CONDITION: any finding marked `blocking` → pause, surface to
      me, do not proceed to Phase 4.
    - Record `## Agentic QA` in 04-ship.md: checks_run list, AC coverage
      table (AC id → method → status → evidence/reason), findings table
      (id, severity, source, text, status), autonomous coverage %.

 4. PUNCHLIST (residual human QA; follow references/punchlist-schema.md)
    - Write `<FEATURE_DIR>/04-punchlist.json`. Schema v2. One item per
      unverified residual. Do NOT pad.
    - If Phase 3 verified 100% of AC and produced zero human-required
      rows: `items: []` is valid and correct.
    - Severity: `blocking` for items tied to human_required/partial AC
      where the unverified surface is customer-visible; otherwise
      `watch`. Do NOT escalate watch → blocking to force attention.
    - Required fields: schema_version, schema.generator, feature_id,
      project, short_sha, full_sha, deploy_url, deploy_state, title,
      created_at, agentic_pass {...}, items [...].
    - Validate: `bash scripts/check-punchlist.sh <FEATURE_DIR>/04-punchlist.json`
      — fix every RED. YELLOW is advisory.
    - Record `## Punchlist` in 04-ship.md: source path, repo mirror path
      (written in Phase 9), V1 pointer path (written in Phase 9), web
      app URL (https://ship-punchlist-web.vercel.app/<owner>/<repo>/feature/<feature_id>),
      blocking/watch summary, gating mode.

 5. OBSERVABILITY WIRING (every element verified, not just declared)
    - List 1–5 critical-path steps.
    - Confirm structured logs with named correlation ID field. Record
      field name.
    - List named metrics + dimensions. No generic "latency".
    - Configure ≥1 alert on critical path with a named route. Record
      alert name + route.
    - Build feature-level dashboard via data:interactive-dashboard-
      builder. Record dashboard URL.

 6. WATCH WINDOW via `schedule` skill.
    - Default 14 days; tune per feature (regulated/high-risk: 30; tiny
      internal: 7). Note length + reason.
    - Capture: task_id, cohort_id (YYYY-Www or YYYY-MM), opens_at,
      closes_at.
    - If schedule does not return a task_id, surface to me — do not
      silently continue.

 7. ROLLBACK PLAN
    - Trigger (the observation that flips the rollback decision — incl.
      open blocking punchlist items that can't clear in-window)
    - Steps (actual commands / MCP calls, in order)
    - ETA (minutes)
    - Owner (me unless declared otherwise in project CLAUDE.md)

 8. RELEASE NOTES (both)
    - Internal: pulled from 03-build-notes.md + `## Agentic QA`. What
      changed, what to watch, autonomous coverage %, links to dashboard
      + build-notes + punchlist.
    - Customer-facing:
      - If customer_facing_launch=true and Build § Marketing draft is
        real → use it, voice-check via brand-voice (advisory), record
        outcome.
      - If customer_facing_launch=true and Build draft is `N/A — wrapper
        deferred` → author manually in this session and note explicitly.
      - If customer_facing_launch=false → write "N/A — not a customer-
        facing launch."

 9. PROMOTION
    - Read `pipeline.repo_brief_dir`, `pipeline.changelog_path`, and
      `pipeline.punchlist_dir` (default `.punchlist/`) from project
      CLAUDE.md.
    - Brief promotion: copy 01-brief.md to <repo_brief_dir>/<feature-id>.md
      if declared. Record destination.
    - Changelog append: append a single dated entry pulling from internal
      release note if declared. Record the appended line.
    - PUNCHLIST MIRROR (always, not optional):
      - Copy 04-punchlist.json to
        <project-repo>/<punchlist_dir>/<feature_id>.json.
      - Write V1 pointer <project-repo>/<punchlist_dir>/<short_sha>.json
        with body: {"schema_version":"2","ref":"<feature_id>.json"}.
      - Record both paths.
    - If a declared write fails → surface to me, don't swallow it.

10. WRITE 04-ship.md per references/ship-template.md. Set
    `status: ready-for-signoff`. Frontmatter must include
    `agentic_qa_coverage_pct`, `punchlist_blocking_open`, `punchlist_url`.

11. UPDATE 00-manifest.md: mark 04-ship: ready-for-signoff, record
    deploy URL, dashboard URL, watch-window task ID, punchlist URL.

12. RUN `bash scripts/check-ship.sh <FEATURE_DIR>/04-ship.md` — fix every
    RED before surfacing. (The checker runs check-punchlist.sh too.)

13. SIGN-OFF GATING. Read `pipeline.punchlist_gating` from project
    CLAUDE.md (default `strict`).
    - `strict` + any open blocking punchlist item → do NOT surface the
      close message. Surface the blocker list instead and ask me to
      address (or temporarily flip to advisory, which logs to lessons.md).
    - `advisory` → surface the count in the close message and proceed.
      Log the override + reason to lessons.md on close.

14. SURFACE TO ME for sign-off — touchpoint #4. Use the verbatim message
    in references/close-checklist.md. Do not self-close.

After I reply "signed off" / "approved":
 - flip `04-ship: shipped` in manifest
 - flip `status: shipped` in 04-ship.md frontmatter
 - if gating was overridden to advisory with open blocking items, ensure
   the lessons.md entry is written before closing

Done when: deploy state READY (verified via MCP), smoke passed, agentic
QA pass recorded with autonomous coverage %, 04-punchlist.json written +
validated, observability wired (logs + metrics + ≥1 alert + dashboard),
watch scheduled with task_id captured, release notes drafted (and voice-
checked if customer-facing), promotion complete incl. mandatory punchlist
mirror + V1 pointer, manifest updated, gating check passed, I signed off.
```

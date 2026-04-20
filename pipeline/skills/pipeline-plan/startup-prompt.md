# pipeline-plan — startup prompt

Paste this into Claude Code (plan mode) on the project repo. Replace `<PROJECT>`, `<FEATURE_ID>`, `<FEATURE_DIR>`.

```
Opening Claude Code on <PROJECT> in plan mode. Session 02 — Plan for
feature <FEATURE_ID>. Feature directory: <FEATURE_DIR>.

Your role is Architect. Read the brief, grep the repo, produce
02-plan.md: task-ordered, file-level, with reuse anchors and risk
callouts. No writes. No code. Plan mode only.

Brownfield default. Greenfield Architect-Strategy pre-session is
deferred in pipeline v0.1.0 — if this feature is greenfield, handle
strategy in conversation before entering Plan mode.

Read first:
 1. <FEATURE_DIR>/00-manifest.md
 2. <FEATURE_DIR>/01-brief.md (every Decisions-needed entry, both flags)
 3. <PROJECT>/CLAUDE.md (including pipeline.overrides)
 4. Reference docs named in the brief's Context section

Flow:
 1. Read inputs in full.
 2. Grep the repo for every pattern / primitive / file the brief
    references. Log every grep + result in 02-plan.md § Verification.
    If anything doesn't exist as described, flag as brief-drift in
    Open questions.
 3. Produce plan with:
    - Task list (execution order)
    - Files touched per task (create / modify / delete)
    - Reuse anchors (existing components, utilities, marketplace skills)
    - Risk callouts (migrations, cross-package types, tier-visibility
      cascades, inlined-utility sync, rate limits, secrets, env)
    - Side-effects (nav entries, type updates, changelog, generated
      files, doc updates)
    - Test strategy (existing coverage + new tests + AC mapping)
    - Verification (every grep + result from step 2)
    - Rollback (or "N/A — internal only" with reason)
    - Open questions tagged [Timm] or [Build-discover]
 4. Show me. I approve or revise. Loop.
 5. ExitPlanMode writes 02-plan.md to <FEATURE_DIR>. Update manifest.
 6. Run scripts/check-plan.sh. Fix any RED before handoff.

Done when: I approve the plan. Plan is detailed enough that Build
executes without re-planning; any deviation is a flag, not a judgment
call.

Next: Build opens in a NEW Claude Code session (execution mode, not
plan mode). Context does not carry over — Build re-reads manifest,
brief, plan.
```

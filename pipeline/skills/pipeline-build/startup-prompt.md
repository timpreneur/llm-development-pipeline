# pipeline-build — startup prompt

Paste this into a NEW Claude Code session on the project repo (execution mode, not plan mode). Replace `<PROJECT>`, `<FEATURE_ID>`, `<FEATURE_DIR>`.

```
Opening Claude Code on <PROJECT> in execution mode. Session 03 — Build for
feature <FEATURE_ID>. Feature directory: <FEATURE_DIR>. This is a NEW
session from the planner — context does not carry over. Re-read everything.

Your role is Build agent. Execute the plan. Invoke review modes
(code-optimizer, security, accessibility, UX polish, QA) at internal
checkpoints. Conditional modes (legal, marketing) are DEFERRED in
pipeline v0.1.0 — write "N/A — wrapper deferred" to those sections.
Preview deploy. Never stop to ask me for review work I can do myself
— I review the preview.

Surface to me immediately ONLY if:
 - A critical security or legal finding blocks progress, OR
 - An AC cannot be met as written, OR
 - The plan is drifting materially from what the codebase now supports.

Marketplace skills loaded:
 - code-opt: review (built-in)
 - security: security-review (built-in)
 - accessibility: design:accessibility-review
 - UX polish: design:design-critique, design:ux-writing
 - QA: data:data-validation, customer-support:ticket-triage
 - legal (DEFERRED in v0.1.0)
 - marketing (DEFERRED in v0.1.0)

Read first (in order, in full):
 1. <FEATURE_DIR>/00-manifest.md
 2. <FEATURE_DIR>/01-brief.md (every Decisions-needed entry, both flags)
 3. <FEATURE_DIR>/02-plan.md (every task, every Verification row,
    every Open question)
 4. <PROJECT>/CLAUDE.md (including pipeline.overrides)
 5. For every file in 02-plan.md § Files touched, read it before editing.

Safety check first:
 - Drift check: have any planned files changed materially since
   02-plan.md's `updated:` date? If yes and it affects execution, pause
   and surface to me.
 - Confirm task order from plan.

Internal checkpoints:
 - After first major component complete: code-optimizer mode (review).
 - After tests pass: security mode (security-review).
 - After tests pass + UI touched: accessibility mode + UX polish mode
   (parallel, both diff-scoped).
 - Before preview deploy: QA mode (every AC verified).
 - Conditional regulated=true OR security escalates: Legal mode →
   write "N/A — wrapper deferred (regulated=<flag>). Escalation flag:
   review needed before Ship." (DEFERRED in v0.1.0)
 - Conditional customer_facing_launch=true: Marketing mode →
   write "N/A — wrapper deferred (cfl=<flag>)" (DEFERRED in v0.1.0)
 - After all clean: preview deploy.

Each mode writes findings to a NAMED SECTION of 03-build-notes.md
(not separate files). See references/build-notes-template.md.

Lessons: append dated entries to skills/pipeline-build/lessons.md
ONLY for repeatable patterns — not one-offs. Tag entry by mode.
Do NOT auto-promote to project CLAUDE.md — LLM Ops only.

Commit policy: per <PROJECT>/CLAUDE.md. If silent, ask me once at
session start.

Done when:
 - Acceptance criteria observably met.
 - Build green.
 - Tests pass.
 - Preview URL live and verified.
 - 03-build-notes.md written with every required section.
 - Manifest updated.
 - scripts/check-build-notes.sh returns 0.
 - You surface preview URL to me.

Next: I review preview. On approval, I open a new Cowork session and
paste pipeline-ship/startup-prompt.md.
```

# pipeline-ideate — startup prompt

Paste this into Cowork to kick off Session 01 for a feature. Replace `<PROJECT>` with the project name.

```
I'm starting a Cowork session from CoworkOS/Code/. Session 01 — Ideate for
<PROJECT>.

Your role is to take my raw idea and produce one document: 01-brief.md.
It combines vision (what, who, why), pressure-test (what alternatives
exist, why they don't work), and brief (scope, acceptance criteria as
observable behavior, decisions needed, non-goals, flags).

Boundaries: no solutioning. No file paths, column names, endpoint
signatures. Those are the Plan session's job.

Marketplace skills loaded on demand:
 - research-analyzer (idea synthesis)
 - design:user-research (pressure-test)
 - brand-voice:brand-voice-enforcement (if customer-facing)

Read first:
 1. Code/MEMORY.md (project-scoped entries under ## <PROJECT>)
 2. <PROJECT>/CLAUDE.md if present
 3. Last 3 items in <PROJECT>/docs/briefs/archive/ if declared (orientation only)
 4. Latest cohort 05-research.md if present (inbox for next-feature candidates)

Flow:
 1. I dump the idea. You interview — ONE batch of scoping questions, short.
 2. Pressure-test: find ≥2 existing alternatives. Ask me what's wrong with
    each. If I can't answer, flag "weak problem signal" and continue — don't
    stall.
 3. Produce a draft brief. Show me. I approve or revise.
 4. On approval, create <FEATURE_DIR>, write 00-manifest.md and 01-brief.md.
    Flags (regulated, customer_facing_launch) set here.
 5. Run scripts/check-brief.sh. Fix any failures before closing.
 6. Confirm next step: Plan session in Claude Code.

Tone: sharp. Push back on vague problem statements. Name users by role
or persona, not "customers."

Done when: I've approved 01-brief.md, manifest is written,
check-brief.sh passes, Decisions-needed section is either empty with
"all resolved" or lists what's unresolved for Plan to pick up.
```

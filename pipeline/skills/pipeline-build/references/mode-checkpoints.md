# Mode checkpoints — pipeline-build internal flow

One session, scheduled internally. Timm sees only the preview at the end — unless something critical surfaces (see `SKILL.md § Escalation rules`).

## Flow diagram

```
SAFETY CHECK
  read brief + plan + project CLAUDE.md (in full)
  drift check since plan's `updated:` date
  confirm task order
  confirm commit policy

EXECUTE TASKS
  ↓ after first major component complete
  ┌─────────────────────────────────────────────────┐
  │ CODE-OPTIMIZER MODE                             │
  │ marketplace: review (built-in)                  │
  │ scope: diff so far                              │
  │ output: § Code-opt findings                     │
  │ resolution: inline fix or note-and-continue     │
  └─────────────────────────────────────────────────┘

CONTINUE TASKS → RUN TESTS → TESTS PASS
  ↓
  ┌─────────────────────────────────────────────────┐
  │ SECURITY MODE                                   │
  │ marketplace: security-review (built-in)         │
  │ scope: full diff                                │
  │ checks: auth, validation, SSRF, injection,      │
  │         secrets, perms, deps                    │
  │ output: § Security findings                     │
  │ resolution: critical/high inline; lower noted   │
  │ escalation: if touches regulated surface →      │
  │   append "Escalation flag: Legal mode required" │
  │   (v0.1.0: Legal is DEFERRED — escalation text  │
  │   lands, Ship must flag to Timm)                │
  └─────────────────────────────────────────────────┘
  ↓ parallel (both diff-scoped, fast)
  ┌─────────────────────────────────────────────────┐
  │ ACCESSIBILITY MODE (if UI touched)              │
  │ marketplace: design:accessibility-review        │
  │ scope: UI surface                               │
  │ output: § Accessibility findings                │
  └─────────────────────────────────────────────────┘
  ┌─────────────────────────────────────────────────┐
  │ UX POLISH MODE (if UI touched)                  │
  │ marketplace: design:design-critique,            │
  │              design:ux-writing                  │
  │ scope: UI surface                               │
  │ applies: pipeline.overrides.ux_polish           │
  │          (forbidden_patterns, required_reuse)   │
  │ output: § UX findings                           │
  └─────────────────────────────────────────────────┘

  ↓
  ┌─────────────────────────────────────────────────┐
  │ QA MODE                                         │
  │ marketplace: data:data-validation,              │
  │              customer-support:ticket-triage     │
  │ scope: every AC from 01-brief.md                │
  │ output: § QA report                             │
  │ resolution: fail AC → loop back to execute or   │
  │             surface to Timm if fundamental      │
  └─────────────────────────────────────────────────┘

  ↓ conditional gates (DEFERRED IN v0.1.0)

  ┌─────────────────────────────────────────────────┐
  │ LEGAL MODE (if regulated=true OR escalated)     │
  │ DEFERRED in v0.1.0                              │
  │ v0.1.0 behavior: write "N/A — wrapper deferred  │
  │   (regulated=<flag>)" + preserve escalation     │
  │   text so Ship flags to Timm.                   │
  │ future: marketplace: legal:compliance,          │
  │         legal:legal-risk-assessment,            │
  │         legal:compliance-check,                 │
  │         legal:contract-review (if DPA)          │
  │ future scope: regulated surfaces in diff        │
  │ future output: § Legal findings                 │
  │ future: BLOCKING — no preview until criticals   │
  │         resolved or risk-accepted.              │
  └─────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────┐
  │ MARKETING MODE (if customer_facing_launch=true) │
  │ DEFERRED in v0.1.0                              │
  │ v0.1.0 behavior: write "N/A — wrapper deferred  │
  │   (cfl=true)" — Ship authors copy manually.     │
  │ future: marketplace: marketing:content-creation,│
  │         marketing:brand-voice,                  │
  │         brand-voice:brand-voice-enforcement     │
  │ future scope: feature surface as shipped        │
  │ future output: § Marketing draft                │
  │ future: PARALLEL, NON-BLOCKING during QA.       │
  └─────────────────────────────────────────────────┘

  ↓ all non-blocking checks clean

PREVIEW DEPLOY
  trigger: vercel MCP (or project-specific hook)
  verify: get_deployment → state: READY
  capture: URL into § Preview URL

CLOSE
  write 03-build-notes.md (all sections)
  update 00-manifest.md (Build row → done)
  run check-build-notes.sh → must be green
  surface preview URL to Timm
```

## Mode invocation — how

The built-in modes (`review`, `security-review`) are invoked via their slash-commands in Claude Code. Use the command, capture the output, paste/summarize into the named section of `03-build-notes.md`. Do not expect the built-in to write the file itself.

Marketplace mode skills (e.g., `design:accessibility-review`) are invoked as skills. Capture their output and land it in the named section. If a skill produces long output, keep the summary in the build-notes section and link or reference the full output.

## Mode scope rules

- **Code-opt:** scope = diff at first-major-component checkpoint (not full feature yet).
- **Security:** scope = full feature diff, after all tasks complete.
- **A11y, UX polish:** scope = UI surface in full diff. Skip if no UI touched.
- **QA:** scope = every AC from brief, mapped to tests + manual checks.
- **Legal (deferred):** scope = regulated surfaces in full diff, plus any escalation from Security.
- **Marketing (deferred):** scope = feature surface as it will ship.

## When to skip a mode

Only skip:

- **Accessibility / UX polish** — if no UI was touched. Write `N/A — no UI surface in this feature's diff.` in the section.
- **Legal** — always skip in v0.1.0 (deferred). Write `N/A — wrapper deferred` per the rules in `build-notes-template.md`.
- **Marketing** — always skip in v0.1.0 (deferred). Same treatment.

Do **not** skip Code-opt, Security, or QA. Those run on every feature. If the diff is tiny, run them anyway — the sections become short, not absent.

## Escalation — what surfaces to Timm mid-session

Only these three cases:

1. **Critical security finding** that can't be fixed without a design decision, or **Legal/regulated concern** that can't be deferred to Ship.
2. **AC unmeetable as written.**
3. **Material plan drift** — the codebase has changed since the plan such that execution can't proceed as planned.

Everything else stays internal. Fix, note, continue.

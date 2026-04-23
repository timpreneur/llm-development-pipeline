# NN-<session>.md — template

Every session artifact (`01-brief.md`, `02-plan.md`, `03-build-notes.md`, `04-ship.md`, `05-research.md`) opens with the same YAML frontmatter. Body shape varies by session.

## Frontmatter contract

```yaml
---
session: <01-ideate|02-plan|03-build|04-ship|05-research>
feature_id: <YYYY-MM-DD-slug>     # same as the feature dir name
project: <project>                # primary project
owner: <timm|cc|auto>             # who ran this session
status: <in_progress|done|blocked|skipped>
inputs: [<filenames of prior artifacts this session read>]
updated: <YYYY-MM-DD>             # ISO date
regulated: <true|false>           # frontmatter flag from brief; copied forward each session
customer_facing_launch: <true|false>  # ditto
---
```

Rules:

- `session` matches the filename's `NN-<name>` prefix. If they disagree, the filename wins and the session field is a bug.
- `feature_id` must equal the feature dir name.
- `project` is the primary project (even for multi-repo features).
- `inputs` lists the prior artifacts *actually read* in this session — not merely available. Used by LLM Ops to spot re-entry patterns.
- `updated` is a date, not a timestamp. Multiple updates on the same day don't change the value.
- `regulated` and `customer_facing_launch` copy forward from `01-brief.md`. If Security mode flips `regulated` to `true` mid-Build (per the escalation contract), that change propagates forward and also updates `01-brief.md` in place.

## Session-specific body shape

Each session owns its own body shape. Substrate doesn't dictate the content — only the frontmatter. The sections each session must produce are specified in that session's own SKILL.md. For quick reference:

| Session | Required body sections |
|---------|------------------------|
| `01-ideate` | Vision · Pressure-test (≥2 alternatives) · Scope / in-out · Acceptance criteria (observable) · Decisions needed · Non-goals · Context · Flags rationale |
| `02-plan` | Task list (ordered) · Files touched per task · Reuse anchors · Risks · Side-effects · Test strategy · Rollback strategy · Verification log (grep evidence) · Open questions |
| `03-build` | Commit range · AC status · Code-opt findings · Security findings · Accessibility findings · UX findings · QA report · Legal findings (or "N/A: <reason>") · Marketing draft (or "N/A: <reason>") · Lessons captured |
| `04-ship` | Preflight · Deploy URL + verified state · Smoke evidence · Migrations · Rollback plan · Release notes (internal + customer-facing) · Observability wiring · Watch window task ID · Promotion status |
| `05-research` | Per-feature analysis (adoption, pain, unmet, surprise) · Cohort themes · Candidate list (ranked, evidence-cited) · Inbox seeds dropped |

"N/A: <reason>" is acceptable and expected for conditional sections. What's *not* acceptable is silently omitting a required section — the manifest can't tell "skipped" from "forgotten."

## Flag decision tree (for `01-brief.md`'s setters)

Decide during Ideate, carry forward through every session:

**`regulated: true`** if any of:
- Handles PII beyond name + email (SSN, DOB, financial, health).
- Processes payments directly (not just a link to Stripe checkout that we don't see).
- Subject to region-specific regulation (GDPR DSAR workflows, CCPA, HIPAA, PCI, etc.).
- Contract / DPA / vendor review is in scope.
- Triggers an internal policy review (e.g., anything that emails customers in bulk is on the edge — check with Timm).

**`regulated: false`** is the default. When unsure, default to `false` in Ideate; Security mode auto-flips to `true` during Build if it detects regulated-surface patterns in the diff, and that flip propagates back to `01-brief.md`.

**`customer_facing_launch: true`** if any of:
- End users will see the feature (new UI surface, new user-visible behavior, onboarding step).
- Marketing / comms plan is expected (release note on blog, email to list, social).
- It's a renamed / repositioned feature that will prompt customer questions.

**`customer_facing_launch: false`** if:
- Internal tool only (admin dashboard, ops workflow, internal Slack bot).
- Silent infra change (migrations, perf, security patches that don't alter UX).
- Bug fix with no user-visible repositioning.

## Example — `01-brief.md` frontmatter

```yaml
---
session: 01-ideate
feature_id: 2026-04-19-sample-feature
project: example-fixture
owner: timm
status: done
inputs: []
updated: 2026-04-19
regulated: false
customer_facing_launch: true
---
```

## Example — `03-build-notes.md` frontmatter (inputs non-empty)

```yaml
---
session: 03-build
feature_id: 2026-04-19-sample-feature
project: example-fixture
owner: cc
status: in_progress
inputs: [00-manifest.md, 01-brief.md, 02-plan.md]
updated: 2026-04-19
regulated: false
customer_facing_launch: true
---
```

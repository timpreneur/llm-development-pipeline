# Close checklist — dev-pipeline-plan

Run through this **only after Timm explicitly approves the plan in-session.**

## Step 1 — ExitPlanMode writes `02-plan.md`

Per Claude Code plan-mode semantics, the only writable exit is `ExitPlanMode`. Compose the full `02-plan.md` in-session, then exit plan mode with the final content.

File path: `<FEATURE_DIR>/02-plan.md`.

## Step 2 — Update manifest

Edit `<FEATURE_DIR>/00-manifest.md`. Plan row:

| Session  | Status | Owner | Updated     | Artifact    |
|----------|--------|-------|-------------|-------------|
| 02-plan  | done   | cc    | YYYY-MM-DD  | 02-plan.md  |

Aggregate status (per substrate rule): stays `in_progress` because Build/Ship/Research rows are still `pending`.

## Step 3 — Run the validator

```bash
bash skills/dev-pipeline-plan/scripts/check-plan.sh <FEATURE_DIR>/02-plan.md
```

- Exit 0 → continue.
- Non-zero (RED) → re-enter plan mode, fix the flagged section(s), re-run ExitPlanMode.

## Step 4 — Confirm handoff to Build

Tell Timm verbatim:

> "Plan approved. `02-plan.md` at `<FEATURE_DIR>`. Next: open a **NEW** Claude Code session on `<PROJECT>` in **execution mode** (not plan mode). Paste `dev-pipeline-build/startup-prompt.md` with `<FEATURE_ID>` = `<actual>` and `<FEATURE_DIR>` = `<actual>`. Build is a new session — context does not carry over, Build re-reads manifest/brief/plan."

The "NEW session" emphasis matters — Plan and Build are deliberately separated so Build doesn't inherit planning context or tool history.

## Step 5 — Lessons check (silent)

Did a pattern surface? If yes, append to `lessons.md`. If no, skip.

## Guardrail summary

The validator (`scripts/check-plan.sh`) enforces:

| Check | Enforced by |
|-------|-------------|
| Frontmatter has `session: 02-plan` | regex |
| Frontmatter has all 9 required fields | field-by-field grep |
| Frontmatter `regulated` / `customer_facing_launch` are boolean (copied from brief) | regex |
| Body has H1 | grep |
| Body has `## Summary` | grep |
| Body has `## Task list` | grep |
| Body has `## Files touched` | grep |
| Body has `## Reuse anchors` | grep |
| Body has `## Risk callouts` | grep |
| Body has `## Side-effects` | grep |
| Body has `## Test strategy` | grep |
| Body has `## Verification` | grep |
| `## Verification` has at least 1 non-template row | content presence check (not just the heading) |
| Body has `## Rollback` | grep |
| Body has `## Open questions` | grep |

Yellow (warnings, not blocking):
- Verification row count < 3 → "plan may be under-researched"
- Task list has < 2 tasks → "feature may be too small to need a plan"
- `## Rollback` body is empty (not "N/A — …") → "rollback section must be filled or explicitly marked N/A with reason"

# pipeline-ship — close checklist

Run this before surfacing to Timm. No shortcuts. This is touchpoint #4.

## Checklist

1. Every H2 in `references/ship-template.md` is present and non-empty in `04-ship.md`. Empty sections must be `N/A — <reason>`, not omitted.
2. Frontmatter complete:
   - `session: 04-ship`
   - `feature_id`, `project`, `owner: timm`
   - `status: ready-for-signoff` (NOT `shipped` — Timm flips that)
   - `inputs: [00-manifest.md, 01-brief.md, 02-plan.md, 03-build-notes.md]`
   - `regulated`, `customer_facing_launch` copied from brief (must be literal `true` / `false`)
   - `deploy_url` set
   - `deploy_state: READY`
   - `watch_window_task_id` set
3. Deploy state is `READY` via the platform MCP — not just "pushed to main". The verification call + response snippet is in the `## Deploy` section.
4. Production smoke has both a read and a write path recorded, with timestamps. Evidence, not "LGTM".
5. Observability: critical path listed, correlation ID field named, named metrics with dimensions, ≥1 alert with a named route, dashboard URL recorded.
6. Watch window: `task_id` returned from `schedule` skill, `cohort_id`, `opens_at`, `closes_at` all recorded. No task_id = stop, surface to Timm.
7. Rollback plan present with trigger, steps, ETA, owner. Not aspirational — actual commands / MCP calls.
8. Release notes: internal draft present. Customer-facing draft present per brief's `customer_facing_launch` flag (manually authored in v0.1.0 if Build's Marketing wrapper is deferred, and noted as such).
9. Promotion: both fields addressed (either action taken + recorded, or `N/A — not declared`).
10. Manifest updated: `04-ship: ready-for-signoff`, deploy URL, dashboard URL, watch-window task_id recorded.
11. `bash scripts/check-ship.sh <FEATURE_DIR>/04-ship.md` — no RED.

## Surface-to-Timm message (verbatim template)

```
✅ 04-ship.md ready for sign-off — touchpoint #4.

Feature: <feature_id>
Project: <project>

**Deployed.**
- Prod URL: <deploy_url>
- Deploy state: READY (verified via <platform MCP> at <timestamp>)
- Smoke: read + write paths green at <timestamp>

**Observability wired.**
- Critical path: <N> steps, correlation ID `<field>`
- Metrics: <count> named with dimensions
- Alerts: <count>, routed to <routes>
- Dashboard: <url>

**Watch window.**
- Scheduled: <task_id> — cohort `<cohort_id>`
- Opens: <opens_at> / Closes: <closes_at>
- Length: <N> days (<reason if not default>)

**Release notes.**
- Internal: drafted.
- Customer-facing: <drafted (voice-checked) | drafted (manual, v0.1.0 — Build's Marketing wrapper deferred) | N/A — not a customer-facing launch>

**Promotion.**
- Brief: <copied to <path> | N/A — not declared>
- Changelog: <appended to <path> | N/A — not declared>

**Rollback.** Trigger, steps, ETA, owner captured in § Rollback.

Artifact: <FEATURE_DIR>/04-ship.md

Reply "signed off" to flip manifest + 04-ship.md to `shipped`.
Reply with changes and I'll cycle before closing.

[if regulated=true: append] ⚠ Regulated surface — preserved escalation text in build-notes; no Legal wrapper in v0.1.0.
[if customer_facing_launch=true and manual draft: append] ⚠ Customer-facing copy authored manually in v0.1.0 (Build Marketing wrapper deferred). Read the customer-facing note before signing off.
```

## Post-sign-off (after Timm replies "signed off" / "approved")

1. Flip `04-ship: shipped` in `00-manifest.md`.
2. Flip `status: shipped` in `04-ship.md` frontmatter.
3. If any notable pattern surfaced during this ship (deploy-state check failure, dashboard gap, release-note thrash, etc.), append to `lessons.md` with phase tag.

## Post-sign-off (after Timm replies with changes)

Cycle. Address changes, re-run `check-ship.sh`, re-surface with the updated verbatim message. Do not flip `shipped` until explicit sign-off.

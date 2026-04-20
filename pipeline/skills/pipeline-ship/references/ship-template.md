# 04-ship.md — template

Canonical shape for Ship session output. Every H2 must be present. Empty sections must be `N/A — <reason>`. Never silently omit.

```markdown
---
session: 04-ship
feature_id: YYYY-MM-DD-slug
project: <project-name>
owner: timm
status: ready-for-signoff   # flip to `shipped` only after Timm signs off
inputs: [00-manifest.md, 01-brief.md, 02-plan.md, 03-build-notes.md]
updated: YYYY-MM-DD
regulated: false
customer_facing_launch: false
deploy_url: https://...
deploy_state: READY
watch_window_task_id: <schedule-task-id>
---

# 04-ship — <feature title>

## Preflight

- build-notes check: PASS (`check-build-notes.sh` — no RED)
- AC coverage: <N>/<N> AC rows present and PASS
- security/legal criticals: <resolved | risk-accepted with Timm sign-off in build-notes | N/A>
- preview URL (pre-deploy): <url> state=READY, re-verified at YYYY-MM-DDTHH:MMZ
- env parity: dev → staging → prod consistent with <PROJECT>/CLAUDE.md

## Migrations

| name | env | status | timestamp |
|------|-----|--------|-----------|
| <name> | prod | applied | YYYY-MM-DDTHH:MMZ |

(If none: `None — no schema changes in this feature.`)

## Deploy

- Platform: <Vercel | other>
- Command/MCP call: <`deploy_to_vercel(...)` or equivalent>
- Deploy URL: <url>
- State verification: `get_deployment(<id>) → state: READY` at YYYY-MM-DDTHH:MMZ
- Response snippet:
  ```json
  { "state": "READY", "url": "...", "readyState": "READY" }
  ```

## Smoke

- Read path: <endpoint> → <status> at YYYY-MM-DDTHH:MMZ — <1-line observation>
- Write path: <endpoint> → <status> at YYYY-MM-DDTHH:MMZ — <1-line observation>
- Additional checks: <…>

## Observability

**Critical path.** (1–5 steps)

1. <step> — log field: `<correlation_id_field>`
2. <step> — …

**Metrics.**

| metric | dimensions |
|--------|------------|
| `share_links.create.latency_ms` | `workspace_id`, `region` |
| `share_links.view.success_rate` | `region` |

**Alerts.**

| alert | condition | route |
|-------|-----------|-------|
| `share_links_view_failure` | `success_rate < 0.95 for 10m` | `#product-ops-alerts` (Slack) |

**Dashboard.** <dashboard URL> (built via `data:interactive-dashboard-builder`)

## Watch window

- task_id: `<schedule-task-id>`
- cohort_id: `YYYY-Www` (or `YYYY-MM`)
- opens_at: YYYY-MM-DDTHH:MMZ
- closes_at: YYYY-MM-DDTHH:MMZ
- length: 14 days (default) — or note tuned length + reason

## Rollback

- Trigger: <the observation that flips the decision>
- Steps:
  1. <concrete command or MCP call>
  2. <…>
- ETA: <minutes>
- Owner: Timm (or as declared in project CLAUDE.md)

## Release notes

**Internal.**

<internal release note — what changed, what to watch, links to dashboard + build-notes>

**Customer-facing.**

<one of:
 - Voice-checked draft derived from 03-build-notes.md § Marketing draft.
 - Manually authored draft for v0.1.0 because Build's Marketing wrapper is deferred.
 - `N/A — not a customer-facing launch.` (iff customer_facing_launch=false)>

Voice-check: <PASS | ADVISORY-ONLY-v0.1.0 | N/A>. Source skill: `brand-voice:brand-voice-enforcement`.

## Promotion

- `pipeline.repo_brief_dir`: <declared path | not declared>
  - Action: <copied 01-brief.md to <dest> | N/A — not declared>
- `pipeline.changelog_path`: <declared path | not declared>
  - Action: <appended "YYYY-MM-DD — <feature_id> — <one-line>" to <dest> | N/A — not declared>
- Failures: <N/A | surfaced to Timm>

## Sign-off

Surfaced to Timm at YYYY-MM-DDTHH:MMZ. Awaiting reply.

(After sign-off, Ship flips manifest `04-ship: shipped` and this file's `status: shipped`.)
```

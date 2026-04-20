---
session: 04-ship
feature_id: 2026-04-19-bad-example-missing-sections
project: example-fixture
owner: timm
status: ready-for-signoff
inputs: [00-manifest.md, 01-brief.md, 02-plan.md, 03-build-notes.md]
updated: 2026-04-19
regulated: false
customer_facing_launch: false
deploy_url: https://fixture-missing.example
deploy_state: READY
watch_window_task_id: sched_fixture_missing
---

# 04-ship — Bad Example (Missing Sections)

Intentionally omits `## Rollback`, `## Promotion`, and `## Sign-off` — exercises missing-H2 reject path.

## Preflight

- build-notes check: PASS
- AC coverage: 1/1

## Migrations

None.

## Deploy

- Deploy URL: https://fixture-missing.example
- State: READY (verified via platform MCP — fixture placeholder)

## Smoke

- Read path: GET /api/health → 200 OK at 2026-04-19T18:10Z
- Write path: POST /api/noop → 204 No Content at 2026-04-19T18:11Z

## Observability

**Critical path.** 1 step — request. log field: `request_id`.

**Metrics.**

| metric | dimensions |
|--------|------------|
| `fixture.latency_ms` | `region` |

**Alerts.**

| alert | condition | route |
|-------|-----------|-------|
| `fixture_alert` | `latency p95 > 1000` | `#fixture` |

**Dashboard.** https://datadog.example/dashboards/fixture

## Watch window

- task_id: `sched_fixture_missing`
- cohort_id: `2026-W18`
- opens_at: 2026-04-19T18:11Z
- closes_at: 2026-05-03T18:11Z
- length: 14 days (default)

## Release notes

**Internal.** Fixture placeholder.

**Customer-facing.** N/A — not a customer-facing launch.

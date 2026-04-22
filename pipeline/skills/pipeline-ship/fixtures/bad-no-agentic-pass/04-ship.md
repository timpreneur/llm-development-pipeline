---
session: 04-ship
feature_id: 2026-04-19-bad-no-agentic-pass
project: sifly-fixture
owner: timm
status: ready-for-signoff
inputs: [00-manifest.md, 01-brief.md, 02-plan.md, 03-build-notes.md]
updated: 2026-04-19
regulated: false
customer_facing_launch: false
deploy_url: https://fixture-no-agentic.example
deploy_state: READY
punchlist_blocking_open: 0
punchlist_url: https://ship-punchlist-web.vercel.app/timpreneur/sifly-fixture/feature/2026-04-19-bad-no-agentic-pass
watch_window_task_id: sched_fixture_no_agentic
---

# 04-ship — Bad Example (No Agentic QA)

Intentionally fails:
 - `## Agentic QA` section is absent
 - frontmatter missing `agentic_qa_coverage_pct`
 - `## Punchlist` section is absent
 - sibling `04-punchlist.json` is absent

## Preflight

- build-notes check: PASS
- AC coverage: 1/1

## Migrations

None.

## Deploy

- Deploy URL: https://fixture-no-agentic.example
- State: READY (verified via platform MCP at 2026-04-19T18:20Z)

## Smoke

- Read path: GET /api/health → 200 OK at 2026-04-19T18:22Z
- Write path: POST /api/noop → 204 No Content at 2026-04-19T18:23Z

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

- task_id: `sched_fixture_no_agentic`
- cohort_id: `2026-W18`
- opens_at: 2026-04-19T18:23Z
- closes_at: 2026-05-03T18:23Z
- length: 14 days (default)

## Rollback

- Trigger: error rate > 5% for 10m
- Steps:
  1. Redeploy previous build.
- ETA: 5 minutes
- Owner: Timm

## Release notes

**Internal.** Fixture placeholder.

**Customer-facing.** N/A — not a customer-facing launch.

## Promotion

- `pipeline.repo_brief_dir`: not declared. N/A.
- `pipeline.changelog_path`: not declared. N/A.
- `pipeline.punchlist_dir` (default `.punchlist/`): mirror + V1 pointer not written because no punchlist exists — fixture exercises this reject path.

## Sign-off

Surfaced at 2026-04-19T18:24Z (fixture).

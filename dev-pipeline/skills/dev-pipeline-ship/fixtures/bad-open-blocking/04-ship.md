---
session: 04-ship
feature_id: 2026-04-19-bad-open-blocking
project: sifly-fixture
owner: timm
status: ready-for-signoff
inputs: [00-manifest.md, 01-brief.md, 02-plan.md, 03-build-notes.md]
updated: 2026-04-19
regulated: false
customer_facing_launch: false
deploy_url: https://fixture-open-blocking.example
deploy_state: READY
agentic_qa_coverage_pct: 100
punchlist_blocking_open: 0
punchlist_url: https://ship-punchlist-web.vercel.app/timpreneur/sifly-fixture/feature/2026-04-19-bad-open-blocking
watch_window_task_id: sched_fixture_open_blocking
---

# 04-ship — Bad Example (Open Blocking Finding in Agentic Pass)

The ship.md itself is structurally valid. The sibling `04-punchlist.json`
contains `agentic_pass.findings[]` with severity=blocking AND status=open —
a contract break (Phase 3 should have paused). `check-punchlist.sh` must
catch this and `check-ship.sh` must bubble it up as RED.

## Preflight

- build-notes check: PASS
- AC coverage: 1/1

## Migrations

None.

## Deploy

- Deploy URL: https://fixture-open-blocking.example
- State: READY (verified via platform MCP at 2026-04-19T18:30Z)

## Smoke

- Read path: GET /api/health → 200 OK at 2026-04-19T18:32Z
- Write path: POST /api/noop → 204 No Content at 2026-04-19T18:33Z

## Agentic QA

Completed at: 2026-04-19T18:34Z
Autonomous coverage: 100% (1/1 AC verified)

**Checks run.**

- `chrome_navigate`, `console`, `network`, `http_smoke`

**AC coverage.**

| AC id | text | verification | status | evidence / reason |
|-------|------|--------------|--------|-------------------|
| AC1 | Endpoint returns 200 | `http_smoke` | verified | GET /api/health → 200 |

**Findings.**

| id | severity | source | text | status |
|----|----------|--------|------|--------|
| auto-1 | blocking | console | Uncaught TypeError on /admin/dashboard | open |

(Fixture intentionally records an open blocking finding in the JSON — ship.md itself still passes section-structural checks.)

## Punchlist

- Source of truth: `<FEATURE_DIR>/04-punchlist.json`
- Repo mirror: `<project-repo>/.punchlist/2026-04-19-bad-open-blocking.json`
- V1 pointer: `<project-repo>/.punchlist/aaaaaaa.json` → `{"schema_version":"2","ref":"2026-04-19-bad-open-blocking.json"}`
- Web app: https://ship-punchlist-web.vercel.app/timpreneur/sifly-fixture/feature/2026-04-19-bad-open-blocking
- Summary: **0 blocking, 0 watch** (but the agentic pass has an open blocking finding — see JSON)
- Schema check: `bash scripts/check-punchlist.sh <FEATURE_DIR>/04-punchlist.json` → EXPECTED FAIL
- Gating: `pipeline.punchlist_gating=strict`

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

- task_id: `sched_fixture_open_blocking`
- cohort_id: `2026-W18`
- opens_at: 2026-04-19T18:33Z
- closes_at: 2026-05-03T18:33Z
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
- `pipeline.punchlist_dir` (default `.punchlist/`): `.punchlist/`
  - Mirror: would copy to `<project-repo>/.punchlist/2026-04-19-bad-open-blocking.json`
  - V1 pointer: would write `<project-repo>/.punchlist/aaaaaaa.json`

## Sign-off

Surfaced at 2026-04-19T18:35Z (fixture).

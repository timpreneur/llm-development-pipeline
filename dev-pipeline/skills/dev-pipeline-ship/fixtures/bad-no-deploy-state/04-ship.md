---
session: 04-ship
feature_id: 2026-04-19-bad-example-no-deploy-state
project: sifly-fixture
owner: timm
status: ready-for-signoff
inputs: [00-manifest.md, 01-brief.md, 02-plan.md, 03-build-notes.md]
updated: 2026-04-19
regulated: false
customer_facing_launch: false
deploy_url: https://fixture-no-state.example
deploy_state: BUILDING
watch_window_task_id:
---

# 04-ship — Bad Example (No Deploy State READY)

Intentionally fails:
 - `deploy_state: BUILDING` (not READY)
 - empty `watch_window_task_id`
 - `## Deploy` section omits `READY` and platform MCP verification
 - `## Observability` section is empty
 - `## Watch window` section is empty (no task_id, no cohort_id)

## Preflight

- build-notes check: PASS (placeholder)
- env parity: assumed
- AC coverage: 1/1

## Migrations

None — no schema changes.

## Deploy

Deploy ran. URL: https://fixture-no-state.example

(Intentionally no platform-MCP state-verification block — exercises the missing-READY reject path.)

## Smoke

- Read path: GET /api/health → 200 OK at 2026-04-19T18:00Z

## Observability

(Intentionally empty.)

## Watch window

(Intentionally empty — no task_id, no cohort_id.)

## Rollback

- Trigger: error rate > 5% for 10m
- Steps:
  1. Redeploy previous build.
- ETA: 5 minutes
- Owner: Timm

## Release notes

**Internal.**

Test feature; placeholder.

**Customer-facing.**

N/A — not a customer-facing launch.

## Promotion

- `pipeline.repo_brief_dir`: not declared. N/A.
- `pipeline.changelog_path`: not declared. N/A.

## Sign-off

Surfaced at 2026-04-19T18:01Z (fixture).

---
session: 04-ship
feature_id: 2026-04-19-sample-feature
project: example-fixture
owner: timm
status: in_progress
inputs: [00-manifest.md, 01-brief.md, 02-plan.md, 03-build-notes.md]
updated: 2026-04-19
regulated: false
customer_facing_launch: true
---

# 04-ship — Sample Feature

Fixture ship artifact. Ship session would write this; the fixture stubs all required sections. Intentionally `in_progress` to exercise the aggregate-status rule (manifest status = `in_progress` because this row is).

## Preflight
- Build green: ✓ (fixture).
- AC pass: ✓ (fixture).
- No unresolved critical findings: ✓.
- Preview healthy: ✓ (fixture placeholder URL).

## Deploy URL + verified state
N/A — fixture. Real Ship requires platform MCP verification (e.g., `vercel get_deployment` returns `state: READY`).

## Smoke evidence
N/A — fixture.

## Migrations
None (fixture).

## Rollback plan
- Trigger: N/A (fixture).
- Steps: N/A.
- Estimated time: N/A.

## Release notes
### Internal
Fixture — would summarize 03-build-notes.md here.

### Customer-facing
N/A — Marketing wrapper deferred; customer-facing notes would be authored in the real implementation.

## Observability wiring
- Metrics: N/A (fixture).
- Alert route: N/A (fixture).
- Dashboard link: N/A (fixture).

## Watch window
- Task ID: N/A (fixture — `schedule` skill not invoked).
- Duration: 14 days (default).

## Promotion status
- `pipeline.repo_brief_dir`: not declared in fixture project CLAUDE.md → N/A.
- `pipeline.changelog_path`: not declared → N/A.

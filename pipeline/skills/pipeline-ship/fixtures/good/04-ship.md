---
session: 04-ship
feature_id: 2026-04-19-document-share-link
project: example-fixture
owner: timm
status: ready-for-signoff
inputs: [00-manifest.md, 01-brief.md, 02-plan.md, 03-build-notes.md]
updated: 2026-04-19
regulated: false
customer_facing_launch: true
deploy_url: https://example-fixture.vercel.app
deploy_state: READY
watch_window_task_id: sched_2026-04-19_sharelink_watch
---

# 04-ship — Document Share Link

## Preflight

- build-notes check: PASS (`check-build-notes.sh` — 0 RED, 0 YELLOW)
- AC coverage: 5/5 AC rows present and PASS
- security/legal criticals: resolved (rate-limit on public route in commit 5c1d80; no Legal trigger)
- preview URL (pre-deploy): https://example-fixture-git-feature-document-share-link-example.vercel.app state=READY, re-verified at 2026-04-19T17:42Z via Vercel `get_deployment`
- env parity: dev → staging → prod consistent with example-fixture/CLAUDE.md (Vercel + Postgres, separate prod project, RLS verified)

## Migrations

| name | env | status | timestamp |
|------|-----|--------|-----------|
| 0042_share_links_table | prod | applied | 2026-04-19T17:48Z |
| 0043_share_links_token_idx | prod | applied | 2026-04-19T17:49Z |

## Deploy

- Platform: Vercel
- Command/MCP call: `deploy_to_vercel(project=example-fixture, branch=main, target=production)`
- Deploy URL: https://example-fixture.vercel.app
- State verification: `get_deployment(dpl_8h2k3) → state: READY` at 2026-04-19T17:54Z
- Response snippet:
  ```json
  { "state": "READY", "url": "example-fixture.vercel.app", "readyState": "READY", "createdAt": 1745081640000 }
  ```

## Smoke

- Read path: GET /api/docs/doc_fixture_1/share-links (auth: owner-fixture-1) → 200 OK at 2026-04-19T17:56Z — ShareLinks panel renders with empty-state CTA, latency 142ms
- Write path: POST /api/docs/doc_fixture_1/share-links { expires_in_days: 14 } → 201 Created at 2026-04-19T17:57Z — link token issued, webhook registered, latency 311ms
- Cleanup: smoke link revoked via DELETE /api/share-links/<id> at 2026-04-19T17:58Z

## Observability

**Critical path.**

1. Owner hits doc page → `share_links.panel.render` — log field: `request_id`
2. Owner creates link → `share_links.create` — log field: `request_id`, `owner_id`, `doc_id`
3. Recipient opens link → `share_links.resolve` — log field: `request_id`, `link_token_jti`
4. First-view webhook flips status → `share_links.viewed` — log field: `link_token_jti`

**Metrics.**

| metric | dimensions |
|--------|------------|
| `share_links.create.latency_ms` | `owner_id`, `region` |
| `share_links.create.success_rate` | `region` |
| `share_links.resolve.success_rate` | `region` |
| `share_links.resolve.expired_token_rate` | `region` |

**Alerts.**

| alert | condition | route |
|-------|-----------|-------|
| `share_links_resolve_failure` | `resolve.success_rate < 0.95 for 10m` | `#product-ops-alerts` (Slack) |
| `share_links_create_latency_high` | `p95(create.latency_ms) > 1500 for 15m` | `#product-ops-alerts` (Slack) |

**Dashboard.** https://datadog.example/dashboards/share-links-v1 (built via `data:interactive-dashboard-builder`, mirrored to Datadog)

## Watch window

- task_id: `sched_2026-04-19_sharelink_watch`
- cohort_id: `2026-W18`
- opens_at: 2026-04-19T17:54Z
- closes_at: 2026-05-03T17:54Z
- length: 14 days (reason: default — non-regulated, low-risk customer-facing launch)

## Rollback

- Trigger: `share_links_resolve_failure` alert fires for >20m AND error logs show non-rate-limit cause; OR migration 0042 integrity check fails.
- Steps:
  1. `deploy_to_vercel(project=example-fixture, target=production, redeploy_id=<previous-prod-dpl-id>)` — promote previous deployment.
  2. Disable Share button via `feature_flag.set(share_links_create_enabled=false)` — keep resolve route live so in-flight links complete.
  3. If migration-rooted: run `0044_revert_share_links_token_idx` then `0045_revert_share_links_table`. (Both pre-staged.)
- ETA: 8 minutes (steps 1+2); +12 minutes if migrations also revert.
- Owner: Timm.

## Release notes

**Internal.**

Document share links shipped. Owners can now generate a 14-day public link from the doc page (Share button + ShareLinks panel). Recipients hit `/s/<token>` and see a read-only render. Rate-limited at 60 resolves/min/IP. Watch the `share_links_resolve_failure` alert for the next 14 days. Build notes: `<FEATURE_DIR>/03-build-notes.md`. Dashboard: https://datadog.example/dashboards/share-links-v1.

**Customer-facing.**

You can now generate a share link for any document. Open the doc, hit Share, and copy the link. It's good for 14 days. Anyone with the link can view the doc read-only — no account required.

Voice-check: ADVISORY-ONLY-v0.1.0 (manually authored; Build's Marketing wrapper is deferred in v0.1.0). Source skill: `brand-voice:brand-voice-enforcement` — pass on tone, neutral on length.

## Promotion

- `pipeline.repo_brief_dir`: `docs/briefs/archive/`
  - Action: copied 01-brief.md to `docs/briefs/archive/2026-04-19-document-share-link.md`
- `pipeline.changelog_path`: `CHANGELOG.md`
  - Action: appended `2026-04-19 — 2026-04-19-document-share-link — Owners can now generate 14-day read-only share links for documents (rate-limited resolve).` to `CHANGELOG.md`
- Failures: N/A

## Sign-off

Surfaced to Timm at 2026-04-19T18:02Z. Awaiting reply.

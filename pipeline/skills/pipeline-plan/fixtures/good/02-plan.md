---
session: 02-plan
feature_id: 2026-04-19-document-share-link
project: example-fixture
owner: cc
status: done
inputs: [00-manifest.md, 01-brief.md, example-fixture/CLAUDE.md]
updated: 2026-04-19
regulated: false
customer_facing_launch: true
---

# 02-plan — Document Share Link

## Summary

Document share links reuse the existing token-signing helper and public-route handler. New DB table `share_links`, one new endpoint pair (create + resolve), one new public page (`/s/<token>`), and a new ShareLinks panel on the document page. No net-new libraries. Risk concentrated in the token-signing reuse and the public route's rate-limit posture.

## Task list

1. Add `share_links` table + migration.
2. Implement link-create endpoint + token signing (reuse auth helper).
3. Wire `/s/<token>` public route with read-only document render.
4. Build ShareLinks panel on document page with create button + status list.
5. Add active / viewed / expired status badges to link list.
6. Instrument first-view webhook that flips status to "viewed".
7. Seed tests covering AC 1–5.

## Files touched

Task 1:
- create: packages/db/migrations/20260419_share_links.sql
- modify: packages/db/prisma/schema.prisma
- modify: packages/db/src/index.ts (export new model)

Task 2:
- create: apps/api/src/routes/share-links.ts
- modify: apps/api/src/routes/index.ts

Task 3:
- create: apps/web/src/routes/s/[token].tsx
- modify: apps/web/src/middleware/public-routes.ts (register new route)

Task 4:
- modify: apps/web/src/routes/docs/[id].tsx
- create: apps/web/src/components/share-links/ShareLinksPanel.tsx

Task 5:
- modify: apps/web/src/components/share-links/ShareLinksPanel.tsx

Task 6:
- modify: apps/api/src/routes/share-links.ts
- modify: packages/jobs/queues/share-link-events.ts

Task 7:
- create: apps/api/src/routes/__tests__/share-links.test.ts
- create: apps/web/src/routes/s/__tests__/[token].test.tsx

## Reuse anchors

- **Token signing:** `packages/auth/src/token.ts` `sign()` / `verify()` — use same signing secret class, not a new one.
- **Document render:** `apps/web/src/components/docs/DocRender.tsx` — reuse with `readOnly` prop.
- **Empty-state component:** `apps/web/src/components/common/EmptyState.tsx` — matches existing empty-state treatment.
- **Public-route middleware:** `apps/web/src/middleware/public-routes.ts` — existing allowlist; add `/s/*`.
- **Marketplace skills (invoked by Build):** `design:accessibility-review`, `design:design-critique`, `design:ux-writing` (empty-state copy), `data:data-validation` (AC verification).

## Risk callouts

- **Migration risk:** `share_links` is a new table; no backfill needed because no pre-existing link data. Low risk, but migration must run before first deploy.
- **Cross-package types:** `ShareLink` type used in both `apps/api` and `apps/web`. Declare in `packages/types/src/share-link.ts`, not per-package — Build must not inline.
- **Token signing secret reuse:** Reusing auth `SIGNING_SECRET` env var is fine for tokens that expire in 14 days. Do NOT introduce a second secret class; that fragments key rotation.
- **Public route posture:** `/s/<token>` bypasses auth middleware. Build must confirm public-route allowlist is explicit, not default-on, and rate-limit is set per-IP.
- **Tier-visibility cascade:** ShareLink is visible to: owner (own links), anyone with token (read-only render), admin (all). Confirm `tier-visibility` helper is applied — see Verification row 6.

## Side-effects

- Nav: add Share button to document header (`apps/web/src/components/docs/DocHeader.tsx`).
- Types: regenerate `packages/types` after schema change (`pnpm -w codegen`).
- Changelog: append to `CHANGELOG.md` under "Unreleased" during Build; Ship promotes to version block.
- Analytics: register `share_link_created`, `share_link_viewed`, `share_link_expired` events in `packages/analytics/src/events.ts`.
- Env: add `SHARE_LINK_TOKEN_EXPIRY_DAYS=14` to `.env.example` and deploy config.
- Docs: update `<project>/docs/features/sharing.md` with a Share Link subsection.

## Test strategy

Unit tests on `sign()`/`verify()` invocations for share-link tokens (reuse existing auth test harness). Integration tests on link-create endpoint (201 on valid doc, 404 on unknown doc, 403 on non-owner). E2E tests cover AC 1–5 each with one scenario. Manual preview-deploy pass for the ShareLinks panel empty-state, active/viewed/expired badges, and the public view page.

## Verification

| # | Looked for | Command / pattern | Result |
|---|------------|-------------------|--------|
| 1 | Existing public-route middleware | grep -r 'public-routes\|publicRoutes' apps/web/src/middleware/ | Found `apps/web/src/middleware/public-routes.ts` — existing allowlist, add `/s/*`. |
| 2 | Existing token signing helper | grep -r 'sign\|verify' packages/auth/src/ | Found `token.ts` exports `sign(payload, opts)` and `verify(token)` — reuse. |
| 3 | Document model | grep 'model Document' packages/db/prisma/schema.prisma | Found at line 298. Existing fields sufficient; new `share_links` table references doc via FK. |
| 4 | Document render component | grep -r 'DocRender\|<DocRender' apps/web/src/ | Found `DocRender.tsx`; accepts `readOnly` prop — reuse. |
| 5 | Document page Share placeholder | grep -r 'Share' apps/web/src/routes/docs/ | Not found. Task 4 adds Share button to DocHeader. |
| 6 | Tier-visibility helper | grep -r 'tierVisibility\|visibleTo' packages/auth/ | Found `packages/auth/src/visibility.ts`. Applied to existing entities; Build must apply to ShareLink. |
| 7 | Empty-state component | grep -r 'EmptyState' apps/web/src/components/common/ | Found `EmptyState.tsx` with headline + description + cta props. Reuse anchor. |
| 8 | Events registry | grep -r 'export.*Event' packages/analytics/src/events.ts | Found existing registry; add 3 new events per Side-effects. |
| 9 | Forbidden patterns (per CLAUDE.md pipeline.overrides) | grep -r 'direct-DB-from-client\|window\.fetch' apps/web/src/ | Not present in touched files. Safe. |
| 10 | Changelog path declared | grep 'pipeline.changelog_path' example-fixture/CLAUDE.md | Declared: `CHANGELOG.md`. Side-effects + Ship promotion will use it. |

## Rollback

Trigger: link creation or resolve flow causes user-visible errors, or doc content leaks to unauthorized viewers.

Steps:
1. Disable feature via flag `FEATURE_SHARE_LINKS_ENABLED=false` in deploy config (no redeploy required).
2. If DB integrity compromised, restore from pre-deploy snapshot (standard ops runbook).
3. Revert the deploy via `vercel rollback <deployment-id>`.

Estimated time: 5 minutes to disable via flag; 20 minutes for full rollback.

## Open questions

- [Timm] Decision from brief: does the share link carry recipient identity, or is it fully anonymous? — Still open. Defaulting to "fully anonymous" in this plan; Build will omit any recipient-email field from `share_links`.
- [Build-discover] Does the existing `EmptyState` component have a variant for "no-links-yet" vs "no-docs-shared"? Build should grep for existing variants before styling the empty state.

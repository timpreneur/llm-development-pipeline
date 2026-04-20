---
session: 03-build
feature_id: 2026-04-19-document-share-link
project: example-fixture
owner: cc
status: done
inputs: [00-manifest.md, 01-brief.md, 02-plan.md]
updated: 2026-04-19
regulated: false
customer_facing_launch: true
---

# 03-build-notes — Document Share Link

## Commit range

main..7f3a912e

## AC status

- AC 1: PASS — document header renders Share button on first load (e2e: `doc-share.e2e.test.ts::renders button`).
- AC 2: PASS — link-create returns 201 within 800ms, link returned in response (api-test: `share-links.test.ts::returns link`).
- AC 3: PASS — token verifies through 14-day window; expired token returns 410 (api-test: `share-links.test.ts::expiry`).
- AC 4: PASS — first-view webhook flips status within 60s (e2e: `share-link-view.e2e.test.ts::status-flip`).
- AC 5: PASS — expired link shows expired badge in owner panel (component test).

## Code-opt findings

- [low] `share-links.ts` had a redundant try/catch around the webhook dispatch — `enqueue` already swallows non-fatal errors. → fixed in commit 4a91c2.
- [info] Token-signing call shape duplicates the magic-link pattern; extracting a `signFeatureToken(audience, payload)` helper would simplify both. → noted in lessons.

## Security findings

- [medium] Public-route endpoint did not rate-limit by IP. Token validity does not constrain replay. → fixed in commit 5c1d80 (per-IP cap of 60/min on `/s/*` route).
- [low] Read-only render rendered doc title as raw HTML via i18n placeholder; no XSS path because titles are sanitized at write time, but adding explicit escape in template would harden. → fixed in commit 5c1d80.
- [info] No new dependencies added. Audit clean.

No regulated surface touched. Escalation flag not set.

## Accessibility findings

- [WCAG 2.4.7] Focus indicator on Share button was tied to default ring; replaced with the doc-header focus token for consistency. → fixed.
- [WCAG 1.3.1] Empty-state heading in the ShareLinks panel was a `<div>` with heading-style classes; promoted to `<h2>` so screen readers announce the section. → fixed.

## UX findings

- Empty-state copy iterated with `design:ux-writing`. Final: "No share links yet. Create your first one." with sub-line "Links appear here once someone views them." Overrides applied: `pipeline.overrides.ux_polish.required_reuse` requires `EmptyState` component → applied.
- `design:design-critique`: active-badge color was warning-yellow; matched design system to neutral-teal per doc-page pattern. → fixed.

## QA report

- AC 1: PASS — e2e: `apps/web/tests/e2e/doc-share.e2e.test.ts::renders button`.
- AC 2: PASS — api: `apps/api/tests/share-links.test.ts::returns link`.
- AC 3: PASS — api: `apps/api/tests/share-links.test.ts::expiry`.
- AC 4: PASS — e2e: `apps/web/tests/e2e/share-link-view.e2e.test.ts::status-flip`.
- AC 5: PASS — component: `apps/web/src/components/share-links/__tests__/ShareLinksPanel.test.tsx::expired badge`.

`customer-support:ticket-triage` simulated 4 likely support questions ("how do I revoke a link?", "recipient says link doesn't work", "can I see who viewed?", "is the link safe to share by email?"). All four are non-blocking; revoke is out-of-scope per Non-goals; "link doesn't work" routes to existing troubleshooting KB; "who viewed" warrants a Non-goals-update (we don't record identities, by design); "is it safe?" warrants a one-line trust footer on the view page (see Lessons).

## Legal findings

N/A — trigger conditions not met (regulated=false, security-escalated=false).

## Marketing draft

N/A — wrapper deferred (customer_facing_launch=true). Ship authors customer-facing copy manually in v0.1.0.

## Lessons captured

- [code-opt] Token-signing reuse pattern (sign helper for feature-scoped tokens) appeared in magic-link, password-reset, and now share-link. Promotion candidate: yes (project CLAUDE.md should require `signFeatureToken` for any new feature-scoped token).
- [QA] Public view pages should include a one-line trust footer ("This document was shared by the owner via a time-limited link."). Promotion candidate: watch.

## Preview URL

URL: https://example-fixture-git-feature-document-share-link-example.vercel.app
State: READY (vercel get_deployment → state: READY)
Verified at: 2026-04-19T15:04Z

# 02-plan.md — template

Canonical shape for the plan that Plan session produces via ExitPlanMode. The validator (`scripts/check-plan.sh`) checks for the sections marked **Required**.

## Frontmatter (Required)

```yaml
---
session: 02-plan
feature_id: <YYYY-MM-DD-slug>
project: <project-name>
owner: cc
status: done
inputs: [00-manifest.md, 01-brief.md, <PROJECT>/CLAUDE.md]
updated: YYYY-MM-DD
regulated: <copied from brief>
customer_facing_launch: <copied from brief>
---
```

Required fields (validator): `session`, `feature_id`, `project`, `owner`, `status`, `inputs`, `updated`, `regulated`, `customer_facing_launch`.

## Body sections

### `# 02-plan — <Feature Title>` (Required)

H1 matching the brief's feature title.

### `## Summary` (Required)

One paragraph, ≤5 sentences. What is this plan, in plain language, for someone who hasn't read the brief.

### `## Task list` (Required)

Numbered list, execution order. One task per line, terse. Each task should be 30 minutes to 4 hours of Build work — smaller than that is overhead, larger than that is under-planned.

Example:

```
1. Add share-links table and migration.
2. Wire link-create endpoint; accept doc_id, return token.
3. Build `/s/<token>` public route with read-only render.
4. Render ShareLinks panel on doc page with empty-state.
5. Wire active/viewed/expired status badges on link list.
6. Instrument first-view webhook to flip status.
7. Seed tests for each AC.
```

### `## Files touched` (Required)

Per task, which files are created, modified, or deleted. Use a bullet list nested under each task number, or a flat table — whichever is clearer.

Example:

```
Task 1:
- create: <repo-relative path to migration>
- create: <repo-relative path to share-link model>
- modify: <repo-relative path to schema>

Task 2:
- create: <repo-relative path to endpoint handler>
- modify: <repo-relative path to router index>
```

Paths must be repo-relative. No absolute paths.

### `## Reuse anchors` (Required)

Bulleted list of existing things Build should use instead of inventing. Link each to its repo-relative path where applicable.

Categories:
- **Components:** existing UI components that cover part of the feature.
- **Utilities:** helpers, services, hooks that do related work.
- **Marketplace skills:** e.g., `design:ux-writing` for empty-state copy, `customer-support:ticket-triage` for QA mode, etc. (These are pre-enumerated in the brief's conditional modes; here just confirm which apply to *this* feature.)
- **Patterns:** naming conventions, module layouts, test patterns from `<PROJECT>/CLAUDE.md`'s `pipeline.overrides.required_reuse`.

### `## Risk callouts` (Required)

Bulleted list. What could break in production that's not obvious from the feature surface. Each entry names the risk and the mitigation.

Examples:
- **Migration risk:** new `share_links` table needs backfill for existing docs that lack a link record. Mitigation: task 0a seeds historical records.
- **Cross-package types:** `ShareLink` type consumed in `<package-a>` and `<package-b>`. Mitigation: declare in shared types package, not per-package.
- **Rate limits:** public route capped at 60/min/IP. Mitigation: enforce via existing rate-limit middleware.
- **Secrets:** new env var `SHARE_LINK_SIGNING_SECRET` needed — add to deployment config, not committed.

### `## Side-effects` (Required)

Bulleted list. Things Build must touch that aren't in the feature's core file set.

Examples:
- Nav: add Share button to doc header.
- Types: regenerate `<type-package>` after schema change.
- Changelog: add `CHANGELOG.md` entry under "Unreleased".
- Docs: update `<project>/docs/features/sharing.md` with share-link subsection.
- Generated files: rerun codegen after schema change.
- Env: add `SHARE_LINK_SIGNING_SECRET` to `.env.example`.
- Analytics: add `share_link_created` and `share_link_viewed` events to event schema.

### `## Test strategy` (Required)

One paragraph on approach + mapping from acceptance criteria to tests.

Example:

```
Unit coverage on invite-create endpoint, token validation, and expiry
logic. Integration coverage on the email-send → accept flow using the
existing test harness in <test-path>. AC 1–5 each get one e2e test.
Manual preview-deploy check for the empty-state and error-state UI.
```

### `## Verification` (Required — must not be empty)

Every grep, file-read, or structural check the Plan session performed, with the query and the result. This is how Build knows the plan isn't hallucinated.

Format (table or bulleted):

```
| # | Looked for | Command / pattern | Result |
|---|------------|-------------------|--------|
| 1 | Existing public-route middleware | grep 'public-routes\|publicRoutes' apps/web/src/middleware/ | Found at apps/web/src/middleware/public-routes.ts — matches brief assumption. |
| 2 | Doc page Share placeholder | grep 'Share' apps/web/src/routes/docs/ | Not found — doc header has no Share placeholder. Task 4 creates from empty. |
| 3 | Document model | grep 'model Document' packages/db/ | Found; schema in packages/db/prisma/schema.prisma — existing fields sufficient; new share_links table FKs in. |
| 4 | Token signing pattern | grep 'jwt\|signToken' packages/auth/ | Found reusable sign helper — Reuse anchor. |
```

Empty table = rejected by validator.

### `## Rollback` (Required)

How to undo this feature if Ship or Watch reveals a defect.

Format:
```
Trigger: <what kind of defect would trigger rollback>
Steps: <numbered steps to revert — DB migrations, feature flags, code revert>
Estimated time: <minutes to rollback>
```

For internal-only changes that don't affect production, the body may be exactly:

```
N/A — internal-only change; no production surface touched.
```

The string must include `N/A` and a reason. Validator accepts this.

### `## Open questions` (Required — may say "none")

Anything Plan couldn't resolve. Tagged entries:

- `[Timm]` — decisions Timm needs to make before or during Build.
- `[Build-discover]` — small things Build should grep further before deciding (not surfaced to Timm).

If none: body is exactly `None.`

---

## What not to write

- **No code.** Plan mode means no writes. Code examples in the plan are fine only if they illustrate a pattern ("use the same shape as `<existing-file>`").
- **No invented paths.** Every path in `## Files touched` and `## Verification` must be grep-confirmed or explicitly flagged as new ("create: …").
- **No hand-waving on risk.** "Might have edge cases" is not a risk callout; "new endpoint accepts arbitrary email, no rate-limit → abuse risk" is.

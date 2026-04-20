---
name: pipeline-ship
description: Session 04 — Ship. Deploy to production, verify deploy state via platform MCP, wire observability, schedule the watch window, draft release notes, and promote artifacts into the project repo. Use when the user says "start a Ship session", "ship <feature>", "deploy <feature>", "run Session 04", "promote <feature>", or hands off an approved preview URL for release. Runs in a Cowork session. Requires 03-build-notes.md present and preview green. Writes `<FEATURE_DIR>/04-ship.md` and updates the manifest. Ends with Timm's final sign-off (pipeline touchpoint #4). Do NOT use for writing customer-facing marketing copy from scratch without a Build § Marketing draft — author manually in v0.1.0.
---

# pipeline-ship — Session 04 (Cowork, owner: timm)

Wrapper around the Ship session: take a green, preview-verified feature from Build and put it into production with observability, a watch window, release notes, and promoted artifacts. Timm's final touchpoint (#4) is the sign-off at the end.

## When this fires

- User says: "start a Ship session", "ship <feature>", "deploy <feature>", "run Session 04", "promote <feature>", "cut the release", "run the release", or hands off a preview URL for release.
- A feature directory exists at `<PROJECT>/<YYYY-MM-DD-slug>/` with at minimum `00-manifest.md`, `01-brief.md`, `02-plan.md`, `03-build-notes.md`.
- Build left the preview URL in `READY` state and AC status is all `PASS`.

## Pre-reads (non-negotiable — in full, no skimming)

Before any deploy action, read in this order:

1. `<FEATURE_DIR>/00-manifest.md`
2. `<FEATURE_DIR>/01-brief.md`
3. `<FEATURE_DIR>/02-plan.md`
4. `<FEATURE_DIR>/03-build-notes.md` — every section, especially Preview URL, Security findings, Legal findings, Marketing draft
5. `<PROJECT>/CLAUDE.md` — pipeline block, deploy constraints, env layout, `pipeline.repo_brief_dir`, `pipeline.changelog_path`

If `03-build-notes.md` is missing, has unresolved RED from `check-build-notes.sh`, or lacks a Preview URL with state `READY`, stop and tell Timm. Do not deploy.

## Phase 1 — Preflight gate

Block deploy unless every one of these is true. If any fails, surface to Timm with the specific reason; do not proceed.

- Build is green. `03-build-notes.md` passes `check-build-notes.sh` (no RED).
- Every AC in the brief has a matching `- AC <N>: PASS` row in `## AC status`.
- No unresolved critical/high security or legal findings (resolved or explicitly risk-accepted by Timm in build-notes).
- Preview URL state is `READY`, verified via platform MCP at deploy-time (not older than ~24h; re-verify if stale).
- Env parity chain (dev → staging → prod) is consistent with `<PROJECT>/CLAUDE.md`.

## Phase 2 — Deploy

1. **Migrations.** Run per project policy. Log every migration as a row under `## Migrations` in `04-ship.md` with name, target env, status, and timestamp. If no migrations: write `None — no schema changes in this feature.`
2. **Deploy to production** using the platform MCP declared in `<PROJECT>/CLAUDE.md` (typical: Vercel `deploy_to_vercel` or equivalent).
3. **Verify deploy state explicitly** via the platform MCP (e.g., Vercel `get_deployment` → `state: READY`). **Never assume from a push.** Record the verification call + response snippet in `04-ship.md`.
4. **Production smoke check.** Run scenario-level smoke against the live prod URL (minimum: one read path + one write path that exercises the feature). Record evidence — endpoint, status, timestamp, and a 1–2 line observation. Don't fake green. If smoke fails, roll back per plan and surface to Timm.

## Phase 3 — Observability wiring

Do not declare "wired" without verifying each element exists and is reachable.

1. **Critical-path steps.** List the 1–5 steps on the feature's main user path.
2. **Structured logs.** Confirm every critical-path step emits a structured log with a named correlation ID field. Record the field name.
3. **Named metrics.** List each metric by name (snake_case or dotted), with its dimensions. No generic "latency" — `share_links.create.latency_ms{workspace_id}` or similar.
4. **Alerts.** Configure at least one alert on the critical path. Each alert must have a named route (pager channel, Slack channel, email). Record alert name + route.
5. **Dashboard.** Build a feature-level dashboard via `data:interactive-dashboard-builder`. Record the dashboard URL.

## Phase 4 — Watch window

Schedule a watch window via the `schedule` marketplace skill. Capture the returned task ID in `04-ship.md` under `## Watch window`.

- Default: 14 days from deploy-verified timestamp.
- Tune per feature: regulated or high-risk features → 30 days; tiny internal tooling → 7 days. Note the chosen length + reason.
- Record: `task_id`, `cohort_id` (`YYYY-Www` or `YYYY-MM`), `opens_at`, `closes_at`.

If `schedule` does not return a task ID, do not silently continue — surface to Timm.

## Phase 5 — Rollback plan

Draft a short, concrete rollback plan under `## Rollback`:

- **Trigger** — what observation flips the rollback decision (error rate spike, specific alert, integrity check failure).
- **Steps** — actual commands / platform MCP calls, in order.
- **ETA** — minutes to full rollback.
- **Owner** — Timm unless declared otherwise in `<PROJECT>/CLAUDE.md`.

## Phase 6 — Release notes (internal + customer-facing)

Write both under `## Release notes`.

- **Internal.** Pulled from `03-build-notes.md`. What changed, what to watch, links to dashboard + build-notes.
- **Customer-facing.** If the brief's frontmatter has `customer_facing_launch: true`:
  - If `03-build-notes.md` § Marketing draft has a real draft → use it, voice-check via `brand-voice:brand-voice-enforcement`, record the check outcome.
  - **v0.1.0 behavior:** Build's Marketing wrapper is deferred. Expect `N/A — wrapper deferred (...)` in the build draft. Ship must author the customer-facing copy manually in v0.1.0 and note that explicitly in `04-ship.md`.
  - If `customer_facing_launch: false` → write `N/A — not a customer-facing launch.`

## Phase 7 — Promotion

Check `<PROJECT>/CLAUDE.md` for `pipeline.repo_brief_dir` and `pipeline.changelog_path`.

- **Brief promotion.** If `pipeline.repo_brief_dir` is declared: copy `01-brief.md` to `<pipeline.repo_brief_dir>/<feature-id>.md`. Record the destination path in `## Promotion`.
- **Changelog append.** If `pipeline.changelog_path` is declared: append a single dated entry pulling from the internal release note. Record the appended entry in `## Promotion`.
- **Neither declared.** Write `N/A — project did not declare pipeline.repo_brief_dir or pipeline.changelog_path.` This is valid; don't fabricate paths.

If declared but the write fails (permission, missing dir), do not silently swallow it — surface to Timm.

## Phase 8 — Close (final touchpoint)

1. Write `<FEATURE_DIR>/04-ship.md` using `references/ship-template.md`. Preserve frontmatter shape; set `status: ready-for-signoff`.
2. Update `00-manifest.md`: mark `04-ship: ready-for-signoff`, record deploy URL, dashboard URL, watch-window task ID.
3. Run `scripts/check-ship.sh <FEATURE_DIR>/04-ship.md` — fix every RED.
4. Surface to Timm with the verbatim close message in `references/close-checklist.md`. Do not self-close. Only after Timm replies "signed off" / "approved" do you flip `04-ship: shipped` in the manifest and `status: shipped` in `04-ship.md`.

## Deferred in v0.1.0

- **Build-side Marketing wrapper.** Ship authors customer-facing copy manually if `customer_facing_launch: true`. Logged to lessons.md.
- **Automated release-note voice-check as a gating step.** Voice-check still happens; it's advisory in v0.1.0, not a block.

## Project overrides read from `<PROJECT>/CLAUDE.md`

- `pipeline.repo_brief_dir` — destination for brief promotion
- `pipeline.changelog_path` — destination for changelog append
- `pipeline.watch_window_default_days` — override default 14
- `pipeline.rollback_owner` — override default Timm

## Files you touch

- `<FEATURE_DIR>/04-ship.md` (create)
- `<FEATURE_DIR>/00-manifest.md` (update)
- `<pipeline.repo_brief_dir>/<feature-id>.md` (copy) — if declared
- `<pipeline.changelog_path>` (append) — if declared
- `lessons.md` in this skill (append on notable patterns)

## Files you must not touch

- Any file under `<FEATURE_DIR>/` other than `04-ship.md` and `00-manifest.md`
- `01-brief.md`, `02-plan.md`, `03-build-notes.md` — read-only here
- Any project repo file outside the two promotion destinations

## Smoke test

`bash scripts/smoke.sh` runs `check-ship.sh` against the three fixtures in `fixtures/`. Expected: good=rc0, bad-no-deploy-state=rc1, bad-missing-sections=rc1.

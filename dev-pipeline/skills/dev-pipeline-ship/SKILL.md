---
name: dev-pipeline-ship
description: Session 04 — Ship. Deploy to production, verify deploy state via platform MCP, run the agentic QA pass against the live URL, write the residual human punchlist, wire observability, schedule the watch window, draft release notes, and promote artifacts into the project repo. Use when the user says "start a Ship session", "ship <feature>", "deploy <feature>", "run Session 04", "promote <feature>", or hands off an approved preview URL for release. Runs in a Cowork session. Requires 03-build-notes.md present and preview green. Writes `<FEATURE_DIR>/04-ship.md` and `<FEATURE_DIR>/04-punchlist.json` and updates the manifest. Ends with Timm's final sign-off (pipeline touchpoint #4). Do NOT use for writing customer-facing marketing copy from scratch without a Build § Marketing draft — author manually in v0.1.0.
---

# dev-pipeline-ship — Session 04 (Cowork, owner: timm)

Wrapper around the Ship session: take a green, preview-verified feature from Build and put it into production with an agentic QA pass, a human punchlist scoped to what the agent couldn't verify, observability, a watch window, release notes, and promoted artifacts. Timm's final touchpoint (#4) is the sign-off at the end.

## When this fires

- User says: "start a Ship session", "ship <feature>", "deploy <feature>", "run Session 04", "promote <feature>", "cut the release", "run the release", or hands off a preview URL for release.
- A feature directory exists at `<PROJECT>/<YYYY-MM-DD-slug>/` with at minimum `00-manifest.md`, `01-brief.md`, `02-plan.md`, `03-build-notes.md`.
- Build left the preview URL in `READY` state and AC status is all `PASS`.

## Pre-reads (non-negotiable — in full, no skimming)

Before any deploy action, read in this order:

1. `<FEATURE_DIR>/00-manifest.md`
2. `<FEATURE_DIR>/01-brief.md`
3. `<FEATURE_DIR>/02-plan.md` — including `## Checks` override block if present
4. `<FEATURE_DIR>/03-build-notes.md` — every section, especially Preview URL, Security findings, Legal findings, Marketing draft
5. `<PROJECT>/CLAUDE.md` — pipeline block, deploy constraints, env layout, `pipeline.repo_brief_dir`, `pipeline.changelog_path`, `pipeline.punchlist_gating`
6. `references/agentic-qa-playbook.md` — the Phase 3 check menu
7. `references/punchlist-schema.md` — the Phase 4 output contract

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

## Phase 3 — Agentic QA (live-URL pass)

Claude drives the verified prod URL and runs the scripted checks before writing the human punchlist. Full check menu, auto-detect rules, and recording format live in `references/agentic-qa-playbook.md` — follow it.

1. **Core pass (every ship).** Navigate (`mcp__Claude_in_Chrome__navigate`) → console capture (`read_console_messages`) → network capture (`read_network_requests`) → HTTP smoke on read + write paths → Vercel logs (`get_runtime_logs`, `get_deployment_build_logs`) → AC walk, tagging each AC as `verified` / `partial` / `human_required`.
2. **Conditional passes.** Auto-trigger from brief/plan signals per the playbook's decision table (a11y scan, responsive pass, screenshot critique for `customer_facing_launch: true`; auth-boundary check if `auth`/`middleware`/`session` files touched; extended API smoke if `api/` or DB migration touched; Playwright specs if present).
3. **`## Checks` override.** If `02-plan.md` has a `## Checks` section, honor its include/skip directives. Skip directives require a one-line reason — record it in `04-ship.md`. No reason = ignore the skip.
4. **Stop condition.** Any finding marked `blocking` by the playbook → pause, surface to Timm, do not proceed to Phase 4 or deploy-state flip. Matches the "smoke fails → rollback" posture.
5. **Record.** Write `## Agentic QA` in `04-ship.md` with: checks run (list), AC coverage table (AC id → verification method → status → evidence/reason), findings table (id, severity, source, text, status), and autonomous coverage % (`verified / total AC × 100`, rounded).

Do not write the punchlist until this phase's `## Agentic QA` block is fully recorded.

## Phase 4 — Punchlist (residual human QA)

Write `<FEATURE_DIR>/04-punchlist.json` per `references/punchlist-schema.md`. This is the human QA checklist scoped strictly to what Phase 3 couldn't verify.

1. **Scope.** One item per unverified residual — typically AC rows tagged `human_required` or `partial`. Do not pad. If Phase 3 produced 100% verified coverage and zero human-required rows, `items: []` is valid and correct.
2. **Severity.**
   - `blocking` — open means sign-off is blocked. Reserved for items tied to an AC marked `human_required` or `partial` where the unverified surface is customer-visible.
   - `watch` — review during the watch window; doesn't block sign-off. Routed through the existing `.punchlist/inbox.md` flow when flagged.
   - Do NOT escalate `watch` → `blocking` to force attention. If it's advisory, keep it advisory.
3. **Shape.** Schema v2. Include `schema_version: "2"`, `schema.generator: "dev-pipeline-ship@<version>"`, `feature_id`, `project`, `short_sha`, `full_sha`, `deploy_url`, `deploy_state: "READY"`, `title`, `created_at`, and the `agentic_pass` + `items` blocks. Field-by-field rules in the schema reference.
4. **Validate.** Run `scripts/check-punchlist.sh <FEATURE_DIR>/04-punchlist.json` before moving on. Fix every RED. YELLOW warnings (autonomous coverage < 50%, items.length > 10) are advisory but worth a sanity pass.
5. **Record link in ship notes.** Add `## Punchlist` to `04-ship.md` with the feature-id URL at `https://ship-punchlist-web.vercel.app/<owner>/<repo>/feature/<feature_id>` (the reviewer page) and a one-line "N blocking, M watch" summary.

## Phase 5 — Observability wiring

Do not declare "wired" without verifying each element exists and is reachable.

1. **Critical-path steps.** List the 1–5 steps on the feature's main user path.
2. **Structured logs.** Confirm every critical-path step emits a structured log with a named correlation ID field. Record the field name.
3. **Named metrics.** List each metric by name (snake_case or dotted), with its dimensions. No generic "latency" — `partner_invites.create.latency_ms{dealer_id}` or similar.
4. **Alerts.** Configure at least one alert on the critical path. Each alert must have a named route (pager channel, Slack channel, email). Record alert name + route.
5. **Dashboard.** Build a feature-level dashboard via `data:interactive-dashboard-builder`. Record the dashboard URL.

## Phase 6 — Watch window

Schedule a watch window via the `schedule` marketplace skill. Capture the returned task ID in `04-ship.md` under `## Watch window`.

- Default: 14 days from deploy-verified timestamp.
- Tune per feature: regulated or high-risk features → 30 days; tiny internal tooling → 7 days. Note the chosen length + reason.
- Record: `task_id`, `cohort_id` (`YYYY-Www` or `YYYY-MM`), `opens_at`, `closes_at`.

If `schedule` does not return a task ID, do not silently continue — surface to Timm.

## Phase 7 — Rollback plan

Draft a short, concrete rollback plan under `## Rollback`:

- **Trigger** — what observation flips the rollback decision (error rate spike, specific alert, integrity check failure, open `blocking` punchlist item that can't be cleared in-window).
- **Steps** — actual commands / platform MCP calls, in order.
- **ETA** — minutes to full rollback.
- **Owner** — Timm unless declared otherwise in `<PROJECT>/CLAUDE.md`.

## Phase 8 — Release notes (internal + customer-facing)

Write both under `## Release notes`.

- **Internal.** Pulled from `03-build-notes.md` and `## Agentic QA`. What changed, what to watch, autonomous coverage %, links to dashboard + build-notes + punchlist.
- **Customer-facing.** If the brief's frontmatter has `customer_facing_launch: true`:
  - If `03-build-notes.md` § Marketing draft has a real draft → use it, voice-check via `brand-voice:brand-voice-enforcement`, record the check outcome.
  - **v0.1.0 behavior:** Build's Marketing wrapper is deferred. Expect `N/A — wrapper deferred (...)` in the build draft. Ship must author the customer-facing copy manually in v0.1.0 and note that explicitly in `04-ship.md`.
  - If `customer_facing_launch: false` → write `N/A — not a customer-facing launch.`

## Phase 9 — Promotion

Check `<PROJECT>/CLAUDE.md` for `pipeline.repo_brief_dir`, `pipeline.changelog_path`, and `pipeline.punchlist_dir` (default `.punchlist/`).

- **Brief promotion.** If `pipeline.repo_brief_dir` is declared: copy `01-brief.md` to `<pipeline.repo_brief_dir>/<feature-id>.md`. Record the destination path in `## Promotion`.
- **Changelog append.** If `pipeline.changelog_path` is declared: append a single dated entry pulling from the internal release note. Record the appended entry in `## Promotion`.
- **Punchlist mirror.** Always mirror to the project repo so the web app can read it:
  - Copy `<FEATURE_DIR>/04-punchlist.json` → `<project-repo>/<pipeline.punchlist_dir>/<feature_id>.json` (source-of-truth file the web app renders).
  - Write V1 pointer file `<project-repo>/<pipeline.punchlist_dir>/<short_sha>.json` with contents `{ "schema_version": "2", "ref": "<feature_id>.json" }`. This keeps the installed pre-push hook (which looks for `<short_sha>.json`) passing for pipeline ships.
  - Record both paths under `## Promotion`.
- **Nothing declared except punchlist.** The punchlist mirror is not optional. If neither `repo_brief_dir` nor `changelog_path` is declared, write `N/A — project did not declare pipeline.repo_brief_dir or pipeline.changelog_path.` for those, then still do the punchlist mirror.

If any declared write fails (permission, missing dir), do not silently swallow it — surface to Timm.

## Phase 10 — Close (final touchpoint)

1. Write `<FEATURE_DIR>/04-ship.md` using `references/ship-template.md`. Preserve frontmatter shape; set `status: ready-for-signoff`. Frontmatter must include `agentic_qa_coverage_pct`, `punchlist_blocking_open`, `punchlist_url`.
2. Update `00-manifest.md`: mark `04-ship: ready-for-signoff`, record deploy URL, dashboard URL, watch-window task ID, punchlist URL.
3. Run `scripts/check-ship.sh <FEATURE_DIR>/04-ship.md` — fix every RED. The checker also runs `check-punchlist.sh` internally; any RED from there also blocks.
4. **Sign-off gating.** Consult `pipeline.punchlist_gating` in `<PROJECT>/CLAUDE.md` (default `strict`).
   - `strict` — any open `items[].severity: blocking` → sign-off blocked. Surface to Timm as "N blocking items open — address and re-run check-ship, or override with `pipeline.punchlist_gating: advisory` (logged to lessons.md)."
   - `advisory` — surface the count but don't block. Log the override + reason to `lessons.md` on close.
5. Surface to Timm with the verbatim close message in `references/close-checklist.md` (which now includes autonomous coverage %, blocking-open count, and the punchlist URL). Do not self-close. Only after Timm replies "signed off" / "approved" do you flip `04-ship: shipped` in the manifest and `status: shipped` in `04-ship.md`.

## Deferred in v0.1.0

- **Build-side Marketing wrapper.** Ship authors customer-facing copy manually if `customer_facing_launch: true`. Logged to lessons.md.
- **Automated release-note voice-check as a gating step.** Voice-check still happens; it's advisory in v0.1.0, not a block.
- **V1 punchlist schema.** Pipeline ships always write schema v2. The V1 pointer file in Phase 9 is transitional — retire it once every project has migrated and the pre-push hook is updated to recognize the feature-id form.

## Project overrides read from `<PROJECT>/CLAUDE.md`

- `pipeline.repo_brief_dir` — destination for brief promotion
- `pipeline.changelog_path` — destination for changelog append
- `pipeline.watch_window_default_days` — override default 14
- `pipeline.rollback_owner` — override default Timm
- `pipeline.punchlist_dir` — override default `.punchlist/` for the repo mirror path
- `pipeline.punchlist_gating` — `strict` (default) or `advisory`

## Files you touch

- `<FEATURE_DIR>/04-ship.md` (create)
- `<FEATURE_DIR>/04-punchlist.json` (create)
- `<FEATURE_DIR>/00-manifest.md` (update)
- `<project-repo>/<pipeline.punchlist_dir>/<feature_id>.json` (copy of 04-punchlist.json — always)
- `<project-repo>/<pipeline.punchlist_dir>/<short_sha>.json` (V1 pointer file — always)
- `<pipeline.repo_brief_dir>/<feature-id>.md` (copy) — if declared
- `<pipeline.changelog_path>` (append) — if declared
- `lessons.md` in this skill (append on notable patterns or `advisory` gating overrides)

## Files you must not touch

- Any file under `<FEATURE_DIR>/` other than `04-ship.md`, `04-punchlist.json`, and `00-manifest.md`
- `01-brief.md`, `02-plan.md`, `03-build-notes.md` — read-only here
- Any project repo file outside the promotion destinations and the punchlist mirror paths

## Smoke test

`bash scripts/smoke.sh` runs `check-ship.sh` + `check-punchlist.sh` against the fixtures in `fixtures/`. Expected:
- `good/` → rc0 (04-ship + 04-punchlist both pass)
- `bad-no-deploy-state/` → rc1
- `bad-missing-sections/` → rc1
- `bad-no-agentic-pass/` → rc1 (missing `## Agentic QA` in 04-ship.md)
- `bad-open-blocking/` → rc1 (04-punchlist.json has open `blocking` item under strict gating)

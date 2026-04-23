# Agentic QA playbook

How to run Phase 3 — the autonomous pass that comes after Deploy and before Punchlist. The agent drives the live production URL itself, captures evidence, and writes findings to `04-ship.md`. The goal is to resolve every AC that can be resolved without a human, and to scope the punchlist (Phase 4) to what remains.

Principle: **observe before you punchlist.** Items the agent can't verify become human QA items with a real reason attached. Items the agent *can* verify never make it to the punchlist in the first place.

## When Phase 3 runs

After Phase 2 (Deploy) has flipped `deploy_state: READY` and the production smoke check has passed. Before Phase 4 (Punchlist). If any phase above has surfaced to Timm, Phase 3 does not start.

## Core pass — runs every ship

Five steps, in order. Budget: ~3–5 minutes for a normal feature. Record every call + result in `04-ship.md` under `## Agentic QA`.

### 1. Navigate + console capture

- Tool: `mcp__Claude_in_Chrome__navigate` to the verified prod URL from Phase 2.
- Tool: `mcp__Claude_in_Chrome__read_console_messages` immediately after load.
- **Any `error` level message = finding.** Record source file + line + message verbatim.
- `warn` level: record but do not treat as finding unless it references the feature's paths.

### 2. Network capture

- Tool: `mcp__Claude_in_Chrome__read_network_requests` for the same page load.
- **Any 4xx or 5xx on the feature's routes = finding.** Record URL, status, response body snippet.
- 4xx/5xx on routes unrelated to the feature: record in an "out of scope" bucket, don't block.

### 3. HTTP smoke — read + write paths

The Phase 2 smoke already exercised one read + one write. This step extends coverage to every endpoint the plan added or touched. Pull the list from `02-plan.md § Files touched` — any path under `api/` or matching the project's route convention.

- Read paths: unauthed GET + authed GET. Expect the project's documented behavior (typically 401 + 200).
- Write paths: authed POST/PUT/DELETE with a minimal valid payload. Expect 2xx + a trace in the persistence layer (row in DB, row in log, side effect visible).
- Record each call's URL, status, and a 1–2 line observation.

### 4. Vercel logs

- Tool: `mcp__c2cbaabc-…__get_runtime_logs` for the 10-minute window starting at deploy-verified timestamp.
- Scan for: runtime errors, timeouts, cold-start warnings, hydration mismatches.
- Tool: `mcp__c2cbaabc-…__get_deployment_build_logs` for the deploy's build phase.
- Scan for: TypeScript errors, dependency warnings, bundle-size regressions >10%.
- **Every finding = a row in the findings table.** Severity triage below.

### 5. AC walk

For every AC row in `01-brief.md`, attempt programmatic verification. Tag each:

| Tag | Meaning | Requires |
|-----|---------|----------|
| `verified` | Agent confirmed AC with evidence | Evidence snippet (HTTP response, DB row, log line, screenshot hash) |
| `partial` | Agent confirmed one part, another part needs human | Both an evidence snippet AND a specific "still needs" note |
| `human_required` | AC cannot be verified autonomously | One-line reason (e.g. "subjective visual judgment", "email client rendering", "off-platform action") |

`partial` and `human_required` are the seeds for Phase 4 items. Never tag `verified` without evidence in the AC coverage table — if you don't have the evidence to paste in, the AC is not verified.

## Conditional passes — auto-detect + override

Triggered per Decision 3 (auto-detect with explicit override). The brief + plan declare the signals; Plan can layer explicit `include:` or `skip:` on top.

### Auto-detect triggers

| Signal | Conditional pass | Tool |
|--------|------------------|------|
| `customer_facing_launch: true` in brief frontmatter | Axe a11y scan on feature routes | `mcp__Claude_in_Chrome__javascript_tool` injects axe-core |
| `customer_facing_launch: true` in brief frontmatter | Responsive pass @ 390 / 768 / 1280 | `mcp__Claude_in_Chrome__resize_window` + screenshot each |
| `customer_facing_launch: true` in brief frontmatter | Screenshot self-critique vs. brief copy | `get_page_text` + screenshot, LLM critique against AC |
| Plan § Files touched matches `auth/`, `middleware/`, `session` | Auth boundary check | HTTP: hit each protected route unauthed, expect 401/403 |
| Plan § Files touched matches `api/` OR migration listed | Extended API smoke (CRUD on every new endpoint) | HTTP |
| Repo has `tests/e2e/*.spec.ts` matching feature slug | Headless Playwright run against prod | Bash `npx playwright test --config=...` |

### Plan-side override

If `02-plan.md` contains a `## Checks` section, it layers on top of auto-detect:

```
## Checks
include:
  - playwright                # auto-detect missed it; force it on
skip:
  - responsive                # reason: admin-only feature, desktop-class users
    reason: admin-only feature, desktop-class users
```

Every `skip:` entry requires a one-line `reason:`. Plan validator (`check-plan.sh`) enforces this.

No `## Checks` section → pure auto-detect.

### Conditional pass recording

Same table as core pass findings. Additional columns for which conditional fired and why (auto-detect signal, or plan-declared).

## Severity triage

Every finding gets a severity when it's recorded. Two levels:

- **`blocking`** — the feature shouldn't ship as-is. Touches an AC, or a core path is broken. Phase 3 pauses on any `blocking` finding; does not proceed to Phase 4. Surface to Timm.
- **`watch`** — worth documenting, worth reviewing during the watch window, but doesn't block this ship. Console warnings, axe contrast at 3.8:1 (threshold 4.5:1) on a non-primary element, slow-but-working endpoint, etc.

Default when unsure: **`watch`**. Only escalate to `blocking` if the agent can articulate "this means AC X fails" or "this is a broken core path." If the agent is guessing whether it's blocking, it isn't.

## Stop conditions

Phase 3 halts and surfaces to Timm if:

- Any finding is tagged `blocking`.
- Chrome MCP returns ≥2 consecutive errors (extension disconnected, page won't load).
- Vercel MCP returns errors suggesting the deploy state changed mid-pass.
- An AC the plan listed as `human_required: false` turns out to need human judgment after all — flag the brief + plan for the LLM Ops drift log.

Do not auto-retry. Do not silently downgrade findings. Do not proceed to Phase 4 with unresolved `blocking` items.

## Recording format

Write under `## Agentic QA` in `04-ship.md`:

```markdown
## Agentic QA

**Completed at:** 2026-04-22T14:28:00Z
**Autonomous coverage:** 8 of 12 AC verified (67%)

### Checks run

- chrome_navigate, console, network (core)
- http_smoke (core, 6 endpoints)
- vercel_runtime_logs, vercel_build_logs (core)
- axe (conditional: customer_facing_launch)
- responsive (conditional: customer_facing_launch)

### AC coverage

| AC | Text | Verification | Status | Evidence / Reason |
|----|------|--------------|--------|-------------------|
| AC1 | Dealer can invite a partner by email | http_smoke | verified | POST /api/invites → 200, row in partner_invites |
| AC2 | Invite email visually matches brand | — | human_required | subjective visual judgment |

### Findings

| ID | Severity | Source | Text | Status |
|----|----------|--------|------|--------|
| auto-1 | watch | console | Unhandled promise warning in /admin/invites on hover | open |
| auto-2 | watch | axe | Contrast 4.2:1 on secondary link (threshold 4.5:1) | open |

### Notes

Any free-form notes about the pass — e.g. "Playwright skipped, no e2e specs matched feature slug."
```

## Failure handling

- **Chrome MCP unreachable:** surface to Timm immediately. Do not fall back to curl-only; losing console + network coverage is a Phase 3 failure, not a degraded pass.
- **Vercel logs return empty:** record the empty state as a finding (severity `watch`) — "no runtime logs in 10-min window post-deploy" is itself interesting. Don't treat empty as green.
- **Playwright fails at setup (missing deps):** skip the Playwright conditional, record "skipped — setup failed: {reason}" as a watch finding. Don't block the ship on infra flakiness.
- **Axe finds >20 findings:** record the top 5 by severity + a count, not all 20. A flood usually means the test targeted the wrong route.

## What Phase 3 is NOT

- Not a replacement for unit / integration tests. Those live in the repo and ran in Build.
- Not a full regression suite. Scope is the feature + its direct neighbors.
- Not an excuse to write fewer ACs. ACs are still the contract; Phase 3 just verifies more of them programmatically.

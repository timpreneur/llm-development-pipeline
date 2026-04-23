# Punchlist schema — `04-punchlist.json`

Reference for the Phase 4 output. This is the human QA checklist, scoped to only what the Phase 3 agentic pass couldn't verify. The web app at `https://ship-punchlist-web.vercel.app` reads this file directly from the project repo.

Principle from the standalone punchlist, preserved: **don't pad.** If Phase 3 verified 100% of AC and produced zero human-required items, `items` is an empty array and the punchlist is a one-line "agent verified all AC, no human QA required."

## File locations

Two paths, always written together. The feature-dir copy is the source of truth; the repo copy is the mirror the web app reads.

| Role | Path | Written by |
|------|------|------------|
| Source of truth | `<FEATURE_DIR>/04-punchlist.json` | Phase 4 |
| Project-repo mirror | `<project-repo>/.punchlist/<feature_id>.json` | Phase 9 (Promotion) |
| V1 hook compat (pipeline ships) | `<project-repo>/.punchlist/<short_sha>.json` | Phase 9, pointer file only |

The V1 compat file exists so the installed pre-push hook — which looks for a file matching `<short_sha>` — keeps passing for pipeline ships. Shape of the pointer file:

```json
{ "schema_version": "2", "ref": "<feature_id>.json" }
```

The web app treats `ref` pointers as redirects to the real file. Keeps the hook installed in every project from erroring on pipeline-authored pushes.

## Full schema

```jsonc
{
  "schema_version": "2",
  "schema": {
    "version": "2",
    "generator": "dev-pipeline-ship@0.1.0"
  },

  "feature_id": "2026-04-22-partner-invites",
  "project": "sifly-central",
  "short_sha": "abc1234",
  "full_sha": "abc1234567890abcdef1234567890abcdef12345",
  "deploy_url": "https://sifly-central.vercel.app",
  "deploy_state": "READY",
  "title": "Partner invite flow",
  "created_at": "2026-04-22T14:30:00Z",

  "agentic_pass": {
    "completed_at": "2026-04-22T14:28:00Z",
    "autonomous_coverage_pct": 67,
    "checks_run": [
      "chrome_navigate",
      "console",
      "network",
      "http_smoke",
      "vercel_runtime_logs",
      "vercel_build_logs",
      "axe",
      "responsive"
    ],
    "ac_coverage": [
      {
        "ac_id": "AC1",
        "text": "Dealer can invite a partner by email",
        "verification": "http_smoke",
        "status": "verified",
        "evidence": "POST /api/invites → 200, row in partner_invites table (id=42)"
      },
      {
        "ac_id": "AC2",
        "text": "Invite email visually matches brand",
        "verification": null,
        "status": "human_required",
        "reason": "subjective visual judgment; email client rendering"
      }
    ],
    "findings": [
      {
        "id": "auto-1",
        "severity": "watch",
        "source": "console",
        "text": "Unhandled promise warning in /admin/invites on hover",
        "status": "open"
      }
    ]
  },

  "items": [
    {
      "id": "1",
      "ac_ref": "AC2",
      "severity": "blocking",
      "text": "Open a real invite email in Gmail + Outlook; verify brand matches design spec.",
      "surface": "transactional email",
      "rationale": "Email client rendering can't be agentically verified"
    },
    {
      "id": "2",
      "severity": "watch",
      "text": "Sanity-check /admin/invites on mobile Safari for overflow.",
      "surface": "/admin/invites",
      "rationale": "Responsive pass ran desktop-class headless Chrome; real Safari not verified"
    }
  ]
}
```

## Field reference

### Root

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `schema_version` | string | yes | Must be `"2"` for pipeline-authored punchlists |
| `schema.generator` | string | yes | Format: `dev-pipeline-ship@<version>`. Used for future retirement decisions |
| `feature_id` | string | yes | Directory name under `<PROJECT>/` — `YYYY-MM-DD-slug` |
| `project` | string | yes | Project slug (matches `<PROJECT>/CLAUDE.md`) |
| `short_sha` | string | yes | `git rev-parse --short HEAD` at deploy |
| `full_sha` | string | yes | Full commit SHA |
| `deploy_url` | string | yes | Verified prod URL from Phase 2 |
| `deploy_state` | string | yes | Should always be `"READY"` when this file is written |
| `title` | string | yes | Pulled from `01-brief.md` frontmatter |
| `created_at` | string (ISO 8601) | yes | File write timestamp, UTC |

### `agentic_pass` block

The full record of what Phase 3 did. The web app renders this panel above the human items, read-only, so the reviewer sees what's already verified before starting.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `completed_at` | ISO 8601 | yes | When Phase 3 finished |
| `autonomous_coverage_pct` | integer | yes | `verified AC count / total AC count × 100`, rounded |
| `checks_run` | array of strings | yes | From the playbook's check menu; see `agentic-qa-playbook.md` |
| `ac_coverage` | array | yes | One entry per AC in the brief |
| `findings` | array | yes | All findings from core + conditional passes. `[]` if none |

`ac_coverage[].status` is one of `verified` / `partial` / `human_required`. `verified` requires `evidence`; the others require `reason`.

`findings[].severity` is one of `blocking` / `watch`. `findings[].status` is `open` / `resolved`. Phase 3 pauses on any open `blocking` — so `findings` at Phase 4 write time will never contain an open `blocking`.

### `items` block — the human punchlist

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | Per-file ordinal, `"1"`, `"2"`, etc. |
| `ac_ref` | string | no | Link to an AC from `ac_coverage` (typically `partial` or `human_required`) |
| `severity` | string | yes | `blocking` or `watch` |
| `text` | string | yes | What the reviewer should do. Specific, actionable |
| `surface` | string | yes | Page, component, flow, or off-platform surface ("transactional email") |
| `rationale` | string | yes | One-line reason this isn't verified by the agentic pass |

## Severity rules

- **`blocking`** — open means sign-off is blocked (gating per project config: strict default, advisory override in `<PROJECT>/CLAUDE.md`). Reserved for items that directly touch an AC marked `human_required` or `partial` where the unverified half is customer-visible.
- **`watch`** — review during the watch window; does not block sign-off. Flagged `watch` items flow through the existing `.punchlist/inbox.md` in the normal session-start path.

Do not escalate `watch` → `blocking` to "force attention." If an item is advisory, mark it `watch` and trust the watch window.

## Item discipline

Inherits the standalone punchlist's anti-padding rule. Item count should match the actual residual after the agentic pass — not a minimum.

| Phase 3 residual | Expected `items` count |
|------------------|------------------------|
| 100% autonomous coverage, zero human-required AC | `[]` — valid, don't invent items |
| One or two `human_required` AC | 1–3 items, each tied to an AC |
| Heavy subjective surface (design-polish feature) | 3–6 items |
| Legacy-pattern ship (no AC, infra-only) | 1 smoke item: "sanity-check deploy URL still loads, nothing regressed" |

Negative example — don't do this:

> Item 3: "In a future ship, verify the agentic pass correctly skips responsive on admin-only features."

That's a meta-test about the pipeline itself, not a check on the feature being deployed. Belongs in `lessons.md`, not the punchlist.

## Validation

`scripts/check-ship.sh` calls a helper (`scripts/check-punchlist.sh`, added in the same pass) that runs:

- RED on invalid JSON.
- RED on missing required fields.
- RED on `items[].severity: blocking` without a matching `ac_coverage` entry marked `human_required` or `partial`.
- RED on `autonomous_coverage_pct` outside `[0, 100]`.
- RED on any `findings[].severity: blocking` with `status: open` (Phase 3 should have paused — this is a contract break).
- YELLOW on `autonomous_coverage_pct < 50` (prompts review: is the feature under-specified, or is the agentic pass under-configured?).
- YELLOW on `items.length > 10` (likely padding).

## Web app rendering

The web app reads the file with a dual-format reader:

- Files without `schema_version` → legacy V1 renderer (the existing deploy detail page).
- Files with `schema_version: "2"` → the new feature-scoped renderer, which adds:
  - An agentic-pass panel at the top showing `checks_run`, `autonomous_coverage_pct`, and the AC coverage table.
  - Severity badges: `blocking` items rendered red, `watch` items rendered yellow.
  - Items default-sorted by severity (`blocking` first).

See the "Web app adaptation" section of `integration-plan.md` for the reader-branch implementation.

## Legacy / hotfix compat

Pushes that don't go through dev-pipeline-ship still write V1 files (`<short_sha>.json` without `schema_version`). The web app renders both shapes side-by-side in the project's deploy list. Nothing about this schema breaks the V1 path.

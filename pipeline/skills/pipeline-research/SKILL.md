---
name: pipeline-research
description: Session 05 — Research (per-cohort). Autonomous Cowork session that surfaces what shipped features actually did, what broke, and what users ask for next. Runs when a cohort's watch windows have closed. Use when the user says "start a Research session for cohort <id>", "run Session 05", "research the <cohort> cohort", "what did last <week|month> ship and what happened", or the `schedule` skill fires a cohort-close task. Requires ≥1 feature in the cohort with `04-ship.md` and closed watch window. Writes `<COHORT_DIR>/05-research.md` and seeds `<PROJECT>/_inbox/<YYYY-MM-DD-slug>.md` stubs for strong-signal candidates. Autonomous — no mid-session stops; surfaces clearly at end.
---

# pipeline-research — Session 05 (Cowork, owner: cc, autonomous)

Wrapper around the Research session: per-cohort retrospection over features whose watch windows have closed. Autonomous — no mid-session stops. Ends with a single surface to Timm when the research report and inbox stubs are in place.

## When this fires

- User says: "start a Research session", "run Session 05 for <cohort>", "research cohort <id>", "retro the <week|month> cohort", "what shipped and what happened".
- The `schedule` skill fires a watch-window-close task. The task ID was recorded in each feature's `04-ship.md § Watch window`.
- A cohort directory exists at `Code/pipeline/<PROJECT>/<COHORT_ID>/` OR needs to be created based on closed watch windows.

## Cohort construction

1. Identify the cohort_id (`YYYY-Www` or `YYYY-MM`) from the triggering event or user input.
2. Walk `Code/pipeline/<PROJECT>/` for every `<FEATURE_DIR>` whose `04-ship.md` has:
   - `deploy_state: READY`
   - `status: shipped`
   - A `## Watch window` block with `closes_at` that falls within the cohort's window.
3. **Cap:** max 5 features per cohort session. If more: split into per-surface research runs (e.g., "dashboard" cohort + "billing" cohort) and note the split in the report. Never run a single session over >5 features — findings blur.
4. Create `Code/pipeline/<PROJECT>/<COHORT_ID>/` if it doesn't exist.

## Pre-reads (non-negotiable — in full, per feature)

For each feature in the cohort, read in this order:

1. `<FEATURE_DIR>/00-manifest.md`
2. `<FEATURE_DIR>/01-brief.md` — especially Vision, AC, and success signals
3. `<FEATURE_DIR>/04-ship.md` — observability wiring, dashboard URL, watch window, rollback

Plus, once:

4. `<PROJECT>/CLAUDE.md` — pipeline block, any research-specific overrides

## Autonomy contract

- No stops to ask Timm mid-session. If you're stuck (missing MCP access, dashboard unreachable, claim can't be evidenced), write the uncertainty into the artifact under `## Surfaces for Timm` and keep going.
- One surface at the end. Not incremental pings.

## Phase 1 — Per-feature analysis

For each feature in the cohort, produce a `### <feature_id>` subsection under `## Per-feature findings` covering:

- **Adoption.** Evidence from dashboard/metrics (named metric + dimension + value). Compare to brief's success criteria.
- **Pain points.** Evidence from support tickets (`customer-support:research`), dashboards, direct feedback. Cite ticket IDs / quote snippets.
- **Unmet needs.** What users asked for that this feature didn't cover. Evidence required.
- **Surprises.** What we didn't predict — positive or negative. Evidence required.
- **AC vs reality.** Did the AC actually translate to the outcome the brief wanted, or did it ship to AC but miss the point?

**Every significant claim cites ≥1 evidence source.** No citation = delete the claim. The validator enforces this.

**Correlation vs causation.** Use `data:statistical-analysis` to guard against confound. For any quantitative claim that implies causation (e.g., "feature X caused retention lift"), add a confound note — what else could explain this? The validator looks for confound notes when the body uses causal language.

## Phase 2 — Cohort-level synthesis

Run `design:research-synthesis` across the per-feature findings to surface:

- **Themes.** Patterns that appear across multiple features. Each theme cites ≥2 evidence sources (across ≥2 features).
- **Cross-cohort signals.** E.g., "every customer-facing launch this cohort needed manual copy — Build Marketing wrapper is the bottleneck." These often become LLM-Ops signal.
- **Anti-signals.** Things we expected to see but didn't. Also valuable.

Write under `## Cohort themes`.

## Phase 3 — Candidate list

For each next-feature candidate (or enhancement to an existing feature):

- **Problem statement.** One sentence, role-named user (not "customers").
- **Evidence.** ≥1 cited source. Cite by reference id (ticket, metric name + value, quote tag).
- **Signal strength.** `strong` (multi-source, quantifiable), `moderate` (single strong source or multi-source soft), `weak` (directional, worth watching).
- **Routing.** One of:
  - `new-ideate` — starts a fresh Session 01.
  - `existing-feature-enhancement` — scoped to an existing feature's next iteration; names that feature_id.
  - `backlog` — logged, not seeded.

Write under `## Candidates`. Every candidate must have all four fields. Missing any → validator RED.

## Phase 4 — Inbox seeding

For **strong-signal** candidates only:

1. Create `Code/pipeline/<PROJECT>/_inbox/<YYYY-MM-DD-slug>.md`. Use today's date for the prefix.
2. The stub uses the template in `references/inbox-stub-template.md`. Minimum: problem statement, evidence (pulled from the candidate), proposed route (usually `new-ideate`).
3. Record the inbox path under the candidate in `## Candidates`.

Moderate + weak candidates: listed in the report, not seeded. Timm pulls them up if/when interest rises.

## Phase 5 — Write & surface

1. Write `<COHORT_DIR>/05-research.md` using `references/research-template.md`. Set `status: ready-for-review`.
2. Run `scripts/check-research.sh <COHORT_DIR>/05-research.md` — fix every RED before surfacing.
3. Update `<COHORT_DIR>/00-cohort-manifest.md` (create if missing) with feature list + report path + inbox seeds.
4. Surface to Timm with the verbatim message in `references/close-checklist.md`. One surface. Include any `## Surfaces for Timm` items (unresolved uncertainty, MCP access gaps, flagged candidates needing human call).

## Deferred in v0.1.0

- **Automatic `_meta/metrics.md` aggregation.** LLM-Ops handles that — Research writes the raw per-cohort numbers into `05-research.md § Metrics summary` for LLM-Ops to pick up.
- **Cross-cohort trending.** Single-cohort scope only; trending is LLM-Ops territory.

## Project overrides read from `<PROJECT>/CLAUDE.md`

- `pipeline.research.cohort_size_max` — override default 5
- `pipeline.research.signal_strength_threshold` — override what counts as `strong` (default: ≥2 evidence sources from ≥2 dimensions — ticket+metric, quote+metric, etc.)
- `pipeline.research.inbox_dir` — override default `<PROJECT>/_inbox/`

## Files you touch

- `<COHORT_DIR>/05-research.md` (create)
- `<COHORT_DIR>/00-cohort-manifest.md` (create or update)
- `<PROJECT>/_inbox/<YYYY-MM-DD-slug>.md` (create one per strong-signal candidate)
- `lessons.md` in this skill (append on notable patterns)

## Files you must not touch

- Any feature directory under `<PROJECT>/<FEATURE_DIR>/` — read-only here
- Any project repo file
- `<COHORT_DIR>/` contents for cohorts other than this session's

## Smoke test

`bash scripts/smoke.sh` runs `check-research.sh` against three fixtures. Expected: good=rc0, bad-no-evidence=rc1 (candidates without citations), bad-missing-sections=rc1 (missing required H2s).

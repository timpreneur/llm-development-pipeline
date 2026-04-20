# 05-research.md — template

Canonical shape for the per-cohort Research session output. Every H2 must be present. Empty sections must be `N/A — <reason>`. Never silently omit.

```markdown
---
session: 05-research
cohort_id: YYYY-Www                         # or YYYY-MM
project: <project-name>
owner: cc
status: ready-for-review                    # flip to `reviewed` only after Timm reviews
features: [YYYY-MM-DD-slug-1, YYYY-MM-DD-slug-2, ...]
inputs_per_feature: [00-manifest.md, 01-brief.md, 04-ship.md]
updated: YYYY-MM-DD
inbox_seeds: [_inbox/YYYY-MM-DD-slug.md, ...]   # paths of strong-signal stubs created (or [] if none)
---

# 05-research — Cohort <cohort_id>

## Cohort scope

- Cohort window: YYYY-MM-DD → YYYY-MM-DD
- Features in cohort: <count>
- Cap (5): respected | split into <N> runs (this is run <i>/<N>, surface: <surface>)
- Excluded features (and why): <list or `none`>

## Per-feature findings

### <feature_id-1>

**Brief recap.** <one line — what the feature was supposed to do>

**Adoption.**
- <metric_name{dimension}> = <value> (source: dashboard <url>) — vs brief target: <met | partial | missed>
- …

**Pain points.**
- <ticket-id or quote-tag>: <observation>
- …

**Unmet needs.**
- <evidence-cited observation>
- …

**Surprises.**
- <evidence-cited observation>
- …

**AC vs reality.**
- <which AC translated cleanly; which AC shipped but missed the point>

**Confound notes (any causal claim above).**
- <claim> — alternative explanations: <…>

### <feature_id-2>

(same shape)

## Cohort themes

(Synthesis via design:research-synthesis. Each theme cites ≥2 evidence sources from ≥2 features.)

- **<theme name>** — <one line>. Evidence: <ref-1>, <ref-2>. Features: <feature_id-a>, <feature_id-b>.
- …

**Cross-cohort signals (LLM-Ops fuel).**
- <signal>. Evidence: <…>.

**Anti-signals (expected but didn't see).**
- <anti-signal>. Why we expected it: <…>.

## Candidates

For each candidate:

### <candidate slug>

- **Problem.** <one sentence, role-named user — not "customers">
- **Evidence.**
  - <ref-1> — <observation>
  - <ref-2> — <observation>
- **Signal.** strong | moderate | weak
- **Routing.** new-ideate | existing-feature-enhancement:<feature_id> | backlog
- **Inbox seed.** <path to _inbox/<YYYY-MM-DD-slug>.md if strong; otherwise N/A>

(Repeat per candidate. Strong-signal candidates MUST have an inbox seed; the validator checks.)

## Metrics summary

For LLM-Ops to pick up. Raw per-cohort numbers, no interpretation.

| metric | value | notes |
|--------|-------|-------|
| Features in cohort | <N> | — |
| First-pass done-signal rate (Ship) | <%> | <N>/<denom> |
| Re-entry count (Build) | <N> | sum across cohort |
| Critical security findings | <N> | sum |
| Critical legal findings | <N> | sum |
| Promotion success rate | <%> | <N>/<declared> |

## Surfaces for Timm

(One-time end-of-session surface. List every item that needs human attention. If none: `None — clean cohort.`)

- <item — reason needs Timm>
- …

## References

- Per-feature artifacts: `<PROJECT>/<FEATURE_DIR>/` (00-manifest.md, 01-brief.md, 04-ship.md)
- Dashboards consulted: <urls>
- Support tools consulted: <names>
- Direct feedback channels consulted: <names>
```

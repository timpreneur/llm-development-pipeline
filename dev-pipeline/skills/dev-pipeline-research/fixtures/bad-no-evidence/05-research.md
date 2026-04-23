---
session: 05-research
cohort_id: 2026-W18
project: example-fixture
owner: cc
status: ready-for-review
features: [2026-04-19-fixture-feature]
inputs_per_feature: [00-manifest.md, 01-brief.md, 04-ship.md]
updated: 2026-05-04
inbox_seeds: []
---

# 05-research — Cohort 2026-W18 (BAD: no evidence + strong-signal w/o seed)

Intentionally fails:
 - Candidate `naked-strong` is signal=strong but Inbox seed is N/A — strong-signal candidates must be seeded.
 - Candidate `evidenceless-moderate` Evidence block has zero citation bullets.
 - Candidate `evidenceless-moderate` Signal value is "meh" (not strong|moderate|weak).

## Cohort scope

- Cohort window: 2026-04-27 → 2026-05-03
- Features in cohort: 1
- Cap (5): respected
- Excluded features: none

## Per-feature findings

### 2026-04-19-fixture-feature

**Brief recap.** Placeholder fixture feature.

**Adoption.**
- placeholder

**Pain points.**
- placeholder

**Unmet needs.**
- placeholder

**Surprises.**
- placeholder

**AC vs reality.**
- placeholder

## Cohort themes

- placeholder theme. Evidence: none.

## Candidates

### naked-strong

- **Problem.** Users want a thing.
- **Evidence.**
  - ticket-9001 — observed
- **Signal.** strong
- **Routing.** new-ideate
- **Inbox seed.** N/A — fixture intentionally omits the seed to exercise the validator

### evidenceless-moderate

- **Problem.** Users might want another thing.
- **Evidence.**
  (intentionally no bullets to exercise the no-evidence reject path)
- **Signal.** meh
- **Routing.** backlog
- **Inbox seed.** N/A

## Metrics summary

| metric | value | notes |
|--------|-------|-------|
| Features in cohort | 1 | — |
| First-pass done-signal rate (Ship) | 100% | 1/1 |

## Surfaces for Timm

None — fixture cohort.

## References

- Per-feature artifacts: fixture
- Dashboards consulted: fixture
- Support tools consulted: fixture
- Direct feedback channels consulted: fixture

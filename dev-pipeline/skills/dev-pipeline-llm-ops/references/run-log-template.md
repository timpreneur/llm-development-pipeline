# _meta/runs/YYYY-MM-DDTHH-MM-<mode>.md — run-log template

One run log per LLM-Ops session. Shape varies by `mode`. Every H2 listed for the mode must be present. Empty sections → `N/A — <reason>`.

## Common frontmatter (all modes)

```yaml
---
session: llm-ops
mode: drift-check | lesson-reconciliation | metric-aggregation | fix-session
run_id: YYYY-MM-DDTHH-MM
owner: timm
status: complete | applied | rejected | deferred
updated: YYYY-MM-DD
---
```

## Common body sections (all modes)

```markdown
## Pre-flight

- In-flight manifest check (24h window): <passed | blocked because: <feature_id>(s)>
- Pipeline brief read: YES, at <path>, hash <sha256> (optional, for fix-session)
- _meta/ state read: YES (skill-hashes.json, metrics.md, CHANGELOG.md, runs/)
- Wrapper lessons.md sidecars read: <count> files

## CHANGELOG line

<exact one-liner that was appended to _meta/CHANGELOG.md>
```

## Mode § drift-check

Required H2 sections (in addition to common):

```markdown
## Hashes

| marketplace skill | previous sha256 | current sha256 | drifted? |
|-------------------|-----------------|----------------|----------|
| `schedule` | 3f21… | 3f21… | no |
| `data:interactive-dashboard-builder` | a9c0… | b112… | YES |
| `brand-voice:brand-voice-enforcement` | 772e… | 8ac4… | YES |

## Assessments

For each drift:

- **`data:interactive-dashboard-builder`** — <diff summary>. Verdict: OK | Review | Block. Affected wrapper(s): `dev-pipeline-ship`. Notes: <…>.
- **`brand-voice:brand-voice-enforcement`** — <diff summary>. Verdict: Review. Affected wrapper(s): `dev-pipeline-ship`. Notes: <…>.

## Hash update

- `_meta/skill-hashes.json` updated at YYYY-MM-DDTHH-MM (after assessments logged).
```

## Mode § lesson-reconciliation

Required H2 sections:

```markdown
## Wrappers scanned

- dev-pipeline-substrate: <N> entries, <U> un-reconciled
- dev-pipeline-ideate: <N> entries, <U> un-reconciled
- dev-pipeline-plan: <N> entries, <U> un-reconciled
- dev-pipeline-build: <N> entries, <U> un-reconciled
- dev-pipeline-ship: <N> entries, <U> un-reconciled
- dev-pipeline-research: <N> entries, <U> un-reconciled
- dev-pipeline-llm-ops: <N> entries, <U> un-reconciled

## Dispositions

For each un-reconciled entry reviewed this run:

### <wrapper>/<entry-title-or-date>

- Decision: Promote | Retire | Discard
- Destination (promote): <project/CLAUDE.md path and override key> OR <wrapper contract field>
- Retire reason (retire): <marketplace skill change that obviates it>
- Discard reason (discard): <noise signal>
- Age (entry_date → now): <N days>

## Threshold checks

- Median disposition age this run: <N days> (threshold 14)
- Verdict: <under threshold | BREACH — triggers fix-session>
```

## Mode § metric-aggregation

Required H2 sections:

```markdown
## Cohort source

- Cohort id: `YYYY-Www` or `YYYY-MM`
- 05-research.md path: `<COHORT_DIR>/05-research.md`
- Features: <count>

## Aggregated metrics

| metric (per session type) | value | threshold | verdict |
|---------------------------|-------|-----------|---------|
| First-pass done-signal rate (Ship) | 100% | ≥80% across 3 | OK |
| Re-entry count (Build) per feature | 0 | ≤2 across 3 | OK |
| Cross-session re-interview count per feature | 0 | ≤1 across 3 | OK |
| Promotion success rate | 100% | 100% | OK |
| Drift rate (wrappers needing review this quarter) | 1/7 = 14% | ≤30% | OK |
| Override promotion latency (median) | 6d | ≤14d | OK |

## Threshold checks

- Breaches: none | <list>
- Fix-session triggered: <no | YES — reason>

## metrics.md update

- Row appended to `_meta/metrics.md` at YYYY-MM-DDTHH-MM.
```

## Mode § fix-session

Required H2 sections:

```markdown
## Trigger

- Source: metric-aggregation run <run_id> | drift-check run <run_id> | Timm request on YYYY-MM-DD
- Specific signal: <metric + threshold + value> | <wrapper with Block verdict> | <Timm quote>

## Proposed change

- Files touched:
  - `pipeline-plugin/skills/<skill>/SKILL.md` — <diff summary>
  - `pipeline-plugin/skills/<skill>/references/<file>.md` — <diff summary>
- Rationale: <one paragraph, tied to the trigger>
- Expected metric effect: <which metric improves, by how much we predict>

## Brief delta

- Affected section in `llm-native-dev-pipeline-brief.md`: <section name or N/A>
- Diff summary: <…> | N/A — wrapper-only change, no brief impact

## Approval

- Surfaced to Timm at YYYY-MM-DDTHH-MM
- Timm response: approved | changes requested: <…> | rejected: <…>

## Applied changes (if approved)

- Plugin source edits: <file list>
- Brief edits: <file + section> | N/A
- CHANGELOG line appended.
- status: applied

(if rejected)

## Rejection notes

- Why Timm rejected: <…>
- Next action: <…>
- status: rejected
```

## File naming

`Code/pipeline/_meta/runs/YYYY-MM-DDTHH-MM-<mode>.md`

Examples:

- `2026-04-19T09-00-drift-check.md`
- `2026-04-19T10-15-lesson-reconciliation.md`
- `2026-05-04T11-30-metric-aggregation.md`
- `2026-05-04T15-45-fix-session.md`

# `_meta/` — contract

`Code/pipeline/_meta/` is LLM Ops' home. Three files. Substrate seeds them; session skills append to them via narrow contracts; LLM Ops reads all three and may rewrite them during maintenance passes.

## `_meta/skill-hashes.json`

Purpose: drift detection. Every marketplace skill referenced by a pipeline wrapper gets a hash of its `SKILL.md` at author time. LLM Ops re-hashes on its cadence and flags mismatches for review.

Schema:

```json
{
  "version": 1,
  "seeded_at": "YYYY-MM-DD",
  "seeded_by": "pipeline-substrate",
  "entries": [
    {
      "id": "marketplace:design-critique",
      "type": "marketplace",
      "reference": "design:design-critique",
      "path": "cowork/knowledge-work-plugins/design/*/skills/design-critique/SKILL.md",
      "hash": "sha256:<hex>",
      "hashed_at": "YYYY-MM-DD",
      "used_by": ["pipeline-build:ux-polish-mode"]
    },
    {
      "id": "builtin:review",
      "type": "built-in",
      "reference": "review",
      "path": null,
      "hash": null,
      "hashed_at": null,
      "used_by": ["pipeline-build:code-opt-mode"],
      "note": "Claude Code built-in; drift detected via CC version bump, not content hash."
    }
  ]
}
```

Rules:

- `type` is `marketplace` (hash-tracked) or `built-in` (not hash-tracked; version-tracked via Claude Code).
- `reference` is the skill / command identifier as invoked (`design:design-critique`, `review`, `security-review`).
- `path` on marketplace entries uses a glob where the version segment is `*`, because marketplace plugin versions change. LLM Ops resolves the glob at hash time.
- `hash` is `sha256:<hex-of-SKILL.md-bytes>` for marketplace entries, `null` for built-ins.
- `hashed_at` is the date of the last hash operation (author time for substrate's seed; rewritten by LLM Ops on re-hash).
- `used_by` lists wrapper identifiers (`pipeline-<skill>:<mode>` for mode-scoped use, or just `pipeline-<skill>` for wrapper-scoped).

Substrate seeds this file with every marketplace skill and built-in referenced across the pipeline at v0.1.0 (author time). The initial seed's hashes are placeholder `sha256:seed` — they get replaced on the first LLM Ops drift pass, which actually reads the installed SKILL.md files. This two-step seed avoids a chicken-and-egg problem where substrate runs before all the marketplace plugins are installed on the user's system.

Write policy: only `pipeline-substrate` (on bootstrap or repair) and `pipeline-llm-ops` (on drift checks / re-hash) write to this file.

## `_meta/CHANGELOG.md`

Purpose: append-only log of pipeline-level changes — substrate bootstraps, skill edits, brief-deltas, lesson reconciliation outcomes, metric threshold breaches + responses. Format:

```markdown
# pipeline/_meta/CHANGELOG.md

Append-only. Entries are dated. Owned by pipeline-substrate (seed, repairs) and pipeline-llm-ops (everything else).

## 2026-04-19
- substrate: workspace bootstrap (pipeline-substrate v0.1.0). Seeded _meta/skill-hashes.json (12 entries, all placeholder hashes), _meta/CHANGELOG.md, _meta/metrics.md.

## 2026-04-26
- llm-ops: drift check complete. 0 mismatches on marketplace entries; 12 placeholder hashes replaced with real hashes. Built-ins unchanged.

## 2026-05-03
- llm-ops: lesson reconciliation. 2 entries promoted to project CLAUDE.md pipeline.overrides (example-fixture ux_polish.forbidden_patterns), 1 retired (marketplace now covers), 0 discarded.
```

Rules:

- Entries are grouped by date (ISO `## YYYY-MM-DD`).
- Each bullet names the writer (`substrate:` or `llm-ops:`) and a short summary.
- Never delete or rewrite existing entries. To correct an earlier entry, append a correction with explicit reference.
- Brief-deltas (gaps between the brief at `.templates/` and what's actually authorable) get logged here when discovered — LLM Ops reviews and decides whether to update the brief.

Write policy: substrate appends one line on bootstrap or repair. LLM Ops appends whenever it runs a recurring task or fix-session.

## `_meta/metrics.md`

Purpose: aggregated per-session metrics across features. Populated by LLM Ops after each cohort Research session closes (per the brief's cadence).

Seed shape:

```markdown
# pipeline/_meta/metrics.md

Aggregated after each cohort Research session closes. Owned by pipeline-llm-ops.

## Thresholds (reference)

| Metric | Threshold | Source |
|--------|-----------|--------|
| First-pass done-signal rate (per session type) | <80% across 3 features | brief §LLM Ops |
| Re-entry count per feature (per session type) | >2 across 3 features | brief §LLM Ops |
| Cross-session re-interview count | >1 per feature across 3 | brief §LLM Ops |
| Promotion success rate | <100% | brief §LLM Ops |
| Marketplace-skill drift rate | >30% of wrappers drifting per quarter | brief §LLM Ops |
| Override promotion latency (lesson → CLAUDE.md) | median > 14 days | brief §LLM Ops |

## Per-session rolling rates

| Session       | First-pass done-signal | Re-entry avg | Last updated |
|---------------|------------------------|--------------|--------------|
| 01-ideate     | —                      | —            | —            |
| 02-plan       | —                      | —            | —            |
| 03-build      | —                      | —            | —            |
| 04-ship       | —                      | —            | —            |
| 05-research   | —                      | —            | —            |

## Per-cohort notes

(populated by pipeline-llm-ops after each cohort closes)
```

Rules:

- Thresholds section is a reference from the brief; don't edit without a brief-delta logged to CHANGELOG.md.
- Per-session rolling rates are rewritten on each metric pass, not appended.
- Per-cohort notes are appended, one section per cohort (`### <COHORT_ID>` headings).

Write policy: substrate seeds the table shape. LLM Ops rewrites per-session rows and appends cohort notes.

## Why three separate files

- `skill-hashes.json` is structured data — JSON because LLM Ops diffs it programmatically.
- `CHANGELOG.md` is append-only human-readable history. Markdown because it's for reading, not diffing.
- `metrics.md` mixes structured tables with narrative per-cohort notes — Markdown is the right fit.

If LLM Ops ever needs a new meta file (e.g., a lesson inventory), it proposes the schema via a brief-delta logged in `CHANGELOG.md` and updates `meta-contract.md` in the next substrate pass.

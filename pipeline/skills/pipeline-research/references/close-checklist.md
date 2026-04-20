# pipeline-research — close checklist

Run this before the one-and-only end-of-session surface to Timm.

## Checklist

1. Every H2 in `references/research-template.md` is present and non-empty in `05-research.md`. Empty sections must be `N/A — <reason>`, not omitted.
2. Frontmatter complete:
   - `session: 05-research`
   - `cohort_id`, `project`, `owner: cc`
   - `status: ready-for-review`
   - `features: [...]` matches `## Per-feature findings` subsection count
   - `inputs_per_feature: [00-manifest.md, 01-brief.md, 04-ship.md]`
   - `inbox_seeds: [...]` matches the strong-signal candidates that got seeded (or `[]` if none qualified)
3. Cohort cap respected. If split, every run notes the split + which surface this run covers.
4. Per-feature findings: every cohort feature has its own `### <feature_id>` subsection with all 6 inner blocks (Brief recap, Adoption, Pain points, Unmet needs, Surprises, AC vs reality). Confound notes present for any causal claim.
5. Cohort themes: each theme cites ≥2 evidence sources from ≥2 features.
6. Candidates: each candidate has Problem + Evidence (≥1 ref) + Signal + Routing + Inbox seed (or N/A if not strong).
7. Inbox seeds: every strong-signal candidate has a corresponding `<PROJECT>/_inbox/<YYYY-MM-DD-slug>.md` file, listed under the candidate AND in frontmatter `inbox_seeds`.
8. Metrics summary table populated with raw numbers (no interpretation).
9. Surfaces for Timm section is honest — every uncertainty + MCP-access gap + needs-human-call item is listed. Or `None — clean cohort.`
10. Cohort manifest at `<COHORT_DIR>/00-cohort-manifest.md` exists and lists features + report path + inbox seeds.
11. `bash scripts/check-research.sh <COHORT_DIR>/05-research.md` — no RED.

## Surface-to-Timm message (verbatim template — one surface only)

```
✅ 05-research.md ready for review — cohort <cohort_id>.

Project: <project>
Features in cohort: <count> (<feature_id-1>, <feature_id-2>, …)

**Themes (top 1–3, evidence in report).**
- <theme name>
- <theme name>

**Candidates.**
- Strong (seeded to inbox): <count>
- Moderate: <count>
- Weak: <count>

**Inbox seeds dropped** (each is fuel for a new Ideate session):
- `<PROJECT>/_inbox/<YYYY-MM-DD-slug-1>.md`
- `<PROJECT>/_inbox/<YYYY-MM-DD-slug-2>.md`

**Metrics summary** (raw — for LLM-Ops):
- First-pass done-signal rate (Ship): <%>
- Re-entry count (Build): <N>
- Critical security findings: <N>
- Critical legal findings: <N>
- Promotion success rate: <%>

**Surfaces for Timm.**
- <item — reason needs Timm>
- <item — reason needs Timm>
(Or: None — clean cohort.)

Artifact: `<COHORT_DIR>/05-research.md`
Cohort manifest: `<COHORT_DIR>/00-cohort-manifest.md`

Next step: pull a strong-signal stub from `_inbox/` into a fresh Ideate
session when you're ready.
```

## After Timm reviews

- If Timm replies with edits or "rework X" → cycle within this same session, re-run `check-research.sh`, re-surface.
- If Timm replies "reviewed" / "good" → flip `status: reviewed` in the report frontmatter. No further action needed; this session is done.
- If Timm pulls a stub into Ideate → that's a new Session 01, not part of this session's scope.

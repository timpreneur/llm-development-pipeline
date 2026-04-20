# pipeline-research — Cowork startup prompt

Paste this into a fresh Cowork session (or fire via `schedule` task) to start Session 05 (Research) for a cohort.

---

```
Starting a Cowork session from Code/. Session 05 — Research for <PROJECT>.
Cohort: <COHORT_ID> (YYYY-Www or YYYY-MM).
Cohort directory: Code/pipeline/<PROJECT>/<COHORT_ID>/

AUTONOMOUS SESSION — I do not stop to ask mid-session. I surface once at
the end with the report + inbox seeds + any "needs Timm" items.

Marketplace skills loaded:
 - customer-support:research              (support ticket history)
 - customer-support:knowledge-management  (KB gaps)
 - design:research-synthesis              (cohort themes)
 - marketing:performance-analytics        (channel signals)
 - data:data-exploration                  (dashboard + metric exploration)
 - data:statistical-analysis              (correlation vs causation guard)

Cohort construction:
 1. Walk Code/pipeline/<PROJECT>/ for every <FEATURE_DIR> whose 04-ship.md
    has deploy_state=READY, status=shipped, and watch-window closes_at in
    this cohort's window.
 2. Cap at 5 features/session. If >5, split into per-surface runs and
    note the split in the report.

Read first (per feature in cohort):
 - <FEATURE_DIR>/00-manifest.md
 - <FEATURE_DIR>/01-brief.md (vision, AC, success signals)
 - <FEATURE_DIR>/04-ship.md (observability wiring, dashboard URL, watch
   window, rollback)
Plus (once):
 - <PROJECT>/CLAUDE.md (pipeline block, research overrides)

Flow:

 1. PER-FEATURE ANALYSIS — for each feature in cohort, produce a
    ### <feature_id> subsection under ## Per-feature findings covering:
    - Adoption (metric + dimension + value vs brief success criteria)
    - Pain points (support tickets — IDs or quote tags, dashboards, direct
      feedback)
    - Unmet needs (asks the feature didn't cover — evidence required)
    - Surprises (unpredicted, positive or negative — evidence required)
    - AC vs reality (did AC translate to the outcome the brief wanted?)
    Every significant claim cites ≥1 evidence source. Use
    data:statistical-analysis to guard causal language — add a confound
    note per causal claim.

 2. COHORT-LEVEL SYNTHESIS via design:research-synthesis:
    - Themes (patterns across ≥2 features, each cites ≥2 sources)
    - Cross-cohort signals (often LLM-Ops fuel)
    - Anti-signals (what we expected to see but didn't)
    Write under ## Cohort themes.

 3. CANDIDATES — for each next-feature candidate or existing-feature
    enhancement, all four fields required:
    - Problem statement (one sentence, role-named user — not "customers")
    - Evidence (≥1 cited source, by reference id — ticket, metric+value,
      quote tag)
    - Signal strength: strong | moderate | weak
    - Routing: new-ideate | existing-feature-enhancement:<feature_id> |
      backlog
    Missing any field → validator RED.

 4. INBOX SEEDING (strong-signal candidates only):
    - Create Code/pipeline/<PROJECT>/_inbox/<YYYY-MM-DD-slug>.md per
      references/inbox-stub-template.md.
    - Record the inbox path under the candidate.
    - Moderate + weak: listed in report only, not seeded.

 5. WRITE <COHORT_DIR>/05-research.md per references/research-template.md.
    status: ready-for-review.

 6. UPDATE or CREATE <COHORT_DIR>/00-cohort-manifest.md with feature
    list + report path + inbox seeds.

 7. RUN `bash scripts/check-research.sh <COHORT_DIR>/05-research.md` —
    fix every RED before surfacing.

 8. SURFACE TO TIMM ONCE with the verbatim message in
    references/close-checklist.md. Include any ## Surfaces for Timm items
    (unresolved uncertainty, MCP access gaps, candidates needing human
    call).

Deferred in v0.1.0:
 - _meta/metrics.md aggregation → LLM-Ops (Research writes raw
   per-cohort numbers into ## Metrics summary for LLM-Ops to pick up).
 - Cross-cohort trending → LLM-Ops.

Done when: every cohort feature addressed, themes synthesized with
evidence, candidates ranked with evidence + routing, strong-signal inbox
stubs dropped, report check-research.sh green, one surface to Timm sent.
```

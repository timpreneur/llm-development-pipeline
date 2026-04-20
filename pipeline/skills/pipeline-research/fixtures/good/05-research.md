---
session: 05-research
cohort_id: 2026-W18
project: example-fixture
owner: cc
status: ready-for-review
features: [2026-04-19-document-share-link, 2026-04-22-workspace-setup-checklist]
inputs_per_feature: [00-manifest.md, 01-brief.md, 04-ship.md]
updated: 2026-05-04
inbox_seeds: [_inbox/2026-05-04-share-link-resolve-retry-flow.md]
---

# 05-research — Cohort 2026-W18

## Cohort scope

- Cohort window: 2026-04-27 → 2026-05-03
- Features in cohort: 2
- Cap (5): respected
- Excluded features (and why): none

## Per-feature findings

### 2026-04-19-document-share-link

**Brief recap.** Owners could generate a 14-day read-only share link for a document; recipients hit `/s/<token>`; link status (active / viewed / expired) shows on owner's doc page.

**Adoption.**
- `share_links.create.count{region=NA}` = 312 over 14d (dashboard: https://datadog.example/dashboards/share-links-v1) — vs brief target of ≥100 links: met (3.1× target)
- `share_links.resolve.success_rate{region=NA}` = 0.91 over 14d — vs brief implied target ≥0.95: partial (9pp gap)

**Pain points.**
- ticket-8142: "link said expired after 2 days even though it should last 14" — recipient hit a rate-limit 429 on first click, which the UI rendered as "expired"
- ticket-8196 + ticket-8211: same pattern — 429 misread as expiry by recipients
- quote-t42 (Slack #product-ops, 2026-04-29): "I've had 4 recipients tell me the link doesn't work"

**Unmet needs.**
- ticket-8190: owner asked "can I revoke an active link?" — Non-goals in brief explicitly excluded revoke, but 7 tickets in cohort flagged this
- ticket-8203: "I want to generate 20 share links at once" — bulk link creation

**Surprises.**
- Adoption 3.1× target. Positive surprise; suggests pent-up demand that predates this feature.
- Recipient-side page-load success was 99.4%, better than project baseline (94%). Likely because the view page is short and has no marketing footer yet.

**AC vs reality.**
- AC 2 (link-create returns 201 within 800ms): shipped clean. ✓
- AC 4 (status flips to "viewed" within 60s): shipped clean, but the RELATED pain point is 429-on-resolve-reads-as-expired, which is *between* AC 3 (token verify) and AC 4 (status flip). Neither AC caught it.

**Confound notes (any causal claim above).**
- "Pent-up demand" (surprise): alternative explanations — novelty effect (first 14d post-launch); email announcement driver (we posted in the changelog feed 2026-04-22). Watch the W19+ adoption curve to disambiguate.

### 2026-04-22-workspace-setup-checklist

**Brief recap.** Checklist widget on the workspace home guides new workspace owners through their first 5 setup tasks.

**Adoption.**
- `onboarding_checklist.task_completion_rate{step=connect_source}` = 0.71 over 11d (dashboard: https://datadog.example/dashboards/onboarding-checklist-v1) — vs brief target ≥0.60: met
- `onboarding_checklist.task_completion_rate{step=invite_teammate}` = 0.12 — vs brief target ≥0.40: missed (28pp gap)

**Pain points.**
- ticket-8205: "checklist says invite a teammate but I'm the only person on my team right now" — 4 similar tickets
- quote-t49 (support intake form, 2026-04-30): "I'm a new workspace, I don't have teammates yet"

**Unmet needs.**
- Owners want an "I'll do this later" dismiss per-step option. 6 tickets + 3 intake quotes.

**Surprises.**
- `connect_source` step completion 71% (well above target). Suggests the friction was discovery, not willingness.

**AC vs reality.**
- All 4 AC shipped clean.
- Brief success criterion was "≥40% complete all 5 tasks in first week" — actual 18%. The missed target is driven entirely by `invite_teammate` step, not the widget itself.

**Confound notes (any causal claim above).**
- The `invite_teammate` step low completion is likely caused by solo-founder workspaces at setup time, not by widget UX. Alt explanation: UX friction we haven't measured — we'd need a session recording sample to rule out.

## Cohort themes

- **UI conflates rate-limiting with expiry/permanence.** Evidence: ticket-8142, ticket-8196, ticket-8211 (share-link); quote-t49 framing (onboarding checklist asks for action user can't take, UI offers no "later" path). Features: 2026-04-19-document-share-link, 2026-04-22-workspace-setup-checklist. Pattern: the workspace surfaces terminal-looking states for transient/deferrable conditions.
- **Success-criteria / AC mismatch.** Evidence: share-link AC 2+3+4 all PASS but 9pp gap on resolve.success_rate; onboarding AC all PASS but 22pp gap on 5-task completion. Features: both. Neither brief had an AC that directly tied to the cohort-level outcome metric.

**Cross-cohort signals (LLM-Ops fuel).**
- Both features shipped with customer-facing release notes authored manually (Build's Marketing wrapper deferred in v0.1.0). Both voice-checks were ADVISORY-ONLY. Signal: v0.1.x priority candidate — promote Build Marketing wrapper + flip voice-check to gating. Evidence: 04-ship.md § Release notes in both features.

**Anti-signals (expected but didn't see).**
- No regulated-surface findings. Expected because brief flags were false, but worth noting the regulated-path has not been exercised end-to-end in this cohort.
- No rollback events. Expected for a small cohort but notable — neither feature tripped the rollback trigger.

## Candidates

### share-link-resolve-retry-flow

- **Problem.** Recipients hit a 429 on the first resolve-link click and the UI renders that as "link expired," making owners think the share system is broken.
- **Evidence.**
  - ticket-8142 — "link said expired after 2 days" (actually 429)
  - ticket-8196 — same pattern, different owner
  - ticket-8211 — same pattern, owner reports 4 recipients affected
  - quote-t42 (Slack #product-ops) — "4 recipients tell me the link doesn't work"
  - metric `share_links.resolve.success_rate{region=NA}` = 0.91 (9pp gap vs implied target)
- **Signal.** strong
- **Routing.** new-ideate
- **Inbox seed.** `example-fixture/_inbox/2026-05-04-share-link-resolve-retry-flow.md`

### onboarding-checklist-defer-step

- **Problem.** New solo-founder workspaces get told to "invite a teammate" with no deferral path, which hurts checklist completion.
- **Evidence.**
  - ticket-8205 + 4 similar tickets
  - quote-t49 (support intake, 2026-04-30)
  - metric `onboarding_checklist.task_completion_rate{step=invite_teammate}` = 0.12 (28pp gap)
- **Signal.** moderate
- **Routing.** existing-feature-enhancement:2026-04-22-workspace-setup-checklist
- **Inbox seed.** N/A (moderate signal)

### bulk-share-link-create

- **Problem.** Owners with ≥10 docs want a bulk-link-creation flow.
- **Evidence.**
  - ticket-8203 — "I want to generate 20 share links at once"
- **Signal.** weak
- **Routing.** backlog
- **Inbox seed.** N/A (weak signal)

## Metrics summary

| metric | value | notes |
|--------|-------|-------|
| Features in cohort | 2 | — |
| First-pass done-signal rate (Ship) | 100% | 2/2 |
| Re-entry count (Build) | 0 | — |
| Critical security findings | 0 | 1 medium resolved in 5c1d80 (share-link) |
| Critical legal findings | 0 | both features regulated=false |
| Promotion success rate | 100% | 2/2 projects had repo_brief_dir + changelog_path declared; both completed |

## Surfaces for Timm

- `share-link-resolve-retry-flow` strong-signal candidate is seeded. Worth pulling into Ideate ahead of the next planned work — recipients currently perceive the share system as broken.
- Cross-cohort signal on Build Marketing wrapper deferral is starting to accumulate (2/2 customer-facing launches needed manual copy in v0.1.0). LLM-Ops will see this in the metrics summary; worth flagging now.

## References

- Per-feature artifacts: `example-fixture/2026-04-19-document-share-link/`, `example-fixture/2026-04-22-workspace-setup-checklist/`
- Dashboards consulted: https://datadog.example/dashboards/share-links-v1, https://datadog.example/dashboards/onboarding-checklist-v1
- Support tools consulted: customer-support MCP (ticket history range 2026-04-19 → 2026-05-03)
- Direct feedback channels consulted: Slack #product-ops (quote-t42, t49), support intake form exports (quote-t49)

# pipeline-ship — lessons

Append-only sidecar. One entry per notable pattern or edit-worthy incident. Tag entries by phase.

Entry shape:

```
## YYYY-MM-DD — <short title> [<phase>]

- Context: <one line>
- Signal: <what surfaced it — a failure mode, a repeated fixup, Timm feedback>
- Candidate change: <proposed wrapper edit or project override>
- Promotion: <yes | watch | no>
```

Valid `<phase>` tags: `preflight`, `deploy`, `observability`, `watch`, `rollback`, `release-notes`, `promotion`, `close`.

---

## 2026-04-19 — v0.1.0 deferral: customer-facing copy authored manually [release-notes]

- Context: Build's Marketing wrapper is deferred in v0.1.0. Build draft arrives as `N/A — wrapper deferred` for customer-facing features.
- Signal: Design decision from the pipeline brief. Ship must bridge the gap for v0.1.0.
- Candidate change: In v0.1.x, wire `marketing:content-creation` + `brand-voice:brand-voice-enforcement` into Build so Ship's customer-facing release note is a voice-checked edit, not a from-scratch draft. Flip voice-check from advisory to gating once Build's draft is reliable.
- Promotion: watch.

## 2026-04-22 — ship-punchlist merged into pipeline-ship: agentic-first QA [close]

- Context: Absorbed the standalone ship-punchlist app into pipeline-ship. Inserted Phase 3 (Agentic QA — live-URL checks against AC) and Phase 4 (human punchlist scoped to residuals) between Deploy and Observability. Schema v2 with `schema_version: "2"`, `feature_id`-keyed files at `.punchlist/<feature_id>.json`, plus a V1 pointer `{"schema_version":"2","ref":"<feature_id>.json"}` at `.punchlist/<short_sha>.json` so the installed pre-push hook keeps passing for pipeline ships. Web app got a dual-format reader + new `/[owner]/[repo]/feature/[feature_id]` route. Severity model: `blocking` (gates sign-off per `pipeline.punchlist_gating`, strict default) vs `watch` (flows through the existing inbox during the watch window).
- Signal: The two tools were fighting each other — standalone punchlist asked humans to re-run checks the pipeline could verify autonomously. "Don't pad" principle applied: Phase 4 `items[]` is the residual after Phase 3, not a minimum. Empty `items[]` is a valid, celebrated outcome ("agent verified all AC, no human QA required").
- Candidate change: Watch for two failure modes over the next ~5 cohorts. (a) `autonomous_coverage_pct < 50` becoming the median — would mean the playbook's default `checks_run` list is under-configured, not a one-off; tune `agentic-qa-playbook.md`. (b) `items[].severity: watch` items piling up un-reviewed during the watch window — would mean `inbox.md` routing isn't closing the loop; promote a watch-window nudge into `close-checklist.md`. Also watch for pointer-file drift: if a project's pre-push hook rejects v2 pointers, the promotion step needs a compat shim.
- Promotion: watch.

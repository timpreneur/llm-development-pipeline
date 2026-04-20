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

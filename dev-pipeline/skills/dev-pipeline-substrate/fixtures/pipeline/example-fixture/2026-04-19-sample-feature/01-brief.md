---
session: 01-ideate
feature_id: 2026-04-19-sample-feature
project: example-fixture
owner: timm
status: done
inputs: []
updated: 2026-04-19
regulated: false
customer_facing_launch: true
---

# 01-brief — Sample Feature

This is a substrate-fixture brief. It exists so the convention can be validated end-to-end without a real feature being in flight. Every required section is present, content is intentionally thin.

## Vision
A sample customer-facing capability on the workspace home, used only to exercise the pipeline plumbing.

## Pressure-test — alternatives

1. **Do nothing.** Users have no current signal that this is missing; cost of build > signal strength. Rejected because: fixture needs ≥2 alternatives to pass the Ideate guardrail.
2. **Bolt onto existing dashboard widget.** Cheaper, but collides with layout conventions and will confuse the existing UI. Rejected because: fixture.

## Scope
- In: fixture scope. Stub brief.
- Out: anything that would make this a real feature.

## Acceptance criteria (observable)
- The fixture feature dir exists at `Code/pipeline/example-fixture/2026-04-19-sample-feature/`.
- Every required artifact is present and passes frontmatter lint.
- The manifest's status table reflects reality.

## Decisions needed
None. Fixture.

## Non-goals
- Shipping real code.
- Exercising conditional modes (legal / marketing) — those wrappers are deferred.

## Context
This brief is part of `dev-pipeline-substrate`'s smoke test. It is not meant to be executed as a real feature.

## Flags rationale
- `regulated: false` — no PII, no payments, no regulated surface.
- `customer_facing_launch: true` — fixture exercises the marketing-draft conditional path (which currently writes "N/A — wrapper deferred").

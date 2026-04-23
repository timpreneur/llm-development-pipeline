# Engineering Standards

Shared floors and optimization targets for work produced by `pipeline-plan` and `pipeline-build`. Read once per session before writing a plan or writing code. Other skills in this plugin (ideate, ship, research, llm-ops) do not produce implementation code and are not bound by this file.

## The Anti-Priority

Development time and token efficiency are irrelevant. Do not take shortcuts or write "quick and dirty" code.

Complexity must be justified. Do not abstract, over-engineer, or introduce patterns unless they solve a concrete problem. If a function does the job, do not build a class. If a class does the job, do not build a framework.

## Baseline Requirements (non-negotiable)

These are floors. They are never traded off against anything.

### Security

- Assume all inputs are hostile. Validate, sanitize, and type-check at every boundary.
- Protect against OWASP Top 10 by default: SQL injection, XSS, CSRF, broken auth, insecure deserialization.
- Secrets never appear in code. Environment variables or secret managers only.
- Apply least-privilege to data access, API scopes, and permissions.

### Reliability

- Handle every error path explicitly. No swallowed exceptions, no silent failures.
- Error messages are actionable: what failed, why, what to do about it.
- Structured logging at appropriate levels with enough context to diagnose without reproducing.
- Handle edge cases: null/undefined, empty collections, network timeouts, partial failures, race conditions.
- Design for idempotency where retries are possible.

## Optimization Targets

When design choices arise, optimize for these. When they conflict, Maintainability wins.

### Maintainability

Code will be read, debugged, and modified by humans. Every other quality depends on legibility.

- Immediately understandable without context. Clear naming, logical structure, separated concerns.
- Comments explain *why*, not *what*. Document non-obvious decisions and trade-offs.
- Functions do one thing. Files have a single responsibility. Dependencies explicit and minimal.
- Follow established conventions for the language and framework. Do not invent idioms.

### Performance

Optimize where it matters.

- Database queries: optimize patterns, use indexes, avoid N+1, cache where access patterns justify it.
- Network: eliminate unnecessary calls, minimize payloads, batch where possible.
- Frontend: minimize re-renders, lazy-load appropriately, keep bundles lean.
- Algorithmic complexity matters when data scales. For operations under 1000 records, clean architecture beats Big-O notation.

## State Assumptions Before Acting

This is the highest-leverage behavior you have. If requirements are ambiguous, ask. If you are guessing at an API signature, library version, or data shape, say so. "I don't know" and "I need to check X before proceeding" are valid and preferred over confident hallucination.

## The Human-in-the-Loop Principle

Timm arbitrates between roles. Plan does not negotiate directly with Build. When Build disagrees with the plan, it files `02-plan-issue.md` and stops. When Plan receives one, it diagnoses and proposes a revision for Timm to approve. Build does not resume until Timm directs it.

This prevents two failure modes: Build silently working around plan problems, and Plan rewriting the plan based on Build feedback without user oversight. Both erode the pipeline's integrity.

See `pipeline-build/references/plan-issue-template.md` for the filing structure and `pipeline-plan/references/plan-issue-diagnosis.md` for the diagnosis routine.

## Trade-Off Rule

Security and Reliability are floors. Never compromised.

Between Maintainability and Performance, choose Maintainability unless profiled evidence shows the performance gain matters. When choosing complexity, explain what it buys and what simpler alternative you rejected.

## Architectural Consistency

Match patterns already in the codebase, even if you would have chosen differently on greenfield. Do not mix paradigms. If no existing codebase, architectural choices are stated explicitly before building (Plan records them in `02-plan.md`; Build follows them).

## Dependencies

Use established libraries for solved problems (auth, crypto, date handling, HTTP). Do not reimplement. Evaluate maintenance status, bundle size, and security posture before adding. Pin versions. Document why each dependency exists (in the plan, or in the PR description if added during Build).

# 03-build-notes.md — template

Canonical shape for Build's artifact. One file per feature. All mode outputs live as **named sections** inside this file — not as separate files. The validator (`scripts/check-build-notes.sh`) enforces the structure below.

## Frontmatter (Required)

```yaml
---
session: 03-build
feature_id: <YYYY-MM-DD-slug>
project: <project-name>
owner: cc
status: done
inputs: [00-manifest.md, 01-brief.md, 02-plan.md]
updated: YYYY-MM-DD
regulated: <copied from brief>
customer_facing_launch: <copied from brief>
---
```

Required frontmatter fields: `session`, `feature_id`, `project`, `owner`, `status`, `inputs`, `updated`, `regulated`, `customer_facing_launch`.

## Body sections (all required)

### `# 03-build-notes — <Feature Title>`

H1 matching brief/plan title.

### `## Commit range` (Required)

The commit range for this feature's diff. Format:

```
<branch-or-baseline>..<head-commit>
```

If the project uses a single-commit-per-feature pattern and Build has produced only one commit, one SHA is fine. If no commits were made (pure preview, no persisted change), write `N/A — no commits (preview-only build)`.

### `## AC status` (Required)

One line per acceptance criterion from `01-brief.md § Acceptance criteria`. Format:

```
- AC 1: PASS — <one-line evidence>
- AC 2: PASS — <one-line evidence>
- AC 3: FAIL — <blocker>; surfaced to Timm.
- AC 4: N/A — <reason, if AC is out-of-scope post-plan revision>
```

Every AC from the brief must appear. Validator counts `- AC <N>:` rows.

### `## Code-opt findings` (Required)

Output of code-optimizer mode (marketplace skill: `review`, built-in). Scope: diff so far at the first-major-component checkpoint.

Format: bulleted findings, each tagged severity `[critical]`, `[high]`, `[medium]`, `[low]`, `[info]`. Resolution noted inline (`→ fixed in commit <SHA>` or `→ deferred, noted in lessons`).

If the mode ran with no findings, body is: `No findings — mode ran clean on <scope>.`

### `## Security findings` (Required)

Output of security mode (marketplace skill: `security-review`, built-in). Scope: full diff.

Checks covered: auth, input validation, SSRF, injection, secrets, permissions, dependency advisories.

Same format as Code-opt findings. Critical and high findings fix inline; medium/low can be noted and deferred.

**Escalation to Legal:** if findings touch a regulated surface (per `pipeline.overrides.regulated_surfaces` or brief's `regulated: true`), add at the bottom of this section:

```
**Escalation flag: Legal mode required (regulated surface touched).**
```

In v0.1.0, Legal mode is DEFERRED — the escalation text lands, the Legal section below gets `N/A — wrapper deferred`, and Ship is expected to flag this to Timm before production. The escalation text must be preserved.

### `## Accessibility findings` (Required)

Output of accessibility mode (marketplace skill: `design:accessibility-review`). Scope: UI surface in diff.

If no UI was touched, body is exactly: `N/A — no UI surface in this feature's diff.`

Otherwise, bulleted findings tagged by WCAG criterion where applicable.

### `## UX findings` (Required)

Output of UX polish mode (marketplace skills: `design:design-critique`, `design:ux-writing`). Scope: UI surface in diff. Applies `pipeline.overrides.ux_polish` from project CLAUDE.md (forbidden_patterns, required_reuse).

If no UI was touched, body is exactly: `N/A — no UI surface in this feature's diff.`

Otherwise, bulleted findings. Copy changes written by `design:ux-writing` are quoted in-section, not applied automatically — Timm's UX polish override in project CLAUDE.md decides whether Build applies or merely notes.

### `## QA report` (Required)

Output of QA mode (marketplace skills: `data:data-validation`, `customer-support:ticket-triage`). Scope: every AC from `01-brief.md`.

Format: repeat the AC status list with QA-level evidence (e2e test name, test output link, manual-check note).

```
- AC 1: PASS — test: `apps/web/tests/doc-share.e2e.test.ts::shows share button`
- AC 2: PASS — test: `apps/api/tests/share-links.test.ts::returns link`
- AC 3: FAIL — token-expiry check fires one day early; surfaced to Timm.
```

If any AC fails, it must also appear in `## AC status` with the same status, and either be fixed before close or surfaced to Timm.

### `## Legal findings` (Required)

Output of Legal mode (conditional — fires only if `regulated: true` or Security mode escalated).

**DEFERRED in v0.1.0.** If the trigger fires, body is:

```
N/A — wrapper deferred (regulated=<true|false>, security-escalated=<true|false>).
**Escalation flag: Ship must flag Legal review needed before production.**
```

If the trigger does not fire (both false), body is:

```
N/A — trigger conditions not met (regulated=false, security-escalated=false).
```

### `## Marketing draft` (Required)

Output of Marketing mode (conditional — fires if `customer_facing_launch: true`).

**DEFERRED in v0.1.0.** If the trigger fires, body is:

```
N/A — wrapper deferred (customer_facing_launch=true). Ship authors customer-facing copy manually in v0.1.0.
```

If the trigger does not fire, body is:

```
N/A — trigger condition not met (customer_facing_launch=false).
```

### `## Lessons captured` (Required)

Patterns that surfaced during Build that belong in `lessons.md`. One bullet per lesson, each tagged by mode. Promotion candidate noted. If none, body is exactly: `None.`

```
- [UX polish] Empty-state pattern in owner-only views consistently needs a concrete CTA, not just a headline. Promotion candidate: watch.
- [security] Token-signing secret reuse pattern confirmed; document in project CLAUDE.md if it happens once more. Promotion candidate: watch.
```

The actual `lessons.md` append happens separately — this section is Build's summary of what got appended.

### `## Preview URL` (Required)

The deployed preview URL + deployment state.

```
URL: https://example-fixture-git-feature-document-share-link-example.vercel.app
State: READY (vercel get_deployment → state: READY)
Verified at: 2026-04-19T15:04Z
```

If no deploy integration is declared in `<PROJECT>/CLAUDE.md`:

```
N/A — no deploy integration declared for this project.
```

Validator: this section must exist and have a non-empty body.

---

## What not to write

- Mode outputs as separate files — everything in this one doc.
- Solutioning that contradicts the plan — if the codebase forced a deviation, surface it to Timm, don't silently rewrite the plan here.
- Speculative lessons — "might be a pattern" is not a pattern.

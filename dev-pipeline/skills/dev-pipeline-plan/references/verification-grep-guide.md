# Verification grep guide

The `## Verification` section is the most important part of `02-plan.md`. It's the evidence that the plan is grounded in what the codebase actually is — not what the brief assumed it is.

## What to grep for

Walk the brief and ask, for each statement: "Is this already true in the repo? Where?"

Categories to check:

1. **Named primitives.** Every table, type, component, endpoint, hook, utility, or service the brief references. If the brief says "reuse the existing email flow," grep for the email flow.
2. **Patterns the brief assumes.** "Owners have a workspace home" → grep for the home route. "Auth is handled" → grep for auth middleware.
3. **Files the brief implies will exist.** If Scope mentions "a ShareLinks panel," grep for Share/share to see what's there.
4. **Reuse candidates.** Before planning a new helper/component, grep for similar names and shapes — there's usually a pattern to follow.
5. **`pipeline.overrides.required_reuse` from project CLAUDE.md.** Every listed pattern must appear in `## Reuse anchors` with a verified location.
6. **`pipeline.overrides.forbidden_patterns` from project CLAUDE.md.** Grep to confirm the plan doesn't introduce any forbidden patterns.
7. **Risk surface.** Migrations present → grep migration history. Cross-package types → grep the shared types package. Secrets → grep `.env.example`.
8. **Test patterns.** Grep existing tests for the kind of test Build will add.

## Log format

One row per grep. Column headers:

- `#` — incrementing index.
- `Looked for` — plain-language description of what you were checking.
- `Command / pattern` — the actual grep invocation (or a natural-language description if you used a file-read / structural check).
- `Result` — what you found. Be specific. Paths, match counts, surprises.

Example row:

```
| 2 | Existing share-links table | grep -r 'model ShareLink\|share_links' packages/db/prisma/ | Found: model ShareLink in schema.prisma (line 412). Missing fields: viewed_at, expires_at. Task 1 adds both. |
```

## Don't omit

- Greps that returned **nothing** — that's evidence too. A nothing-found result means the plan is creating something new, which changes `## Files touched` and `## Risk callouts`.
- Greps that returned **surprises** — flag as brief-drift in `## Open questions` if the surprise contradicts a brief assumption.

## Don't fabricate

If you haven't actually run the grep, don't write a row for it. Plan mode gives you read access to the repo — use it.

## Minimum bar

The validator doesn't count rows, but a typical feature produces **5–15 verification rows**. Under 3 is a flag; the plan is probably under-researched.

## Format flexibility

Table is preferred (parseable, scannable). A bulleted list is acceptable if the table gets unwieldy. What matters: every grep has a distinct entry with query + result.

---
session: 02-plan
feature_id: 2026-04-19-bad-example-missing-sections
project: example-fixture
owner: cc
status: done
inputs: [00-manifest.md, 01-brief.md]
updated: 2026-04-19
regulated: false
customer_facing_launch: false
---

# 02-plan — Bad Example (Missing Required Sections)

Intentionally omits `## Side-effects` and `## Rollback` to exercise the section-presence rejects.

## Summary

Placeholder.

## Task list

1. Placeholder task.
2. Placeholder task two.

## Files touched

Task 1:
- create: placeholder.md

## Reuse anchors

- Placeholder.

## Risk callouts

- Placeholder.

## Test strategy

Placeholder strategy.

## Verification

| # | Looked for | Command / pattern | Result |
|---|------------|-------------------|--------|
| 1 | placeholder | grep placeholder | Found. |
| 2 | placeholder2 | grep placeholder2 | Found. |
| 3 | placeholder3 | grep placeholder3 | Found. |

## Open questions

None.

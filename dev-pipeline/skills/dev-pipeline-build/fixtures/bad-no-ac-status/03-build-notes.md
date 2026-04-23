---
session: 03-build
feature_id: 2026-04-19-bad-example-no-ac
project: example-fixture
owner: cc
status: done
inputs: [00-manifest.md, 01-brief.md, 02-plan.md]
updated: 2026-04-19
regulated: false
customer_facing_launch: false
---

# 03-build-notes — Bad Example (No AC Rows)

Intentionally has `## AC status` heading but no `- AC <N>:` rows — exercises the AC-count reject path.

## Commit range

main..abc1234

## AC status

(no rows on purpose — fixture)

## Code-opt findings

No findings — mode ran clean.

## Security findings

No findings — mode ran clean.

## Accessibility findings

N/A — no UI surface in this feature's diff.

## UX findings

N/A — no UI surface in this feature's diff.

## QA report

No AC rows in fixture.

## Legal findings

N/A — trigger conditions not met (regulated=false, security-escalated=false).

## Marketing draft

N/A — trigger condition not met (customer_facing_launch=false).

## Lessons captured

None.

## Preview URL

https://fixture-preview.example/
State: READY

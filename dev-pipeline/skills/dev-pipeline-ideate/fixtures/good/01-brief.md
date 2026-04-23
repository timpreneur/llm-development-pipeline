---
session: 01-ideate
feature_id: 2026-04-19-document-share-link
project: example-fixture
owner: timm
status: done
inputs: [00-manifest.md]
updated: 2026-04-19
regulated: false
customer_facing_launch: true
---

# 01-brief — Document Share Link

## Vision

**What.** A document owner can generate a time-limited public share link for a document, and the recipient of that link lands on a read-only view page that works without an account.

**Who.** A workspace owner who needs to share a single document with an outside collaborator one time, without adding them as a workspace member.

**Why.** Today, sharing a document with someone outside the workspace requires an account invite plus seat cost. Moving to link-based sharing unlocks ad-hoc external collaboration without the account overhead.

## Pressure-test

### Alternative 1 — Export to PDF and email
What it is: Owner exports the doc as a PDF and attaches it to an email.
Why it doesn't work here: Breaks the live-link to the source doc; recipient gets a snapshot that stales immediately, and there's no way to revoke access after send.

### Alternative 2 — Generic link-sharing SaaS
What it is: Off-the-shelf document-sharing tool bolted onto the workspace.
Why it doesn't work here: Introduces a second auth surface and fragments the workspace's single-source-of-truth for permissions. Link provenance would live outside the app.

### Alternative 3 — Do nothing
What it is: Keep account-invite-only sharing.
Why it doesn't work here: Users repeatedly ask for a lighter-weight path. Friction is a blocker for external collaboration use cases.

## Brief

### Scope

- An owner can open a document and click a Share button to generate a link.
- The owner sees the link copied to their clipboard within 2 seconds of click.
- The link is valid for 14 days from creation.
- A recipient who opens the link lands on a read-only view of the document without logging in.
- The owner sees link status (active / viewed / expired) on the document page.

### Acceptance criteria

1. When an owner opens a document, they see a Share button in the document header.
2. When the owner clicks Share and confirms, the system returns a link within 2 seconds.
3. When a recipient opens the link within 14 days, they land on a read-only view of the document.
4. When a recipient views the link for the first time, the owner's link status flips to "viewed" within 60 seconds.
5. When a link is older than 14 days, it shows as expired on the owner's page and the public view returns a 410.

### Non-goals

- Password-protected share links — deferred.
- Editable share links (recipients can edit) — deferred.
- Bulk link creation (many docs at once) — deferred.
- Revoking or recalling an active link — deferred.

### Decisions needed

- [Timm] Does the link carry the recipient's identity (they must enter email before viewing) or is it fully anonymous?
- [Plan] Does the read-only view reuse the existing document-render component, or does it need a stripped read-only variant?

## Flags

regulated: false — no PII collected; link token is the only identifier and carries no user identity.

customer_facing_launch: true — recipients are external users. They see the landing page and read-only view copy.

## Context

- Prior share-permissions work in the last cohort informs the reuse question (see Decisions needed).
- External-collaboration ask has appeared in 8 support tickets over the last 30 days — the business driver for prioritizing now.

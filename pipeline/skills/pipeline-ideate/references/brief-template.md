# 01-brief.md — template

Canonical shape for the brief that Ideate produces. The validator (`scripts/check-brief.sh`) checks for the sections marked **Required**.

## Frontmatter (Required)

```yaml
---
session: 01-ideate
feature_id: <YYYY-MM-DD-slug>
project: <project-name>
owner: timm
status: done                         # set to done only after Timm approves
inputs: [00-manifest.md]
updated: YYYY-MM-DD
regulated: true|false                # Required — explicit boolean
customer_facing_launch: true|false   # Required — explicit boolean
---
```

`session`, `feature_id`, `project`, `owner`, `status`, `inputs`, `updated`, `regulated`, `customer_facing_launch` are all required. `check-brief.sh` rejects the brief if any are missing.

## Body

### `# 01-brief — <Feature Title>` (Required)

H1 heading with the feature title. One line.

### `## Vision` (Required)

Three paragraphs max:
1. **What.** One sentence. Observable. "When an owner clicks X, they see Y."
2. **Who.** Role or persona — never "customers," never "users" without a qualifier. "A new workspace owner in their first week" or "An external collaborator opening a shared doc for the first time."
3. **Why.** What changes for that person. Outcome, not output.

### `## Pressure-test` (Required — ≥2 alternatives)

List **at least two** existing alternatives. For each, state what's wrong.

Format:

```
### Alternative 1 — <name>
What it is: <one line>
Why it doesn't work here: <Timm's answer, verbatim or paraphrased>
```

If Timm couldn't differentiate from an alternative, include the line:

```
⚠ weak problem signal — Timm couldn't name a clean differentiator.
```

The validator counts alternatives by `### Alternative` subheadings. Fewer than 2 = reject.

### `## Brief`

The executable summary. Subsections:

#### `### Scope` (Required)

Bulleted list of in-scope behaviors. Observable, user-facing. No file paths, no component names.

Example (good):
- Owner can generate a share link for a document.
- Recipient opens the link and sees a read-only view.
- Link expires after 14 days.

Example (bad — rejected):
- ~~Add `/api/v1/share-links` endpoint.~~
- ~~Create `ShareLinkModal.tsx` component.~~
- ~~New column `expires_at` on `share_links` table.~~

#### `### Acceptance criteria` (Required)

Numbered list of **observable** conditions. Each must be testable by a human using the product.

Format: "When <context>, <actor> <observable action>, and <observable outcome>."

Example:
1. When an owner opens a document, they can click "Share" to generate a link.
2. When a link is generated, it's copied to the owner's clipboard within 2 seconds.
3. When a recipient opens the link, they land on a read-only view in ≤3 seconds.

#### `### Non-goals` (Required)

Bulleted list of what's **explicitly out** of scope for this feature. Helps Plan avoid scope creep.

#### `### Decisions needed` (Required — may be empty)

Questions that couldn't be resolved in-session. Each entry gets a label: `[Timm]`, `[Plan]`, `[Research]`.

If all resolved in-session, the section says exactly: `All resolved.`

Example:
- `[Plan]` Which component library owns the share modal?
- `[Timm]` Does the link carry recipient identity or is it fully anonymous?
- `[Research]` How often do owners currently share docs via other means?

### `## Flags` (Required)

Two booleans, restated with rationale:

```
regulated: false — no PII beyond email, no billing, no regulated surface.
customer_facing_launch: true — external recipients will see the view page and copy.
```

Rationale is not validated but recommended — it tells Build's conditional modes why they are or aren't firing.

### `## Context` (Optional)

Links to reference docs, prior briefs, research notes that Plan should read. One bullet per link, with a one-line reason.

Example:
- `<project>/docs/briefs/archive/2026-03-12-workspace-setup.md` — prior work on workspace setup.
- `Code/pipeline/<project>/2026-04-01/_cohort/05-research.md` — user research that surfaced this problem.

---

## What not to write

- No file paths (`.md`, `.ts`, `.tsx`, `.py`, `apps/web/...`) — `check-brief.sh` flags these.
- No endpoint signatures (`POST /...`, `GET /...`).
- No column names or schema fragments.
- No library or framework names ("use Zustand", "React Query", "Prisma schema").
- No component names (`ShareLinkModal`, `<UserCard />`).

If any of those appear in the draft, cut them before showing Timm.

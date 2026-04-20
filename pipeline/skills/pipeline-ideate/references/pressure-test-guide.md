# Pressure-test guide

The pressure-test is the heart of Ideate. It exists to catch **fake problems** before they become a brief, a plan, and a shipped feature nobody uses.

## The premise

If a real problem exists, **alternatives also exist**. People are already trying to solve it with whatever's at hand — a spreadsheet, a competitor's product, a Slack thread, a manual workaround. The pressure-test surfaces those alternatives and asks: why aren't they enough?

If Timm can't name what's wrong with the alternatives, the problem isn't real **for him yet**. The brief doesn't fail closed in that case — it ships with a `⚠ weak problem signal` flag. Plan and Build proceed with eyes open.

## What counts as an "alternative"

Three buckets, in priority order:

1. **Internal workaround.** Something Timm or the team already does without the proposed feature. Examples: "I email each recipient manually," "we track this in a Notion DB," "we just don't do it."
2. **External product.** A tool — competitor, adjacent SaaS, generic — that solves a similar problem. Examples: "Postmark handles invites for them," "every comparable SaaS uses a generic share-link service for this."
3. **Do nothing.** The status quo. "We could just not build this." This is always a valid alternative — if doing nothing is acceptable, the feature isn't needed.

You need **two**. They can be from any combination of buckets — two internal, two external, one of each, etc. "Do nothing" can count as one of the two.

## How to run the pressure-test

After Timm's idea-dump and the scoping interview:

1. **Brainstorm aloud.** Name 3–5 candidate alternatives. Use `research-analyzer` if it's a market/prior-art question, `design:user-research` if it's a behavioral/persona question.
2. **Pick the top 2.** Strongest candidates — most plausible substitutes for the proposed feature.
3. **Ask Timm:** "What's wrong with `<alternative>` for this use case?"
4. **Listen for the answer shape:**
   - **Strong:** Specific failure mode tied to the user's actual workflow. ("Postmark doesn't know our workspace permission model — recipients would see fields we don't want them to see.")
   - **Weak:** Generic preference, no specifics. ("It's just not great.")
   - **Tautological:** Restates the proposed feature as the differentiator. ("Postmark doesn't have *our* share flow." — That's not a reason; it's a circular argument.)
5. **Capture verbatim or close-paraphrase.** The brief's pressure-test section quotes Timm's reasoning, not yours.

## What to do when Timm can't differentiate

Common signal: he hesitates, says "I dunno, it just felt like we should build it," or restates the feature as the differentiator.

**Don't stall.** Don't kill the session. Don't lecture.

Do:
1. Note the alternative he couldn't differentiate.
2. Add the line `⚠ weak problem signal — Timm couldn't name a clean differentiator from <alternative>.` to that alternative's entry.
3. In `## Decisions needed`, add: `[Research]` What's the actual failure mode of `<alternative>` for this use case?
4. Continue to draft the brief.

This routes the validation question to the Research session (post-ship), where real user data can answer it. The cost of building a feature that nobody needs is high; the cost of building one with a `weak signal` flag and learning from real usage is much lower.

## What not to do

- **Don't pretend the pressure-test passed when it didn't.** The flag exists so Plan and Build can stay alert.
- **Don't do Timm's job for him.** If he can't name the differentiator, *that's the data point* — don't invent one and write it down as his answer.
- **Don't extend the pressure-test into a research project.** Two alternatives, ten minutes max. If it's deeper than that, it belongs in Research, not Ideate.

## Example — strong pressure-test

Feature idea: "Let owners share documents with a public link."

```
### Alternative 1 — Export to PDF and email
What it is: Owner exports the doc and attaches it to an email.
Why it doesn't work here: Breaks the live-link to the source doc;
recipient gets a snapshot that stales immediately, and there's no
way to revoke access after send.

### Alternative 2 — Generic link-sharing SaaS
What it is: Off-the-shelf document-sharing tool bolted onto the workspace.
Why it doesn't work here: Introduces a second auth surface and fragments
the workspace's single-source-of-truth for permissions. Link provenance
would live outside the app.
```

## Example — weak pressure-test (still ships, with flag)

Feature idea: "Public directory page listing workspaces."

```
### Alternative 1 — Just list them on the workspace home
What it is: Add a "Browse workspaces" section to each page.
Why it doesn't work here: ⚠ weak problem signal — Timm couldn't name
a clean differentiator. "I just think a directory is cleaner."

### Alternative 2 — Do nothing
What it is: Don't expose workspaces publicly.
Why it doesn't work here: Some owners want to be discoverable; a few
have asked. Generic answer, not tied to a specific request.
```

Decisions-needed will get: `[Research]` Do owners actually ask for a directory page, and what would they want on it?

# pipeline-substrate — invocation prompts

Substrate isn't a full session orchestrator like ideate / plan / build / ship / research. It's invoked for three narrow purposes. Below are the prompts for each.

---

## Bootstrap — first-time pipeline setup

```
I'm starting a Cowork session from CoworkOS/Code/. Bootstrap the pipeline.

Your job: create Code/pipeline/ if missing, seed Code/pipeline/_meta/ with
the three meta files (skill-hashes.json, CHANGELOG.md, metrics.md)
following references/meta-contract.md. Idempotent — if _meta/ files
exist, leave them alone.

Report what you created vs what was already present.

Read first:
 1. references/pipeline-dir-convention.md
 2. references/meta-contract.md

Boundaries:
 - Never overwrite existing _meta/ files without an explicit repair
   request from me.
 - Don't touch anything outside Code/pipeline/.
 - Don't modify any feature dir's artifacts — substrate's writes are
   scoped to _meta/ (plus Code/pipeline/ itself if it doesn't exist).

Done when: bootstrap log is written to _meta/CHANGELOG.md and you've
told me what changed.
```

---

## Validate — audit pipeline state

```
I'm starting a Cowork session from CoworkOS/Code/. Validate the pipeline
workspace state.

Your job: enumerate every project dir under Code/pipeline/, walk every
feature dir, confirm each feature's 00-manifest.md exists and parses,
confirm each referenced artifact file exists with valid frontmatter per
references/session-file-template.md, confirm _meta/ files exist with
the shapes in references/meta-contract.md. Emit a report: green / yellow
/ red per feature dir + overall.

Read first:
 1. references/pipeline-dir-convention.md
 2. references/manifest-template.md
 3. references/session-file-template.md
 4. references/meta-contract.md

Boundaries:
 - Read only. No writes, no repairs unless I explicitly say "repair."
 - Do not modify frontmatter or manifest rows, even to "fix" them —
   surface the issue and wait.

Done when: the report is in front of me and I decide whether to trigger
a repair pass.
```

---

## Repair — fix malformed state

```
I'm starting a Cowork session from CoworkOS/Code/. Repair the pipeline
workspace state. Scope: <PATH or FEATURE_ID>.

Your job: apply targeted fixes to malformed artifacts — rewrite
frontmatter to match references/session-file-template.md, add missing
manifest rows as `pending`, re-sort the status table. Log every change
to Code/pipeline/_meta/CHANGELOG.md.

Read first:
 1. references/pipeline-dir-convention.md
 2. references/manifest-template.md
 3. references/session-file-template.md
 4. The validation report I'm handing you (what's broken + why).

Boundaries:
 - Only touch what the report flagged. No opportunistic cleanup.
 - Preserve existing content — repair adjusts structure, never semantic
   content of briefs / plans / notes.
 - If a repair would lose content, stop and surface it instead.

Done when: every flagged issue is either repaired or explicitly
declined (with reason), and _meta/CHANGELOG.md has the entries.
```

# pipeline-plugin — CONVENTIONS

Patterns every wrapper skill in this plugin follows. New wrappers adopt these from day one so the validator shape and wrapper authorship stay predictable.

---

## 1. AWK-emits-verdict-lines (validator pattern)

**Problem.** Per-subsection validation — counting bullets inside a named H2, checking that every H3 under a parent has a required field, confirming a table has N data rows — is easy to botch in bash + awk. The failure mode: awk builds a multi-line record and hands it back to bash, bash reads it with `while IFS= read -r line`, and every embedded newline in the record body becomes its own record. One real incident: `pipeline-research/scripts/check-research.sh` logged 124 false REDs on its good fixture because every bullet in the Candidates block got parsed as its own candidate. See `pipeline-research/lessons.md` (2026-04-19 entry) and `pipeline-llm-ops/lessons.md` (cross-cutting entry).

**Rule.** Do the entire per-subsection validation inside a single awk pass. Have awk emit one verdict per line, prefixed with `RED:` or `YELLOW:`. Bash reads those simple one-line records and routes them to `record_red` / `record_yellow`.

**Shape:**

```bash
AWK_OUT="$(awk '
  /^## Foo$/ { in_section=1; next }
  /^## /    { in_section=0 }
  in_section && /^### / {
    count++
    if ($0 !~ /expected-pattern/) print "RED:H3 missing required marker at line " NR
  }
  END {
    if (count == 0) print "RED:## Foo has no H3 entries"
    if (count > 0 && count < 2) print "YELLOW:## Foo has only " count " H3 entry"
  }
' "$FILE" || true)"

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  case "$line" in
    RED:*)    record_red    "${line#RED:}" ;;
    YELLOW:*) record_yellow "${line#YELLOW:}" ;;
  esac
done <<< "$AWK_OUT"
```

**Why this works.** Each verdict is one line. Bash's `while read` cleanly tokenizes it. Awk keeps all the stateful multi-pass logic (tracking "am I inside this section," "am I inside this H3," counters, seen-keys maps) where it belongs — in one place, in one language, with no IPC serialization to get wrong.

**When to apply.** Every new validator in this plugin. If a check needs to reason about structure across multiple lines of a section, it goes in awk. Don't round-trip structured records through bash strings.

---

## 2. Validator error discipline

- `set -euo pipefail` at the top of every validator.
- Guard every `grep` that might not match with `|| true`. Frontmatter extraction: `echo "$FRONTMATTER" | grep -E "^${key}:" | … || true` — we want an empty string, not a non-zero exit from `set -e`.
- `awk` invocations inside `$(...)` subshells also get `|| true` — defensive against any awk-level error surfacing as validator failure.
- Two severity channels: `RED` fails the validator (exit 1). `YELLOW` is a warning that prints but doesn't fail. Use RED for contract breaks; YELLOW for style / discoverability issues.
- Exit codes: `0` GREEN (maybe YELLOW warnings), `1` RED, `2` usage / input error. No other exit codes.

---

## 3. Smoke test shape

Every wrapper's `scripts/smoke.sh` asserts three cases:

| Fixture | Expected rc |
|---------|-------------|
| `fixtures/good/*.md` | 0 |
| `fixtures/bad-<specific>/*.md` | 1 |
| `fixtures/bad-<specific>/*.md` | 1 |

Two "bad" fixtures covering distinct failure modes — missing required sections vs. a contract breach inside a populated file. Smoke exits 0 iff all three match.

---

## 4. Frontmatter is YAML and will be parsed

Every SKILL.md has `---` YAML frontmatter with `name` + `description`. `claude plugin validate` parses it. Two gotchas we hit:

- **Embedded double quotes + angle brackets inside an unquoted scalar** can trip the YAML parser. `pipeline-llm-ops/SKILL.md` originally used `"fix <wrapper>"` in an unquoted description — parser rejected it with `Unexpected token`.
- **Fix:** either wrap the whole description in single quotes (which preserves literal double quotes inside), or strip the angle-bracket placeholders from the frontmatter. The skill body can still use them freely.

Run `claude plugin validate .claude-plugin/plugin.json` as the last step of any wrapper edit that touches frontmatter.

---

## 5. Run-log + CHANGELOG discipline (LLM-Ops)

- Run logs: one file per session at `Code/pipeline/_meta/runs/YYYY-MM-DDTHH-MM-<mode>.md`. Shape is mode-specific; the template is at `pipeline-llm-ops/references/run-log-template.md`.
- CHANGELOG: append-only, one dated one-liner per run, format `YYYY-MM-DD — <mode> — <short summary>`. Never rewrite past lines.
- Skill-hashes: `_meta/skill-hashes.json` is updated **after** drift-check assessments are logged, not before. We want drift recorded even if the assessment verdict is "Review."

---

## 6. Lessons sidecar discipline

- Every wrapper has `lessons.md`. Append-only. One entry per notable pattern or edit-worthy incident.
- Entry shape is defined in the wrapper's own `lessons.md` header. Keep the body intact once written.
- LLM-Ops `lesson-reconciliation` appends a `disposition:` line inline under reconciled entries. Do not rewrite the entry body.

---

## 7. Writable surface

Per-session SKILL.md files declare their writable surface explicitly under "Files you touch" / "Files you must not touch." Respect those boundaries. Cross-cutting LLM-Ops is the only role allowed to edit plugin source or the pipeline brief (`Code/.templates/llm-native-dev-pipeline-brief.md`), and only inside a `fix-session` after Timm approval.

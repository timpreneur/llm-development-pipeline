# pipeline-llm-ops — lessons (meta)

Meta-lessons about the maintainer itself. Same append-only shape as other wrappers.

Entry shape:

```
## YYYY-MM-DD — <short title> [<mode>]

- Context: <one line>
- Signal: <what surfaced it>
- Candidate change: <proposed meta-change — cadence, threshold, contract>
- Promotion: <yes | watch | no>
```

Valid `<mode>` tags: `drift-check`, `lesson-reconciliation`, `metric-aggregation`, `fix-session`, `cross-cutting`.

---

## 2026-04-19 — validator convention: multi-line record parsing in awk, not bash [cross-cutting]

- Context: pipeline-research check-research.sh first cut tried to round-trip per-candidate records through bash using `\x1f` separators. Embedded newlines in record bodies broke the `while read` loop — 124 false REDs on the good fixture.
- Signal: First smoke run blew up. Fix: do all per-subsection validation inside a single awk pass that emits `RED:<msg>` / `YELLOW:<msg>` lines, then have bash read those lines and feed them into `record_red` / `record_yellow`.
- Candidate change: Add this to a pipeline-plugin/CONVENTIONS.md file as "pattern: awk-emits-verdict-lines". Every new validator (starting with pipeline-llm-ops check-run-log.sh) applies the pattern from the start.
- Promotion: yes — already applied proactively in pipeline-llm-ops.

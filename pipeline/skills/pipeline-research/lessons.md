# pipeline-research — lessons

Append-only sidecar. One entry per notable pattern or edit-worthy incident. Tag entries by phase.

Entry shape:

```
## YYYY-MM-DD — <short title> [<phase>]

- Context: <one line>
- Signal: <what surfaced it — a failure mode, a repeated fixup, Timm feedback>
- Candidate change: <proposed wrapper edit or project override>
- Promotion: <yes | watch | no>
```

Valid `<phase>` tags: `cohort-construction`, `per-feature`, `synthesis`, `candidates`, `inbox`, `close`.

---

## 2026-04-19 — v0.1.0 deferral: metrics aggregation belongs to LLM-Ops [close]

- Context: Research session produces per-cohort numbers (done-signal rates, re-entry counts, critical-finding counts). Originally scoped to roll them into `_meta/metrics.md` directly.
- Signal: Design decision from the pipeline brief — LLM-Ops owns `_meta/`. Research writes raw numbers into `## Metrics summary` for LLM-Ops to pick up.
- Candidate change: Keep this split permanent. Add an LLM-Ops-side reader that consumes `## Metrics summary` from the latest cohort's `05-research.md`.
- Promotion: watch (pending LLM-Ops skill authoring).

## 2026-04-19 — validator bug: awk record separator with embedded newlines [synthesis]

- Context: First cut of `check-research.sh` split the Candidates block into per-H3 subsections with awk using `\x1f` as a field separator, then read records back with `while IFS= read -r line`. Because each record's "body" still contained literal `\n`, `read -r` treated every line as its own record — produced 124 false REDs on the good fixture (every bullet became a candidate).
- Signal: Caught by the first smoke-test run. Validator shape was right; the bash/awk IPC was wrong.
- Candidate change: Pattern rule for future wrapper validators — **if a section needs per-subsection validation with multi-line bodies, do the whole validation inside a single awk pass that emits `RED:<msg>` / `YELLOW:<msg>` lines**, then have bash read those lines and feed them into `record_red` / `record_yellow`. Do NOT try to round-trip structured records through bash string parsing. Apply this pattern to the upcoming pipeline-llm-ops validator proactively.
- Promotion: yes — worth a line in `pipeline-plugin/CONVENTIONS.md` (or the plugin README) once we write one up.

#!/usr/bin/env bash
#
# pipeline-substrate bootstrap
#
# Idempotently seed Code/pipeline/_meta/ with skill-hashes.json, CHANGELOG.md,
# metrics.md. Safe to run repeatedly; never overwrites existing _meta/ files.
#
# Usage:
#   bootstrap.sh <pipeline-root>
#
# pipeline-root is the path to Code/pipeline/ (e.g. /path/to/Code/pipeline).
# Creates it if missing.

set -euo pipefail

PIPELINE_ROOT="${1:-}"
if [[ -z "$PIPELINE_ROOT" ]]; then
  echo "ERROR: pipeline root required" >&2
  echo "Usage: bootstrap.sh <pipeline-root>" >&2
  exit 2
fi

PLUGIN_VERSION="0.1.0"
TODAY=$(date -u +%Y-%m-%d)
META_DIR="$PIPELINE_ROOT/_meta"

mkdir -p "$META_DIR"

created=()
present=()

# --- skill-hashes.json seed --------------------------------------------------

seed_skill_hashes() {
  cat <<EOF
{
  "version": 1,
  "seeded_at": "$TODAY",
  "seeded_by": "pipeline-substrate $PLUGIN_VERSION",
  "entries": [
    {
      "id": "builtin:review",
      "type": "built-in",
      "reference": "review",
      "path": null,
      "hash": null,
      "hashed_at": null,
      "used_by": ["pipeline-build:code-opt-mode"],
      "note": "Claude Code built-in; drift detected via CC version bump, not content hash."
    },
    {
      "id": "builtin:security-review",
      "type": "built-in",
      "reference": "security-review",
      "path": null,
      "hash": null,
      "hashed_at": null,
      "used_by": ["pipeline-build:security-mode"],
      "note": "Claude Code built-in; drift detected via CC version bump, not content hash."
    },
    {
      "id": "marketplace:research-analyzer",
      "type": "marketplace",
      "reference": "research-analyzer",
      "path": "*/skills/research-analyzer/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-ideate"]
    },
    {
      "id": "marketplace:design-user-research",
      "type": "marketplace",
      "reference": "design:user-research",
      "path": "design/*/skills/user-research/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-ideate"]
    },
    {
      "id": "marketplace:design-accessibility-review",
      "type": "marketplace",
      "reference": "design:accessibility-review",
      "path": "design/*/skills/accessibility-review/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-build:accessibility-mode"]
    },
    {
      "id": "marketplace:design-design-critique",
      "type": "marketplace",
      "reference": "design:design-critique",
      "path": "design/*/skills/design-critique/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-build:ux-polish-mode"]
    },
    {
      "id": "marketplace:design-ux-writing",
      "type": "marketplace",
      "reference": "design:ux-writing",
      "path": "design/*/skills/ux-writing/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-build:ux-polish-mode"]
    },
    {
      "id": "marketplace:design-research-synthesis",
      "type": "marketplace",
      "reference": "design:research-synthesis",
      "path": "design/*/skills/user-research/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-research"]
    },
    {
      "id": "marketplace:data-data-validation",
      "type": "marketplace",
      "reference": "data:data-validation",
      "path": "data/*/skills/data-validation/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-build:qa-mode"]
    },
    {
      "id": "marketplace:data-data-exploration",
      "type": "marketplace",
      "reference": "data:data-exploration",
      "path": "data/*/skills/data-exploration/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-research"]
    },
    {
      "id": "marketplace:data-statistical-analysis",
      "type": "marketplace",
      "reference": "data:statistical-analysis",
      "path": "data/*/skills/statistical-analysis/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-research"]
    },
    {
      "id": "marketplace:data-interactive-dashboard-builder",
      "type": "marketplace",
      "reference": "data:interactive-dashboard-builder",
      "path": "data/*/skills/interactive-dashboard-builder/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-ship"]
    },
    {
      "id": "marketplace:customer-support-ticket-triage",
      "type": "marketplace",
      "reference": "customer-support:ticket-triage",
      "path": "customer-support/*/skills/ticket-triage/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-build:qa-mode"]
    },
    {
      "id": "marketplace:customer-support-customer-research",
      "type": "marketplace",
      "reference": "customer-support:customer-research",
      "path": "customer-support/*/skills/customer-research/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-research"]
    },
    {
      "id": "marketplace:customer-support-knowledge-management",
      "type": "marketplace",
      "reference": "customer-support:knowledge-management",
      "path": "customer-support/*/skills/knowledge-management/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-research"]
    },
    {
      "id": "marketplace:marketing-content-creation",
      "type": "marketplace",
      "reference": "marketing:content-creation",
      "path": "marketing/*/skills/content-creation/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-ship"]
    },
    {
      "id": "marketplace:marketing-performance-analytics",
      "type": "marketplace",
      "reference": "marketing:performance-analytics",
      "path": "marketing/*/skills/performance-analytics/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-research"]
    },
    {
      "id": "marketplace:brand-voice-brand-voice-enforcement",
      "type": "marketplace",
      "reference": "brand-voice:brand-voice-enforcement",
      "path": "brand-voice/*/skills/brand-voice-enforcement/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-ideate", "pipeline-ship"]
    },
    {
      "id": "marketplace:schedule",
      "type": "marketplace",
      "reference": "schedule",
      "path": "*/skills/schedule/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-ship"]
    },
    {
      "id": "marketplace:skill-creator",
      "type": "marketplace",
      "reference": "skill-creator",
      "path": "*/skills/skill-creator/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-llm-ops"]
    },
    {
      "id": "marketplace:cowork-plugin-management-cowork-plugin-customizer",
      "type": "marketplace",
      "reference": "cowork-plugin-management:cowork-plugin-customizer",
      "path": "cowork-plugin-management/*/skills/cowork-plugin-customizer/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-llm-ops"]
    },
    {
      "id": "marketplace:consolidate-memory",
      "type": "marketplace",
      "reference": "consolidate-memory",
      "path": "*/skills/consolidate-memory/SKILL.md",
      "hash": "sha256:seed",
      "hashed_at": null,
      "used_by": ["pipeline-llm-ops"]
    }
  ]
}
EOF
}

# --- CHANGELOG.md seed -------------------------------------------------------

seed_changelog() {
  cat <<EOF
# pipeline/_meta/CHANGELOG.md

Append-only log of pipeline-level changes. Owned by pipeline-substrate (seed, repairs) and pipeline-llm-ops (everything else).

## $TODAY
- substrate: workspace bootstrap (pipeline-substrate $PLUGIN_VERSION). Seeded _meta/skill-hashes.json, _meta/CHANGELOG.md, _meta/metrics.md. All marketplace-skill hashes are placeholder "sha256:seed" — first pipeline-llm-ops drift pass will replace them with real hashes.
EOF
}

# --- metrics.md seed ---------------------------------------------------------

seed_metrics() {
  cat <<EOF
# pipeline/_meta/metrics.md

Aggregated after each cohort Research session closes. Owned by pipeline-llm-ops.

## Thresholds (reference — from the brief, do not edit without logging a brief-delta)

| Metric | Threshold |
|--------|-----------|
| First-pass done-signal rate (per session type) | <80% across 3 features |
| Re-entry count per feature (per session type)  | >2 across 3 features |
| Cross-session re-interview count                | >1 per feature across 3 |
| Promotion success rate                          | <100% |
| Marketplace-skill drift rate                    | >30% of wrappers drifting per quarter |
| Override promotion latency (lesson → CLAUDE.md) | median > 14 days |

## Per-session rolling rates

| Session       | First-pass done-signal | Re-entry avg | Last updated |
|---------------|------------------------|--------------|--------------|
| 01-ideate     | —                      | —            | —            |
| 02-plan       | —                      | —            | —            |
| 03-build      | —                      | —            | —            |
| 04-ship       | —                      | —            | —            |
| 05-research   | —                      | —            | —            |

## Per-cohort notes

(populated by pipeline-llm-ops after each cohort closes)
EOF
}

maybe_write() {
  local path="$1"
  local seed_fn="$2"
  if [[ -f "$path" ]]; then
    present+=("$path")
  else
    "$seed_fn" > "$path"
    created+=("$path")
  fi
}

maybe_write "$META_DIR/skill-hashes.json" seed_skill_hashes
maybe_write "$META_DIR/CHANGELOG.md"      seed_changelog
maybe_write "$META_DIR/metrics.md"        seed_metrics

# If CHANGELOG already existed, append a bootstrap line so LLM Ops can see the
# event. Never modify existing lines.
if [[ " ${present[*]-} " == *"$META_DIR/CHANGELOG.md"* ]]; then
  {
    echo ""
    echo "## $TODAY"
    echo "- substrate: bootstrap re-run (pipeline-substrate $PLUGIN_VERSION). _meta/ already present; no seeds overwritten."
  } >> "$META_DIR/CHANGELOG.md"
fi

echo "pipeline-substrate bootstrap @ $PIPELINE_ROOT"
echo "  created:"
if (( ${#created[@]} )); then
  for p in "${created[@]}"; do echo "    - $p"; done
else
  echo "    (none)"
fi
echo "  already present:"
if (( ${#present[@]} )); then
  for p in "${present[@]}"; do echo "    - $p"; done
else
  echo "    (none)"
fi

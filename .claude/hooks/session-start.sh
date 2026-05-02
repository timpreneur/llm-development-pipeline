#!/usr/bin/env bash
# SessionStart hook: keep local branch in sync with origin.
#
# Behavior:
#   - clean tree + behind upstream → fast-forward pull and report
#   - dirty tree + behind          → warn, do not pull
#   - diverged                     → warn, do not pull
#   - up to date / no upstream / not a repo → silent

set +e

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  exit 0
fi

git fetch --quiet origin 2>/dev/null

if ! git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
  exit 0
fi

BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null)
AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null)
DIRTY=$(git status --porcelain 2>/dev/null)

[ -z "$BEHIND" ] && exit 0
[ "$BEHIND" -eq 0 ] && exit 0

UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')

if [ "$AHEAD" -gt 0 ]; then
  echo "## Branch diverged from ${UPSTREAM}"
  echo ""
  echo "Local: ${AHEAD} ahead, ${BEHIND} behind. Resolve manually before continuing."
  exit 0
fi

if [ -n "$DIRTY" ]; then
  echo "## Branch is ${BEHIND} commit(s) behind ${UPSTREAM}"
  echo ""
  echo "Working tree has uncommitted changes — auto-pull skipped. Stash or commit, then run \`git pull\`."
  exit 0
fi

PREV_HEAD=$(git rev-parse HEAD)
if git pull --ff-only --quiet 2>/dev/null; then
  echo "## Pulled ${BEHIND} commit(s) from ${UPSTREAM}"
  echo ""
  git log --oneline "${PREV_HEAD}..HEAD" 2>/dev/null | sed 's/^/- /'
  echo ""
else
  echo "## Pull from ${UPSTREAM} failed"
  echo ""
  echo "Local is ${BEHIND} commit(s) behind but \`git pull --ff-only\` failed. Investigate before continuing."
fi

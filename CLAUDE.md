

## Git sync (local + cloud)

This repo is worked on in two places: locally on Timm's Mac and in Claude Code on the web. GitHub is the source of truth.

- **At session start:** run `git pull` on the current branch before making any changes.
- **At session end:** commit any work-in-progress and run `git push` so the other environment sees it.
- **Never edit the same branch in both places at once.** If unsure which side has the latest, run `git fetch && git status` and reconcile before editing.

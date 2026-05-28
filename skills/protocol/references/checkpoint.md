# Checkpoint Flow

Use this reference for `$checkpoint` or `/checkpoint`. It is a mid-session snapshot.

## Rule

Checkpoint is file-level only: update the state quartet locally and do zero git operations. Do not append a handoff.

## Steps

1. Read:
   - `obsidian-docs/CURRENT.md`
   - `obsidian-docs/NEXT.md`
   - `obsidian-docs/RISKS.md`
   - `obsidian-docs/TODO.md`
2. If the session is long-running or several agents may be editing the docs repo, optionally run `team-collab health --docs obsidian-docs` first. It is read-only; warnings mean you should inspect local/remote state before adding more state text.
3. Assess session state so far from `git status`, `git diff`, and conversation context.
4. Update only sections of the state quartet that changed. Keep diffs minimal and compact: no chronological logs, no PR/commit lists, no long bullets.
   - If detail is needed, keep one concise summary plus a standard Markdown link to a handoff/devlog/archive/design doc.
   - If a changed section is already overgrown, remove stale state before adding new state.
5. Do not `git add`, commit, push, or pull.
6. Report one line per file changed: section name and what changed.

## Difference from handoff

- `/handoff` = end-of-session: pull + append handoff + update state quartet + commit + rebase + push.
- `/checkpoint` = mid-session: update state quartet only, zero git operations.

A long session can have multiple checkpoints. Final `/handoff` still runs at the end.

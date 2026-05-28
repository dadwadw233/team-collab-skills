# TODO Ownership

Use this reference before starting, claiming, completing, blocking, or reassigning items in `obsidian-docs/TODO.md`.

TODO ownership is a git-backed distributed lock. Claiming must be immediately committed and pushed; otherwise another agent may take the same task.

## Hard rules

1. Before starting any TODO task, check ownership first.
2. Never modify a TODO line whose `@owner` is not you: not content, state, or `[x]`.
3. Claiming is not lazy-load. Move-to-`进行中` must be immediately followed by `git commit` and `git push`.
4. Claim push conflicts mean do not auto-grab. If someone else claimed the same task, abort and inform the user.

## Section shape

```markdown
## 进行中
- [ ] <task> @<owner> since YYYY-MM-DD [other metadata]

## 阻塞
- [ ] <task> @<owner> since YYYY-MM-DD (blocked by: <reason>)

## 待办（未认领，先到先得）
- [ ] <task>                  # no @owner = unclaimed

## 最近完成
- [x] <task> @<owner> YYYY-MM-DD
```

## Before starting work

1. `cd obsidian-docs && git pull --rebase`
2. Locate the target line in TODO.md.
3. Branch:
   - In `进行中`, `@owner` is you -> proceed.
   - In `进行中`, `@owner` is someone else -> stop and report: "TODO `<task>` is claimed by `@xxx` since `<date>`. Do you want to coordinate, wait, or forcibly reassign? I won't proceed without your decision."
   - In `阻塞` -> stop and report the blocker.
   - In `待办` -> execute claim flow.
   - Not in TODO.md -> stop and ask user if they want to add it first.

## Claim flow

1. Remove the line from `## 待办`.
2. Append to `## 进行中`: `- [ ] <original-text> @<user> since <today>` plus metadata.
3. `git add TODO.md`
4. `git commit -m "chore(todo): claim \"<short task>\" @<user>"`
5. `git push`
6. If push rejected: `git pull --rebase` then retry push.
7. If the rebase hits a conflict, meaning someone else claimed concurrently: abort, inform user, do not auto-retake.
8. If push succeeds: the claim is yours.

Determine `<user>` from `git config user.name` or explicit conversation context. If unsure, ask before claiming.

## During work

- Progress updates go in `最近完成` only when tasks are actually done.
- If a task is bigger than expected and should split, add sub-tasks under the parent in `进行中`, each with `@you since <today>`. Keep parent as umbrella.
- Keep TODO concise. A TODO line is an action, not a design note; move background and evidence to NEXT/design docs/devlogs and link with standard Markdown.

## Completion at handoff time

For tasks you own that finished this session:

1. Flip `[ ]` -> `[x]`.
2. Move from `进行中` to `最近完成`.
3. Replace `since <start-date>` with `<completion-date>`.
4. Keep `@owner` unchanged.

For tasks you own that did not finish: leave in `进行中`; optionally add a sub-note like `completed sub-tasks X of Y; blocker: ...`.

For tasks you do not own: do not touch. If evidence shows their task is done, leave a note for the owner but do not mark `[x]` yourself.

Keep `最近完成` to the most recent 15-20 items. Archive or delete older completed items; durable history lives in `_handoffs/` and `开发记录/<用户名>/`.

## Stale claim release

A `进行中` entry whose `since` is more than 14 days old may be re-claimed by someone else:

1. Edit the line, replacing `@old-owner since <old-date>` with `@new-owner since <today>`.
2. Commit: `chore(todo): re-claim stale TODO from @old-owner (idle 14d)`.
3. Recommended etiquette: message the original owner on Feishu/Slack first.

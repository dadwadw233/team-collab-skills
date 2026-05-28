# Handoff Flow

Use this reference for `$handoff <topic>` or `/handoff <topic>`. It is an end-of-session flow: pull, append a handoff, update changed state docs, commit, rebase, push.

Docs default-branch sync failures, conflicts, rejected pushes, hook failures, and gitleaks failures must stop and report. Do not force-push the docs default branch. Do not use `--no-verify`.

## Step 1: sync remote

```bash
cd obsidian-docs && git pull --rebase origin main
```

Conflict -> abort, report, stop. User resolves and re-invokes.

## Step 2: empty-session pre-check

Before doing anything else, check all three:

1. **Code repo `git status`**: any modified / staged / untracked non-`.claude/worktrees/` files? Any new commits (`git log origin/main..HEAD`)?
2. **Docs repo `cd obsidian-docs && git status`**: same?
3. **Current session conversation**: any substantive decisions, tests run, design discussions, or observations worth recording?

If all three are empty:

- Report: "本次 session 无可交接改动，跳过 /handoff"
- Do not append a handoff file.
- Do not commit, do not push.
- Exit this skill invocation.

If the user passed a topic string but the session is empty, still treat it as empty. Do not fabricate a handoff to match the topic. Report: "topic `<...>` 没有对应到实际改动；如果希望我先做一些事再 /handoff，请告诉我具体要做什么。"

If any of the three has content, proceed.

## Step 3: read current team state

Read:

- `obsidian-docs/CURRENT.md`
- `obsidian-docs/NEXT.md`
- `obsidian-docs/RISKS.md`
- `obsidian-docs/TODO.md`

## Step 4: assess session delta

From the conversation, both repos' `git diff`, and this session's commits, identify:

- Which files changed on which side (code vs docs).
- What decisions were made and why.
- What tests were run and their pass/fail count.
- What risks were newly discovered or resolved.
- What's unfinished that the next session should pick up.

## Step 5: write handoff file

Derive project name from `git remote get-url origin` in the code repo if not obvious. Handoff path:

```text
obsidian-docs/_handoffs/YYYY-MM-DD-HHMM-<topic>.md
```

`<topic>` is a short kebab-case English or short Chinese phrase reflecting the session's theme. Same day, multiple handoffs: create separate files; never edit historical handoffs.

Use `templates/handoff.md` as the clean starting point. Required structure:

```markdown
---
title: handoff YYYY-MM-DD <topic>
date: YYYY-MM-DD
project: <project-name-from-git-remote>
author: <user name if known, else agent name>
topic: <topic>
tags: [handoff]
---

# Handoff YYYY-MM-DD · <topic>

## Summary
1-3 factual sentences: what was done, what state is reached.
DO NOT write chain-of-thought, abandoned approaches, or meta commentary.

## Changed files
Two columns: code repo / docs repo. One short note per entry.

## Decisions made
Decision + Why. If it's an architecture/product decision, also write an ADR entry according to project convention.

## Tests run
Exact commands + pass/fail counts. If no tests were run, write "无" / "none"; never fabricate.

## Risks
New risks found, or previously-active risks resolved. New risks also go into `RISKS.md`.

## Suggested next steps
1-5 ordered actions at a granularity that lets the next person start immediately.
```

## Step 6: update state quartet

Edit only sections that changed. Do not rewrite entire files unless compacting stale state. State docs must be brief, structured, and link-driven; do not append chronological logs.

- Before adding new state, remove or archive obsolete prose. Long background, PR evidence, experiment details, and acceptance logs belong in `_handoffs/`, `开发记录/<用户名>/`, `archive/`, ADR, or focused design docs; leave one concise summary plus a standard Markdown link.
- `CURRENT.md`: milestones / active branch / current focus / 3-5 milestone-level recent completions, if changed.
- `NEXT.md`: strike finished items; append concise next steps with acceptance criteria and links; move resolved decisions out to `CURRENT.md` or an ADR.
- `RISKS.md`: add new risks to active table; move resolved ones to archive.
- `TODO.md`:
  - Tasks you finished: flip `[ ]` -> `[x]`, move from `进行中` to `最近完成`, keep `@owner`, replace timestamp with completion date.
  - Tasks with progress but not finished: stay in `进行中`, optionally add a sub-note.
  - Tasks newly blocked: move to `阻塞` with `blocked by: <reason>`.
  - Tasks newly discovered for later: append to `待办`.
  - If `最近完成` exceeds 15-20 items, archive or drop old completed items; history remains in handoffs/devlogs.
  - Do not touch tasks whose `@owner` is not you.

Load `todo-ownership.md` before editing TODO items.

## Step 7: sync to remote

In the docs repo:

1. Precise `git add`; do not `git add .`:
   ```bash
   git add CURRENT.md NEXT.md RISKS.md TODO.md _handoffs/ 开发记录/<用户名>/ <any other paths you touched>
   ```
2. `git status` -> show staged files to the user.
3. `git commit -m "docs(handoff): <topic> YYYY-MM-DD"`
   - Never `--no-verify`; gitleaks pre-commit must run.
4. If commit fails due to gitleaks: do not retry, do not `--no-verify`. Show the report to the user.
5. `git pull --rebase origin main`
   - Conflict -> abort rebase, keep local commit, report, stop.
6. `git push origin main`
   - Rejected -> report to user, suggest manual `git pull --rebase && git push`; never force-push the docs default branch.
7. Report commit hash and push result.

## Step 8: concise final report

Keep final report under about 15 lines:

- Handoff file path.
- Which sections of CURRENT / NEXT / RISKS / TODO changed, skipping unchanged files.
- Docs repo commit hash and push result.
- Anything the user should do next.

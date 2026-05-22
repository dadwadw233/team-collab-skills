# Team Progress Sync Reference

Use for `$team-progress <time-window>` / `/team-progress <time-window>` or when the user asks to check recent progress from other team members and review needs.

## Goal

Give a compact, decision-useful progress digest for a bounded time window: what changed, who may be blocked, and which PRs/MRs need the user to review or approve.

## Inputs

- Required: a time window such as `24h`, `48h`, `3d`, or `since YYYY-MM-DD HH:mm`.
- Optional: project name, include-self flag, specific users, or specific code/docs roots.
- Default scope: current team-collab project and other team members.

If the time window is missing or unclear, ask exactly one short question and stop.

## Source discovery

1. Identify project roots without scanning the whole vault:
   - Current repo and `obsidian-docs/` if present.
   - Registered `codePath`, `docsPath`, or `docsGitRoot` from `~/.team-collab/config.json` when the cwd is under one of them.
2. Refresh safely:
   - Prefer `git fetch --all --prune` in code/docs repos.
   - If a docs repo is clean and on its default branch, `git pull --ff-only` is allowed.
   - Never commit, push, rebase, force-push, or edit docs during this workflow.
3. Read only bounded sources:
   - `obsidian-docs/开发记录/<user>/` files modified or dated inside the window.
   - Recent `_handoffs/` files inside the window.
   - `CURRENT.md`, `NEXT.md`, `RISKS.md`, and `TODO.md` for current blockers and ownership.
   - Code PRs/MRs from `gh` / `glab` whose author, update time, or review state falls in the window.
   - Recent remote branches or commits only if PR/MR metadata is unavailable.

Do not load all dev records, all handoffs, or unrelated Obsidian vault folders.

## PR/MR review discovery

Use available CLIs without leaking tokens:

- GitHub: `gh pr list --state open --json number,title,author,updatedAt,reviewDecision,url,isDraft,headRefName,baseRefName,statusCheckRollup`.
- GitLab: `glab mr list --state opened --output json` or the closest supported output.
- For docs repos on GitLab, include docs MRs as well as code MRs.

Classify each item:

- `needs_user`: review/approval/merge/bypass likely needs the user.
- `blocked`: conflict, failing required checks, draft waiting on input, or explicit blocker in title/body/devlog.
- `informational`: active work with no user action needed.

If auth or network fails, retry once. If still failing, report the data gap in the final `未确认` section; do not stop the whole report if docs/dev records are still readable.

## Output format

Mirror the user's language. Keep it concise; target 20 lines or less unless there is a lot of real activity.

Use these sections in order:

```markdown
## 时间范围
- <window>; 数据源：<docs/devlog/handoff/PR/MR sources actually checked>

## 总览
- <1-3 bullets: overall progress, blockers, review load>

## 成员进展
- <member>: <finished/active work>; <evidence path or PR/MR link if useful>

## 阻塞与风险
- <member or area>: <blocker/risk>; <needed next action>

## 需要你处理
- <PR/MR/link>: <review/approve/merge/bypass decision needed>

## 未确认
- <missing auth/network/source gap, only if any>
```

If a section is empty, write `无` for that section rather than omitting it. Prefer links and file paths over long quotes.

## Rules

- Facts first, speculation last. Mark uncertainty explicitly.
- Do not expose secrets, tokens, private customer data, or sensitive unreleased details.
- Do not change repository state except safe fetch/fast-forward docs pull.
- Do not ping Feishu/groups or send notifications from this workflow.
- Do not ask the user to approve obvious read-only checks; proceed and summarize failures only if they affect confidence.

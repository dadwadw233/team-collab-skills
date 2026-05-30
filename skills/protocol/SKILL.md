---
name: team-collab-protocol
version: 0.5.5
description: |
  Use when the current repo is explicitly governed by team-collab: `obsidian-docs/` exists in cwd/ancestor, repo `AGENTS.md`/`CLAUDE.md` imports team-collab, the cwd is under a registered code/docs path, or the user asks for team-collab handoff/checkpoint/docs governance/Feishu automation. Do not use solely because a global config file exists.
---

# Team Collaboration Protocol

Slim runtime entrypoint for team projects using the OPC collective docs architecture. Load only the reference that matches the current task; do not read the whole playbook or vault by default.

## Activation

Use this protocol only from a strong signal:

- `obsidian-docs/` exists in the current repo or an ancestor.
- Repo-root `AGENTS.md` / `CLAUDE.md` references team-collab, `obsidian-docs`, CURRENT/NEXT/RISKS/TODO, `_handoffs`, or `开发记录/<用户名>/`.
- The cwd is under a registered `codePath`, `docsPath`, or `docsGitRoot` in `~/.team-collab/config.json` or legacy `~/.team-docs-config`.
- The user asks about handoff, checkpoint, team progress, docs refresh, team docs workflow, TODO ownership, Feishu automation, docs audit, setup, migration, or normalization.

Weak signal: a global team-collab config exists somewhere. Do not activate from that alone; it is a project registry, not proof that every repo is governed.

## Context budget

- Global/project pointers should only trigger this skill; they should not duplicate protocol details.
- On normal startup in a team project, read repo-root `AGENTS.md` and the state quartet only: `CURRENT.md`, `RISKS.md`, `NEXT.md`, `TODO.md`.
- Read recent `_handoffs/`, personal `开发记录/`, design docs, or the human playbook only when the user task requires that history.
- Do not scan the whole Obsidian vault, all docs, or all memories to orient yourself.
- If multiple references could apply, load the smallest set that covers the task.

## Reference router

| Situation | Load |
|---|---|
| Session start, repo orientation, docs sync, setup, onboarding, migration, Feishu, compliance, audit | `references/startup-and-audit.md` |
| `$handoff <topic>` or `/handoff <topic>` end-of-session flow | `references/handoff.md` |
| `$checkpoint` or `/checkpoint` mid-session snapshot | `references/checkpoint.md` |
| Git sync, push, force-push, conflicts, rejected push, hooks, gitleaks | `references/git-policy.md` |
| Creating or substantially editing project docs, frontmatter, filenames, taxonomy | `references/docs-standards.md` |
| `$docs-refresh <audit>` / `/docs-refresh <audit>` or updating Obsidian docs from a stale audit/dev record | `references/docs-refresh.md` |
| `$team-progress <window>` / `/team-progress <window>` or checking teammate progress, blockers, and PR/MR review needs | `references/team-progress.md` |
| Starting, claiming, completing, blocking, or reassigning TODO items | `references/todo-ownership.md` |

## Always-on constraints

- Never force-push protected/shared/unclear branches: `main`, `master`, `release/*`, `prod/*`, docs default branches, other people's branches, or unclear ownership branches.
- Self-owned non-protected working branches may be force-pushed after rebase or cleanup; prefer `--force-with-lease` and first check branch, status, and upstream.
- Never `git commit --no-verify`; never bypass gitleaks or equivalent secret checks.
- Never blindly recover from semantic git failures: non-fast-forward, protected-branch rejection, permission denied, hook/gitleaks failure, or rebase conflicts must stop and be reported.
- Never write secrets, credentials, customer private data, unreleased internal endpoints, or unannounced commercial secrets into docs.
- In docs repos, never `git add .`; precise-add intended files only.
- Do not fabricate a handoff for an empty session.
- Personal dev records go under `obsidian-docs/开发记录/<用户名>/`; do not create parallel devlog folders.
- Do not modify another owner's TODO item without explicit user direction.

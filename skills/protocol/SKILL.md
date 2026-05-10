---
name: team-collab-protocol
description: |
  Use when the current repo is explicitly governed by team-collab: `obsidian-docs/` exists in cwd/ancestor, repo `AGENTS.md`/`CLAUDE.md` imports team-collab, the cwd is under a registered code/docs path, or the user asks for team-collab handoff/checkpoint/docs governance/Feishu automation. Do not use solely because a global config file exists.
---

# Team Collaboration Protocol

AI-side runtime protocol for team projects using the OPC collective documentation architecture. This entrypoint is intentionally slim: load only the reference file that matches the user's current task.

## Activation signals

Load this skill only from a strong team-project signal or an explicit user request.

Strong signals:
- The current directory or an ancestor contains `obsidian-docs/`.
- The current repo's `AGENTS.md` or `CLAUDE.md` references this protocol, `obsidian-docs`, CURRENT/NEXT/RISKS/TODO, `_handoffs`, or `开发记录/<用户名>/`.
- The current directory is equal to or underneath a registered `codePath`, `docsPath`, or `docsGitRoot` in `~/.team-collab/config.json` or legacy `~/.team-docs-config`.
- The user explicitly asks for handoff, checkpoint, team docs workflow, PR/MR docs governance, TODO owner claims, doc standards, Feishu automation, docs repo audit/normalization, or new-member docs onboarding.

Weak signal:
- `~/.team-collab/config.json` or `~/.team-docs-config` exists somewhere on the machine.

Do **not** load or enforce this full protocol solely from the weak signal. Many users keep a global config after joining one team project; it must not make unrelated repos inherit team docs behavior.

## Context snapshot

- Code lives on GitHub or GitLab; code changes go through the code platform PR/MR flow.
- Docs live in an Obsidian-backed docs directory, usually available as `obsidian-docs/` from the code repo. Existing vault subdirectories are valid after user confirmation; do not migrate them just because a template path exists.
- Project-level agent instructions live in repo-root `AGENTS.md`; `CLAUDE.md`, if present, should normally be a thin pointer.
- Shared project state is the quartet `CURRENT.md`, `NEXT.md`, `RISKS.md`, `TODO.md`.
- Session audit trails are append-only files under `obsidian-docs/_handoffs/`.
- Personal dev records must live under `obsidian-docs/开发记录/<用户名>/`.

## Load the right reference

| Situation | Load this file |
|---|---|
| Session start, repo orientation, docs sync, state quartet reading | `references/startup-and-audit.md` |
| Setup, onboarding, migration, compliance/audit, Feishu integration | `references/startup-and-audit.md` |
| `$handoff <topic>` or `/handoff <topic>` end-of-session flow | `references/handoff.md` |
| `$checkpoint` or `/checkpoint` mid-session snapshot | `references/checkpoint.md` |
| Any git sync, push, force-push, conflict, rejected push, hook/gitleaks issue | `references/git-policy.md` |
| Creating or substantially editing project docs, frontmatter, filenames, taxonomy | `references/docs-standards.md` |
| Starting, claiming, completing, blocking, or reassigning TODO.md items | `references/todo-ownership.md` |

If multiple rows apply, load the smallest set needed. For example, a handoff that updates TODO.md should use `handoff.md`, `git-policy.md`, and `todo-ownership.md`; it does not need the full audit reference.

## Default session flow

1. Confirm a strong activation signal. If only a global config exists, do not enforce team-collab.
2. If inside a team project, read `references/startup-and-audit.md` and follow its startup sequence before substantive work.
3. Keep code changes in the code repo and project memory in `obsidian-docs/`.
4. Use `$checkpoint` for a local mid-session state update; use `$handoff <topic>` for end-of-session sync.
5. Prefer the npm CLI for setup checks: `team-collab register ... --dry-run`, `team-collab doctor --project <project>`, and `team-collab docs-path` when the playbook path is unknown.

## Always-on constraints

- Never force-push protected/shared/unclear branches: `main`, `master`, `release/*`, `prod/*`, docs repo default branches, other people's branches, or branches with unclear ownership.
- Self-owned non-protected working branches may be force-pushed after rebase, commit cleanup, or conflict repair. Prefer `--force-with-lease`; use plain `--force` only when ownership is certain and no one else has pushed. Check `git branch --show-current`, `git status -sb`, and `git branch -vv` first.
- Never `git commit --no-verify`; never bypass gitleaks or equivalent secret checks.
- Never blindly retry or auto-recover from semantic git failures: non-fast-forward rejection, protected branch rejection, permission denied, hook/gitleaks failure, or rebase conflicts must stop and be reported.
- Never write secrets, credentials, customer private data, unreleased internal service endpoints, or unannounced commercial secrets into docs.
- In docs repos, never `git add .`; precise-add only the intended files.
- Do not fabricate a handoff for an empty session.
- Do not create new top-level `开发日志/`, `devlog/`, or mixed-author devlog files; personal records go under `开发记录/<用户名>/`.
- Do not modify a TODO line owned by someone else without explicit user direction.

## Templates and scripts

- Templates live in `templates/`: `OVERVIEW.md`, `CURRENT.md`, `NEXT.md`, `RISKS.md`, `TODO.md`, `handoff.md`, `ADR.md`.
- Manual fallback script: `scripts/handoff-manual.sh`.
- Human-readable playbook: `gitlab.com/<team-group>/team-collab-playbook`.

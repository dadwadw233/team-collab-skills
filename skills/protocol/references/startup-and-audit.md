# Startup And Audit

Use this reference for session arrival, setup, onboarding, migration, Feishu integration, compliance checks, and docs normalization.

## Repository context

When this protocol applies:

- **Code** lives in a code repository on GitHub or GitLab. Internal team projects should prefer GitLab `embodot/<project>` for new repos or mirrors, while existing GitHub repos may remain on GitHub.
- **Docs** live in an Obsidian-backed project docs directory, accessed from `obsidian-docs/` in the code repo. New projects should prefer a separate GitLab docs repository, but existing projects may already use a project subdirectory inside a larger Obsidian vault. Both layouts are valid after explicit user confirmation. The actual local code/docs paths may be custom and must be discovered before setup.
- **Repository governance** is split by purpose:
  - Code repo: `main` is protected; code changes go through the code platform's PR/MR flow; never force-push protected/shared/unclear branches; GitHub PRs may request Codex/Copilot review, GitLab MRs follow project review settings, and humans decide.
  - GitLab docs repo: `main` is protected with no direct push by default; high-level shared docs go through MR; personal process records may follow the project's relaxed direct-push path.
- **Project-level instructions** for agents live in `AGENTS.md` at the code repo root. `CLAUDE.md`, if present, is typically a thin import pointer to `AGENTS.md`.
- **Shared docs state** is expressed in the state quartet:
  - `CURRENT.md` -- one-screen project status
  - `NEXT.md` -- strategic next actions and open decisions
  - `RISKS.md` -- active risks and archived-resolved ones
  - `TODO.md` -- task-level checklist with explicit `@owner` claims
- **Audit trail** of each AI session lives in `obsidian-docs/_handoffs/YYYY-MM-DD-HHMM-<topic>.md`.
- **Personal dev records** live in `obsidian-docs/开发记录/<用户名>/YYYY-MM-DD-<topic>.md`.

## Trigger matrix

- **Session start in a team project**: orient, sync docs, then read the state quartet before substantive work.
- **Substantive work**: keep code changes in the code repo and project memory in `obsidian-docs`; use personal dev records for process notes.
- **Setup, onboarding, migration, Feishu integration, or "is this repo compliant?"**: inspect the real local layout first. Prefer:
  - `team-collab register <project> --code <code-dir> --docs <docs-dir> --dry-run`
  - `team-collab init --join <project> --dry-run`
  - `team-collab doctor --project <project>`
- **Existing Obsidian vault subdirectory**: treat it as `vault-subdir`; do not copy or migrate it into `Projects/<project>-docs` unless the user explicitly approves that migration.
- **Mid-session checkpoint**: update the state quartet only; do not commit or push.
- **End-of-session handoff**: write one handoff, update changed state docs, then commit/rebase/push docs strictly.
- **Health check**: when a previous session may have stopped mid-push, or multiple agents touched state docs, run `team-collab health --docs obsidian-docs` or `team-collab doctor --project <project> --health`. It is read-only and uses git log only.


## Context budget

Use progressive loading so agent sessions find the right context without paying for the whole vault:

- Do not scan the whole Obsidian vault, all project docs, all handoffs, or all personal dev records during startup.
- Default startup context is repo-root `AGENTS.md` plus `CURRENT.md`, `RISKS.md`, `NEXT.md`, and `TODO.md`.
- Read recent `_handoffs/` only when the current task needs session history or the state quartet is stale/ambiguous.
- Read design docs, specs, or `开发记录/<用户名>/` only when they are directly relevant to the user request.
- Treat `team-collab docs-path` and the human playbook as reference lookup tools, not startup context.

## Arrival sequence

Run this check sequence in order.

### Step A: orient yourself

1. Detect the docs path: `ls obsidian-docs/` should show `CURRENT.md` etc. If not, the user may not be in a team project -- ask before proceeding.
2. Detect the git layout:
   - Run `git -C obsidian-docs rev-parse --show-toplevel` to see whether docs are a standalone repo or a subdirectory inside a larger vault repo.
   - If standalone, `git -C obsidian-docs remote -v` should usually point to a `-docs` repo.
   - If it is a vault subdirectory, sync and commit through the parent vault git root, while editing only the selected project docs directory.
   - Run `git log <upstream>..HEAD --oneline` in the code repo and in the docs git root when an upstream exists.
   - If docs are ahead of upstream with `CURRENT.md` / `NEXT.md` / `RISKS.md` / `TODO.md` or `_handoffs/` commits, report that a previous session may not have published and ask whether to retry the docs push before editing more state.

### Step B: sync remote docs

```bash
cd obsidian-docs && git pull --rebase origin main
```

- Success (fast-forward or no changes) -> proceed.
- Non-fast-forward conflict -> abort rebase, list conflicting files, stop and report to the user. They resolve manually and re-invoke.

### Step C: read team state

Read in this order:

1. `obsidian-docs/CURRENT.md`
2. `obsidian-docs/RISKS.md`
3. `obsidian-docs/NEXT.md`
4. `obsidian-docs/TODO.md`
5. Optionally recent 2-3 entries in `obsidian-docs/_handoffs/`

If the user gave a task that is not in `NEXT.md`, pause and align with them before acting unless the task is clearly an urgent fix or the user explicitly overrides project planning.

## Project audit / normalization

Run audit when the user asks about project setup, migration, normalization, Feishu automation, onboarding readiness, or whether the repo follows the team standard. Do not run audit on every session start unless the user asks or the project appears misconfigured.

From the code repo root, prefer:

```bash
team-collab register <project> --code <code-dir> --docs <docs-dir> --dry-run
team-collab doctor --project <project>
team-collab doctor --project <project> --health
<team-collab-playbook>/scripts/audit-project-docs.sh obsidian-docs . <username>
```

If `team-collab` is not installed, ask the user to install `@embodot/collab@latest`. If the playbook checkout path is unknown, run `team-collab docs-path` first; only search likely local paths such as `~/team-playbook`, `~/projects/team-collab-playbook`, or the user's Obsidian vault if the npm CLI is unavailable.

For setup or migration, do not clone, copy, move docs, rewrite config, or repair symlinks before you have summarized the detected layout and the user has approved the plan. Existing Obsidian vault subdirectories are legitimate docs locations; normalize them in place unless the user explicitly asks for a standalone docs repo migration.

Interpret audit output:

- `failure(s)` mean the docs baseline is broken and should be fixed before normal work continues.
- `warning(s)` mean recommended integration gaps such as missing Feishu CI/workflow or agent entry files. Existing projects may migrate these gradually; new projects should aim for zero warnings.
- Audit is read-only. Do not "fix all" without checking whether changes belong in the docs repo, code repo, or playbook.

## Baseline enforcement scope

Project baseline is enforced during audit/init, not every normal session. A mature project should have:

- `README.md` (form=index)
- `OVERVIEW.md` or equivalent (form=design, topic contains `positioning` or `overview`)
- `CURRENT.md` / `NEXT.md` / `RISKS.md` / `TODO.md`
- `_handoffs/` and `开发记录/<用户名>/`
- `决策日志.md` or `ADR/NNN-*.md`
- `archive/`

In ordinary feature/debug work, flag missing baseline items only if they directly affect the requested task.

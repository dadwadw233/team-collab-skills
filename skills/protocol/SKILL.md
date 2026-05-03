---
name: protocol
description: |
  Use when the current repo is a team project: `obsidian-docs/` exists in cwd or an ancestor; project `AGENTS.md`/`CLAUDE.md` references team-collab, `obsidian-docs`, CURRENT/NEXT/RISKS/TODO, or `_handoffs`; cwd matches a path listed in `~/.team-docs-config`; or the user asks about handoff, checkpoint, team docs workflow, PR/MR docs governance, TODO owner claims, doc standards, Feishu automation, or project docs audit/normalization. Do not load solely because `~/.team-docs-config` exists.
---

# Team Collaboration Protocol

This skill encodes the AI-side protocol for working in a team project that follows the OPC collective documentation architecture. It complements the human-facing playbook (typically at `gitlab.com/<team-group>/team-collab-playbook`).

## Context (what you're looking at)

When this skill is loaded, the user is working in a project where:

- **Code** lives in a code repository on GitHub or GitLab, accessed from `~/projects/<project>/`. Internal team projects should prefer GitLab `embodot/<project>` for new repos or mirrors, while existing GitHub repos may remain on GitHub.
- **Docs** live in a separate docs repository on GitLab (invite-only, source of truth), accessed from `~/projects/<project>/obsidian-docs/` — which is either a symlink to an Obsidian vault subdirectory, or a direct `git clone` into that path.
- **Repository governance** is split by purpose:
  - Code repo: `main` is protected; code changes go through the code platform's PR/MR flow; never force-push `main`; GitHub PRs may request Codex/Copilot review, GitLab MRs follow project review settings, and humans decide.
  - GitLab docs repo: `main` is protected with no direct push by default; high-level shared docs go through MR; personal process records may follow the project's relaxed direct-push path.
- **Project-level instructions** for agents live in `AGENTS.md` at the code repo root (cross-agent standard per agents.md). `CLAUDE.md`, if present, is typically a thin import pointer to `AGENTS.md`.
- **Shared docs state** is expressed in **four** files at the docs repo root (the "state quartet"):
  - `CURRENT.md` — one-screen project status (the team's single reading entry point)
  - `NEXT.md` — strategic next actions + open decisions (coarse-grained)
  - `RISKS.md` — active risks + archived-resolved ones
  - `TODO.md` — task-level checklist with explicit `@owner` claims (fine-grained)
- **Audit trail** of each AI session lives in `obsidian-docs/_handoffs/YYYY-MM-DD-HHMM-<topic>.md` (append-only).
- **Personal dev records** must live in `obsidian-docs/开发记录/<用户名>/YYYY-MM-DD-<topic>.md`. This path is mandatory; do not create new top-level `开发日志/`, `devlog/`, or mixed-author devlog files.
- **Docs follow a strict form/topic taxonomy** — see "Document standards" section below.

## Activation signals

Load this skill only from a strong team-project signal or an explicit user request.

Strong signals:
- The current directory or an ancestor contains `obsidian-docs/`.
- The current repo's `AGENTS.md` or `CLAUDE.md` references this protocol, `obsidian-docs`, CURRENT/NEXT/RISKS/TODO, `_handoffs`, or `开发记录/<用户名>/`.
- The current directory is inside a path listed in `~/.team-docs-config`.
- The user explicitly asks for handoff, checkpoint, team docs workflow, PR/MR docs governance, TODO owner claims, doc standards, Feishu automation, docs repo audit/normalization, or new-member docs onboarding.

Weak signal:
- `~/.team-docs-config` exists somewhere on the machine.

Do **not** load or enforce this full protocol solely from the weak signal. Many users keep that file globally after joining one team project; it must not make unrelated repos inherit team docs behavior.

## Trigger matrix

- **Session start in a team project**: orient, sync docs, then read the state quartet before substantive work.
- **Substantive work**: keep code changes in the code repo and project memory in `obsidian-docs`; use personal dev records for process notes.
- **Setup, onboarding, migration, Feishu integration, or "is this repo compliant?"**: run the read-only project audit if the playbook checkout is available.
- **Mid-session checkpoint**: update the state quartet only; do not commit or push.
- **End-of-session handoff**: write one handoff, update changed state docs, then commit/rebase/push docs strictly.

## When you arrive in a session

Run this check sequence — order matters.

### Step A: orient yourself

1. Detect the docs path: `ls obsidian-docs/` should show `CURRENT.md` etc. If not, the user may not be in a team project — ask before proceeding.
2. Detect the git layout:
   - Run `cd obsidian-docs && git remote -v` — it should point to a `-docs` repo (often on GitLab).
   - Run `git log origin/main..HEAD --oneline` in both the code repo and `obsidian-docs` — zero lines means you're up to date locally vs remote tracking branches.

### Step B: sync remote docs (mandatory)

```bash
cd obsidian-docs && git pull --rebase origin main
```

- Success (fast-forward or no changes) → proceed.
- Non-fast-forward conflict → **abort rebase**, list conflicting files, **stop** and report to the user. They'll resolve manually and re-invoke you.

### Step C: read team state

Read in this order:

1. `obsidian-docs/CURRENT.md` — current state, one screen
2. `obsidian-docs/RISKS.md` — active risks (avoid the pits others recorded)
3. `obsidian-docs/NEXT.md` — strategic next actions and undecided items
4. `obsidian-docs/TODO.md` — task-level todos with owner claims (see "TODO.md ownership" section below)
4. Optionally recent 2-3 entries in `obsidian-docs/_handoffs/` — what happened recently

If the user gave you a task in their prompt that isn't in `NEXT.md`, **pause and align** with them before acting — the task may be mid-flight from elsewhere or out of scope for this session.

## Project audit / normalization

Run audit when the user asks about project setup, migration, normalization, Feishu automation, onboarding readiness, or whether the repo follows the team standard. Do not run audit on every session start unless the user asks or the project appears misconfigured.

From the code repo root, prefer:

```bash
<team-collab-playbook>/scripts/audit-project-docs.sh obsidian-docs . <username>
```

If the playbook checkout path is unknown, search likely local paths such as `~/team-playbook`, `~/projects/team-collab-playbook`, or the user's Obsidian vault. If not found, report that audit needs the playbook checkout and continue with manual checks.

Interpret audit output:
- `failure(s)` mean the docs baseline is broken and should be fixed before normal work continues.
- `warning(s)` mean recommended integration gaps such as missing Feishu CI/workflow or agent entry files. Existing projects may migrate these gradually; new projects should aim for zero warnings.
- Audit is read-only. Do not "fix all" without checking whether changes belong in the docs repo, code repo, or playbook.

## When the user invokes `/handoff <topic>` (end-of-session)

You will generate a team handoff record and sync it to remote. **Strict step-by-step execution**. Any failure: stop, report, do not retry, do not force, do not `--no-verify`.

### Step 1: sync remote

```bash
cd obsidian-docs && git pull --rebase origin main
```

Conflict → abort, report, stop. User resolves and re-invokes.

### Step 2: empty-session pre-check (short-circuit)

Before doing anything else, check all three of:

1. **Code repo `git status`**: any modified / staged / untracked non-`.claude/worktrees/` files? Any new commits (`git log origin/main..HEAD`)?
2. **Docs repo `cd obsidian-docs && git status`**: same?
3. **Current session conversation**: any substantive decisions, tests run, design discussions, or observations worth recording?

If **all three are empty** (the user ran `/handoff` without actually doing anything in the session):

- Report: "本次 session 无可交接改动，跳过 /handoff"
- Do **not** append a handoff file.
- Do **not** commit, do **not** push.
- **Exit** this skill invocation. Do not proceed to step 3+.

If the user passed a topic string but the session is empty: still treat as empty session. Do not fabricate a handoff to match the topic. Report: "topic `<...>` 没有对应到实际改动；如果希望我先做一些事再 /handoff，请告诉我具体要做什么。"

If **any** of the three has content → proceed to step 3.

### Step 3: read current team state

Read:
- `obsidian-docs/CURRENT.md`
- `obsidian-docs/NEXT.md`
- `obsidian-docs/RISKS.md`
- `obsidian-docs/TODO.md`

### Step 4: assess session delta

From the conversation + both repos' `git diff` + this session's commits:

- Which files changed on which side (code vs docs).
- What decisions were made and **why**.
- What tests were run and their pass/fail count.
- What risks were newly discovered or resolved.
- What's unfinished that the next session (human or AI) should pick up.

### Step 5: write handoff file

Derive project name from `git remote get-url origin` in the code repo if not obvious. Handoff path:

```
obsidian-docs/_handoffs/YYYY-MM-DD-HHMM-<topic>.md
```

`<topic>` is a short kebab-case English or short Chinese phrase reflecting the session's theme. Same day, multiple handoffs: just create separate files — never edit historical handoffs.

Handoff file structure (see `templates/handoff.md` in this skill for a clean template):

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
Decision + Why. If it's an architecture/product decision, also write an ADR entry (project convention — see the project's own ADR location).

## Tests run
Exact commands + pass/fail counts. If no tests were run, write "无" / "none" — never fabricate.

## Risks
New risks found, or previously-active risks resolved. New risks also go into `RISKS.md`.

## Suggested next steps
1-5 ordered actions at a granularity that lets the next person (human or AI) start immediately.
```

### Step 6: update state quartet (CURRENT / NEXT / RISKS / TODO, in-place, minimal diff)

**Edit only the sections that changed** — do not rewrite entire files.

- `CURRENT.md`: milestones / active branch / recent completions / current focus, if any changed
- `NEXT.md`: strike finished items; append new next steps; move resolved decisions out to `CURRENT.md` or an ADR
- `RISKS.md`: add new risks to the active table; move resolved ones to the archive section
- `TODO.md`:
  - Task(s) you finished this session: flip `[ ]` → `[x]`, move from "进行中" to "最近完成", keep `@owner`, replace timestamp with completion date
  - Task(s) you made progress on but didn't finish: stay in "进行中", you may add a sub-note
  - Task(s) you newly encountered blockers on: move to "阻塞" with a `blocked by: <reason>` annotation
  - Task(s) newly discovered that need doing later: append to "待办"
  - **DO NOT touch tasks whose `@owner` is not you**. Not even `[x]` them if they look done. At most, leave a note suggesting the owner verify.

### Step 7: sync to remote (strict)

In the docs repo:

1. **Precise `git add`** — do not `git add .` (would catch `.obsidian/workspace.json` etc if `.gitignore` missed it):
   ```bash
   git add CURRENT.md NEXT.md RISKS.md TODO.md _handoffs/ 开发记录/<用户名>/ <any other paths you touched>
   ```
2. `git status` → show staged files to the user.
3. `git commit -m "docs(handoff): <topic> YYYY-MM-DD"` — commit message must be specific and meaningful.
   - **Never `--no-verify`**. gitleaks pre-commit must run.
4. If commit fails due to gitleaks: **do not retry, do not `--no-verify`**. Show the gitleaks report to the user. They clean up and re-invoke.
5. `git pull --rebase origin main` — in case of a remote push during steps 3-7.
   - Conflict → abort rebase, **keep the local commit**, report, stop.
6. `git push origin main`.
   - Rejected → report to user, suggest `git pull --rebase && git push` (manual), **never `--force`**.
7. Report commit hash + push result.

### Step 8: concise final report (≤ 15 lines)

- Handoff file path.
- Which sections of CURRENT / NEXT / RISKS / TODO changed (skip unchanged).
- Docs repo commit hash + push result.
- Anything the user should do next (resolve a conflict, check something, approve a migration, etc.).

## When the user invokes `/checkpoint` (mid-session)

Mid-session snapshot. **File-level only — no git operations.**

### Steps

1. Read `obsidian-docs/CURRENT.md`, `NEXT.md`, `RISKS.md`, `TODO.md`.
2. Assess session state so far from `git status` + `git diff` + conversation.
3. Update **only** sections of the state quartet that changed — in place, minimal diff. No append-handoff.
4. **Do not** `git add`, commit, push, or pull. Checkpoint is a working-tree snapshot, nothing leaves local.
5. One-line report per file changed: which section + what changed.

### Difference from `/handoff`

- `/handoff` = end-of-session: pull + append handoff + update state quartet + commit + rebase + push
- `/checkpoint` = mid-session: update state quartet only, zero git ops

Long session can have multiple checkpoints. Final `/handoff` still runs at end.

## Conflict handling decision tree

### Your `git pull --rebase` hit a conflict

1. Open the conflicted file(s). Identify `<<<<<<<` / `=======` / `>>>>>>>` markers.
2. Decide: usually both sides matter and need merging — do not arbitrarily pick one side.
3. After resolution: `git add <file>` then `git rebase --continue`.
4. If you cannot confidently resolve: `git rebase --abort` (returns to pre-rebase state), report to user, stop.

### Your `git push` was rejected

Remote advanced during your session. You already hold a valid local commit.

1. Report the push rejection.
2. Suggest the user run `git pull --rebase && git push` themselves.
3. **Do not force-push**. Never `--force`, `--force-with-lease`, or `+main`.
4. The local handoff file and commit are preserved.

### Two people edited `CURRENT.md` concurrently

- `_handoffs/` is append-only and never conflicts — use it as the lifeboat.
- For `CURRENT.md` conflicts, resolve section-by-section manually during rebase.
- If the same section was rewritten by both, flag to user and let them choose — do not auto-merge semantic content.

### gitleaks blocked the commit

Staged content contains something matching a secret pattern (OpenAI key, AWS token, DB URL with password, etc.).

1. Show the gitleaks report to the user verbatim.
2. **Do not `--no-verify`**. Even if the user asks — explain it defeats the purpose.
3. If the match is a true secret: user removes it or substitutes `<YOUR_API_KEY>`-style placeholder, re-commit.
4. If the match is a false positive (test fixture with fake key, public sample data): user adds a `.gitleaks.toml` allowlist entry (path-based or commit-based), then re-commit. See https://github.com/gitleaks/gitleaks for allowlist syntax.

## Hard constraints (violating these = stop immediately)

### Git-level (sync, pushes, secrets)

1. **Never force push**. Not `--force`, not `--force-with-lease`, not `push -f`.
2. **Never `--no-verify`**. The gitleaks hook is the last line of defense for secret leaks.
3. **Never retry failed git operations automatically**. One failure → stop and report.
4. **Never fabricate a handoff to satisfy a topic parameter**. Empty session = no handoff.
5. **Never write these into the docs repo**:
   - API keys / access tokens / OAuth secrets / private keys
   - Database connection strings with credentials
   - Customer full names or customer-internal contact info
   - Other OPC members' internal company confidential data
   - Unreleased internal service URLs / ports / IPs
   - Unannounced product commercial secrets
6. **Never `git add .`** in the docs repo. Always precise-add by filename.
7. **Never commit `*.canvas`, `*.base`, `.obsidian/`, `.trash/`, `.DS_Store` into the docs repo** — these are either oversized binary-ish, per-user config, or OS cruft. If they slip past `.gitignore`, fix `.gitignore` rather than committing.
8. **Keep wikilinks out of critical cross-file references**. Use standard Markdown `[text](./path.md)` for CURRENT/NEXT/RISKS/TODO/ADR internal links so they render on web (GitHub/GitLab). Wikilinks are OK for informational prose but not for navigation anchors.
9. **Respect PR/MR boundaries**:
   - Code repo changes and formal code docs: use the code platform's PR/MR flow (GitHub PR or GitLab MR).
   - High-level shared docs (`OVERVIEW`, PRD, test plan, project design, architecture design, roadmap, major decisions, `CURRENT/NEXT/RISKS/TODO`, `决策日志`): GitLab docs MR.
   - Personal process records (`开发记录/<用户名>/...`, personal research notes, `_handoffs/...`): direct push is allowed when the project docs repo explicitly keeps that relaxed path.

### Document-standards-level (form, topic, frontmatter, naming)

10. **Every `.md` you create or substantially edit must have frontmatter** with at least these fields:
   ```yaml
   ---
   title: <clear short title>
   form: state | trace | decision | design | reference | index
   updated: YYYY-MM-DD
   status: draft | active | deprecated | archived
   tags: [<at least one>]
   ---
   ```
   If creating a new doc and you can't commit to a `form`, **stop and ask the user** which form fits.
11. **`form` value must match the doc's structure and lifecycle**. A trace document that rewrites history, or a state doc that appends timestamped entries, is a form violation — flag it.
12. **Naming must follow the form's convention**:
    - `state` → uppercase no prefix (`CURRENT.md`, `NEXT.md`, `RISKS.md`, `TODO.md`)
    - `trace` → `_handoffs/YYYY-MM-DD-HHMM-<kebab-topic>.md` for handoffs, or `开发记录/<用户名>/YYYY-MM-DD-<kebab-topic>.md` for personal dev records
    - `decision` → `ADR-NNN-<slug>.md` or entries inside `决策日志.md`
    - `design` → semantic name, optionally two-digit prefix `NN-<name>.md` for ordered series; `OVERVIEW.md` / `00-项目概览.md` for the entry
    - `reference` → semantic name
    - `index` → `README.md` or `00_INDEX.md`
13. **Refuse to create these filenames**: `草稿.md`, `未命名*.md`, `随笔.md`, `tmp_*.md`, `test*.md` (unless actually a test file for code), `20260420_xxx.md` (wrong date format). Suggest a valid name instead.
14. **trace and decision forms are append-only on history**. An existing `_handoffs/2026-04-20-...md` or `ADR-005-...md` cannot be rewritten — fix typos only, never semantic content. To supersede a decision, create a new ADR with `status: supersedes ADR-005` and flip the old one to `status: deprecated`.
15. **One thing per file** for `trace` and `decision` forms — one session per handoff, one change topic per dev record, one decision per ADR.
16. **When modifying any doc, update `updated: YYYY-MM-DD`** in its frontmatter.
17. **`state` form docs (CURRENT/NEXT/RISKS/TODO) must stay ≤ ~300 lines**. Over 2× that, warn the user and propose archiving old content to `archive/`.
18. **Every project must have**: `README.md` (index), at least one `form: design` doc with `topic: positioning` or `topic: overview` (e.g. `OVERVIEW.md`), state quartet, `_handoffs/`, `开发记录/<用户名>/`, `决策日志.md` (or `ADR/` dir), and `archive/`. If any is missing when you enter a project, flag it.

### TODO.md ownership (防 race condition)

19. **Before starting any TODO task**, follow the claim flow (see "TODO.md ownership" section). Check ownership first, claim atomically via commit+push, never take on a task without verifying you hold the lock.
20. **Never modify a TODO line whose `@owner` is not you** — neither content, nor state, nor `[x]`. Even if the task "looks done", the rightful owner makes that call.
21. **Claiming is not lazy-load**. Move-to-进行中 must be immediately followed by `git commit` + `git push`. No "claim first, push later" — that invites race conditions.
22. **Claim push conflicts = do not auto-grab**. If your claim push is rejected because someone else claimed the same task, abort, inform the user, let them coordinate — never `--force` to win the race.

## Document standards (the full picture)

Form/topic dual-axis, required baseline, naming — the single source of truth is the human-readable `07-文档组织规范.md` in the team playbook. Hard constraints #9–#17 above encode the subset an AI must enforce silently.

**The 6 forms** and their structure:

| form | structure | mutable? | target lines |
|------|-----------|----------|--------------|
| `state` | snapshot, rewritable | yes | <300 |
| `trace` | timestamped append-only log | **never rewrite history** | 100-300/entry |
| `decision` | recorded decisions | **supersede, don't edit** | 50-200/entry |
| `design` | narrative explanation | major revisions OK | 300-1500 |
| `reference` | lookup manual | update as needed | 200-800 |
| `index` | navigation | update on structure change | 50-200 |

**Topic is free-form** (recommended words: `positioning`, `overview`, `product`, `requirements`, `architecture`, `modules`, `implementation`, `research`, `benchmark`, `experiment`, `ops`, `external`, `self`), expressed as `topic: [word1, word2]` in frontmatter.

**Required baseline for every team project**:
- `README.md` (form=index)
- `OVERVIEW.md` or equivalent (form=design, topic contains `positioning` or `overview`)
- `CURRENT.md` / `NEXT.md` / `RISKS.md` / `TODO.md` (form=state, four-file quartet)
- `_handoffs/` and `开发记录/<用户名>/` (form=trace)
- `决策日志.md` or `ADR/NNN-*.md` (form=decision)
- `archive/`

## TODO.md ownership (full claim flow)

TODO.md has four sections. Each section has rules:

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

### Before starting any TODO work

1. `cd obsidian-docs && git pull --rebase`
2. Locate the target line in TODO.md.
3. Branch:
   - **In 进行中, `@owner` is you** → proceed.
   - **In 进行中, `@owner` is someone else** → STOP. Report: "TODO `<task>` is claimed by `@xxx` since `<date>`. Do you want to (a) coordinate with them, (b) wait for them to release, or (c) forcibly reassign? I won't proceed without your decision."
   - **In 阻塞** → STOP. Report the blocker.
   - **In 待办** → execute claim flow (below).
   - **Not in TODO.md at all** → STOP. Ask user if they want to add it first.

### Claim flow (atomic, lock-style)

1. Remove the line from `## 待办`.
2. Append to `## 进行中`: `- [ ] <original-text> @<user> since <today>` plus any metadata.
3. `git add TODO.md`
4. `git commit -m "chore(todo): claim \"<short task>\" @<user>"`
5. `git push`
6. **If push rejected**: `git pull --rebase` then retry push. If the rebase hits a conflict (meaning someone else claimed concurrently), **abort**, inform user, do NOT auto-retake.
7. **If push succeeds**: the claim is yours, proceed to do the work.

Determine `<user>` from `git config user.name` or the conversation context if the user explicitly identifies themselves. If unsure, ask before claiming.

### During work

- Progress updates go in `## 最近完成` only when tasks are actually done (`[x]`), not mid-work.
- If you discover a task you took on is bigger than expected and should split: add sub-tasks to `## 进行中` under the parent (indented), each with `@you since <today>`. Keep parent as umbrella.

### Completion (at `/handoff` time)

For tasks YOU own that finished this session:

1. Flip `[ ]` → `[x]`.
2. Move from `## 进行中` to `## 最近完成`.
3. Replace `since <start-date>` with `<completion-date>`.
4. Keep `@owner` unchanged (it's your audit trail).

For tasks YOU own that didn't finish: leave in `## 进行中`; optionally add a sub-note like `  └─ completed sub-tasks X of Y; blocker: ...`.

For tasks YOU don't own: **don't touch**. If you observe evidence their task is done, leave a comment for the owner but don't mark `[x]` yourself.

### Stale claim release (etiquette, not enforced)

A 进行中 entry whose `since` is >14 days old may be re-claimed by someone else:

1. Manual: edit the line, replace `@old-owner since <old-date>` with `@new-owner since <today>`.
2. Commit message: `chore(todo): re-claim stale TODO from @old-owner (idle 14d)`.
3. **Recommended etiquette**: message the original owner on Feishu/Slack first (not technically required, but rude to skip).

## Templates

See the `templates/` directory in this skill for copy-pastable clean starting points. All templates include the required frontmatter (title / form / topic / updated / status / tags) out of the box.

- `templates/OVERVIEW.md` — project narrative entry (form=design, topic=[positioning, overview])
- `templates/CURRENT.md` — one-screen status (form=state)
- `templates/NEXT.md` — strategic next actions + undecided items (form=state)
- `templates/RISKS.md` — active + archive (form=state)
- `templates/TODO.md` — task quartet with `@owner` claim mechanic (form=state)
- `templates/handoff.md` — handoff frontmatter + sections (form=trace)
- `templates/ADR.md` — architecture decision record (form=decision)

## Scripts

See the `scripts/` directory:

- `scripts/handoff-manual.sh` — shell-only handoff flow for non-AI users or when the agent isn't running

## Rationale links (for curious agents and humans)

- The state quartet CURRENT/NEXT/RISKS/TODO compresses the team's full devlog into four one-screen reads — it's the heart of the protocol. Each has a distinct role: project state / strategic direction / risks / task-level work tracking with ownership.
- `_handoffs/` append-only means parallel sessions never conflict on the audit trail.
- TODO ownership with immediate push is a distributed lock pattern — git's existing push-then-pull conflict detection gives us race-condition protection for free, without a central task server.
- gitleaks + hard constraints around `--no-verify` come from the observation that an accidental push of a secret to a private repo is effectively a permanent leak (all collaborators' clones preserve history) — prevention is orders of magnitude cheaper than recovery.
- AGENTS.md at the project level is the cross-agent open standard (agents.md); `CLAUDE.md` if present is a thin `@./AGENTS.md` import pointer for Claude Code, keeping one source of truth.
- Form/topic dual-axis separates "what's the document's structural role" from "what's it about", letting the same 6-form taxonomy apply to research, product, infra projects alike — the main protocol enforces form, project-specific topics are free.

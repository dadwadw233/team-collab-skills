---
name: protocol
description: |
  OPC (One-Person-Company) collective team collaboration protocol. Load when any of these is true: (1) `obsidian-docs/` exists in cwd or an ancestor dir; (2) `~/.team-docs-config` exists; (3) project's `AGENTS.md` or `CLAUDE.md` references this protocol or an `obsidian-docs/` path; (4) user mentions handoff, checkpoint, CURRENT.md, NEXT.md, RISKS.md, `_handoffs/`, team-collab, team-docs-sync, or invokes `/handoff`/`/checkpoint`; (5) user asks about team docs workflow or multi-OPC coordination. Provides start/mid/end-session workflow, handoff file format, CURRENT/NEXT/RISKS templates, git sync (pull→commit→push) with hard constraints (no force push, no `--no-verify`, no fabricated empty handoffs), conflict handling decision tree, gitleaks false-positive handling, cross-agent reference behavior.
---

# Team Collaboration Protocol

This skill encodes the AI-side protocol for working in a team project that follows the OPC collective documentation architecture. It complements the human-facing playbook (typically at `gitlab.com/<team-group>/team-collab-playbook`).

## Context (what you're looking at)

When this skill is loaded, the user is working in a project where:

- **Code** lives in a code repository (typically GitHub), accessed from `~/projects/<project>/`.
- **Docs** live in a separate docs repository (typically GitLab, invite-only), accessed from `~/projects/<project>/obsidian-docs/` — which is either a symlink to an Obsidian vault subdirectory, or a direct `git clone` into that path.
- **Project-level instructions** for agents live in `AGENTS.md` at the code repo root (cross-agent standard per agents.md). `CLAUDE.md`, if present, is typically a thin import pointer to `AGENTS.md`.
- **Shared docs state** is expressed in three files at the docs repo root:
  - `CURRENT.md` — one-screen project status (the team's single reading entry point)
  - `NEXT.md` — next actions + open decisions
  - `RISKS.md` — active risks + archived-resolved ones
- **Audit trail** of each AI session lives in `obsidian-docs/_handoffs/YYYY-MM-DD-HHMM-<topic>.md` (append-only).

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
3. `obsidian-docs/NEXT.md` — next actions and undecided items
4. Optionally recent 2-3 entries in `obsidian-docs/_handoffs/` — what happened recently

If the user gave you a task in their prompt that isn't in `NEXT.md`, **pause and align** with them before acting — the task may be mid-flight from elsewhere or out of scope for this session.

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

### Step 6: update CURRENT / NEXT / RISKS (in-place, minimal diff)

**Edit only the sections that changed** — do not rewrite entire files.

- `CURRENT.md`: milestones / active branch / recent completions / current focus, if any changed
- `NEXT.md`: strike finished items; append new next steps; move resolved decisions out to `CURRENT.md` or an ADR
- `RISKS.md`: add new risks to the active table; move resolved ones to the archive section

### Step 7: sync to remote (strict)

In the docs repo:

1. **Precise `git add`** — do not `git add .` (would catch `.obsidian/workspace.json` etc if `.gitignore` missed it):
   ```bash
   git add CURRENT.md NEXT.md RISKS.md _handoffs/ 开发记录/ <any other paths you touched>
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
- Which sections of CURRENT / NEXT / RISKS changed (skip unchanged).
- Docs repo commit hash + push result.
- Anything the user should do next (resolve a conflict, check something, approve a migration, etc.).

## When the user invokes `/checkpoint` (mid-session)

Mid-session snapshot. **File-level only — no git operations.**

### Steps

1. Read `obsidian-docs/CURRENT.md`, `NEXT.md`, `RISKS.md`.
2. Assess session state so far from `git status` + `git diff` + conversation.
3. Update **only** CURRENT / NEXT / RISKS sections that changed — in place, minimal diff. No append-handoff.
4. **Do not** `git add`, commit, push, or pull. Checkpoint is a working-tree snapshot, nothing leaves local.
5. One-line report per file changed: which section + what changed.

### Difference from `/handoff`

- `/handoff` = end-of-session: pull + append handoff + update triad + commit + rebase + push
- `/checkpoint` = mid-session: update triad only, zero git ops

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
8. **Keep wikilinks out of critical cross-file references**. Use standard Markdown `[text](./path.md)` for CURRENT/NEXT/RISKS/ADR internal links so they render on web (GitHub/GitLab). Wikilinks are OK for informational prose but not for navigation anchors.

## Templates

See the `templates/` directory in this skill for copy-pastable clean starting points:

- `templates/CURRENT.md` — one-screen status structure
- `templates/NEXT.md` — next actions + undecided items structure
- `templates/RISKS.md` — active + archive structure
- `templates/handoff.md` — handoff file frontmatter + sections
- `templates/ADR.md` — architecture decision record

## Scripts

See the `scripts/` directory:

- `scripts/handoff-manual.sh` — shell-only handoff flow for non-AI users or when the agent isn't running

## Rationale links (for curious agents and humans)

- The triad CURRENT/NEXT/RISKS is a compression of the team's full devlog into a one-screen status that anyone can read in a minute — it's the heart of the protocol.
- `_handoffs/` append-only means parallel sessions never conflict on the audit trail.
- gitleaks + hard constraints around `--no-verify` come from the observation that an accidental push of a secret to a private repo is effectively a permanent leak (all collaborators' clones preserve history) — prevention is orders of magnitude cheaper than recovery.
- AGENTS.md at the project level is the cross-agent open standard (agents.md); `CLAUDE.md` if present is a thin `@./AGENTS.md` import pointer for Claude Code, keeping one source of truth.

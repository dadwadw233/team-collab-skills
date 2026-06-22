<div align="center">

<img src="assets/banner.svg" alt="Team Collab Skills banner" width="100%">

<br>

[![Code: Apache-2.0](https://img.shields.io/badge/Code-Apache--2.0-f59e0b.svg)](./LICENSE) [![Docs: CC BY-SA 4.0](https://img.shields.io/badge/Docs-CC%20BY--SA%204.0-14b8a6.svg)](./LICENSE-DOCS.md)
[![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-14b8a6?logo=anthropic&logoColor=white)](https://docs.anthropic.com/en/docs/claude-code/plugins)
[![Codex](https://img.shields.io/badge/Codex-marketplace-10a37f?logo=openai&logoColor=white)](https://github.com/openai/codex)
[![Adapters](https://img.shields.io/badge/Adapters-Cursor%20%7C%20VS%20Code%20%7C%20Cline%20%7C%20OpenCode%20%7C%20Continue%20%7C%20Gemini-0f172a)](#adapter-matrix)
[![GitHub stars](https://img.shields.io/github/stars/dadwadw233/team-collab-skills?style=social)](https://github.com/dadwadw233/team-collab-skills)

**One team documentation and multi-agent collaboration protocol, packaged for Claude Code, Codex, Cursor, VS Code, Cline, OpenCode, Continue, Gemini CLI, and manual workflows.**

[Quick Start](#quick-start) · [Adapter Matrix](#adapter-matrix) · [Multi-Agent Collaboration](#multi-agent-collaboration) · [Repository Map](#repository-map) · [中文简介](#中文简介)

</div>

---

## Why This Exists

AI coding sessions fail teams in boring ways: context is lost, TODO ownership is unclear, docs drift, and handoffs become chat archaeology. `team-collab-skills` turns the operating rules into reusable agent runtime artifacts:

- **State quartet**: `CURRENT.md`, `NEXT.md`, `RISKS.md`, `TODO.md`
- **Session rituals**: `$checkpoint` during long work, `$handoff <topic>` at the end, `$team-progress <window>` for recent teammate progress, `$docs-refresh <audit-doc>` when docs are stale
- **TODO ownership**: explicit `@owner` claim mechanics to avoid parallel-agent races
- **Docs governance**: code changes go through PR/MR, shared docs go through docs MR, personal records stay under `开发记录/<用户名>/`
- **State hygiene**: state docs stay concise, structured, and link-driven instead of becoming chronological PR/commit logs
- **Multi-tool packaging**: native Claude/Codex packaging plus thin adapters for mainstream IDE/CLI tools
- **Multi-agent collaboration (v0.2.0+)**: file-backed wave protocol with agent identity, task/resource claims plus heartbeat, truth-source freshness gates, review/merge gate, and optional tmux live-session acceleration; coordinators and workers collaborate through committed files

The human playbook and npm CLI live in [`embodot/team-collab-playbook`](https://gitlab.com/embodot/team-collab-playbook). This repository is the **agent runtime source of truth**.

Runtime scope is intentionally narrow: this repo ships skills, protocol references, adapters, manifests, scripts, and user-facing README/license material. Architecture audits, implementation plans, brainstorms, and other process notes belong outside the public runtime tree; local drafts may live in the gitignored `_meta/` directory.

---

## Quick Start

### Claude Code

```bash
claude plugin marketplace add dadwadw233/team-collab-skills
claude plugin install team-collab@team-collab-skills
```

Claude loads the protocol as `team-collab:team-collab-protocol` when a strong team-project signal is present, such as `obsidian-docs/`, project `AGENTS.md`, CURRENT/NEXT/RISKS/TODO references, or explicit handoff/checkpoint/docs-governance requests.

### Codex CLI

```bash
codex plugin marketplace add https://github.com/dadwadw233/team-collab-skills.git
```

Codex entrypoints:

```text
$checkpoint
$handoff <topic>
$team-progress 24h
$docs-refresh <audit-doc-or-topic>
```

Codex may not support arbitrary custom top-level slash commands. If `/handoff`, `/checkpoint`, `/team-progress`, or `/docs-refresh` reaches the model as plain text, the global/project `AGENTS.md` pointer should treat it as equivalent to the `$...` form.

### Team CLI Installer

If your team uses the playbook package:

```bash
npm install -g @embodot/collab@latest
team-collab install-skills --agent all --force
team-collab doctor --project <project>
```

---

## Adapter Matrix

| Tool | Native shape | Files shipped here | Install strategy |
|------|--------------|--------------------|------------------|
| **Claude Code** | Plugin marketplace + skills | `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, `skills/*/SKILL.md` | `claude plugin marketplace add dadwadw233/team-collab-skills` |
| **Codex CLI** | Marketplace + plugin manifest | `.agents/plugins/marketplace.json`, `.codex-plugin/plugin.json`, `skills/*` | `codex plugin marketplace add https://github.com/dadwadw233/team-collab-skills.git` |
| **Cursor** | Project rules | `adapters/cursor/.cursor/rules/team-collab.mdc` | Copy into project when Cursor is used |
| **VS Code / Copilot** | Custom instructions | `adapters/vscode/.github/copilot-instructions.md`, `.github/instructions/team-collab.instructions.md` | Copy into project when Copilot is used |
| **Cline** | Workspace rules | `adapters/cline/.clinerules/team-collab.md` | Copy into project when Cline is used |
| **OpenCode** | `AGENTS.md` + `opencode.json` instructions | `adapters/opencode/AGENTS.md`, `adapters/opencode/opencode.json` | Prefer root `AGENTS.md`; use `opencode.json` for explicit references |
| **Continue** | Local rules | `adapters/continue/.continue/rules/team-collab.md` | Copy into `.continue/rules/` |
| **Gemini CLI** | `GEMINI.md` + custom commands | `adapters/gemini/GEMINI.md`, `.gemini/commands/*.toml` | Copy into project for `/handoff`, `/checkpoint`, `/team-progress`, and `/docs-refresh` commands |
| **Manual** | Markdown + shell helper | `skills/protocol/SKILL.md`, `skills/protocol/scripts/handoff-manual.sh` | Read and run manually if no skill-native agent is available |

Adapter files are intentionally **thin pointers**. Do not fork the protocol into every tool-specific rule file; keep `skills/protocol/SKILL.md` and `skills/protocol/references/` as the source of truth.

## Context Budget

Team-collab is designed for progressive loading:

- Global pointers only detect strong team-project signals and route to the skill.
- Normal team-project startup reads repo `AGENTS.md` plus `CURRENT.md`, `RISKS.md`, `NEXT.md`, and `TODO.md`.
- Handoffs, personal dev records, design docs, the full playbook, and the wider Obsidian vault load only when a task needs them.
- A global `~/.team-collab/config.json` is not enough to activate the protocol in unrelated repositories.

---

## What Lives Here

| Runtime artifact | Purpose |
|------------------|---------|
| `skills/protocol/SKILL.md` | Slim runtime entrypoint: activation rules, quick context, hard constraints, and references to task-specific protocol files |
| `skills/protocol/references/` | Detailed protocol modules for startup/audit, handoff, checkpoint, team progress, docs refresh, git policy, docs standards, TODO ownership, and multi-agent wave/status/gate/claim/live-session workflows |
| `skills/handoff/SKILL.md` | Codex-friendly `$handoff <topic>` wrapper that delegates to the protocol entrypoint |
| `skills/checkpoint/SKILL.md` | Codex-friendly `$checkpoint` wrapper that delegates to the protocol entrypoint |
| `skills/team-progress/SKILL.md` | Codex-friendly `$team-progress <window>` wrapper for teammate progress, blockers, and PR/MR review needs |
| `skills/docs-refresh/SKILL.md` | Codex-friendly `$docs-refresh <audit-doc>` wrapper for stale Obsidian docs refresh |
| `skills/protocol/templates/` | Baseline project-doc templates for state, trace, and decision documents |
| `skills/protocol/scripts/handoff-manual.sh` | Shell-only fallback for manual handoff flow |
| `adapters/` | Tool-specific thin pointers for Cursor, VS Code, Cline, OpenCode, Continue, and Gemini CLI |

---

## Multi-Agent Collaboration

v0.2.0 promotes multi-agent work into a file-backed wave model: a coordinator plans the wave, worker agents claim tasks/resources, per-agent status plus claims carry the heartbeat, and gate checks protect merge readiness. Files are the truth; tmux live sessions only accelerate delivery and never replace committed status, messages, reviews, claims, or digests.

CLI surface from `@embodot/collab`:

- `multi-agent enable|init`
- `agent start|checkpoint|finish|close|status`
- `multi-agent digest|gate|plan --check|monitor`
- `agent bind-session|watch|send`

Protocol references:

- [Multi-agent wave layout](./skills/protocol/references/multi-agent.md)
- [Gate checks and plan validation](./skills/protocol/references/gate-check.md)
- [Agent status lifecycle](./skills/protocol/references/agent-status.md)
- [Live-session accelerator](./skills/protocol/references/live-session.md)
- [Claims and freshness gates](./skills/protocol/references/claim-and-freshness.md)

---

## How It Works

```text
                 team project signal
        obsidian-docs/ · AGENTS.md · user asks handoff
                           │
                           ▼
             ┌──────────────────────────┐
             │ team-collab-protocol     │
             │ source of truth          │
             └────────────┬─────────────┘
                          │
          ┌───────────────┼────────────────┐
          ▼               ▼                ▼
   Claude plugin     Codex marketplace   IDE/CLI adapters
   skills/*          $handoff/$checkpoint/$team-progress/$docs-refresh
          │               │                │
          └───────────────┼────────────────┘
                          ▼
      CURRENT · NEXT · RISKS · TODO · _handoffs · 开发记录
```

```text
                     coordinator
                          │
                          ▼
       wave files: PRD · pr-plan · claims · decisions
                          │
              ┌───────────┼───────────┐
              ▼           ▼           ▼
       implementer   reviewer      tester
          start       status       status
            │           │           │
            └──── checkpoint ─ finish ────┐
                                           ▼
                             gate: sign-off · review · claims · freshness
                                           │
                                           ▼
                                         merge
```

---

## Repository Map

```text
team-collab-skills/
├── .claude-plugin/              # Claude Code marketplace + plugin metadata
├── .agents/plugins/             # Codex marketplace metadata
├── .codex-plugin/               # Codex plugin metadata
├── adapters/                    # Thin pointers for non-skill-native tools
│   ├── cursor/
│   ├── vscode/
│   ├── cline/
│   ├── opencode/
│   ├── continue/
│   └── gemini/
├── assets/                      # README visuals
├── scripts/                     # Repo validation helpers
└── skills/
    ├── protocol/                # Slim entrypoint, references, templates, multi-agent wave workflows
    │   └── references/          # Startup/docs modules plus multi-agent wave/status/gate/claim/live-session
    ├── handoff/                 # Codex wrapper
    ├── checkpoint/              # Codex wrapper
    ├── team-progress/           # Codex wrapper
    └── docs-refresh/            # Codex wrapper
```

---

## Validate

```bash
scripts/validate-structure.sh
git diff --check

# Codex marketplace smoke test
CODEX_HOME="$(mktemp -d)" codex plugin marketplace add "$PWD"
```

`validate-structure.sh` checks required manifests/adapters and ensures runtime files do not point at the human playbook repository.

## Release

```bash
scripts/bump-version.sh X.Y.Z
scripts/validate-structure.sh
```

`skills/protocol/SKILL.md` is the protocol version source of truth. The bump script rewrites plugin manifests, adapter drift markers, wrapper protocol ranges, and validation constants, then leaves the diff for manual review.

---

## 中文简介

`team-collab-skills` 是团队协作文档协议的 **AI runtime 仓库**。它把 handoff、checkpoint、team-progress、docs-refresh、CURRENT/NEXT/RISKS/TODO、TODO `@owner` 认领、Obsidian 项目文档规范、代码 PR/MR 与文档 MR 边界，封装成 Claude/Codex 可安装的 skill/plugin，同时为 Cursor、VS Code、Cline、OpenCode、Continue、Gemini CLI 提供轻量 adapter。

v0.2.0 起，它也把多 agent wave 协作提升为一等协议：coordinator 规划 wave，worker 通过 status/claims/heartbeat 协作，gate 用 review、claim 与 freshness 检查守住 merge，tmux live-session 只是加速层，文件仍是唯一真相源。

边界很明确：

- **这里**放 agent runtime：skills、plugins、marketplace manifests、adapter templates。
- **playbook** 放人类 SOP、npm CLI、installer、doctor、Feishu/GitLab 自动化。

---

## Related

- [team-collab-playbook](https://gitlab.com/embodot/team-collab-playbook) — human SOP and `@embodot/collab` CLI
- [agentskills.io specification](https://agentskills.io/specification) — open skill format used by the protocol skill
- [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) — companion Obsidian Markdown/Canvas/Base skills
- [AGENTS.md standard](https://agents.md/) — cross-agent project instruction format

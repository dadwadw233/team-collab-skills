# Agent marketplace boundary and multi-agent support

Date: 2026-05-06

## Decision

`team-collab-skills` is the source of truth for agent runtime artifacts:

- Agent skills (`skills/*/SKILL.md`)
- Claude Code plugin marketplace metadata (`.claude-plugin/marketplace.json`)
- Codex plugin marketplace metadata (`.agents/plugins/marketplace.json`)
- Codex plugin metadata (`.codex-plugin/plugin.json`)
- Lightweight adapters for agent-specific entrypoints such as `$handoff` and `$checkpoint`

`team-collab-playbook` remains the human and operations layer:

- SOP/playbook documents
- `@embodot/collab` npm CLI
- `install-skills`, `doctor`, `register`, `init`, `sync`
- Feishu/GitLab/GitHub automation templates

The playbook installer can register marketplaces, but it must register this repository as the marketplace source. It must not publish Codex plugin runtime files from the playbook repository.

## Why this correction is necessary

The previous Codex marketplace implementation put `.agents/plugins/marketplace.json`, `.codex-plugin/plugin.json`, and `$handoff` / `$checkpoint` wrapper skills into `team-collab-playbook`. That made the playbook repository act like an agent skill marketplace, which conflicts with the existing Claude architecture and with the repo responsibility split.

The corrected install shape is:

```bash
claude plugin marketplace add dadwadw233/team-collab-skills
claude plugin install team-collab@team-collab-skills
codex plugin marketplace add https://github.com/dadwadw233/team-collab-skills.git
```

## Researched structures

| Tool | Supported structure to respect | How this repo should support it |
| --- | --- | --- |
| Claude Code | Plugins live in directories with `.claude-plugin/plugin.json`; skills live under `skills/<name>/SKILL.md`; marketplaces list plugins. Existing `claude plugin marketplace add dadwadw233/team-collab-skills` works with the repo marketplace. | Keep `.claude-plugin/marketplace.json` and `skills/*/SKILL.md` here. |
| Codex CLI | Current local Codex bundled marketplaces use `.agents/plugins/marketplace.json`; each plugin root has `.codex-plugin/plugin.json`; plugin manifests can point at `skills`. `codex plugin marketplace add` accepts Git URLs and local marketplace roots. | Add `.agents/plugins/marketplace.json` and `.codex-plugin/plugin.json` here, with plugin source `./` and `skills: ./skills/`. |
| Cursor | Cursor rules are the durable repo-level instruction mechanism. | Keep project `AGENTS.md` as source of truth; future adapter can generate `.cursor/rules/team-collab.mdc` as a thin pointer. |
| VS Code / GitHub Copilot | Copilot customization supports `.github/copilot-instructions.md`, `AGENTS.md`, and file-based `*.instructions.md`. | Prefer `AGENTS.md`; future adapter can add `.github/instructions/team-collab.instructions.md` if needed. |
| Cline | Cline rules support `.clinerules/`, legacy tool rule files, and `AGENTS.md`; Cline also has Skills/Workflows. | Prefer `AGENTS.md`; future adapter can add `.clinerules/team-collab.md` or Cline skill packaging after live validation. |
| OpenCode | OpenCode rules support `AGENTS.md`, custom instruction files, and `opencode.json` `instructions`. | Prefer `AGENTS.md`; future adapter can add `opencode.json` only when the project already uses it. |
| Continue | Continue rules use workspace `.continue/rules` Markdown files and Hub rules. | Future adapter can create `.continue/rules/team-collab.md` as a thin pointer. |
| Gemini CLI | Gemini CLI supports custom commands under `~/.gemini/commands` and `<project>/.gemini/commands`. | Future adapter can provide command TOML templates for handoff/checkpoint, but not as part of the playbook marketplace. |

## Implementation rule

When adding support for a new agent:

1. Put reusable runtime instructions in `skills/*` where possible.
2. Put marketplace/plugin metadata in this repo only.
3. Keep project-local agent files as thin pointers to `AGENTS.md` or the installed `team-collab-protocol` skill.
4. Keep installer/doctor logic in `team-collab-playbook` and make it call this repo.
5. Do not copy the full protocol into every adapter unless the target tool has no stable include/reference mechanism.

## Primary references

- Claude Code plugins: https://docs.anthropic.com/en/docs/claude-code/plugins
- Claude Code skills: https://docs.anthropic.com/en/docs/claude-code/skills
- Codex CLI local help: `codex plugin marketplace add --help` in Codex CLI 0.128.0
- Codex bundled marketplace examples: `~/.codex/.tmp/bundled-marketplaces/openai-bundled/`
- VS Code / GitHub Copilot customization: https://code.visualstudio.com/docs/copilot/copilot-customization
- Cline rules: https://docs.cline.bot/customization/cline-rules.md
- Continue rules: https://docs.continue.dev/customize/deep-dives/rules
- OpenCode rules: https://opencode.ai/docs/rules
- Gemini CLI custom commands: https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/custom-commands.md

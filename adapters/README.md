# Team Collab Agent Adapters

This directory contains thin adapter templates for agents that do not consume the skill repository directly as a Claude or Codex plugin.

## Boundary

- Source of truth: `skills/protocol/SKILL.md`.
- Plugin/runtime manifests: this repository.
- Human SOP, npm CLI, doctor, installer, and Feishu/GitLab automation: `team-collab-playbook`.
- Project-local agent files should be pointers, not full protocol copies.

## Adapters

| Tool | Files | Why this shape |
| --- | --- | --- |
| Cursor | `.cursor/rules/team-collab.mdc` | Cursor project rules use MDC files under `.cursor/rules`. |
| VS Code / GitHub Copilot | `.github/copilot-instructions.md`, `.github/instructions/team-collab.instructions.md` | Copilot supports repo-wide custom instructions and instruction files. |
| Cline | `.clinerules/team-collab.md` | Cline rules are project files under `.clinerules/`; Cline also detects `AGENTS.md`. |
| OpenCode | `AGENTS.md`, `opencode.json` | OpenCode rules support `AGENTS.md` and `opencode.json` instruction references. |
| Continue | `.continue/rules/team-collab.md` | Continue local rules live in `.continue/rules`. |
| Gemini CLI | `GEMINI.md`, `.gemini/commands/*.toml` | Gemini CLI supports context files and project custom commands. |

Copy the relevant adapter files into a project only when that tool is actually used. Prefer keeping a repo-root `AGENTS.md` as the cross-agent source of truth.

## References used

- Cursor rules: https://cursor.com/docs/rules
- VS Code / GitHub Copilot customization: https://code.visualstudio.com/docs/copilot/copilot-customization
- Cline rules: https://docs.cline.bot/customization/cline-rules.md
- OpenCode rules: https://opencode.ai/docs/rules
- Continue rules: https://docs.continue.dev/customize/deep-dives/rules
- Gemini CLI context files: https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md
- Gemini CLI custom commands: https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/custom-commands.md

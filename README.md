# team-collab-skills

Claude Agent Skills for OPC (One-Person-Company) collective team collaboration — provides a protocol that AI agents (Claude Code, Codex CLI, Cursor, Cline, Continue, Gemini CLI, ...) follow when working in team projects with shared documentation repos.

## What lives here

| Skill | Purpose |
|-------|---------|
| `team-collab-protocol` | Full team collaboration protocol: startup orientation, audit/normalization, handoff / checkpoint flow, CURRENT/NEXT/RISKS/TODO state quartet, mandatory `开发记录/<用户名>/...`, code-platform PR/MR and GitLab docs MR boundaries, git sync conventions, hard constraints, conflict handling decision tree |
| `handoff` | Codex-friendly `$handoff <topic>` wrapper that delegates to `team-collab-protocol` |
| `checkpoint` | Codex-friendly `$checkpoint` wrapper that delegates to `team-collab-protocol` |

The skill content is written against the [Anthropic Agent Skills open specification](https://agentskills.io/specification). This repository is the runtime distribution source for agent-facing skills/plugins/marketplaces and thin IDE/CLI adapters. The human SOP, npm CLI, installers, doctor checks, and Feishu/GitLab automation live in the playbook repository.

## Install

### Claude Code

```bash
claude plugin marketplace add dadwadw233/team-collab-skills
claude plugin install team-collab@team-collab-skills
```

Skill becomes available as `team-collab:team-collab-protocol`. Claude auto-loads it from strong project signals such as `obsidian-docs/`, project instructions, current path matching `~/.team-collab/config.json` or legacy `~/.team-docs-config`, or explicit user requests about handoff/checkpoint/team docs, Feishu automation, or project docs audit/normalization. Existence of a global team-collab config alone is intentionally not enough.

### Codex CLI

```bash
codex plugin marketplace add https://github.com/dadwadw233/team-collab-skills.git
```

The Codex marketplace manifest is in `.agents/plugins/marketplace.json`, and the Codex plugin manifest is in `.codex-plugin/plugin.json`. This is intentional: Codex runtime artifacts belong in this skills repository, not in the human playbook repository. The playbook installer may call this command, but it should not be the marketplace source.

Use:

```text
$handoff <topic>
$checkpoint
```

Codex may not support custom top-level `/handoff` or `/checkpoint` slash commands; if those reach the model as plain text, the global `AGENTS.md` pointer tells Codex to treat them as equivalent to the `$...` form.

### Other agents (OpenCode, Cursor, VS Code, Cline, Continue, Gemini CLI)

```bash
# Clone to the agent's skill directory (exact path varies by agent — see agent's docs)
git clone https://github.com/dadwadw233/team-collab-skills.git <agent-skills-dir>
```

Or git-submodule into your agent's skill workspace. SKILL.md is a standard open-spec skill file, any compliant agent will load it.

For non-skill-native tools, keep the protocol as a referenced rule instead of copying it:
- Codex: global `~/.codex/AGENTS.md` plus project root `AGENTS.md`
- OpenCode: project rules point to root `AGENTS.md`
- Cursor: rules point to root `AGENTS.md`
- VSCode: workspace note points humans and extensions to root `AGENTS.md`

This repository also ships thin templates under `adapters/`:

| Tool | Template path |
|------|---------------|
| Cursor | `adapters/cursor/.cursor/rules/team-collab.mdc` |
| VS Code / GitHub Copilot | `adapters/vscode/.github/copilot-instructions.md`, `adapters/vscode/.github/instructions/team-collab.instructions.md` |
| Cline | `adapters/cline/.clinerules/team-collab.md` |
| OpenCode | `adapters/opencode/AGENTS.md`, `adapters/opencode/opencode.json` |
| Continue | `adapters/continue/.continue/rules/team-collab.md` |
| Gemini CLI | `adapters/gemini/GEMINI.md`, `adapters/gemini/.gemini/commands/*.toml` |

These adapter files are intentionally pointers. Do not copy the full protocol into each tool-specific file; keep `skills/protocol/SKILL.md` as the source of truth.

## Validate

```bash
scripts/validate-structure.sh
git diff --check
```

### Manual (no agent)

The skill's protocol text and templates are readable Markdown. You can `git clone` this repo just to keep a local reference and follow the handoff flow manually — see `skills/protocol/scripts/handoff-manual.sh` for a shell-only implementation.

## Context

This skill is meant to be installed by members of an OPC collective that has:

- A team playbook repo (e.g. `gitlab.com/<team>/team-collab-playbook`) with human-facing docs
- Per-project docs directories, usually GitLab docs repos (`gitlab.com/<team>/<project>-docs`) for new projects, with existing Obsidian vault subdirectories allowed when that is the user's established workflow
- Code repos on GitHub or GitLab with protected `main`; code changes go through the platform's PR/MR flow
- GitLab docs repos with protected `main`; high-level shared docs through MR; personal dev records may use the project's relaxed direct-push path
- Individual `~/.team-collab/config.json` listing projects each member opted into, with legacy `~/.team-docs-config` compatibility
- The `@embodot/collab` npm CLI for `install-skills`, `register`, `init`, `sync`, and `doctor`

If you don't have those yet, read the playbook first — this skill is the AI-facing layer that complements it.

## License

MIT — see [LICENSE](./LICENSE).

## Related

- [agentskills.io specification](https://agentskills.io/specification) — the open standard this skill follows
- [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) — companion skill for Obsidian flavored markdown (install this too if you're in our team)
- [AGENTS.md standard](https://agents.md/) — cross-agent project-level instructions format we use

# team-collab-skills

Claude Agent Skills for OPC (One-Person-Company) collective team collaboration — provides a protocol that AI agents (Claude Code, Codex CLI, Cursor, Cline, Continue, Gemini CLI, ...) follow when working in team projects with shared documentation repos.

## What's in here

| Skill | Purpose |
|-------|---------|
| `protocol` | Full team collaboration protocol: handoff / checkpoint flow, CURRENT/NEXT/RISKS/TODO state quartet, mandatory `开发记录/<用户名>/...`, GitHub PR/GitLab MR boundaries, git sync conventions, hard constraints, conflict handling decision tree |

The skill is written against the [Anthropic Agent Skills open specification](https://agentskills.io/specification) and works with any agent that implements the standard.

## Install

### Claude Code

```bash
claude plugin marketplace add dadwadw233/team-collab-skills
claude plugin install team-collab@team-collab-skills
```

Skill becomes available as `team-collab:protocol`. Claude auto-loads it from strong project signals such as `obsidian-docs/`, project instructions, current path matching `~/.team-docs-config`, or explicit user requests about handoff/checkpoint/team docs. Existence of `~/.team-docs-config` alone is intentionally not enough.

### Other agents (Codex CLI, OpenCode, Cursor, VSCode, Cline, Continue, Gemini CLI)

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

### Manual (no agent)

The skill's protocol text and templates are readable Markdown. You can `git clone` this repo just to keep a local reference and follow the handoff flow manually — see `skills/protocol/scripts/handoff-manual.sh` for a shell-only implementation.

## Context

This skill is meant to be installed by members of an OPC collective that has:

- A team playbook repo (e.g. `gitlab.com/<team>/team-collab-playbook`) with human-facing docs
- Per-project docs repos (`gitlab.com/<team>/<project>-docs`) under an invite-only Group
- GitHub code repos with PR-only protected `main`
- GitLab docs repos with protected `main`; high-level shared docs through MR; personal dev records through direct push
- Individual `~/.team-docs-config` listing projects each member opted into
- A `team-docs-sync.sh` batch clone/pull script

If you don't have those yet, read the playbook first — this skill is the AI-facing layer that complements it.

## License

MIT — see [LICENSE](./LICENSE).

## Related

- [agentskills.io specification](https://agentskills.io/specification) — the open standard this skill follows
- [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) — companion skill for Obsidian flavored markdown (install this too if you're in our team)
- [AGENTS.md standard](https://agents.md/) — cross-agent project-level instructions format we use

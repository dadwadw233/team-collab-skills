<!-- team-collab-protocol-source: skills/protocol/SKILL.md@0.5.0 -->
<!-- team-collab-required-commands: handoff, checkpoint, team-progress, docs-refresh -->
<!-- team-collab-source-of-truth: repo AGENTS.md + installed team-collab-protocol skill -->

# Team Collab Protocol Pointer

This is a thin pointer. If this repository is a team project, follow repo-root `AGENTS.md` first and use the installed `team-collab-protocol` skill as the source of truth.

Strong signals:

- `obsidian-docs/` exists in this repo or an ancestor.
- `AGENTS.md` references team-collab, CURRENT/NEXT/RISKS/TODO, `_handoffs`, or `obsidian-docs`.
- The user asks about handoff, checkpoint, team progress, TODO ownership, docs normalization, project audit, or Feishu automation.

## Context budget

Read only `obsidian-docs/CURRENT.md`, `RISKS.md`, `NEXT.md`, and `TODO.md` before normal substantive work. Do not load the full playbook, all handoffs, all dev records, or the whole Obsidian vault unless the task specifically needs them.

Use `$handoff <topic>`, `$checkpoint`, and `$team-progress <window>` for team-collab session flows.

Use `$docs-refresh <audit-doc>` or `/docs-refresh <audit-doc>` when updating Obsidian docs from a staleness audit: archive stale content first, rewrite active docs as current truth, and prefer useful Mermaid diagrams over long prose.

<!-- team-collab-protocol-source: skills/protocol/SKILL.md@0.6.1 -->
<!-- team-collab-required-commands: handoff, checkpoint, team-progress, docs-refresh -->
<!-- team-collab-source-of-truth: repo AGENTS.md + installed team-collab-protocol skill -->

# Team Collab Protocol Pointer

Use for Agent, Chat, and Edit requests only in repositories that opt into team-collab governance.

Activation signals:

- `obsidian-docs/` exists in this repo or an ancestor.
- `AGENTS.md` references team-collab, CURRENT/NEXT/RISKS/TODO, `_handoffs`, or `obsidian-docs`.
- The user asks about handoff, checkpoint, team progress, team docs workflow, TODO ownership, Feishu automation, project audit, or docs normalization.

When active, follow repo-root `AGENTS.md` and the installed `team-collab-protocol` skill. Use `$handoff <topic>`, `$checkpoint`, and `$team-progress <window>`.

## Context budget

This is a thin pointer. Read only the state quartet by default; do not load the full playbook, all handoffs, all dev records, or the whole Obsidian vault unless the task specifically needs them.

Use `$docs-refresh <audit-doc>` or `/docs-refresh <audit-doc>` when updating Obsidian docs from a staleness audit: archive stale content first, rewrite active docs as current truth, and prefer useful Mermaid diagrams over long prose.

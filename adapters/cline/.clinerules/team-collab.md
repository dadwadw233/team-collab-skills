# Team Collab Protocol Pointer

Apply only when the workspace has `obsidian-docs/`, team-collab references in `AGENTS.md`/`CLAUDE.md`, or the user asks about handoff, checkpoint, team docs workflow, TODO ownership, Feishu automation, project audit, or docs normalization.

Required behavior:

1. Read repo-root `AGENTS.md` first.
2. Use the installed `team-collab-protocol` skill as the source of truth.
3. Use `$handoff <topic>` for end-of-session handoff and `$checkpoint` for mid-session state snapshots.

## Context budget

This file is a thin pointer. Read only `obsidian-docs/CURRENT.md`, `RISKS.md`, `NEXT.md`, and `TODO.md` before normal substantive work. Do not load the full playbook, all handoffs, all dev records, or the whole Obsidian vault unless the task specifically needs them.

Use `$docs-refresh <audit-doc>` or `/docs-refresh <audit-doc>` when updating Obsidian docs from a staleness audit: archive stale content first, rewrite active docs as current truth, and prefer useful Mermaid diagrams over long prose.

---
name: docs-refresh
description: Use when the user invokes `$docs-refresh`, asks to update Obsidian project docs from a stale audit/dev record, or wants old docs archived while active docs become current.
---

# Team Collab Docs Refresh

Codex does not reliably support arbitrary custom top-level slash commands, so the supported Codex entry point is:

```text
$docs-refresh <audit-doc-or-topic>
```

## Required behavior

1. Treat text after `$docs-refresh` as the audit source, dev record, or refresh topic.
2. Follow the installed `team-collab-protocol` skill and its `references/docs-refresh.md` flow.
3. If the protocol skill is not loaded, read:

```text
~/.codex/skills/team-collab-protocol/SKILL.md
```

4. If missing, stop and tell the user to run:

```bash
team-collab install-skills --agent codex --force
```

5. Do not improvise a docs refresh from this wrapper alone. The protocol reference owns staleness audit handling, archive-first edits, active-doc rewrite rules, Mermaid preference, verification, and git governance.

## Compatibility note

If `/docs-refresh` reaches the model as plain text, handle it exactly the same way as `$docs-refresh`.

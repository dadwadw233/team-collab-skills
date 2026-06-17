---
name: handoff
requires_protocol: ">=0.6.0,<0.7.0"
description: Use when the user invokes `$handoff`, asks for a handoff, or asks to finish a team-collab session by updating CURRENT/NEXT/RISKS/TODO and syncing docs.
---

# Team Collab Handoff

This is a Codex-friendly command wrapper. Codex does not currently support arbitrary custom top-level slash commands like `/handoff`, so the supported Codex entry point is:

```text
$handoff <topic>
```

## Required behavior

1. Treat any text after `$handoff` as the handoff topic.
2. Immediately follow the installed `team-collab-protocol` skill and its `references/handoff.md` flow.
3. If the `team-collab-protocol` skill is not available in the current session, read it from:

```text
~/.codex/skills/team-collab-protocol/SKILL.md
```

4. If that file is missing, stop and tell the user to run:

```bash
team-collab install-skills --agent codex --force
```

5. Do not improvise a partial handoff from this wrapper alone. The protocol references own git sync, empty-session checks, state-quartet updates, sensitive-data rules, conflict handling, commit, and push behavior.

## Compatibility note

If a future Codex version supports custom slash commands and `/handoff` reaches the model as plain user text, handle it exactly the same way as `$handoff`.

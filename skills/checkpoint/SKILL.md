---
name: checkpoint
description: Use when the user invokes `$checkpoint`, asks for a checkpoint, or asks to update CURRENT/NEXT/RISKS/TODO without committing or pushing.
---

# Team Collab Checkpoint

This is a Codex-friendly command wrapper. Codex does not currently support arbitrary custom top-level slash commands like `/checkpoint`, so the supported Codex entry point is:

```text
$checkpoint
```

## Required behavior

1. Immediately follow the installed `team-collab-protocol` skill section "When the user invokes `/checkpoint`".
2. If the `team-collab-protocol` skill is not available in the current session, read it from:

```text
~/.codex/skills/team-collab-protocol/SKILL.md
```

3. If that file is missing, stop and tell the user to run:

```bash
team-collab install-skills --agent codex --force
```

4. Do not commit, push, pull, or append a handoff file during checkpoint. The full protocol owns exactly which state files may be edited.

## Compatibility note

If a future Codex version supports custom slash commands and `/checkpoint` reaches the model as plain user text, handle it exactly the same way as `$checkpoint`.

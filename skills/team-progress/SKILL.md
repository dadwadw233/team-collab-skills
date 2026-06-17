---
name: team-progress
requires_protocol: ">=0.6.0,<0.7.0"
description: Use when the user invokes `$team-progress`, asks to sync recent progress from other team members, or asks who has blockers or PR/MR items needing review in a team-collab project.
---

# Team Progress Sync

Codex-friendly command wrapper for concise team progress review. Supported Codex entry point:

```text
$team-progress <time-window>
```

Examples: `$team-progress 24h`, `$team-progress 3d`, `$team-progress since 2026-05-21 09:00`.

## Required behavior

1. Require a time window. If missing or ambiguous, ask one short question for the window and stop.
2. Treat the window as the lookback range for other team members' activity unless the user explicitly includes themselves.
3. Follow the installed `team-collab-protocol` skill and its `references/team-progress.md` flow.
4. If the protocol skill is not available in the current session, read it from:

```text
~/.codex/skills/team-collab-protocol/SKILL.md
```

5. If that file is missing, stop and tell the user to run:

```bash
team-collab install-skills --agent codex --force
```

6. Keep the final report concise and sectioned. Do not produce a long audit log unless the user asks for details.

## Compatibility note

If a future Codex version supports custom slash commands and `/team-progress` reaches the model as plain user text, handle it exactly the same way as `$team-progress`.

# Adapter Source Markers

All thin adapters in this directory are pointers to the runtime protocol, not independent protocol copies.

Required marker fields:

- `team-collab-protocol-source: skills/protocol/SKILL.md@0.5.5`
- `team-collab-required-commands: handoff, checkpoint, team-progress, docs-refresh`
- `team-collab-source-of-truth: repo AGENTS.md + installed team-collab-protocol skill`

`./scripts/validate-structure.sh` fails if an adapter loses the marker, command set, source-of-truth pointer, or context-budget reminder.

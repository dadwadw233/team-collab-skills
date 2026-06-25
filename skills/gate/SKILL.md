---
name: gate
requires_protocol: ">=0.6.0,<0.7.0"
description: Use when the user invokes `$gate`, asks whether a PR/merge is ready, asks to gate-check or merge-gate a multi-agent task, or asks "can this merge?".
---

# Team Collab Gate

This is a Codex-friendly command wrapper for the multi-agent **merge gate** check. Codex does not currently support arbitrary custom top-level slash commands like `/gate`, so the supported Codex entry point is:

```text
$gate --pr <number>
```

## What this does

The gate runs the pre-merge checks for a multi-agent task: agent sign-off, independent review, dependencies merged, owned-files scope, human-gated patterns, claim integrity, and truth-source freshness. `$gate` is the human→coordinator shortcut so you can ask "can this merge?" in one line instead of typing the full CLI.

## Required behavior

1. Follow the installed `team-collab-protocol` skill and its `references/gate-check.md` flow. If the protocol skill is not available in the current session, read `~/.codex/skills/team-collab-protocol/SKILL.md`; if that file is missing, stop and tell the user to run `team-collab install-skills --agent codex --force`.
2. Before running any CLI command, check `command -v team-collab`. If missing, stop and tell the user to install the CLI with `npm install -g @embodot/collab@latest`, then refresh skills with `team-collab install-skills --agent codex --force` if needed.
3. Parse a `--pr <number>` (or `--pr=<number>`) from the text after `$gate`. If the user said something like `$gate 42` or `$gate PR42`, treat the number as the PR. If no PR is given, ask which PR.
4. Infer the wave from the current working directory if possible (`multi-agent/<slug>/` subtree); otherwise ask, or pass it through as `--wave <slug>`.
5. Run the gate:
   ```bash
   team-collab multi-agent gate --pr <number> [--wave <slug>]
   ```
6. Report the result clearly to the user. Exit code 0 means the task may merge (possibly with warnings); exit code 5 means the gate found a blocking issue — summarize which check failed and point to the relevant `references/gate-check.md` section. Exit code 2 means a config/wave problem; 4 means a git/network read failure.
7. Do not merge anything yourself. The gate only checks; merging is a separate human or coordinator decision.

## Compatibility note

If a future Codex version supports custom slash commands and `/gate` reaches the model as plain user text, handle it exactly the same way as `$gate`.

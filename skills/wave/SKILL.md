---
name: wave
requires_protocol: ">=0.6.0,<0.7.0"
description: Use when the user invokes `$wave`, asks to start or enter a multi-agent wave, or asks to spin up / set up a wave for a batch of tasks coordinated across agents.
---

# Team Collab Wave

This is a Codex-friendly command wrapper for the multi-agent **wave** entry point. Codex does not currently support arbitrary custom top-level slash commands like `/wave`, so the supported Codex entry point is:

```text
$wave <slug-or-goal>
```

## What this does

A wave is a batch of multi-agent work coordinated entirely through committed files. `$wave` is the human→coordinator shortcut for starting or entering one, so you don't have to type the full `multi-agent enable` / `multi-agent init` CLI flags by hand.

## Required behavior

1. Follow the installed `team-collab-protocol` skill and its `references/multi-agent.md` flow. If the protocol skill is not available in the current session, read `~/.codex/skills/team-collab-protocol/SKILL.md`; if that file is missing, stop and tell the user to run `team-collab install-skills --agent codex --force`.
2. Before running any CLI command, check `command -v team-collab`. If missing, stop and tell the user to install the CLI with `npm install -g @embodot/collab@latest`, then refresh skills with `team-collab install-skills --agent codex --force` if needed.
3. Treat the text after `$wave` as a slug only when it is a single token matching `^[a-z][a-z0-9-]{2,63}$`. Otherwise, treat it as a goal, derive a slug, and confirm the slug with the user before creating anything.
4. Ensure the project has multi-agent mode enabled. If it does not, run:
   ```bash
   team-collab multi-agent enable
   ```
5. If the wave folder does not yet exist, create it:
   ```bash
   team-collab multi-agent init --slug <slug>
   ```
   If `<slug-or-goal>` was a free-text goal rather than a slug, read the generated `multi-agent/<slug>/PRD.md` and `pr-plan.md` and draft a first cut of the wave plan (goal, task breakdown, suggested roles) into them, then tell the user what you drafted and ask for confirmation.
6. If the wave folder already exists, just orient: read `multi-agent/<slug>/PRD.md`, `pr-plan.md`, and any existing `agent-runs/**`, then summarize the current wave state to the user.
7. Follow `references/multi-agent.md` for the wave layout, ownership, and command boundaries. Do not improvise task assignments from this wrapper alone — present the plan and let the user, coordinator, or CLI task lifecycle commands drive the next step.

## Compatibility note

If a future Codex version supports custom slash commands and `/wave` reaches the model as plain user text, handle it exactly the same way as `$wave`.

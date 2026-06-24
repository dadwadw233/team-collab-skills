---
name: digest
requires_protocol: ">=0.6.0,<0.7.0"
description: Use when the user invokes `$digest`, asks for a multi-agent wave digest or progress summary, or asks "what's the status of the wave" / "where are things".
---

# Team Collab Digest

This is a Codex-friendly command wrapper for the multi-agent **wave digest**. Codex does not currently support arbitrary custom top-level slash commands like `/digest`, so the supported Codex entry point is:

```text
$digest <slug>
```

## What this does

The digest aggregates a whole wave into one view: what needs a decision, what's blocked, what's merge-ready, the merge order, truth-source/resource risks, and which agents have gone stale. `$digest` is the human→coordinator shortcut for "where are things right now".

## Required behavior

1. Treat the first token after `$digest` as the wave slug. If none is given, infer the wave from the current working directory (`multi-agent/<slug>/` subtree). If still unknown, ask which wave.
2. Run the digest:
   ```bash
   team-collab multi-agent digest --wave <slug>
   ```
   If the user asked for a fresher view of code/docs state, add `--refresh-truth-source`. If they asked about a specific time window, add `--since <duration>`.
3. Present the digest output to the user. Call attention to anything in the Needs Decision, Blockers, or Stale Agents sections, since those are the items most likely to need the user's input.
4. Do not edit any files. The digest is read-only. If a decision or unblock is needed, tell the user what's blocking and let them direct the next step.

## Compatibility note

If a future Codex version supports custom slash commands and `/digest` reaches the model as plain user text, handle it exactly the same way as `$digest`.

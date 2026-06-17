# Live Session

Use this reference only for Phase 4/P1 live-session concepts: tmux binding, watch, send, monitor, message artifacts, ACK handling, and safety rules. It is usage guidance; these CLI commands are not implemented by this reference or this task.

## Concept

Live session is an accelerator above the file protocol. The canonical truth stays in `multi-agent/` files. A tmux pane is never source of truth; anything important must be recoverable from status, messages, reviews, PRD, claims, or digests.

## Session binding

A bound status may contain:

```yaml
session:
  type: tmux
  host: localhost
  target: session:window.pane
  cwd: <worktree cwd>
  last_seen: <iso-8601-or-null>
```

`agent bind-session` is Phase 4/P1. The design requires a handshake by default: send a token to the pane and require the worker to reply with the expected agent id. `--skip-handshake` is only for explicit human-confirmed exceptions.

## Messages and ACK

Messages live at `multi-agent/<slug>/messages/YYYY-MM-DD-HHMM-to-<agent-id>.md`. They are `form: trace` and include `from`, `to`, `task_id`, `wave`, `type` (`instruction`, `question`, `notice`, or `control`), `requires_ack`, `created`, `created_at`, `ack_at`, and `ack_via`.

The body sections are Instruction, Required Actions, Context, and Reply / ACK format. If `requires_ack: true`, `ack_at: null` is the durable pending marker. ACK closure must be durable: the receiver checkpoints its own status or the coordinator records `ack_at`/`ack_via` after observing an ACK.

## Command concepts

- `agent watch`: capture a tmux pane tail, redact secrets by default, print to stdout, and do not write shared docs unless an explicit update flag exists.
- `agent send`: write or validate a message file, commit it locally, push according to policy, then send a short `[team-collab-control]` prefix plus message path and 1-3 actions to tmux.
- `multi-agent monitor`: compute git/docs/tmux signals, write monitor digests, and optionally auto-send only whitelisted controls.

## Safety rules

- Bind must handshake; mismatch refuses binding.
- Capture-pane output is temporary and must not pollute shared docs.
- Send is audit-first: persist the message before tmux send. Do not send a long instruction whose only record is the pane.
- Auto-send whitelist is hardcoded to STOP / PAUSE / RUN GATE. No other instruction, notice, or question may be auto-sent.
- Secret-like content from pane capture is redacted and warned, not written to docs.
- Local tmux is the v0.2.0 shape; remote tmux or other transports are later work.

## Boundary

Phase 4 CLI is intentionally outside Phase 3 runtime references. When the user asks to implement live-session commands, use the design spec and add tests in the playbook repo; do not add hidden behavior from this reference alone.

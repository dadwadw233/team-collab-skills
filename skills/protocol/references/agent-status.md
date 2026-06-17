# Agent Status

Use this reference when starting, checkpointing, finishing, closing, or reading an agent run.

## Path and identity

Status files live at `multi-agent/<slug>/agent-runs/<task-id>/<agent-id>.md`. The agent id format is `<tool>-<machine>-<short-label>` and must match the CLI validator. Keep `agent_id` separate from `human_owner`; the former is the tool identity, the latter is the accountable human.

## Frontmatter schema

Every status file is `form: trace` and keeps v0.1.x lint-compatible fields: `title`, `status`, `updated`, and `tags`. The multi-agent fields describe:

- Identity: `agent_id`, `role`, `tool`, `machine`, `human_owner`, `task_id`, `wave`.
- Code execution state: `branch`, `worktree`, `base`.
- `truth_source`: `code_path`, `code_base`, `code_behind`, `code_dirty`, `docs_path`, `docs_base`, `docs_behind`, `docs_fresh`, `trust_status`, `checked_at`.
- Ownership intent: `owned_files`, `contracts_owned`, `owned_resources`, `changed_files`.
- Claim heartbeat: `claim.claimed_at`, `claim.heartbeat_at`, `claim.stale_after`.
- Coordination: `depends_on`, `blocked_by`, `needs_decision`, `pr`, `pr_url`, `review`, `merge_commit`.
- Optional Phase 4 session: `session.type`, `session.host`, `session.target`, `session.cwd`, `session.last_seen`.
- `last_update` is ISO-8601; top-level `updated` remains `YYYY-MM-DD`.

## Body sections

The body H2 order is fixed:

```markdown
## Current Focus
## Changed Files
## Next
## Blockers
## Risks
## Tests
## Review
## Sign-off
```

Use Current Focus and Next for the current Plan / Progress story. Use Blockers for blocked work. Put test commands and results under Tests. Put Completed, PR, Known risks, Human decision needed, Merge commit, and Production-ready lines under Sign-off.

## Lifecycle commands

`agent start` creates the status with `status: working`, writes the initial `truth_source`, records explicit ownership arrays, initializes the claim heartbeat, materializes the affected task/resource claims, and may create a worktree depending on role.

`agent checkpoint` refreshes `changed_files`, Current Focus, Blockers, Next, `last_update`, `updated`, `needs_decision`, and always refreshes `claim.heartbeat_at`. If blockers are present, status becomes `blocked`; if blockers clear, a previously blocked agent returns to `working`.

`agent finish` sets `status: review` and writes Sign-off. `--abandoned` instead sets `status: abandoned`, clears blockers, and releases affected claims. A normal finish keeps the claim active until close.

`agent close` requires `status: review`, a matching PR, and a valid merge commit. It sets `status: done`, records `merge_commit`, releases affected claims, and appends closing Sign-off lines.

`agent status` is read-only. `--all` prints a wave table; default prints the resolved status file.

## Writing constraints

Only the owning agent should write its own `agent-runs/<task>/<agent-id>.md`. Other agents read it and ask for changes through their own status, reviews, messages, or coordinator decisions. Do not hand-edit `changed_files`; the CLI refreshes it from git diff.

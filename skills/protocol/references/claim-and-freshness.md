# Claim And Freshness

Use this reference when reasoning about task/resource claims, heartbeat stale detection, `truth_source`, code/docs freshness gates, or claim conflicts.

## Canonical source

The per-agent status file is canonical for `claim`, `owned_files`, `contracts_owned`, and `owned_resources`. Files under `claims/tasks` and `claims/resources` are CLI-materialized views rebuilt from the affected status file during lifecycle commands.

If status and claims drift, report the conflict first. Do not let one agent silently edit another agent's status to repair it.

## Claim files

Task claims live at `multi-agent/<slug>/claims/tasks/<task-id>.md`. Resource claims live at `multi-agent/<slug>/claims/resources/<resource-id>.md`.

Claim frontmatter includes `status` (`active`, `stale`, or `released`), `claim_type`, `claim_key`, `owner_agent`, `wave`, `branch`, `worktree`, `claimed_at`, `heartbeat_at`, `stale_after`, `released_at`, and `released_reason`. The body records Current owner, Heartbeat, and History.

## Heartbeat and stale rules

`claim.heartbeat_at` is the stale baseline. `agent start`, `agent checkpoint`, and normal `agent finish` refresh it. `stale_after` defaults to 4h unless the wave or command overrides it.

A stale heartbeat is not a distributed lock release by itself. It lets digest/gate warn and lets `agent start --steal-stale` reclaim stale resource claims with an explicit History line.

## truth_source

`truth_source` separates code freshness from docs freshness:

- Code: `code_path`, `code_base`, `code_behind`, `code_dirty`.
- Docs: `docs_path`, `docs_base`, `docs_behind`, `docs_fresh`.
- Trust: `trust_status` is `trusted`, `stale-warn`, or `stale-blocked`.
- `checked_at` is ISO-8601 and should be refreshed when truth source is rechecked.

Do not infer docs trust from a clean code repo. A project can have clean code and stale docs.

## Freshness gates

`code_freshness_gate` and `docs_freshness_gate` policies are `hard`, `warn`, or `off`.

- `hard` plus behind commits refuses `agent start` with exit 3.
- `warn` records a risk and continues.
- `off` is an explicit override and should still be visible in the recorded truth source.
- Missing origin is local-only and can be treated as behind=0; configured origin read/fetch failure is an external dependency failure.

`agent checkpoint --refresh-truth-source` may discover stale-blocked later, but checkpoint should warn rather than block the heartbeat.

## Claim integrity

Gate and lint check that:

- The status heartbeat is not stale.
- No other active status claims the same task id.
- No other active status claims any `owned_resources` entry.
- The materialized `claims/tasks` and `claims/resources` owner matches the canonical status.
- `touched_contracts` is contained in `contracts_owned`.

## Conflict boundary

Coordinator owns PRD, PR plan, and decision board. Individual agents own their status. Reviewers own review files. CLI owns the affected claim views. For semantic conflicts or concurrent push rejection, follow `git-policy.md`; do not auto-merge meaning.

Cross-machine invariant: auto-commit makes local state durable, but only an explicit docs repo push makes it visible to other machines.

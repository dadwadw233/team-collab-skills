# Multi-Agent Protocol

Use this reference when a project has opted into Team Collab multi-agent work or when the user asks about waves, `multi-agent/` layout, agent lifecycle, gate, `plan --check`, `lint-multi-agent`, claims, freshness, or live-session concepts.

## Activation

Run multi-agent workflows only after a strong project signal and explicit opt-in:

- The CLI-resolved docs repo `AGENTS.md` (`docsPath/AGENTS.md`) contains the `[multi-agent]` section written by `team-collab multi-agent enable`; code-root `AGENTS.md` may only be a pointer.
- The docs repo has a tracked `multi-agent/` directory; it must not be ignored.
- The code repo should ignore the docsPath subdir for in-code-docs layouts so wave artifacts do not enter code PRs.
- A global `~/.team-collab/config.json` helps resolution, but it is not by itself proof that every repo is multi-agent enabled.

If opt-in is missing, do not create wave files by hand. Ask the coordinator to run `team-collab multi-agent enable` first.

## Wave layout

Each wave lives under `multi-agent/<slug>/` in the docs repo:

```text
PRD.md
pr-plan.md
decision-board.md
agent-runs/<task-id>/<agent-id>.md
reviews/PR<int>-<reviewer-agent-id>.md
messages/YYYY-MM-DD-HHMM-to-<agent-id>.md
claims/tasks/<task-id>.md
claims/resources/<resource-id>.md
digests/YYYY-MM-DD-HHMM.md
```

The PRD is the wave brief and contract plan. `pr-plan.md` is the merge/dependency table. `decision-board.md` is the coordinator-owned human-decision list. Per-agent status files are the canonical task state. Claims files are CLI-materialized views rebuilt from status files.

## Wave file contracts

Keep these invariants when reading, reviewing, or editing wave files:

- `PRD.md` is `form: design` and keeps the fixed 10-section skeleton: Human Brief, North Star, Repository / Docs State, Architecture / Contract Plan, PR Plan, File Ownership / Conflict Surface, Resource / Claim Plan, Decision Board, Review Gates, and Result Summary.
- `pr-plan.md` has the required table columns `task_id`, `pr`, `branch`, `worktree`, `owner_agent`, `depends_on`, `risk`, `merge_policy`, and `notes`; `merge_policy` is `human-gated`, `coordinator-gated`, or `review-gated-auto`.
- `decision-board.md` entries use `D-NNN` headings and status `example`, `pending`, `accepted`, or `rejected`. Template examples must stay `status: example` so digest/gate do not count them as real pending decisions.
- `digests/YYYY-MM-DD-HHMM.md` is an append-only `form: trace` snapshot with fixed sections: Needs Decision, Blockers, Merge Ready, Risky PRs, Merge Order, Truth Source / Resource Risks, Stale Agents, and Plan Deviations. Empty sections say `- none`.
- `reviews/`, `messages/`, and `claims/` are trace artifacts; see the focused references before editing or validating them.

## Command route

- Project setup: `team-collab multi-agent enable`, then `team-collab multi-agent init --slug <wave>`.
- Agent lifecycle: `team-collab agent start`, `checkpoint`, `finish`, `close`, and read-only `status`.
- Coordinator view: `team-collab multi-agent digest --wave <wave>`.
- Validation layer: `team-collab multi-agent gate --pr <int>`, `team-collab multi-agent plan --check`, and `team-collab lint-multi-agent`.
- Phase 4 live session concepts are described in `live-session.md`; this reference does not mean those CLI commands are implemented in this repo.

## Read-only vs write commands

Setup write commands are `multi-agent enable` and `multi-agent init`: enable updates opt-in/project scaffolding, and init creates the wave skeleton. Do not run them in a read-only review unless the user asked for setup.

Lifecycle write commands are `agent start`, `agent checkpoint`, `agent finish`, `agent close`, and `multi-agent digest`. They write docs files, exact-add only those `multi-agent/` files, auto-commit locally, and never auto-push. Other machines see the work only after an explicit docs repo push.

Read-only validation commands are `agent status`, `multi-agent gate`, `multi-agent plan --check`, and `lint-multi-agent`. They must not update docs files and must not trigger auto-commit.

## Jump to focused references

- Status schema and lifecycle writing rules: `agent-status.md`.
- Gate, review, plan check, and lint policy: `gate-check.md`.
- Claims, heartbeat, stale detection, and truth source: `claim-and-freshness.md`.
- Phase 4 tmux/message safety model: `live-session.md`.

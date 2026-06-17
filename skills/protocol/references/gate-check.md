# Gate Check

Use this reference for review summaries, `team-collab multi-agent gate`, `team-collab multi-agent plan --check`, and `team-collab lint-multi-agent`.

## Review summary schema

Review files live at `multi-agent/<slug>/reviews/PR<int>-<reviewer-agent-id>.md`. They are `form: trace`, `status: active`, and include `pr`, `reviewer`, `target_branch`, `target_sha`, `verdict`, `created`, and `last_update`. Valid verdicts are `clean`, `p2-only`, `needs-fix`, and `blocked`.

The body has `Scope`, `P0 (block merge)`, `P1 (block merge)`, `P2 (allowed with note)`, and `Verification commands`. Gate reads the verdict and treats unresolved P0/P1 as blocking.

## Gate 10 checks

`multi-agent gate --pr <int> [--wave <slug>] [--base <ref>]` runs these 10 checks:

1. Agent Sign-off exists: Completed is non-empty and PR matches the status file.
2. Independent review exists when `pr-plan.merge_policy` is not `review-gated-auto`; acceptable verdict is `clean` or `p2-only`.
3. No matching review has unresolved P0/P1; `needs-fix` and `blocked` verdicts block merge.
4. `depends_on` PRs are merged via status `merge_commit`, unless waived in `pr-plan.md` notes.
5. Touched files from git are within `owned_files`; out-of-scope files are plan deviations.
6. Human-gated file patterns require a human sign-off line in PRD Human decisions or status Sign-off.
7. Status `last_update` is within the stale threshold.
8. Claim integrity: heartbeat is fresh, no other active same-task/resource claim, and `touched_contracts` is a subset of `contracts_owned`.
9. Truth source freshness: `stale-blocked` fails; `stale-warn` warns; hard docs freshness plus `docs_behind > 0` fails.
10. Tests/CI pass when configured.

Output uses a table with pass, fail, skipped, and warning marks. Exit code 0 means no failing rows. Exit code 2 means invalid wave/PR/config. Exit code 5 means the gate found a business failure.

## plan --check

`multi-agent plan --check [--wave <slug>] [--refresh-truth-source] [--strict]` is read-only schema and cross-cutting validation. It checks PRD sections, `pr-plan.md` columns, `decision-board.md`, status/review/message/claim frontmatter, freshness, claim consistency, heartbeat staleness, contract owners, resource collisions, and Phase 4 session integrity when active.

Default exit is 0 even with warnings. With `--strict`, any warning returns exit code 5.

## lint-multi-agent

`lint-multi-agent` is warning-only and should not fail a normal local run merely because warnings exist. Warning categories:

- Schema: missing wave files, incomplete status frontmatter, invalid role/status/verdict/claim/session enums, duplicate agent ids, message filename/to mismatch, claim drift.
- Freshness: stale heartbeat, old `truth_source.checked_at`, `trust_status=stale-blocked`, inconsistent code base in one wave.
- Conflict: duplicate contract owners, duplicate active resource claimants, unacknowledged `requires_ack` messages older than one hour.

## Read-only rule

Gate, plan check, and lint are validation commands. They do not write docs, do not exact-add files, and do not auto-commit. Use lifecycle commands or coordinator edits to repair what they report.

`plan --check --refresh-truth-source` may run `git fetch` to refresh code/docs freshness. Omit that flag for local-only or no-network review passes.

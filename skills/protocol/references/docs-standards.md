# Document Standards

Use this reference when creating or substantially editing team project docs, frontmatter, filenames, templates, taxonomy, or docs baseline.

The human-readable source of truth is `07-文档组织规范.md` in the team playbook. This reference encodes the subset an AI must enforce.

## Required frontmatter

Every `.md` you create or substantially edit must have frontmatter with at least:

```yaml
---
title: <clear short title>
form: state | trace | decision | design | reference | index
updated: YYYY-MM-DD
status: draft | active | deprecated | archived
tags: [<at least one>]
---
```

If creating a new doc and you cannot commit to a `form`, stop and ask the user which form fits.

## Warning-only lint contract

`team-collab lint` checks Markdown frontmatter and optional line budgets as warnings, not hard failures:

- Required keys: `title`, `form`, `updated`, `status`, and `tags`.
- `form` must be one of `state`, `trace`, `decision`, `design`, `reference`, or `index`.
- `updated` must match `YYYY-MM-DD`.
- `target_lines`, when present, must be numeric.
- Body length over `target_lines * 1.2` is an over-budget warning; over `target_lines * 1.5` is a stronger warning.
- Missing frontmatter in legacy docs is still a warning-first cleanup signal, not an automatic rewrite mandate.

Use these warnings to compact, archive, or split docs; do not blindly rewrite historical `trace` or `decision` files just to silence lint.

## Form rules

- `form` value must match the doc's structure and lifecycle. A trace document that rewrites history, or a state doc that appends timestamped entries, is a form violation.
- `trace` and `decision` forms are append-only on history. An existing `_handoffs/2026-04-20-...md` or `ADR-005-...md` cannot be semantically rewritten. Fix typos only.
- To supersede a decision, create a new ADR with `status: supersedes ADR-005` and flip the old one to `status: deprecated`.
- One thing per file for `trace` and `decision`: one session per handoff, one change topic per dev record, one decision per ADR.
- When modifying any doc, update `updated: YYYY-MM-DD` in frontmatter.
- `state` docs (`CURRENT/NEXT/RISKS/TODO`) are short current-state caches, not devlogs, PR lists, or commit timelines. Keep them brief, structured, and link-driven.
- `CURRENT.md` should stay about 80-120 lines; `NEXT/RISKS/TODO` should stay about 80-150 lines. If over budget, compact first and move history/evidence to `_handoffs/`, `开发记录/<用户名>/`, `archive/`, ADR, or a focused design doc.
- Each bullet carries one fact, risk, decision, or action. Do not pack background, evidence, acceptance logs, and PR lists into one item.
- Critical references must use standard Markdown links such as `[V1.6 PRD](./EvoNav/32-V1.6-PRD.md)`. Obsidian wikilinks are allowed only as non-critical prose.

## Naming rules

- `state` -> uppercase no prefix: `CURRENT.md`, `NEXT.md`, `RISKS.md`, `TODO.md`.
- `trace` -> `_handoffs/YYYY-MM-DD-HHMM-<kebab-topic>.md` for handoffs, or `开发记录/<用户名>/YYYY-MM-DD-<kebab-topic>.md` for personal dev records.
- `decision` -> `ADR-NNN-<slug>.md` or entries inside `决策日志.md`.
- `design` -> semantic name, optionally two-digit prefix `NN-<name>.md` for ordered series; `OVERVIEW.md` / `00-项目概览.md` for the entry.
- `reference` -> semantic name.
- `index` -> `README.md` or `00_INDEX.md`.

Refuse to create these filenames: `草稿.md`, `未命名*.md`, `随笔.md`, `tmp_*.md`, `test*.md` unless actually a code test file, or `20260420_xxx.md` with the wrong date format. Suggest a valid name instead.

## Link rules

Keep wikilinks out of critical cross-file references. Use standard Markdown `[text](./path.md)` for CURRENT/NEXT/RISKS/TODO/ADR internal links so they render on GitHub/GitLab. Wikilinks are OK for informational prose but not for navigation anchors.

## The six forms

| form | structure | mutable? | target lines |
|------|-----------|----------|--------------|
| `state` | snapshot, rewritable | yes | 80-150 |
| `trace` | timestamped append-only log | never rewrite history | 100-300/entry |
| `decision` | recorded decisions | supersede, do not edit history | 50-200/entry |
| `design` | narrative explanation | major revisions OK | 300-1500 |
| `reference` | lookup manual | update as needed | 200-800 |
| `index` | navigation | update on structure change | 50-200 |

Topic is free-form. Recommended words include `positioning`, `overview`, `product`, `requirements`, `architecture`, `modules`, `implementation`, `research`, `benchmark`, `experiment`, `ops`, `external`, `self`. Express it as `topic: [word1, word2]` in frontmatter.

## Required baseline

Project baseline is enforced during audit/init, not every normal session. A mature project should have:

- `README.md` (form=index)
- `OVERVIEW.md` or equivalent (form=design, topic contains `positioning` or `overview`)
- `CURRENT.md` / `NEXT.md` / `RISKS.md` / `TODO.md` (form=state)
- `_handoffs/` and `开发记录/<用户名>/` (form=trace)
- `决策日志.md` or `ADR/NNN-*.md` (form=decision)
- `archive/`

In ordinary feature/debug work, flag missing baseline items only if they directly affect the requested task.

## Templates

See `templates/` in this skill:

- `templates/OVERVIEW.md` -- project narrative entry (form=design, topic=[positioning, overview])
- `templates/CURRENT.md` -- one-screen status (form=state)
- `templates/NEXT.md` -- strategic next actions and undecided items (form=state)
- `templates/RISKS.md` -- active and archive risks (form=state)
- `templates/TODO.md` -- task quartet with `@owner` claim mechanic (form=state)
- `templates/handoff.md` -- handoff frontmatter and sections (form=trace)
- `templates/ADR.md` -- architecture decision record (form=decision)

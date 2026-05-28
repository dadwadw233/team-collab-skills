# Team-Collab Architecture Audit Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Turn the signed-off architecture audit into a sequence of small, reviewable, squash-mergeable PR/MR changes without over-engineering the git+markdown protocol.

**Architecture:** Keep Team-Collab as a simple git+Markdown protocol, but make the high-risk parts machine-checkable. Protocol text lives in `team-collab-skills`; CLI, doctor, lint, installer, npm packaging, and playbook docs live in `team-collab-playbook`. Every feature below is designed as one squash PR/MR unit, with paired cross-repo changes only when needed.

**Tech Stack:** Markdown skills and adapters, Bash validation, Node.js CLI in `@embodot/collab`, Python lint helpers, GitHub PRs for `team-collab-skills`, GitLab MRs for `team-collab-playbook`.

---

## Source Requirement

Implementation source of truth:

- Requirement memo: `docs/audits/2026-05-29-architecture-first-principles.md`
- Final decisions: sections `10.1` through `10.4`, plus reviewer sign-off section `11`
- Current package versions at planning time: `team-collab-skills` v0.4.5, `@embodot/collab` v0.1.47

Non-goals confirmed by the audit closure:

- Do not introduce a broker, database, or heavyweight coordination service.
- Do not switch TODO to per-task files yet.
- Do not add `last_writer` section markers yet.
- Do not auto-generate `CURRENT.md` rollups yet.
- Do not hard-fail cloud-synced docs paths by default.

## Task Count and Conflict Summary

There are **11 implementation tasks**, intended as **11 squash PR/MR units** after the audit/plan documentation PR.

| ID | Squash PR/MR unit | Primary repo(s) | Depends on | Conflict risk |
|---|---|---|---|---|
| TC-ARCH-01 | TODO ownership honesty + task identity policy | skills + playbook docs | none | low |
| TC-ARCH-02 | Protocol version metadata + doctor mismatch checks | skills + playbook | none | medium |
| TC-ARCH-03 | `team-collab lint` command family foundation | playbook | TC-ARCH-02 preferred | medium |
| TC-ARCH-04 | TODO schema lint, warning-only | playbook + docs | TC-ARCH-03 | medium |
| TC-ARCH-05 | Frontmatter and `target_lines` lint, warning-only | playbook + docs | TC-ARCH-03 | medium |
| TC-ARCH-06 | `CURRENT.md` summary-cache policy + reactive docs-refresh | skills + playbook docs | TC-ARCH-01 | medium |
| TC-ARCH-07 | Boundary lint after state policy lands | playbook + docs | TC-ARCH-04, TC-ARCH-05, TC-ARCH-06 | high |
| TC-ARCH-08 | Handoff recovery + multi-writer health checks | skills + playbook | TC-ARCH-03 | medium |
| TC-ARCH-09 | Cloud-sync warnings + acknowledgement config | skills + playbook | TC-ARCH-03 | medium |
| TC-ARCH-10 | Optional agent provenance metadata and commit trailers | skills + playbook docs | TC-ARCH-02, TC-ARCH-06 | medium |
| TC-ARCH-11 | Adapter source-hash / drift validation | skills | TC-ARCH-06, TC-ARCH-10 | medium |

Conflict notes:

- TC-ARCH-03/04/05/07 all touch CLI lint surfaces and tests. Do them serially.
- TC-ARCH-06/08/10 all touch protocol workflow references. Do TC-ARCH-06 first so later changes use the final state-doc vocabulary.
- TC-ARCH-08/09 both touch `doctor` / startup-audit behavior in playbook. They can be parallel in theory, but serial is safer.
- TC-ARCH-11 should be last because adapters should reflect final command names, provenance wording, and state-cache policy.
- TC-ARCH-02 should happen before stricter lint rollout, or all new lint checks must remain warning-only until version checks exist. This plan does both: TC-ARCH-02 early, TC-ARCH-04/05/07 warning-first.

## Branch and PR Policy

Use one branch per task:

```bash
git switch main
git pull --ff-only
# example branch name
git switch -c arch/tc-arch-01-todo-intent
```

For paired repo work:

- Skills repo: GitHub PR, squash merge.
- Playbook repo: GitLab MR, squash merge.
- Use the same task ID in branch names, commit titles, and PR/MR summaries.
- If both repos change, merge the runtime skill PR first only when playbook checks depend on it; otherwise merge playbook first when CLI is the enforcement source.

Verification baseline for every task:

```bash
# in team-collab-skills
scripts/validate-structure.sh
git diff --check HEAD~1 HEAD

# in team-collab-playbook, when touched
npm test
npm run check
npm run pack:dry-run
git diff --check HEAD~1 HEAD
```

---

## TC-ARCH-01: TODO Ownership Honesty + Task Identity Policy

**Goal:** Stop calling TODO ownership a distributed lock; document the real semantics as public intent declaration with optimistic collision detection.

**Files:**

- Modify: `skills/protocol/references/todo-ownership.md`
- Modify: `skills/protocol/templates/TODO.md`
- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/07-文档组织规范.md`
- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/templates/docs-repo/TODO.md`
- Optional docs: `/Users/yuyuanhong/projects/team-collab-playbook/03-日常工作流.md`

**Implementation steps:**

1. Replace `git-backed distributed lock` with `public intent declaration with optimistic collision detection`.
2. Add a short warning: git detects textual conflicts, not semantic duplicate tasks.
3. Introduce optional task identity guidance, e.g. `id: T-YYYYMMDD-NN` or `blocks: NEXT#N`; do not require it yet.
4. Update TODO templates so examples can carry a stable identity without making the line unreadable.
5. Keep claim flow unchanged except for wording.

**Verification:**

```bash
scripts/validate-structure.sh
git diff --check HEAD~1 HEAD
```

Playbook verification if touched:

```bash
npm run check
npm test
```

**Squash commit title:** `docs(protocol): clarify TODO ownership semantics`

---

## TC-ARCH-02: Protocol Version Metadata + Doctor Mismatch Checks

**Goal:** Make wrapper/protocol compatibility visible and machine-checkable before expanding lint semantics.

**Files:**

- Modify: `skills/protocol/SKILL.md`
- Modify: `skills/handoff/SKILL.md`
- Modify: `skills/checkpoint/SKILL.md`
- Modify: `skills/team-progress/SKILL.md`
- Modify: `skills/docs-refresh/SKILL.md`
- Modify: `.codex-plugin/plugin.json`
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/bin/team-collab.js`
- Test in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/tests/test_*.py` or add a focused test file if the existing test style supports CLI checks.

**Implementation steps:**

1. Add protocol frontmatter: `version: 0.5.0` or the next chosen plugin version.
2. Add wrapper frontmatter: `requires_protocol: ">=0.5.0,<0.6.0"`.
3. Keep wrapper runtime instructions non-authoritative; they instruct agents to stop on mismatch, but enforcement belongs to `doctor`.
4. In playbook `doctor`, read installed Codex skill files and Claude plugin metadata where available.
5. Warn when wrapper/protocol version requirements do not match installed protocol.
6. Do not fail by default in normal `doctor` until one release after the metadata exists; hard-fail can be a later strict mode.

**Verification:**

```bash
scripts/validate-structure.sh
npm run check
npm test
team-collab doctor --project <known-local-project>
```

Expected: doctor reports compatible installed protocol/wrappers, or a clear actionable warning.

**Squash commit title:** `feat(protocol): add version compatibility metadata`

---

## TC-ARCH-03: `team-collab lint` Command Family Foundation

**Goal:** Grow `lint-state` into a grouped lint family without changing existing behavior.

**Files:**

- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/bin/team-collab.js`
- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/scripts/lint-state-docs.py`
- Create in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/scripts/team-collab-lint.py`
- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/scripts/audit-project-docs.sh`
- Modify in playbook docs: `README.md`, `01-新人入门.md`, `06-运维手册.md`
- Test in playbook: extend `tests/test_state_lint.py` or create `tests/test_lint_cli.py`

**Implementation steps:**

1. Add `team-collab lint [docs-dir]` as the new umbrella command.
2. Keep `team-collab lint-state [docs-dir]` and alias `state-lint` working.
3. Make `team-collab lint` initially call state lint only.
4. Output sections with stable names: `state`, `todo`, `frontmatter`, `boundaries`; missing future sections should say `not implemented` only if explicitly requested.
5. Ensure `audit` still treats lint warnings as warnings, not failures.

**Verification:**

```bash
npm test
npm run check
node bin/team-collab.js lint templates/docs-repo
node bin/team-collab.js lint-state templates/docs-repo
node bin/team-collab.js state-lint templates/docs-repo
```

Expected: all three paths return the same 0-warning state lint result for templates.

**Squash commit title:** `feat(cli): add team-collab lint umbrella`

---

## TC-ARCH-04: TODO Schema Lint, Warning-Only

**Goal:** Detect malformed TODO task ownership without enforcing hard failures yet.

**Files:**

- Create in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/scripts/lint-todo-docs.py`
- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/scripts/team-collab-lint.py`
- Test in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/tests/test_todo_lint.py`
- Modify skills docs: `skills/protocol/references/todo-ownership.md`
- Modify playbook docs: `07-文档组织规范.md`

**Lint rules:**

- In `## 进行中`: every task line has exactly one `@owner` and `since YYYY-MM-DD`.
- In `## 阻塞`: every task line has exactly one `@owner`, `since YYYY-MM-DD`, and `(blocked by: ...)`.
- In `## 待办`: task lines should not have `@owner` unless explicitly marked as pre-assigned.
- In `## 最近完成`: every completed task has `@owner` and completion date `YYYY-MM-DD`.
- Warn when apparent duplicate task text appears in multiple sections.
- Warn when `最近完成` exceeds 20 items.
- Do not require task IDs in the first release; warn only if duplicate-looking tasks lack identity.

**Verification:**

```bash
pytest tests/test_todo_lint.py -v
npm test
node bin/team-collab.js lint templates/docs-repo
```

Expected: template TODO is clean; synthetic bad TODO fixtures produce deterministic warnings.

**Squash commit title:** `feat(lint): add TODO ownership schema checks`

---

## TC-ARCH-05: Frontmatter and `target_lines` Lint, Warning-Only

**Goal:** Make the six-form document contract and line budgets measurable.

**Files:**

- Create in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/scripts/lint-frontmatter-docs.py`
- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/scripts/team-collab-lint.py`
- Test in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/tests/test_frontmatter_lint.py`
- Modify skills docs: `skills/protocol/references/docs-standards.md`
- Modify playbook docs: `07-文档组织规范.md`

**Lint rules:**

- Newly checked Markdown files must have frontmatter with `title`, `form`, `updated`, `status`, and `tags`.
- `form` must be one of `state`, `trace`, `decision`, `design`, `reference`, `index`.
- `updated` must match `YYYY-MM-DD`.
- `target_lines` should be numeric if present.
- Warn at `target_lines * 1.2`; stronger warning at `target_lines * 1.5`.
- Missing frontmatter in legacy docs is a warning, not failure.

**Verification:**

```bash
pytest tests/test_frontmatter_lint.py -v
npm test
node bin/team-collab.js lint templates/docs-repo
```

Expected: templates pass; fixtures catch missing keys and invalid forms.

**Squash commit title:** `feat(lint): add frontmatter and line-budget checks`

---

## TC-ARCH-06: `CURRENT.md` Summary-Cache Policy + Reactive Docs Refresh

**Goal:** Encode the signed-off policy: `CURRENT.md` is a hand-maintained summary cache; `$docs-refresh` is reactive maintenance, not a scheduled ritual.

**Files:**

- Modify: `skills/protocol/references/docs-standards.md`
- Modify: `skills/protocol/references/docs-refresh.md`
- Modify: `skills/protocol/templates/CURRENT.md`
- Modify: `skills/protocol/templates/NEXT.md` if link wording changes
- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/07-文档组织规范.md`
- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/templates/claude-code/docs-refresh.md`
- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/templates/docs-repo/CURRENT.md`

**Policy text to include:**

```text
CURRENT.md is a hand-maintained summary cache. It may contain one-line rollups that link to canonical detail in TODO.md, RISKS.md, NEXT.md, ADRs, handoffs, or design docs. Rollups must stay short; if they require explanation, the explanation belongs in the canonical target and CURRENT.md should link out.
```

Docs-refresh trigger conditions:

- A staleness audit, dev record, or external review flagged specific drift.
- A major project shift landed.
- Lint or health reports flagged measurable drift.

Explicit non-rule:

- `$docs-refresh` is not a scheduled ritual. If it needs calendar cadence, revisit generated `CURRENT.md` rollups.

**Verification:**

```bash
scripts/validate-structure.sh
git diff --check HEAD~1 HEAD
```

Playbook if touched:

```bash
npm run check
npm test
```

**Squash commit title:** `docs(protocol): define CURRENT summary-cache policy`

---

## TC-ARCH-07: Boundary Lint After State Policy Lands

**Goal:** Warn when state docs violate the final boundary policy, without pretending semantic duplication can be perfectly detected.

**Files:**

- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/scripts/lint-state-docs.py`
- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/scripts/team-collab-lint.py`
- Test in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/tests/test_state_lint.py`
- Modify docs if needed: `skills/protocol/references/docs-standards.md`, playbook `07-文档组织规范.md`

**Warning patterns:**

- `CURRENT.md` section bullet longer than a practical threshold, e.g. 240 characters, with no Markdown link.
- `CURRENT.md` contains PR/MR list, commit hash lists, or long chronological completion blocks.
- `NEXT.md` items lack an action or acceptance criterion.
- `RISKS.md` entries lack status/action.
- `TODO.md` task lines include long background paragraphs.
- Repeated identical lines across state docs; warn only on exact or normalized duplicates, not fuzzy semantic guesses.

**Verification:**

```bash
pytest tests/test_state_lint.py -v
npm test
node bin/team-collab.js lint templates/docs-repo
```

Expected: no warnings for templates; warning fixtures identify boundary problems.

**Squash commit title:** `feat(lint): warn on state boundary drift`

---

## TC-ARCH-08: Handoff Recovery + Multi-Writer Health Checks

**Goal:** Make non-atomic handoff and concurrent state-file edits visible before they cause silent state drift.

**Files:**

- Modify: `skills/protocol/references/handoff.md`
- Modify: `skills/protocol/references/checkpoint.md`
- Modify: `skills/protocol/references/startup-and-audit.md`
- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/bin/team-collab.js`
- Create or modify in playbook tests: `tests/test_doctor_*.py` or equivalent CLI tests
- Modify playbook docs: `06-运维手册.md`

**Behavior:**

- At startup/audit, if docs repo is ahead of remote with handoff/state commits, report: previous session may not have published; ask whether to retry push.
- During handoff rebase/pull, if upstream changed a state file also touched locally, inspect the relevant diff before finalizing. If ambiguous, stop and ask.
- Add `team-collab doctor --health` or `team-collab health` warning for same state file touched by multiple writers in the last **24h**.
- Health check uses git log only; no telemetry.

**Verification:**

```bash
npm test
npm run check
# Use temporary git repos in tests to simulate ahead-of-origin and multi-writer state changes.
```

Expected: detection reports actionable warnings without modifying files.

**Squash commit title:** `feat(doctor): detect handoff and state concurrency risks`

---

## TC-ARCH-09: Cloud-Sync Warnings + Acknowledgement Config

**Goal:** Warn when docs git roots are inside cloud-sync providers, without breaking valid Obsidian vault workflows.

**Files:**

- Modify in playbook: `/Users/yuyuanhong/projects/team-collab-playbook/bin/team-collab.js`
- Modify in playbook docs: `06-运维手册.md`, `10-新项目初始化Runbook.md`
- Modify: `skills/protocol/references/startup-and-audit.md`
- Optional: `skills/protocol/references/git-policy.md`
- Test in playbook: add doctor/config tests

**Detection list:**

- `~/Library/Mobile Documents/com~apple~CloudDocs/`
- `~/iCloud Drive/`
- `~/Dropbox/`, `~/Dropbox (*)/`
- `~/OneDrive/`, `~/OneDrive - */`
- `~/Google Drive/`, `~/GoogleDrive/`, paths containing `/My Drive/`
- macOS xattr `com.apple.fileprovider.fpfs#P` on docs git root when available
- Config override: `cloudSyncPrefixes`

**Acknowledgement config:**

- `cloudSyncAcknowledged: true` silences repeated startup/audit warnings for a registered project.
- `doctor --strict` still fails even if acknowledged, unless an explicit strict override is later designed.

**Verification:**

```bash
npm test
npm run check
team-collab doctor --docs '<fixture cloud path>' --code '<fixture code path>' --user test
```

Expected: normal doctor warns; strict mode fails; acknowledged project suppresses repeated low-noise startup warnings.

**Squash commit title:** `feat(doctor): warn on cloud-synced docs roots`

---

## TC-ARCH-10: Optional Agent Provenance Metadata and Commit Trailers

**Goal:** Improve auditability without forcing agents to invent runtime identity.

**Files:**

- Modify: `skills/protocol/templates/handoff.md`
- Modify: `skills/protocol/references/handoff.md`
- Modify: `skills/protocol/references/docs-standards.md`
- Modify in playbook: `templates/claude-code/handoff.md`
- Modify in playbook docs: `05-AI工作协议模板.md`, `07-文档组织规范.md`

**Policy:**

- Handoff may include optional `agent` metadata when known.
- Do not require exact model/runtime when unknown.
- Prefer coarse host class: `mac`, `4090`, `cloud-runner`, or `unknown`.
- Optional commit trailers:
  - `Agent: <vendor>/<model-or-unknown> via <runtime-or-unknown>`
  - `Host-Class: mac|4090|cloud-runner|unknown`
- Never hallucinate provenance fields.

**Verification:**

```bash
scripts/validate-structure.sh
git diff --check HEAD~1 HEAD
```

Playbook if touched:

```bash
npm run check
npm test
```

**Squash commit title:** `docs(protocol): add optional agent provenance guidance`

---

## TC-ARCH-11: Adapter Source-Hash / Drift Validation

**Goal:** Reduce adapter drift without building a full adapter generation pipeline yet.

**Files:**

- Modify: `scripts/validate-structure.sh`
- Modify adapters:
  - `adapters/cursor/.cursor/rules/team-collab.mdc`
  - `adapters/vscode/.github/copilot-instructions.md`
  - `adapters/vscode/.github/instructions/team-collab.instructions.md`
  - `adapters/cline/.clinerules/team-collab.md`
  - `adapters/opencode/AGENTS.md`
  - `adapters/continue/.continue/rules/team-collab.md`
  - `adapters/gemini/GEMINI.md`
  - `adapters/gemini/.gemini/commands/*.toml`
- Optional create: `adapters/ADAPTER-SOURCE.md`

**Implementation options:**

Option A, recommended first:

- Add a shared protocol marker block to all adapters, e.g. `team-collab-protocol-source: skills/protocol/SKILL.md@<version>`.
- Validate every adapter mentions required command set: `handoff`, `checkpoint`, `team-progress`, `docs-refresh`.
- Validate every adapter includes context-budget guidance and source-of-truth pointer.

Option B, later if drift persists:

- Add `scripts/build-adapters.py` and generated templates.
- CI validates generated output equals checked-in adapters.

**Verification:**

```bash
scripts/validate-structure.sh
git diff --check HEAD~1 HEAD
```

Expected: validation fails if any adapter misses the marker, command set, or context-budget reminder.

**Squash commit title:** `chore(adapters): validate protocol drift markers`

---

## Live Implementation Board

Use this section as the live tracking board. Update only in implementation planning PRs, not in every feature PR.

| ID | Status | Owner | PR/MR |
|---|---|---|---|
| TC-ARCH-01 | pending | unassigned | TBD |
| TC-ARCH-02 | pending | unassigned | TBD |
| TC-ARCH-03 | pending | unassigned | TBD |
| TC-ARCH-04 | pending | unassigned | TBD |
| TC-ARCH-05 | pending | unassigned | TBD |
| TC-ARCH-06 | pending | unassigned | TBD |
| TC-ARCH-07 | pending | unassigned | TBD |
| TC-ARCH-08 | pending | unassigned | TBD |
| TC-ARCH-09 | pending | unassigned | TBD |
| TC-ARCH-10 | pending | unassigned | TBD |
| TC-ARCH-11 | pending | unassigned | TBD |

## Release Strategy

Recommended release grouping:

1. Release v0.5.0 after TC-ARCH-01, TC-ARCH-02, TC-ARCH-03, and TC-ARCH-06. This publishes the new contract vocabulary before deeper lint checks.
2. Release v0.5.1 after TC-ARCH-04 and TC-ARCH-05. Keep checks warning-only.
3. Release v0.5.2 after TC-ARCH-07, TC-ARCH-08, and TC-ARCH-09.
4. Release v0.5.3 after TC-ARCH-10 and TC-ARCH-11.

Do not flip any new lint from warning to failure until at least one release after the warning is available and `doctor` can report protocol version compatibility.

## Final Acceptance Criteria

The audit implementation is complete when:

- The phrase `git-backed distributed lock` no longer appears in runtime protocol docs.
- `team-collab lint` exists and `lint-state` remains backward compatible.
- TODO schema, frontmatter, target line budgets, and boundary drift have warning-first checks.
- `CURRENT.md` summary-cache policy is explicit in skills and playbook docs.
- `$docs-refresh` is documented as reactive maintenance, not a scheduled ritual.
- Doctor/startup can surface local docs commits ahead of remote, 24h multi-writer state-file warnings, and cloud-sync path risks.
- Protocol/wrapper version metadata exists and `doctor` can report mismatches.
- Handoff/protocol docs describe optional provenance without requiring agents to invent unknown data.
- Adapter validation catches missing command/context/source pointers.
- Both repos pass their standard validation suites.

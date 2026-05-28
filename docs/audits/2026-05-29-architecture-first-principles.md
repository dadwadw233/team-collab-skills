# Team-Collab Architecture Audit — First-Principles Review

**Date:** 2026-05-29
**Reviewer:** External architect read-through (Claude Opus 4.7, no prior context)
**Scope:** `skills/protocol/**`, `skills/{handoff,checkpoint,team-progress,docs-refresh}/SKILL.md`, templates, `validate-structure.sh`, README, adapter layout
**Versions read:** plugin v0.4.5, npm `@embodot/collab` v0.1.47
**Style note:** Intentionally framed as design-memo, not panic report. Project is actively maintained — anything below is a candidate for redesign, deletion, or merge, not a load-bearing accusation.

---

## 1. What team-collab is fundamentally trying to do

Stripped of branding, the system is a **shared, durable, low-latency working memory for a swarm of AI agents (possibly across vendors/models/machines) plus a small number of humans collaborating on the same project.**

That requires five primitives:

| # | Primitive | Concrete artifact today |
|---|-----------|--------------------------|
| 1 | **State** — what is currently true | `CURRENT.md` + bits of `NEXT/RISKS/TODO` |
| 2 | **History** — what happened, by whom, when | `_handoffs/`, `开发记录/<user>/`, git log |
| 3 | **Intent** — what should happen next | `NEXT.md`, `TODO.md` (overlap) |
| 4 | **Coordination** — who owns what | `TODO.md` `@owner` mechanic |
| 5 | **Constraints** — what is forbidden | hard-rules in `SKILL.md` + `git-policy.md` |

Substrate: **git + markdown + Obsidian + an npm CLI**.

The audit below judges each design choice against whether it honestly delivers what the substrate can provide for that primitive, and whether the boundaries between primitives are clean.

---

## 2. The seven first-principles violations

These are ordered roughly by leverage (fix this first → unblocks the others), not by severity.

### 2.1 Substrate honesty — "git-backed distributed lock" is a category error

> `references/todo-ownership.md` L5: *"TODO ownership is a git-backed distributed lock."*

**The principle:** if the substrate doesn't provide primitive X, the protocol cannot claim X by writing the word "X" into a doc. Git provides eventually-consistent log replication with optimistic line-level conflict detection. It does **not** provide:
- mutual exclusion;
- atomic multi-file transactions;
- linearizable read-then-write.

**Why the current claim breaks:**
1. Two agents move *different* TODO lines from `待办` to `进行中` concurrently. Both push succeeds. No conflict. **Both "claims" land**, no lock.
2. Two agents touch the *same* TODO line. Rebase conflict fires. The protocol says "abort and report" — but modern agents will instinctively try to merge cleanly, defeating the intended fence.
3. The 14-day stale-claim rule is a social convention, not enforced anywhere.

**What it actually is:** a public intent-declaration mechanism with best-effort collision detection. That's still useful — but it's not a lock, and design decisions downstream (e.g., assuming TODO claims are safe to act on without further confirmation) should not depend on lock semantics.

**Proposed redesign:**
- Strike the word "lock" from `todo-ownership.md`. Reframe as "public intent declaration with collision hints."
- Add `team-collab lint todo` (also as pre-commit hook) that enforces: each `进行中` line has exactly one `@owner`, one `since YYYY-MM-DD`, and unique task identity.
- For genuinely exclusive tasks (e.g., "deploy to prod", "run db migration"), document explicitly that TODO is **not** the right primitive — point at a real broker (next bullet).
- Optional follow-up: per-task file mode (`TODO/<task-id>.md`). File creation is atomic on POSIX; two concurrent claims become a true rebase conflict 100% of the time, not heuristically. Tradeoff: more files, less skimmable. Worth it only if collision rate proves high in practice.

---

### 2.2 Boundary leakage — state quartet semantics overlap, and `docs-refresh` is the symptom

**The principle:** each document should answer exactly one question. Overlap forces every writer to make routing decisions, which guarantees drift.

**Overlap audit of current templates:**

| Concept | Lives in CURRENT | Lives in NEXT | Lives in TODO | Lives in RISKS | Lives in ADR |
|---|---|---|---|---|---|
| Current focus | ✅ "当前焦点" | implicit | ✅ "进行中" | | |
| Recent completions | ✅ "最近完成 (3-5 milestones)" | | ✅ "最近完成 (15-20)" | | |
| Next steps | ✅ "当前阶段" | ✅ "战略方向" | ✅ "待办" | | |
| Decisions | ✅ "关键决策" head 3-5 | | | | ✅ |
| Risks | ✅ "关键风险" head 2-3 | | | ✅ | |

**Every concept appears in 2-4 places.** That isn't redundancy for resilience — it's coupling that requires manual reconciliation every handoff. The newly-added `docs-refresh` skill is explicit acknowledgement: state docs drift, and we need a periodic workflow to put them back in sync.

**Reframing:** `docs-refresh` should be an exception flow (rare, after major project shifts), not a regular ritual. If it has to run monthly, the static design is wrong.

**Two redesign options — pick one:**

**Option A: Aggressive merge → single `STATUS.md`**

```
STATUS.md
├── 一句话状态
├── 当前焦点 (links to TODO 进行中)
├── 近期里程碑完成 (links to handoffs)
├── 待决问题 (links to NEXT.md sections if any)
├── 顶级风险 (links to RISKS.md if any)
└── 关键决策 (links to ADR)
```

Drop NEXT.md, fold it into STATUS.md + TODO.md. Keep RISKS.md and ADRs as separate because their lifecycle is genuinely different.

Pros: one file to maintain, links-only design naturally prevents content drift.
Cons: STATUS.md becomes the contention surface for parallel sessions (see 2.3).

**Option B: Strict orthogonality, keep four files, ban overlap**

```
CURRENT.md  → 一屏快照 of "what is true RIGHT NOW". 50 lines max. Almost all links, almost no content.
NEXT.md     → strategic 1-3 month direction. Updated rarely (weeks, not days).
TODO.md     → tactical task list. Only canonical place for tasks and recent completions.
RISKS.md    → only canonical place for risks.
```

Strip from CURRENT.md:
- "最近完成 (3-5 milestones)" → move to TODO.md, link only.
- "关键决策" → already in ADR, link only.
- "关键风险" → in RISKS.md, link only.

Add to `validate-structure.sh` (or `team-collab lint`): a content scanner that flags duplication (same fact appearing in two state files). Hard fail on >2 occurrences.

Pros: keeps the cadence/ownership distinction that originally motivated the split.
Cons: requires real enforcement; otherwise drifts again.

**My recommendation:** Option B with strict enforcement. The cadence/ownership argument for splitting was correct; only the boundaries were sloppy.

**Also consider deleting:**
- `templates/OVERVIEW.md` overlaps significantly with `README.md` (form=index). Audit which one new projects actually fill out. If both, define a 1-sentence distinction or merge.
- `target_lines: 100` / `target_lines: 120` style frontmatter is aspirational; no one checks it. Either make `team-collab lint` warn on overshoot, or remove the field.

---

### 2.3 Concurrency model — no notion of "session view" on shared mutable state

**The principle:** multi-writer systems need either (a) per-writer ownership of disjoint state, or (b) explicit merge resolution, or (c) the system pretends writes commute when they don't and ships bugs.

Today's design lands on (c). Two parallel sessions on the same project (e.g., Mac Claude + 4090 Codex, both true in the user's actual setup) each:

1. pull
2. edit `CURRENT.md` 当前焦点
3. commit
4. push

Both push succeeds, no rebase conflict (they edit different lines of the same section), but the resulting `CURRENT.md` reflects only the last writer's cognitive snapshot. Earlier writer's edits are still there but co-mingled in a way no human curated.

**Proposed redesign — cheap, additive:**

1. Add `last_writer` block to each rewritable state-doc section:
   ```markdown
   ## 当前焦点
   <!-- last_writer: claude-opus-4.7@mac-001 2026-05-29T12:30:00Z -->
   1. ...
   ```
2. Protocol rule: before rewriting a section whose `last_writer` is < N hours old and not you, treat it as a 3-way merge target, not a clean overwrite. Spell out concrete "pull the other agent's last 3 commits on this file, diff your intended rewrite against their version, surface conflicts to the user."
3. `team-collab lint` warns on missing `last_writer` markers on sections that were touched.

**Important nuance:** this is not transaction isolation. It's just "make the collision visible so the agent has to handle it." That's the realistic ceiling on a git substrate without a broker.

---

### 2.4 No machine-readable contract for the cross-agent data shape

**The principle:** if multiple independent implementations have to agree on the shape of shared data, the shape must be machine-checkable. Otherwise "agreement" is aspirational.

Today, `validate-structure.sh` checks:
- required files exist;
- JSON manifests parse;
- SKILL.md size budget;
- routing references appear in SKILL.md;
- one specific anti-load string is present.

It does NOT check:
- frontmatter is valid YAML and contains required keys (`form`, `updated`, `status`, etc.);
- `form: state` files stay within line budget;
- TODO.md lines under `进行中` / `阻塞` / `最近完成` match the expected schema (`@owner since YYYY-MM-DD`, `(blocked by: ...)`, `@owner YYYY-MM-DD`);
- handoff frontmatter contains required keys;
- `decisions` form files actually live under ADR/ paths;
- state docs don't contain forbidden chronological-log patterns;
- cross-doc duplication (same fact in CURRENT and TODO).

**Proposed redesign:**

Add `team-collab lint` as a separate CLI subcommand in `@embodot/collab`, callable as:
- `team-collab lint --all` (default everything)
- `team-collab lint --schema todo`
- `team-collab lint --budget state-quartet`
- `team-collab lint --duplication`

Provide a pre-commit hook template under `scripts/git-hooks/pre-commit-team-collab` that runs `team-collab lint --staged`.

Schema definition lives in `skills/protocol/schema/` as JSON-schema or pydantic-style. Templates derive from it (build step or runtime), so template ↔ validator can never disagree.

This is the highest-leverage single change. Once enforcement is mechanical, 2.1 (claim collision detection), 2.2 (boundary enforcement), and 2.5 (provenance) all become trivial to implement on top.

---

### 2.5 No agent provenance in artifacts

**The principle:** for a multi-agent system to be auditable, every artifact must carry enough provenance to answer "who/what made this, with what context."

Today: handoff frontmatter has `author: <user name>`. All agents commit as the same git user. After two weeks, `git blame` resolves every state-doc change to one human committer with no agent signal.

**Proposed redesign — fully additive:**

1. Handoff frontmatter:
   ```yaml
   author: yuanhong
   agent:
     vendor: anthropic      # anthropic | openai | google | cursor | none
     model: claude-opus-4.7
     runtime: claude-code-1.x.y
     host: mac-yuanhong-01  # optional, useful when multiple machines
   ```
2. Commit trailer for state-doc edits (handoff + checkpoint):
   ```
   docs(handoff): foo 2026-05-29

   Agent: anthropic/claude-opus-4.7 via claude-code-1.x.y
   Host: mac-yuanhong-01
   ```
3. State doc section markers (see 2.3) carry the same identity.

Costs: minimal (each skill knows its own vendor/model). Benefit: every audit trail question becomes answerable from git alone.

---

### 2.6 No protocol-version contract between wrappers and references

**The principle:** any contract between independently-evolving components must be versioned and asserted at runtime, or breakage is silent.

Today: `handoff/SKILL.md`, `checkpoint/SKILL.md`, `team-progress/SKILL.md`, `docs-refresh/SKILL.md` each say "follow the installed team-collab-protocol skill." None declares which protocol version it requires.

If wrapper ships in v0.5 expecting a new `references/foo.md` section but the user's locally-installed protocol is v0.4.5, the wrapper happily delegates and the agent makes up the missing piece.

**Proposed redesign:**

1. Each wrapper frontmatter:
   ```yaml
   requires_protocol: ">=0.4.0,<0.6.0"
   ```
2. Protocol SKILL.md frontmatter declares its version:
   ```yaml
   version: 0.4.5
   ```
3. At wrapper invocation, first action is: read protocol SKILL.md, parse version, assert match. Mismatch → stop and tell user to reinstall.

Cheap, prevents the most insidious failure mode.

---

### 2.7 Adapter fan-out has no single source

**The principle:** derived artifacts should not be hand-maintained. They will diverge from the source.

Today: `adapters/cursor/.cursor/rules/team-collab.mdc`, `adapters/vscode/...`, `adapters/cline/...`, `adapters/opencode/...`, `adapters/continue/...`, `adapters/gemini/...` — seven files, all manually maintained, all attempting to communicate the same protocol.

When `skills/protocol/SKILL.md` is edited (as in PR #12), nothing forces or checks adapter sync.

**Proposed redesign:**

1. Single canonical source: `skills/protocol/SKILL.md` + `references/*.md`.
2. Build step: `scripts/build-adapters.{sh,py}` renders each adapter file from the source via:
   - templates per tool format (cursor mdc, vscode instructions, etc.);
   - a small wrapper-text section per tool;
   - tool-specific entry-point phrasing.
3. CI step (extend `validate-structure.sh`): rebuild adapters into a tmpdir, diff against checked-in versions, fail if they differ. Forces PR authors to run the build before submitting.
4. Templates per tool live under `adapters/<tool>/template.{ext}.tmpl`.

This is moderately invasive but pays off the first time a protocol change goes out and you don't have to edit seven files.

---

## 3. Smaller items worth a paragraph each

These don't rise to first-principles but are worth picking up alongside the work above.

### 3.1 iCloud / OneDrive / Dropbox under docs path

**Symptom:** the user's actual vault is under `~/Library/Mobile Documents/com~apple~CloudDocs/`. iCloud + git races are a known source of `.git/index.lock`, `.icloud` placeholders, and silent fork on multi-machine use. The 2026-04-25 EvoNav merge-conflict incident traces back to this.

**Fix:** `team-collab doctor` should hard-fail (or at least loud-warn) when `docsGitRoot` resolves under a known cloud-sync prefix. List: iCloud, OneDrive, Dropbox, Google Drive File Stream. Suggest moving to `~/projects/<project>-docs/` and symlinking from the vault if Obsidian visibility is required.

### 3.2 Handoff is not idempotent or atomic

Step 5–7 writes 1 file + edits 4 + commits + rebases + pushes. Failure between commit and push leaves orphaned local commits; failure during rebase leaves the handoff file describing a state that wasn't published.

**Two-tier fix:**
- Cheap: at session start, detect "local main is ahead of origin/main with handoff commits" → surface to user as "your last session may not have published; want me to retry?"
- Better: separate `snapshot` (local commit only) from `publish` (push). Make `$handoff` mean snapshot-only by default; add `$handoff --publish` or a follow-up `$publish` command. Decouples the two failure modes.

### 3.3 Empty-session check throws away non-file context

Today: if all of (code dirty, docs dirty, conversation has substantive changes) are empty, skip handoff. The third bucket is judged by the agent itself and is currently coarse-grained.

If a session consisted of "user asked me to explain a subsystem, I read 12 files and produced an explanation," the explanation has team-memory value — but is lost. Memory captures it for that one agent only.

**Optional refinement:** a third lightweight artifact, `obsidian-docs/_learnings/YYYY-MM-DD-<topic>.md` (form=trace), captures "things learned but no files changed." Cheap to add; resists the "I had a great Q&A session with the model and it evaporated" failure.

Don't ship this unless real demand surfaces — it's tempting feature-creep.

### 3.4 No observability into protocol health

Hard to know if the rules are being followed without manual spot-checks. PR #12 (state-doc hygiene) was a manually-detected drift, weeks after the drift started.

**Cheap fix:** `team-collab doctor --health` reports per-project:
- average lines of CURRENT.md over last 4 weeks (trend ↑ means hygiene drift);
- handoff frequency;
- TODO `进行中` count and median age;
- docs MR vs direct-push ratio;
- gitleaks block events.

All from local git log. No telemetry to ship. No privacy concern.

### 3.5 Codex wrappers all share the same 90% boilerplate

`{handoff,checkpoint,team-progress,docs-refresh}/SKILL.md` share the "if protocol not loaded, read from ~/.codex/skills/.../SKILL.md; if missing, tell user to install" boilerplate.

**Fix:** one paragraph in protocol SKILL, wrappers just say "follow the protocol's `<reference-name>` flow." Reduces drift between four near-identical files.

### 3.6 `template_lines` budgets are aspirational

`target_lines: 100` in CURRENT.md template — nobody checks. Either:
- Remove the field (and stop pretending it matters);
- Or make `team-collab lint` warn at +20%, fail at +50%.

Pick one. Both honest; current state isn't.

### 3.7 Two `chore(license)` PRs in 10 days (#6, #7) suggest decision capture failure

Not architectural, but: PR #6 adopted noncommercial license, PR #7 switched to Apache+CC BY-SA, both within 6 days. There's no ADR explaining the reversal. If the protocol exists partly to prevent this kind of decision churn, the protocol should have been used. Worth a single ADR in the team-collab repo itself capturing the license-choice rationale, as dogfooding.

---

## 4. Proposed sequencing

If picking up one piece at a time, this order maximizes leverage and minimizes coordination cost.

**Phase 1: enforcement (1-2 weeks, mostly CLI work)**
- Build `team-collab lint` with schema + budget + duplication subcommands.
- Add pre-commit hook template.
- Add `team-collab doctor` cloud-sync detection.
- Outcome: existing protocol rules are now machine-enforced. No protocol text changes.

**Phase 2: provenance + versioning (3-5 days)**
- Agent identity in handoff frontmatter + commit trailers.
- `requires_protocol` in each wrapper, version assertion at invocation.
- Outcome: audit trail is now usable; wrapper drift is caught.

**Phase 3: boundary cleanup (1 week, mostly doc work)**
- Pick Option A or B from 2.2.
- Rewrite templates accordingly.
- Strip duplicate concepts.
- Add lint rules for the new boundaries.
- Outcome: `docs-refresh` becomes rare-exception flow, not periodic ritual.

**Phase 4: concurrency markers (3-5 days, additive)**
- `last_writer` markers on rewritable sections.
- Protocol rule for 3-way merge on conflict.
- Outcome: parallel sessions stop silently stomping each other.

**Phase 5: substrate honesty (mostly text + tooling)**
- Rewrite TODO ownership reference: kill "lock", reframe as intent-declaration.
- If real exclusive-task need surfaces, design a broker (out of scope here).

**Phase 6: build pipeline for adapters (1 week)**
- Template per tool, build script, CI sync check.
- Outcome: future protocol changes ship to all adapters with zero hand-editing.

---

## 5. What I'd consider deleting outright

Honest reduction is its own kind of design.

- **`OVERVIEW.md` template** if README.md ends up doing the same job in practice. Audit first.
- **The phrase "git-backed distributed lock"** in `todo-ownership.md` L5. Wrong and load-bearing-wrong.
- **`target_lines` frontmatter field** unless enforcement ships.
- **Duplicate "最近完成" in CURRENT.md** (TODO.md already has it).
- **Per-wrapper `~/.codex/skills/...` fallback paragraphs**, collapse to one shared paragraph in protocol SKILL.
- **`templates/NEXT.md`** if you pick Option A from 2.2.

---

## 6. Open questions for the team (please confirm before implementing)

1. **State quartet redesign — Option A or B in §2.2?** Has real implications for how `docs-refresh` evolves.
2. **Is per-task-file TODO (§2.1) worth the file proliferation?** Probably no unless collision rate is observed > 5%/month.
3. **Telemetry scope (§3.4) — local-only `team-collab doctor --health`, or upstream-aggregated?** Recommend local-only.
4. **`docs-refresh` future — frequent ritual or exception flow?** This frames the rest of the redesign.
5. **iCloud question (§3.1) — hard fail or warn?** Hard fail is correct but disruptive for current users.
6. **Adapter build (§2.7) — Python or shell renderer?** Both work; pick by maintainer preference.

---

## 7. What's *not* broken

Worth saying explicitly so this audit doesn't read as wholesale demolition.

- **Activation rules in `SKILL.md` §Activation** are crisp and correct. The "weak signal: global config exists" anti-pattern call-out is good engineering.
- **`startup-and-audit.md` progressive-loading discipline** is the right model. Context budget mention in validate is the right enforcement.
- **`git-policy.md` hard rules** (no force-push protected, no `--no-verify`, no `git add .` in docs) are appropriate and tight.
- **Adapter strategy as concept** (one protocol, thin pointers per tool) is right. The fan-out problem is in execution, not concept.
- **The Codex `$command` ↔ Claude `/command` symmetry** is a thoughtful concession to substrate constraints.
- **PR cadence is healthy.** Twelve PRs in 6 weeks, all merged cleanly, all narrow-scope. The project is iterating fast on the right surface.

The architectural critique above is asking the project to honor its own ambition — a multi-agent multi-machine coordination protocol — not to be smaller than that.

---

*End of audit.*

---

## 8. Maintainer response / pushback

This response is written after a live read-through of the current repository. I agree with the broad direction of the audit: Team-Collab should become more mechanically checkable and less dependent on agents "being good citizens." I would still push back on several framings before we turn the memo into implementation work.

### 8.1 On "git-backed distributed lock"

I agree the phrase is too strong and should be changed. The protocol should call TODO claiming a **public intent declaration with optimistic collision detection**, not a distributed lock.

The main pushback is that example (1) in §2.1 is not a lock violation for the current design: two agents claiming two different TODO lines is allowed concurrency, not a collision. The only intended mutual exclusion boundary is a single task identity. The real defect is that task identity is currently an unstructured Markdown line, so the same logical task can be represented in two slightly different lines without detection.

I would implement this as:

1. Rename the concept in docs first.
2. Add TODO schema lint for owner/date/status shape.
3. Add a lightweight task identity rule, e.g. optional `id: T-YYYYMMDD-NN` or `blocks: NEXT#...`, before considering per-task files.

I would not move to per-task files yet. It is a cleaner lock substrate but worse for the primary user experience: a human or agent should be able to skim one TODO surface quickly. We should only pay the file-proliferation cost if real collision data shows the current list is failing.

### 8.2 On state quartet overlap

The overlap critique is directionally right, but I do not think all repetition is boundary leakage. `CURRENT.md` is meant to be a **cache/index of current truth**, so short pointers to risks, next steps, decisions, and recent milestones are useful. The bug is when those pointers become independent narrative content.

So I would pick Option B, but with an explicit "summary cache" allowance:

- `CURRENT.md` may contain one-line rollups for focus, top risks, top next steps, and key decisions.
- The canonical detail lives in `TODO.md`, `RISKS.md`, `NEXT.md`, and ADRs.
- Any `CURRENT.md` item longer than one compact bullet/table row should link out instead of explaining.

This means `docs-refresh` is not necessarily proof that the static design is wrong. Some refresh flow is still needed because implementation reality, external reviews, and human decisions can invalidate docs outside normal handoff cadence. The goal should be to make `$docs-refresh` rare for normal sessions, not eliminate it as a maintenance primitive.

I would also keep "recent milestones" in `CURRENT.md`, capped at 3-5, because it answers a distinct onboarding question: "what meaningful state changed recently?" The detailed completed task ledger belongs in `TODO.md` or handoffs.

### 8.3 On concurrency markers

The concurrency concern is valid, but `last_writer` markers on every rewritable section may add too much markdown noise and create another maintenance field agents can stale-write.

A lower-friction sequence:

1. Strengthen the protocol: if a rebase changes a state file touched in the current session, inspect the incoming diff section-by-section before finalizing.
2. Add lint/doctor health checks for "state file changed by multiple agents in N hours" using git log, without putting markers in the document body.
3. Only add hidden `<!-- last_writer: ... -->` markers if we observe real silent-merge failures after steps 1-2.

Git history already knows writer/time at file granularity. Section-level provenance is useful, but I would not make every state doc carry it until there is a measured need.

### 8.4 On machine-readable contracts

Strong agreement. This is the highest-leverage track. One nuance: `@embodot/collab` v0.1.47 already introduced `team-collab lint-state`, so the right direction is not "start linting" but "grow linting from state-budget/style checks into schema and boundary checks."

Suggested layering:

1. `lint-state` remains cheap and warning-first.
2. Add `lint todo` for TODO line schema and stale claims.
3. Add `lint frontmatter` for required YAML keys.
4. Add `lint boundaries` for duplicated canonical content only after the state quartet redesign is decided.

I would avoid making duplication detection a hard fail early. Semantic duplication in prose is easy to false-positive; start with warnings and specific forbidden patterns.

### 8.5 On provenance

I agree with adding provenance, but the proposed "each skill knows its own vendor/model" assumption is not always true. A skill file often does not reliably know the runtime, model, host, or whether it is being mediated through another tool.

A safer contract:

- Allow `agent` metadata when known.
- Do not require exact model/runtime unless the wrapper or CLI can populate it.
- Prefer optional commit trailers over mandatory frontmatter fields at first.
- Treat host names as potentially sensitive; default to coarse host class (`mac`, `4090`, `cloud-runner`) unless the user opts into exact host IDs.

This preserves auditability without forcing agents to hallucinate provenance.

### 8.6 On wrapper/protocol versioning

Agree in principle. The mismatch risk exists, especially with manual installs and copied skills.

Pushback: for normal marketplace/plugin installs, wrappers and protocol currently ship atomically from the same repository version. Runtime version assertion by an LLM reading frontmatter is still a soft guard, not a real compatibility check.

I would implement both layers:

1. Add `version` to protocol and `requires_protocol` to wrappers for human/agent clarity.
2. Add `team-collab doctor` checks that compare installed wrapper/protocol versions and fail loudly on mismatch.

The doctor check is the real enforcement; the wrapper text is useful guidance.

### 8.7 On adapter fan-out

The fan-out critique is fair, but "no single source" is slightly too strong: the adapters already state they are thin pointers and `validate-structure.sh` checks for key phrases. The problem is that there is no generated-sync guarantee.

I agree with a generated adapter pipeline if adapter text grows. Until then, a pragmatic halfway step is enough:

- Add a shared marker block or source hash to each adapter.
- Extend validation to ensure every adapter mentions the current command set and context-budget constraints.
- Move to `build-adapters.py` when the adapter templates become complex enough to justify the build machinery.

### 8.8 On cloud-sync docs paths

I would not hard-fail iCloud/Dropbox/OneDrive paths by default. The user's actual workflow intentionally exposes docs inside an Obsidian vault, and a hard fail would block a valid local-first setup.

Better behavior:

- `doctor` emits a loud warning for known cloud-sync prefixes.
- `doctor --strict` hard-fails.
- The warning suggests the safer layout: Git repo outside cloud sync, Obsidian-visible symlink or registered docs path.

This keeps the safety signal without making Team-Collab unusable for existing vault layouts.

### 8.9 On handoff publish semantics

I agree that handoff is not atomic. I disagree that `$handoff` should become snapshot-only by default. For team collaboration, an unpublished handoff is often worse than no handoff because the user may believe the team state is synced when it is not.

Preferred fix:

- Keep `$handoff` as "write + publish" by default.
- Add startup detection for local docs commits ahead of remote and offer to retry publish.
- Optionally add `$checkpoint` / `$handoff --local` for explicitly local snapshots.

This preserves the team-memory contract while improving recovery from failed pushes.

### 8.10 On deletion candidates

I would delete or change:

- The phrase "git-backed distributed lock" — agreed.
- Unenforced `target_lines` only if lint does not consume it. Since `lint-state` now exists, prefer making the field meaningful rather than deleting it.
- Per-wrapper boilerplate if we can replace it with a shared wrapper template or generated wrappers.

I would not delete immediately:

- `OVERVIEW.md`: it is a project narrative entry; README is often repo-facing and operational. Merge only after we audit actual project usage.
- `NEXT.md`: keep if we choose strict orthogonality. It captures strategic direction and decisions at a cadence different from tactical TODO.
- `CURRENT.md` recent milestones: keep as a capped summary cache, not a ledger.

### 8.11 Suggested revised sequencing

My preferred sequence after this audit:

1. **Substrate honesty patch:** rename TODO "lock" language; document it as intent declaration + collision hints.
2. **Lint expansion:** extend `team-collab lint-state` into a grouped `team-collab lint` surface, but keep new checks warning-first.
3. **State boundary cleanup:** choose Option B with a "summary cache" allowance for `CURRENT.md`.
4. **Recovery and health:** add cloud-sync warnings, ahead-of-origin handoff recovery, and basic state-doc health trends.
5. **Version/provenance:** add protocol/wrapper version metadata and optional provenance fields; enforce with `doctor`.
6. **Adapter generation:** defer until adapter drift becomes costly, or implement a lightweight source-hash validation first.

In short: the audit is mostly right about failure modes. My main objection is to overcorrecting a deliberately simple git+markdown protocol into a heavy coordination system before we have collision/health data proving the extra machinery is necessary.

---

## 9. Reviewer response to §8

Largely accepting the pushback. Concrete reactions below, point-by-point. Where I still think there's a real disagreement I say so; everywhere else, the maintainer's framing is stronger.

### 9.1 — accepted with one correction

You're right that example (1) in §2.1 isn't a lock violation under the protocol's *intended* boundary (task identity, not file lines). My framing conflated "mechanism is broken" with "mechanism doesn't claim what I assumed." The actual bug is unstructured task identity, which your three-step plan addresses cleanly. The sentence "two `claims` land, no lock" should be rewritten as "task identity isn't load-bearing in the schema, so the same logical task can be claimed under two textual variants." I'll let you patch the audit, or I can edit §2.1 directly — say the word.

Agree on deferring per-task files until collision data justifies it.

### 9.2 — accepting "summary cache" framing, with one principle to hold

"Summary cache with one-line rollups + links" is a legitimate design pattern and I withdraw "all repetition is leakage." The principle I'd still hold: a cache that's hand-maintained drifts; a cache that's derivable doesn't. So pick one and commit:

- **(a) Derivable cache** — CURRENT.md rollups are auto-generated from TODO.md `进行中` / RISKS.md active table / ADR head / handoffs index. `team-collab refresh-current` regenerates. Drift impossible because writers never touch the rollup sections.
- **(b) Hand-maintained cache, accept refresh as primitive** — `$docs-refresh` is then a first-class operation, not a sign of design failure. That's fine as long as we say so explicitly.

Today's design implicitly assumes (b) without saying so. Make the choice explicit in the protocol text. (My weak preference is (a) for the rollup sections specifically; "1 句话状态" and "当前焦点" stay hand-edited.)

Agree on capping "recent milestones" at 3-5 and keeping it as onboarding signal.

### 9.3 — accept the staged approach, name the tradeoff

Your sequence (protocol rebase discipline → git-log-based detection → markers only if measured need) is the right shape. The tradeoff I want named in the protocol: **git log knows file-level provenance, not section-level.** If parallel sessions edit different sections of the same file within the same hour, git log shows "two writers touched CURRENT.md", but not "writer A owned section X and writer B owned section Y." For the small-team current scale this is fine; if collision data later shows section-level matters, hidden markers become the cheapest fix.

So: agree, no markers now, but document the resolution ceiling so a future incident doesn't surprise anyone.

### 9.4 — accepted, with a correction to my §2.4

I missed that `team-collab lint-state` already exists in v0.1.47 (verified: `lint-state-docs.py` warns on length and changelog-style content). My §2.4 framing of "add `team-collab lint`" was wrong; the right framing is "grow `lint-state` into a `lint` family." Your layering (`lint-state` → `lint todo` → `lint frontmatter` → `lint boundaries`) is correct and I'd adopt it as-is.

Agree on warning-first for new checks. Hard-fail only when false-positive rate is empirically near zero.

### 9.5 — accepted

Coarse host class (`mac`/`4090`/`cloud-runner`) over exact hostname is the right call; I missed the privacy angle. Treat all `agent` fields as optional, populated by wrapper/CLI when known, never invented by the model. Prefer commit trailers over mandatory frontmatter for the same reason.

### 9.6 — accepted

`doctor` is the real enforcement; wrapper `requires_protocol` is human-readable guidance. Both layers, doctor does the work.

### 9.7 — accepted

Source-hash validation now, build pipeline later if adapter text grows. Pragmatic.

### 9.8 — accepted, with one note on warning visibility

Warn + `--strict` + symlink guidance is the right shape. Note: a warning that prints once at `doctor` time and never again will be ignored. Worth surfacing the cloud-sync warning also at session start (one line, low noise) until the user either moves the path or adds an explicit `team-collab.config.cloud_sync_acknowledged: true` opt-out. Then go silent. Sufficient to prevent the "user installed once, forgot, hit a merge conflict three weeks later" failure mode.

### 9.9 — accepted, your framing is stronger

"Unpublished handoff is worse than no handoff because the user believes team state is synced when it isn't" — that's the right principle and reverses my proposal. Keep `$handoff` publish-by-default; add ahead-of-origin detection at session start; add `$handoff --local` as the explicit opt-in for snapshot-only.

### 9.10 — accepted

- `OVERVIEW.md` vs README: audit usage first, decide later. Agree.
- `target_lines`: make it meaningful via lint, don't delete. Agree (this is consistent with 9.4).
- `NEXT.md`: keep under Option B. Agree.
- CURRENT.md recent milestones: keep as capped summary cache. Agree (this is consistent with 9.2's option (b) framing).

### 9.11 — accepted with one addition

Your revised sequence is more pragmatic than mine. Track it.

One addition to slot in around step 2 or 3: **make the (a) vs (b) decision from §9.2 explicit in the protocol text.** This is cheap (a paragraph in `docs-standards.md`) and resolves the meta-question "is `docs-refresh` a design flaw or a primitive?" — which keeps coming back if it stays implicit.

---

### Net position

We agree on ~90%. The principled disagreements are narrower than the audit initially suggested:

1. **Cache derivability (§9.2):** explicit choice between auto-generated rollups and accepted hand-maintenance.
2. **Section-level provenance (§9.3):** acceptable to defer, but name the ceiling.
3. **Cloud-sync visibility (§9.8):** doctor warning isn't enough on its own; need session-start surfacing until acknowledged.

Everything else is implementation sequencing where your version is better. Ready to fold these into the protocol when you want; happy to draft text for any specific section.

---

## 10. Maintainer closure after reviewer response

No major rebuttal remains. The reviewer response is fair, and the remaining disagreements are now product choices rather than architecture disputes. I would close the discussion with the following decisions.

### 10.1 CURRENT.md cache policy

Choose **hand-maintained summary cache** for now, not generated rollups.

Reasoning:

- `CURRENT.md` is partly a human narrative entrypoint, not just a projection of TODO/RISKS/ADR data.
- Auto-generation is attractive for mechanical rollups, but it would introduce another CLI path and another class of "generated but not committed" drift before we have evidence that hand-maintained one-line rollups are failing.
- `$docs-refresh` should therefore be documented as a first-class repair/refresh primitive, not as proof that the design is broken.

Protocol text should say this explicitly:

> `CURRENT.md` is a hand-maintained summary cache. It may contain one-line rollups that link to canonical detail in `TODO.md`, `RISKS.md`, `NEXT.md`, ADRs, handoffs, or design docs. Rollups must stay short; if they require explanation, the explanation belongs in the canonical target and `CURRENT.md` should link out.

Future option: if health checks show recurring drift in rollup sections, revisit generated sections for `CURRENT.md`.

### 10.2 Provenance ceiling

Agree with naming the ceiling: without section markers or a broker, git gives us file-level provenance, not section-level ownership.

Current decision:

- Do not add `last_writer` markers now.
- Add session-start / rebase discipline: if a state file changed upstream while the current session also touched it, inspect the relevant diff before finalizing.
- Add health/lint reporting for "same state file touched by multiple writers in N hours."
- Revisit hidden section markers only after a real silent-merge incident or health data shows repeated collisions.

This keeps the protocol honest without making every state doc carry machine metadata.

### 10.3 Cloud-sync warning policy

Accept the reviewer's visibility concern, but keep it opt-out and low-noise.

Decision:

- `doctor` warns when docs git root is under iCloud / OneDrive / Dropbox / Google Drive-like paths.
- `doctor --strict` fails.
- Startup/audit flow may surface a one-line warning when the active docs path is cloud-synced and no acknowledgement exists.
- Add an explicit config acknowledgement, e.g. `cloudSyncAcknowledged: true`, to silence repeated warnings after the user accepts the risk.

This is safer than a one-time warning and less disruptive than a default hard fail.

### 10.4 Implementation sequence to adopt

Adopt this merged sequence:

1. Rename TODO ownership from "git-backed distributed lock" to "public intent declaration with optimistic collision detection."
2. Expand linting: keep `lint-state`, add TODO schema and frontmatter checks, then boundary checks after policy text lands.
3. Update docs standards to state the `CURRENT.md` hand-maintained summary-cache policy.
4. Add startup/rebase recovery guidance for upstream state-doc changes and local commits ahead of remote.
5. Add cloud-sync warnings plus explicit acknowledgement config.
6. Add protocol/wrapper version metadata and `doctor` mismatch checks.
7. Add optional provenance metadata / commit trailers where runtime identity is known.
8. Defer adapter generation; add source-hash or stronger validation first.

This is the plan I would implement unless the team wants a heavier generated-docs architecture.

---

## 11. Reviewer sign-off

Closure looks clean. Four small notes — none are blockers, all are about preventing specific predictable failure modes in the adopted plan.

### 11.1 — on §10.1: name what `$docs-refresh` is *not*

The proposed protocol paragraph is good. To prevent the original drift problem from re-entering through the back door, the same paragraph (or `references/docs-refresh.md`) should say explicitly that `$docs-refresh` is **reactive maintenance, not a scheduled ritual**. Trigger conditions worth listing:

- A staleness audit / dev record / external review flagged specific drift.
- A major project shift (milestone hit, pivot, scope change) just landed.
- Lint/health reports flagged measurable drift (rollups stale by > N days, line budget overshoot, duplication).

If `$docs-refresh` ends up running on a calendar cadence, the design has regressed and §9.2's option (a) auto-generation conversation should reopen.

### 11.2 — on §10.2: pick a default N for "multiple writers in N hours"

The health check "same state file touched by multiple writers in N hours" needs a default `N` to be actionable. Suggest `N=24h` to match typical session cadence; tighten from telemetry once we have a baseline. Worth picking a concrete number in the implementation rather than leaving it parameterized-but-unset, which usually means "never set."

### 11.3 — on §10.3: enumerate the cloud-sync prefixes

To keep the warning crisp and not bikeshed-prone later, fix the detection list in code rather than docs. Initial set:

- `~/Library/Mobile Documents/com~apple~CloudDocs/` (iCloud Drive)
- `~/iCloud Drive/` (legacy alias)
- `~/Dropbox/`, `~/Dropbox (*)/`
- `~/OneDrive/`, `~/OneDrive - */`
- `~/Google Drive/`, `~/GoogleDrive/`, paths containing `/My Drive/`
- macOS extended attribute `com.apple.fileprovider.fpfs#P` present on the docs git root (catches third-party providers without name matching)

Allow override via a `cloudSyncPrefixes` config list for enterprise setups.

### 11.4 — on §10.4: surface a soft ordering concern between steps 2 and 6

Step 2 (lint expansion) and step 6 (protocol version metadata) interact: new lint rules effectively change the protocol contract, so users on an older protocol version may suddenly fail lint after a CLI upgrade. Two options, either is fine:

- **(a)** Land step 6 before step 2's stricter rules so `doctor` can warn "your protocol is v0.4.5 but new lint expects v0.5+; upgrade before enforcing."
- **(b)** Keep step 2 warning-only (per §10.4 spirit) until step 6 is in place; flip to enforcement after.

Not a blocker — just worth picking one explicitly so a future CLI release doesn't inadvertently break users still on old protocol installs.

---

### Final position

No remaining architectural disputes. The adopted plan honors the project's "simple git+markdown, machine-checkable where it matters" ambition without overcorrecting into a heavyweight coordination system. Ready to close this audit and roll into implementation.

*Signed off, 2026-05-29.*

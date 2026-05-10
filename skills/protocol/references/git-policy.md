# Git Policy And Conflict Handling

Use this reference for git sync, push, force-push, conflicts, rejected pushes, permission failures, hooks, and gitleaks.

## Hard constraints

1. **Never force-push protected/shared/unclear branches**. This includes `main`, `master`, `release/*`, `prod/*`, docs repo default branches, another person's branch, or any branch whose ownership is unclear.
2. **Self-owned non-protected working branches may be force-pushed** after rebase, commit cleanup, or conflict repair. Prefer `--force-with-lease`; use plain `--force` only when the branch is certainly self-owned and no one else has pushed to it. Check `git branch --show-current`, `git status -sb`, and `git branch -vv` first.
3. **Never `--no-verify`**. The gitleaks hook is the last line of defense for secret leaks.
4. **Never blindly retry or auto-recover from semantic git failures** such as non-fast-forward rejection, protected branch rejection, permission denied, hook/gitleaks failure, or rebase conflicts. Stop and report.
5. **Never fabricate a handoff to satisfy a topic parameter**. Empty session = no handoff.
6. **Never `git add .` in the docs repo**. Always precise-add by filename.
7. **Never commit `.obsidian/`, `.trash/`, `.DS_Store`, or other per-user/OS cruft into the docs repo**. Obsidian `.canvas` and `.base` files may be legitimate project docs; commit them only when intentionally part of shared project memory.
8. **Respect PR/MR boundaries**:
   - Code repo changes and formal code docs: use the code platform's PR/MR flow.
   - High-level shared docs (`OVERVIEW`, PRD, test plan, project design, architecture design, roadmap, major decisions, `CURRENT/NEXT/RISKS/TODO`, `决策日志`): GitLab docs MR.
   - Personal process records (`开发记录/<用户名>/...`, personal research notes, `_handoffs/...`): direct push is allowed when the project docs repo explicitly keeps that relaxed path.

## Retry policy

Retry transient transport failures such as DNS hiccups, TLS connection reset, proxy failures, or temporary remote unavailable messages when the retry does not change repository state. If the user has authorized it, unsetting proxy variables and retrying the same read/push command is acceptable.

Do **not** retry semantic failures without user review: non-fast-forward, protected branch rejection, permission denied, failed hooks, gitleaks, or rebase conflicts.

## Your `git pull --rebase` hit a conflict

1. Open the conflicted files. Identify `<<<<<<<`, `=======`, and `>>>>>>>` markers.
2. Decide whether both sides matter; do not arbitrarily pick one side.
3. After resolution: `git add <file>` then `git rebase --continue`.
4. If you cannot confidently resolve: `git rebase --abort`, report to user, stop.

## Your `git push` was rejected

Remote advanced during your session and you already hold a valid local commit.

1. Report the push rejection.
2. For docs default/shared branches, suggest manual `git pull --rebase && git push`; never force-push.
3. For self-owned non-protected working branches, you may rebase and `git push --force-with-lease` after confirming branch ownership with `git branch --show-current`, `git status -sb`, and `git branch -vv`.
4. If ownership is unclear, stop and ask.

## Two people edited `CURRENT.md` concurrently

- `_handoffs/` is append-only and rarely conflicts; use it as the lifeboat.
- For `CURRENT.md` conflicts, resolve section-by-section during rebase.
- If the same section was rewritten by both, flag to user and let them choose. Do not auto-merge semantic content.

## gitleaks blocked the commit

Staged content contains something matching a secret pattern.

1. Show the gitleaks report to the user.
2. Do not `--no-verify`, even if asked; explain that it defeats the purpose.
3. If true secret: user removes it or substitutes a placeholder like `<YOUR_API_KEY>`, then re-commit.
4. If false positive: user adds a `.gitleaks.toml` allowlist entry, then re-commit. See https://github.com/gitleaks/gitleaks for allowlist syntax.

## Sensitive data ban

Never write these into the docs repo:

- API keys / access tokens / OAuth secrets / private keys
- Database connection strings with credentials
- Customer full names or customer-internal contact info
- Other OPC members' internal company confidential data
- Unreleased internal service URLs / ports / IPs
- Unannounced product commercial secrets

#!/usr/bin/env bash
#
# handoff-manual.sh — shell-only handoff flow for non-AI users (or when the agent isn't running)
#
# Usage:
#   handoff-manual.sh <topic>                    # guided: opens editor to write handoff, then syncs
#   handoff-manual.sh <topic> --message "..."    # non-interactive: use given message as Summary
#
# Assumes you run this from your code repo root (where ./obsidian-docs/ exists).
# Mirrors the /handoff slash command flow but does not update CURRENT/NEXT/RISKS — that's still manual.
#
# Behavior follows the hard constraints in SKILL.md:
#  - no force push
#  - no --no-verify
#  - no automatic retry
#  - stops on any failure

set -e

# ---- color output helpers ----
red()    { printf "\033[31m%s\033[0m\n" "$*"; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
blue()   { printf "\033[34m%s\033[0m\n" "$*"; }

# ---- parse args ----
TOPIC="${1:-}"
MESSAGE=""
if [ "$#" -ge 3 ] && [ "$2" = "--message" ]; then
  MESSAGE="$3"
fi

if [ -z "$TOPIC" ]; then
  red "usage: $0 <topic> [--message \"Summary text\"]"
  exit 1
fi

# ---- sanity checks ----
if [ ! -d "obsidian-docs" ]; then
  red "error: no obsidian-docs/ in current directory ($(pwd))"
  red "       run this from the code repo root."
  exit 1
fi

cd obsidian-docs

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  red "error: obsidian-docs/ is not a git repo."
  exit 1
fi

# ---- step 1: pull remote ----
blue "→ git pull --rebase origin main"
if ! git pull --rebase origin main; then
  red "pull failed (likely conflict or rebase issue). Aborting."
  red "resolve manually, then re-run this script."
  git rebase --abort 2>/dev/null || true
  exit 1
fi

# ---- step 2: empty-session check ----
if [ -z "$(git status --porcelain)" ] && [ -z "$MESSAGE" ]; then
  yellow "docs repo is clean and no --message given; nothing to hand off. Exit."
  exit 0
fi

# ---- step 3: prepare handoff file ----
STAMP=$(date +%Y-%m-%d-%H%M)
AUTHOR=$(git config user.name || echo "unknown")
# derive project from code repo (one level up)
PROJECT=$(cd .. && basename "$(git remote get-url origin 2>/dev/null | sed -E 's|.*/||; s|\.git$||')" 2>/dev/null || basename "$(cd .. && pwd)")
HANDOFF_DIR="_handoffs"
mkdir -p "$HANDOFF_DIR"
HANDOFF_FILE="$HANDOFF_DIR/${STAMP}-${TOPIC}.md"

if [ -n "$MESSAGE" ]; then
  SUMMARY="$MESSAGE"
else
  SUMMARY="<fill in summary: what was done, what state is reached>"
fi

cat > "$HANDOFF_FILE" <<EOF
---
title: handoff ${STAMP:0:10} ${TOPIC}
date: ${STAMP:0:10}
project: ${PROJECT}
author: ${AUTHOR}
topic: ${TOPIC}
tags:
  - handoff
---

# Handoff ${STAMP:0:10} · ${TOPIC}

## Summary

${SUMMARY}

## Changed files

<list what changed in code repo and docs repo>

## Decisions made

<decisions + why>

## Tests run

<commands + pass/fail, or "无">

## Risks

<new risks / resolved risks>

## Suggested next steps

<1-5 ordered actions>
EOF

green "→ handoff file created: $HANDOFF_FILE"

# ---- step 4: open editor for user to fill in if interactive ----
if [ -z "$MESSAGE" ] && [ -t 0 ]; then
  EDITOR="${EDITOR:-vim}"
  blue "→ opening $EDITOR to edit handoff..."
  "$EDITOR" "$HANDOFF_FILE"
fi

# ---- step 5: show what will be committed ----
blue "→ git status preview:"
git add "$HANDOFF_FILE"
git status --short
echo ""

if [ -t 0 ]; then
  read -r -p "proceed with commit + push? [y/N] " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    yellow "aborted by user. handoff file kept at: $HANDOFF_FILE"
    yellow "you can commit manually later."
    exit 0
  fi
fi

# ---- step 6: commit (gitleaks pre-commit will run) ----
COMMIT_MSG="docs(handoff): ${TOPIC} ${STAMP:0:10}"
blue "→ git commit -m \"$COMMIT_MSG\""
if ! git commit -m "$COMMIT_MSG"; then
  red "commit failed (likely gitleaks detected secrets)."
  red "DO NOT use --no-verify. Fix the issue and re-run."
  exit 1
fi

# ---- step 7: pull rebase (in case remote advanced) ----
blue "→ git pull --rebase origin main (safety)"
if ! git pull --rebase origin main; then
  red "rebase conflict after commit. Your commit is preserved locally."
  red "resolve manually, then: git push"
  git rebase --abort 2>/dev/null || true
  exit 1
fi

# ---- step 8: push ----
blue "→ git push origin main"
if ! git push origin main; then
  red "push rejected. Your commit is preserved locally."
  red "run 'git pull --rebase && git push' manually, NEVER --force."
  exit 1
fi

# ---- done ----
COMMIT_HASH=$(git rev-parse --short HEAD)
green "✓ handoff complete"
green "  file: $HANDOFF_FILE"
green "  commit: $COMMIT_HASH"
green "  pushed to: $(git remote get-url origin)"
echo ""
yellow "reminder: review CURRENT.md / NEXT.md / RISKS.md and update them if session changed project state."

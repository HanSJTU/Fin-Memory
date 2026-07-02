# Codex Lane — Kanban Worker with Codex CLI

## Overview

This reference covers the lightweight Hermes+Codex dual-lane convention for Kanban workers. Hermes is always the task owner: it calls `kanban_show`, decides whether Codex is appropriate, creates or selects an isolated workspace, starts and monitors Codex, reconciles any diff, runs verification, and writes the final `kanban_complete` or `kanban_block` handoff. Codex is an input lane only.

## When to Use the Codex Lane

Use when **all** are true:
- Task is coding/refactor/doc/test with clear acceptance criteria
- Bounded diff can be evaluated by Hermes in one run
- Repo can be isolated in a git worktree/branch
- Hermes can run tests itself after Codex exits
- Prompt can state all safety constraints

## Ownership Rules

1. Hermes owns the Kanban lifecycle. Codex must never call `kanban_complete`, `kanban_block`, or gateway messaging.
2. Hermes owns final acceptance — treat Codex commits as untrusted patches.
3. Hermes owns test execution — re-run canonical tests independently.
4. Hermes owns safety — reject changes to safety boundaries even if tests pass.

## Required Worktree Pattern

```bash
TASK_ID="${HERMES_KANBAN_TASK:-t_manual}"
REPO="/path/to/repo"
BASE="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
SAFE_TASK="$(printf '%s' "$TASK_ID" | tr -cd '[:alnum:]_-')"
BRANCH="codex/${SAFE_TASK}/$(date -u +%Y%m%d%H%M%S)"
WORKTREE="/tmp/${SAFE_TASK}-codex-lane"

git -C "$REPO" fetch --all --prune
git -C "$REPO" worktree add -b "$BRANCH" "$WORKTREE" "$BASE"

# Cleanup after reconciliation
git -C "$REPO" worktree remove "$WORKTREE"
git -C "$REPO" branch -D "$BRANCH"
```

## Mode Selection

Use `codex exec --full-auto` for bounded one-shot edits; launch interactively for broader multi-step work.

## Reconciliation Checklist

- [ ] `git status --short --branch` shows only expected files
- [ ] No secrets, credentials, or unrelated data included
- [ ] Safety constraints preserved
- [ ] Codex commits are small enough to cherry-pick
- [ ] Hermes ran canonical tests independently

## kanban_complete Metadata

```json
{
  "codex_lane": {
    "used": true,
    "mode": "exec | goal",
    "worktree": "/absolute/path",
    "result": "accepted | rejected | partial",
    "tests_run": ["pytest tests/..."]
  }
}
```

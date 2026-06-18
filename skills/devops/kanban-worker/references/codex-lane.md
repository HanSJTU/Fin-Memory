# Codex Lane — Kanban Worker with Codex CLI

## Overview

This reference covers the lightweight Hermes+Codex dual-lane convention for Kanban workers. Hermes is always the task owner: it calls `kanban_show`, decides whether Codex is appropriate, creates or selects an isolated workspace, starts and monitors Codex, reconciles any diff, runs verification, and writes the final `kanban_complete` or `kanban_block` handoff. Codex is an input lane only. Codex output is not a task completion signal, not a trusted reviewer, and not allowed to write durable Kanban state directly.

The convention exists so a Hermes worker can use Codex for bounded implementation help without changing the dispatcher. The dispatcher must still spawn Hermes workers. A worker may optionally spawn Codex inside its own run, then accept, partially accept, or reject the lane after independent review and tests.

## When to Use the Codex Lane

Use the Codex lane when **all** of these are true:

- The Kanban task is a coding, refactor, documentation, test, or mechanical migration task with clear acceptance criteria.
- A bounded diff can be evaluated by Hermes in one run.
- The repo can be copied or checked out in an isolated git worktree/branch.
- Hermes can run the relevant tests itself after Codex exits.
- The prompt can state all safety constraints and files that must not change.

## Ownership Rules

1. Hermes owns the Kanban lifecycle. Codex must never call `kanban_complete`, `kanban_block`, `kanban_create`, gateway messaging, or any Hermes board CLI.
2. Hermes owns final acceptance. Treat Codex commits/diffs as untrusted patches until reviewed and verified.
3. Hermes owns test execution. Repeat required verification from Hermes with the repo's canonical wrapper.
4. Hermes owns safety. If Codex changes safety boundaries, risk gates, live trading behavior, or secrets handling, reject the lane even if tests pass.

## Required Worktree and Branch Pattern

```bash
TASK_ID="${HERMES_KANBAN_TASK:-t_manual}"
REPO="/path/to/repo"
BASE="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
SAFE_TASK="$(printf '%s' "$TASK_ID" | tr -cd '[:alnum:]_-')"
BRANCH="codex/${SAFE_TASK}/$(date -u +%Y%m%d%H%M%S)"
WORKTREE="/tmp/${SAFE_TASK}-codex-lane"

git -C "$REPO" fetch --all --prune
git -C "$REPO" worktree add -b "$BRANCH" "$WORKTREE" "$BASE"
```

Cleanup after reconciliation:
```bash
git -C "$REPO" worktree remove "$WORKTREE"
git -C "$REPO" branch -D "$BRANCH"
```

## Mode Selection

Use `codex exec` for bounded one-shot edits:
```python
terminal(
    command="codex exec --full-auto '$(cat /tmp/codex_prompt.md)'",
    workdir=WORKTREE,
    background=True,
    pty=True,
    notify_on_complete=True,
)
```

Use Codex `/goal` only for broader multi-step work. Launch interactively in a PTY/tmux session.

## Reconciliation Checklist

- [ ] `git status --short --branch` shows only expected files
- [ ] `git diff --stat` reviewed by Hermes
- [ ] No secrets, credentials, generated caches, or unrelated data included
- [ ] Safety constraints preserved
- [ ] Codex commits are small enough to cherry-pick cleanly
- [ ] Hermes ran the canonical tests independently
- [ ] Accepted commits/diffs applied to Hermes-owned workspace

## kanban_complete Metadata

Include this in `metadata.codex_lane`:
```json
{
  "codex_lane": {
    "used": true,
    "mode": "exec | goal | skipped",
    "worktree": "/absolute/path",
    "branch": "codex/t_caa69668/20260508100000",
    "result": "accepted | rejected | partial | timed_out",
    "accepted_commits": ["<sha1>"],
    "rejected_reason": "concrete reason or empty",
    "tests_run": [...]
  }
}
```

## Prompt Template

See `templates/pmb-codex-lane-prompt.md` for the exact prompt template used with prediction-market-bot. Adapt the safety constraints for other repos.

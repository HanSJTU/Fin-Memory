---
name: coding-agents
description: "Delegate coding to external AI coding CLIs: Claude Code (Anthropic), Codex (OpenAI), and OpenCode (provider-agnostic). Print mode for one-shots, interactive PTY for multi-turn sessions, PR review, parallel worktrees."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Coding-Agent, Claude, Codex, OpenCode, Autonomous-Coding, PR-Review, Refactoring]
    absorbed: [claude-code, codex, opencode]
---

# Coding Agents — External AI Coding CLI Orchestration

This umbrella covers delegating coding tasks to three external AI coding CLIs. Each has install, auth, print mode (one-shot), interactive mode (PTY), PR review patterns, and parallel work patterns. Choose the one that fits your needs:

| Agent | Provider | Best For | Install |
|-------|----------|----------|---------|
| **Claude Code** | Anthropic | Deep reasoning, security audits, long sessions | `npm install -g @anthropic-ai/claude-code` |
| **Codex** | OpenAI | Fast iterations, batch issue fixing | `npm install -g @openai/codex` |
| **OpenCode** | Provider-agnostic | Multi-provider, open-source, TUI | `npm install -g opencode-ai@latest` |

---

## Section 1: Claude Code — Anthropic's CLI Agent

**References:** `references/claude-code.md` for full CLI flags, MCP integration, hooks, custom subagents, settings, and environment variables.

### Prerequisites

```bash
npm install -g @anthropic-ai/claude-code
claude auth login          # browser OAuth for Pro/Max
claude auth login --console # API key billing
claude --version            # requires v2.x+
claude doctor               # health check
```

### Print Mode (Preferred for One-Shot Tasks)

```bash
terminal(command="claude -p 'Add error handling to all API calls in src/' --allowedTools 'Read,Edit' --max-turns 10", workdir="/path", timeout=120)
```

Key flags: `-p` (print mode), `--allowedTools`, `--max-turns`, `--output-format json`, `--model sonnet/opus/haiku`, `--dangerously-skip-permissions`

### Interactive Mode (Multi-Turn via tmux)

```bash
terminal(command="tmux new-session -d -s claude-work -x 140 -y 40")
terminal(command="tmux send-keys -t claude-work 'cd /path && claude' Enter")
# Handle workspace trust dialog
terminal(command="sleep 5 && tmux send-keys -t claude-work Enter")
# Send task
terminal(command="tmux send-keys -t claude-work 'Refactor the auth module' Enter")
# Monitor
terminal(command="sleep 30 && tmux capture-pane -t claude-work -p -S -50")
```

### PR Review

```bash
# Quick (print mode)
terminal(command="git diff main...feature | claude -p 'Review this diff for bugs and security issues' --max-turns 1", timeout=60)

# Deep (with worktree and tmux)
terminal(command="claude -p 'Review PR thoroughly' --from-pr 42 --max-turns 10", workdir="/project", timeout=120)
```

### Pitfalls

- Interactive mode REQUIRES tmux — Claude Code is a full TUI app
- `--dangerously-skip-permissions` dialog defaults to "No, exit" — must press Down then Enter
- `--max-budget-usd` minimum ~$0.05 for system prompt cache creation
- `--bare` mode skips OAuth — requires `ANTHROPIC_API_KEY`

---

## Section 2: Codex — OpenAI's CLI Agent

**References:** `references/codex.md` for detailed flags, batch PR review, parallel worktrees.

### Prerequisites

```bash
npm install -g @openai/codex
# Auth: OPENAI_API_KEY or Codex OAuth credentials
# Must run inside a git repository!
```

### Print Mode (One-Shot)

```bash
terminal(command="codex exec 'Add dark mode toggle to settings'", workdir="~/project", pty=true)
```

For scratch work (needs git repo):
```bash
terminal(command="cd $(mktemp -d) && git init && codex exec 'Build a snake game in Python'", pty=true)
```

### Background Mode (Long Tasks)

```bash
terminal(command="codex exec --full-auto 'Refactor the auth module'", workdir="~/project", background=true, pty=true)
# Monitor
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")
```

### Key Flags

| Flag | Effect |
|------|--------|
| `exec "prompt"` | One-shot execution, exits when done |
| `--full-auto` | Sandboxed, auto-approves file changes |
| `--yolo` | No sandbox, no approvals (fastest, most dangerous) |

### PR Review (temp clone)

```bash
terminal(command="REVIEW=$(mktemp -d) && git clone https://github.com/user/repo.git $REVIEW && cd $REVIEW && gh pr checkout 42 && codex review --base origin/main", pty=true)
```

### Pitfalls

- **Always use `pty=true`** — Codex is an interactive terminal app
- **Git repo required** — Codex won't run outside a git dir
- Use `exec` for one-shots, `--full-auto` for building
- Background mode for long tasks

---

## Section 3: OpenCode — Provider-Agnostic CLI

**References:** `references/opencode.md` for TUI keybindings, session management, stats, and cost tracking.

### Prerequisites

```bash
npm i -g opencode-ai@latest
# or: brew install anomalyco/tap/opencode
opencode auth login            # or set provider env vars
opencode auth list              # should show at least one provider
```

### Print Mode (One-Shot)

```bash
terminal(command="opencode run 'Add retry logic to API calls'", workdir="~/project")
# Attach files
terminal(command="opencode run 'Review this config' -f config.yaml -f .env.example", workdir="~/project")
# Force specific model
terminal(command="opencode run 'Refactor auth' --model openrouter/anthropic/claude-sonnet-4", workdir="~/project")
```

### Interactive Mode (Background PTY)

```bash
terminal(command="opencode", workdir="~/project", background=true, pty=true)
process(action="submit", session_id="<id>", data="Implement OAuth refresh flow")
process(action="poll", session_id="<id>")
process(action="submit", session_id="<id>", data="Now add error handling")
# Exit with Ctrl+C (not /exit!)
process(action="write", session_id="<id>", data="\\x03")
```

### Key Flags

| Flag | Use |
|------|-----|
| `run 'prompt'` | One-shot execution and exit |
| `--continue` / `-c` | Continue last session |
| `--session <id>` | Continue specific session |
| `--model prov/model` | Force specific model |
| `--file <path>` / `-f` | Attach file(s) to the message |
| `--thinking` | Show model thinking blocks |

### PR Review

```bash
terminal(command="opencode pr 42", workdir="~/project", pty=true)
```

### Pitfalls

- `opencode run` does NOT need pty; interactive TUI does
- `/exit` is NOT a valid command — use Ctrl+C to exit
- PATH mismatch can select wrong binary — check with `which -a opencode`
- Enter may need to be pressed twice in TUI

---

## Common Patterns (All Agents)

### Parallel Worktrees

```bash
# Create isolated worktrees
git worktree add -b fix/issue-78 /tmp/issue-78 main
git worktree add -b fix/issue-99 /tmp/issue-99 main

# Run agents in parallel
# (use the agent's print mode with background=true)
terminal(command="<agent> exec 'Fix issue #78'", workdir="/tmp/issue-78", background=true, pty=true)
terminal(command="<agent> exec 'Fix issue #99'", workdir="/tmp/issue-99", background=true, pty=true)

# Monitor
process(action="list")

# Push and create PRs
terminal(command="cd /tmp/issue-78 && git push -u origin fix/issue-78 && gh pr create ...")

# Cleanup
git worktree remove /tmp/issue-78
```

### Selection Guide

| Task | Recommended Agent |
|------|-------------------|
| Deep code review with security audit | Claude Code |
| Quick one-shot feature implementation | Codex or Claude Code (-p) |
| Multi-provider / open-source preference | OpenCode |
| Long iterative refactoring session | Claude Code (interactive/tmux) |
| Batch issue fixing across worktrees | Codex (--yolo per worktree) |
| Cost-sensitive / model-flexible | OpenCode (bring your own provider) |

---
name: kanban-workflow
description: "Complete Hermes Kanban system: orchestrator decomposition playbook + worker pitfalls/examples/edge cases. Covers profile discovery, task graph creation, dependency linking, goal-mode cards, recovery, good handoff shapes, workspace handling, Codex lane integration, and retry diagnostics."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [kanban, multi-agent, orchestration, worker, routing, decomposition]
    absorbed: [kanban-orchestrator, kanban-worker]
---

# Kanban Workflow — Orchestrator + Worker

This umbrella merges `kanban-orchestrator` and `kanban-worker` into one comprehensive skill. The orchestrator playbook handles decomposition, profile discovery, and task graph creation. The worker section covers pitfalls, handoff shapes, workspace types, and retry diagnostics.

The core worker lifecycle (6 steps: orient → work → heartbeat → block/complete) is auto-injected into every worker's system prompt as `KANBAN_GUIDANCE` from the agent prompt builder. This skill is deeper context for both roles.

---

## Part 1: Orchestrator Playbook

### Profile Discovery (Step 0)

Before fanning out, discover what profiles exist:

```bash
hermes profile list     # prints configured profiles
kanban_list(assignee="<name>")  # sanity-check a single name
# Or just ask the user: "What profiles do you have set up?"
```

Cache results for the conversation.

### When to Use the Board

Create Kanban tasks when:
1. Multiple specialists are needed
2. Work should survive a crash/restart
3. User might want to interject
4. Multiple subtasks can run in parallel
5. Review/iteration is expected
6. The audit trail matters

If **none** apply, use `delegate_task` instead.

### Anti-Temptation Rules

- **Do not execute the work yourself** — route, don't execute
- **For any concrete task, create a Kanban task and assign it**
- **Split multi-lane requests** before creating cards
- **Run independent lanes in parallel** — link only true data dependencies
- **Never create dependent work as independent ready cards** — use `parents=[...]`
- **Always assign to a real profile** — the dispatcher silently drops unknown assignees

### Decomposition Playbook

#### Step 1: Understand the goal — ask clarifying questions if ambiguous.

#### Step 2: Sketch the task graph
1. Extract lanes from the request
2. Map each lane to a discovered profile
3. Decide dependencies (independent or gated)
4. Independent lanes → parallel cards with no parent links
5. Synthesis/review cards → parent links to dependencies

> Words like "also," "finally," or "and" do not automatically imply a dependency. Only link when one card cannot start without another's output.

#### Step 3: Create tasks with parent links

```python
t1 = kanban_create(
    title="research: Postgres cost vs current",
    assignee="<profile-A>",
    body="Compare costs over 3-year window.",
    tenant=os.environ.get("HERMES_TENANT"),
)["task_id"]

t2 = kanban_create(
    title="synthesize recommendation",
    assignee="<profile-B>",
    body="Read findings from T1.",
    parents=[t1],
)["task_id"]
```

#### Step 4: Complete your own task

```python
kanban_complete(
    summary="decomposed into 3 tasks: ...",
    metadata={"task_graph": {"T1": {"assignee": "...", "parents": []}, ...}},
)
```

### Common Patterns

- **Fan-out + fan-in:** N research cards with no parents, one synthesis card with all as parents
- **Pipeline with gates:** `planner → implementer → reviewer`
- **Same-profile queue:** N tasks, same assignee, no dependencies — dispatcher serializes
- **Human-in-the-loop:** `kanban_block()` for input; dispatcher respawns after `/unblock`

### Goal-Mode Cards (Persistent Workers)

For open-ended cards where one turn rarely finishes:

```python
kanban_create(
    title="Translate the full docs site to French",
    assignee="<translator>",
    goal_mode=True,        # judge re-checks after each turn
    goal_max_turns=15,     # optional budget (default 20)
)
```

### Recovering Stuck Workers

1. **Reclaim** — abort running worker, reset task to `ready`
2. **Reassign** — switch to a different profile
3. **Change profile model** — edit profile config, then Reclaim

---

## Part 2: Worker Playbook

### Workspace Handling

| Kind | What it is | How to work |
|------|-----------|-------------|
| `scratch` | Fresh tmp dir, yours alone | Read/write freely; GC'd when task archived |
| `dir:<path>` | Shared persistent dir | Other runs read what you write |
| `worktree` | Git worktree at resolved path | If `.git` doesn't exist, `git worktree add`, then work in it |

### Tenant Isolation

If `$HERMES_TENANT` is set, prefix memory entries with the tenant.

### Good Summary+Metadata Shapes

**Coding task:**
```python
kanban_complete(
    summary="shipped rate limiter — token bucket, 14 tests pass",
    metadata={
        "changed_files": ["rate_limiter.py", "tests/..."],
        "tests_run": 14, "tests_passed": 14,
    },
)
```

**Coding task needing review:**
```python
kanban_comment(body="review-required handoff:\n" + json.dumps({...}))
kanban_block(reason="review-required: rate limiter shipped, needs eyes before merge")
```

**Research task:**
```python
kanban_complete(
    summary="3 libraries reviewed; vLLM wins on throughput",
    metadata={"recommendation": "vLLM", "benchmarks": {...}},
)
```

### Claiming Cards You Created

Pass `created_cards` on `kanban_complete`. The kernel verifies each id exists and was created by your profile.

```python
# GOOD
c1 = kanban_create(title="remediate SQL injection", assignee="security-worker")
kanban_complete(summary="...", created_cards=[c1["task_id"]])
```

### Block Reasons That Get Answered Fast

Bad: `"stuck"` — no context.
Good: `"Rate limit key choice: IP (simple, NAT-unsafe) or user_id (requires auth)?"`

Leave full context as a `kanban_comment`, use `kanban_block` for the one-sentence decision needed.

### Heartbeats

Good: `"epoch 12/50, loss 0.31"`, `"scanned 1.2M/2.4M rows"`
Bad: `"still working"`, empty notes, sub-second intervals.

### Retry Scenarios

- `outcome: "timed_out"` — previous hit max runtime. Chunk or shorten work.
- `outcome: "crashed"` — OOM/segfault. Reduce memory.
- `outcome: "spawn_failed"` — profile config issue. Block and ask human.
- `outcome: "reclaimed"` — operator archived the task. You probably shouldn't be running.
- `outcome: "blocked"` — previous blocked; unblock comment should be in the thread.

### Do NOT

- Call `delegate_task` as a substitute for `kanban_create`
- Call `clarify` — you're headless. Use `kanban_block` instead.
- Modify files outside `$HERMES_KANBAN_WORKSPACE` unless the task body says to.
- Create follow-up tasks assigned to yourself.

### Pitfalls

- Task state can change between dispatch and startup — always `kanban_show` first
- Workspace may have stale artifacts from previous runs
- Don't rely on CLI when the tool is available (CLI may not exist in containerized backends)

### Codex Lane Integration

See `references/codex-lane.md` for the Hermes+Codex dual-lane workflow: worktree isolation, mode selection, reconciliation checklist, and prompt template at `templates/pmb-codex-lane-prompt.md`.

### CLI Fallback (for scripting)

- `kanban_show` ↔ `hermes kanban show <id> --json`
- `kanban_complete` ↔ `hermes kanban complete <id> --summary "..." --metadata '{...}'`
- `kanban_block` ↔ `hermes kanban block <id> "reason"`
- `kanban_create` ↔ `hermes kanban create "title" --assignee <profile> [--parent <id>]`

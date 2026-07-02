---
name: development-lifecycle
description: "Full software development lifecycle: plan → spike → TDD → debug → review. Covers implementation planning, throwaway prototypes, test-driven development (RED-GREEN-REFACTOR), systematic 4-phase debugging, and pre-commit code verification with security scan + independent reviewer."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [planning, tdd, debugging, code-review, spike, development, lifecycle, quality]
    absorbed: [plan, spike, test-driven-development, systematic-debugging, requesting-code-review]
---

# Development Lifecycle — Plan → Spike → TDD → Debug → Review

This umbrella covers five phases of the development workflow. Load this skill when you need to plan implementation, validate an idea, write tests first, debug systematically, or verify code before committing.

---

## Phase 1: Plan (`references/planning.md`)

Write actionable implementation plans with bite-sized tasks (2-5 min each), exact file paths, complete code examples, and verification steps.

**When to use:** user asks for a plan, not execution. Multi-step features, complex requirements, delegation to subagents.

**Core principle:** A good plan makes implementation obvious.

**Key elements:**
- Save plans to `.hermes/plans/YYYY-MM-DD_HHMMSS-<slug>.md`
- Each task = one focused action (write test, run test, implement, verify, commit)
- Include: exact file paths, complete code, exact commands with expected output, verification steps
- Apply DRY, YAGNI, TDD, frequent commits

See `references/planning.md` for full plan document structure, task templates, writing process, and common mistakes.

---

## Phase 2: Spike (`references/spiking.md`)

Throwaway experiments to validate feasibility before committing to a real build.

**When to use:** "let me try this", "spike this out", "is this even possible?", "compare A vs B".

**Core method:** decompose → research → build → verdict

**Key elements:**
- Each spike = one standalone directory: `spikes/NNN-descriptive-name/`
- Per-spike `README.md` with question, approach, results, verdict
- Bias toward something the user can interact with (CLI, HTML page, small web server)
- Comparison spikes get head-to-head tables
- Verdict: VALIDATED / PARTIAL / INVALIDATED

See `references/spiking.md` for full decomposition guide, alignment step, research flow, build tactics, and frontier mode.

---

## Phase 3: Test-Driven Development (`references/tdd.md`)

Write the test first. Watch it fail. Write minimal code to pass. Refactor.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

**Iron Law:** NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.

**RED-GREEN-REFACTOR cycle:**
1. Write one minimal failing test
2. Verify RED — watch it fail for the expected reason
3. Write minimal code to pass (cheating allowed: hardcode, copy-paste)
4. Verify GREEN — watch it pass
5. Refactor — clean up while keeping tests green
6. Repeat

See `references/tdd.md` for common rationalizations table, red flags, anti-patterns, and when-stuck guide.

---

## Phase 4: Systematic Debugging (`references/debugging.md`)

Four-phase root cause analysis. Understand bugs before fixing.

**Iron Law:** NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence, trace data flow | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare, identify differences | Know what's different |
| **3. Hypothesis** | Form theory, test minimally, one variable at a time | Confirmed or new hypothesis |
| **4. Implementation** | Create regression test, fix root cause, verify | Bug resolved, all tests pass |

**Rule of Three:** After 3 failed fixes, STOP and question the architecture.

See `references/debugging.md` for the complete methodology, red flags table, common rationalizations, and integration with TDD.

**Language-specific debugger references:**
- `references/python-debugger.md` — pdb + debugpy + remote-pdb quick reference
- `references/node-debugging.md` — node inspect + CDP + heap snapshots

---

## Phase 5: Pre-Commit Code Verification (`references/code-verification.md`)

Automated verification pipeline before code lands.

**Core principle:** No agent should verify its own work. Fresh context finds what you miss.

**Pipeline:**
1. Get the diff (`git diff --cached`)
2. Static security scan (secrets, SQL injection, eval, unsafe deserialization)
3. Baseline tests and linting (compare against stashed baseline)
4. Self-review checklist
5. Independent reviewer subagent (fresh context, fail-closed JSON verdict)
6. Evaluate results — security/logic failures block commit
7. Auto-fix loop (max 2 cycles with third-agent context)
8. Commit with `[verified]` prefix

See `references/code-verification.md` for reviewer subagent prompt template, security scan patterns, baseline comparison, and auto-fix loop design.

---

## Quick Reference: When to Use Which Phase

| Situation | Phase |
|-----------|-------|
| User wants a plan, not execution | Plan |
| "Let me try X first" — validate feasibility | Spike |
| Building new feature | TDD |
| Bug found (test failure, wrong behavior) | Debugging |
| "Review my changes" or "before I commit" | Code Verification |
| Complex feature that needs all phases | Plan → Spike → TDD → Debug → Verify |

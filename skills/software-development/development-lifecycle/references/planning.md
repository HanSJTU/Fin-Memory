# Planning

## Core Behavior

For planning mode: do not implement code. Deliverable is a markdown plan at `.hermes/plans/YYYY-MM-DD_HHMMSS-<slug>.md`.

## Plan Structure

```
# [Feature Name] Implementation Plan

**Goal:** One sentence
**Architecture:** 2-3 sentences
**Tech Stack:** Key technologies

---

### Task N: [Descriptive Name]

**Objective:** One sentence
**Files:** Create/Modify paths
**Steps:** Write failing test → verify RED → implement → verify GREEN → commit
```

## Bite-Sized Tasks

Each task = 2-5 minutes of focused work. Every step is one action.

**Too big:** "Build authentication system" (50 lines across 5 files)
**Right size:** "Create User model with email field" (10 lines, 1 file)

## Writing Process

1. Understand requirements
2. Explore codebase (search_files, read_file)
3. Design approach (architecture, dependencies)
4. Write tasks in order: setup → core (TDD) → edge cases → integration → cleanup
5. Include: exact file paths, complete code examples, exact commands with expected output

## Principles

- **DRY** — Extract reused logic
- **YAGNI** — Implement only what's needed now
- **TDD** — Every code task includes RED-GREEN-REFACTOR cycle
- **Frequent commits** — Commit after every task

## Common Mistakes

- Vague tasks ("Add authentication") → Be specific ("Create User model with email field")
- Incomplete code → Include copy-pasteable code
- Missing verification → Include exact commands with expected output
- Missing file paths → Every task specifies exact paths

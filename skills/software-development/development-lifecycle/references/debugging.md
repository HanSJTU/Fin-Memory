# Systematic Debugging — 4-Phase Root Cause Analysis

## Iron Law

NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.

## Phase 1: Root Cause Investigation

1. Read error messages carefully — line numbers, file paths, error codes
2. Reproduce consistently — exact steps, every time?
3. Check recent changes — `git log --oneline -10`, `git diff`
4. Gather evidence in multi-component systems — log data at each boundary
5. Trace data flow — where does the bad value originate? Fix at the source, not the symptom

## Phase 2: Pattern Analysis

1. Find working examples — similar code in the codebase
2. Compare against references — read the reference implementation COMPLETELY
3. Identify differences — list every difference, however small
4. Understand dependencies — what config, env, assumptions?

## Phase 3: Hypothesis and Testing

1. Form single hypothesis — "I think X is root cause because Y"
2. Test minimally — smallest possible change, one variable at a time
3. Verify before continuing — worked? → Phase 4. Didn't? → New hypothesis.
4. When you don't know — say so, ask for help, research more

## Phase 4: Implementation

1. Create failing test case — simplest possible reproduction
2. Implement single fix — ONE change at a time, no bundled refactoring
3. Verify fix — regression test + full suite
4. **Rule of Three:** If 3+ fixes failed, STOP and question the architecture

## Red Flags

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Multiple changes at once saves time"
- "One more fix attempt" (on 2+ failed attempts)

## Language Debuggers

- `references/python-debugger.md` — pdb + debugpy + remote-pdb
- `references/node-debugging.md` — node inspect + CDP

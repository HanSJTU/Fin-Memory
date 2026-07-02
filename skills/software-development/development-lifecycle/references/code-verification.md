# Pre-Commit Code Verification

**Core principle:** No agent should verify its own work.

## Step 1 — Get the diff

```bash
git diff --cached
# If empty, try: git diff, then git diff HEAD~1 HEAD
# If still empty: git status — nothing to verify
```

Split by file if diff > 15,000 chars.

## Step 2 — Static security scan

```bash
# Hardcoded secrets
git diff --cached | grep "^+" | grep -iE "(api_key|secret|password|token)\s*=\s*['\"][^'\"]{6,}['\"]"
# Shell injection
git diff --cached | grep "^+" | grep -E "os\.system\(|subprocess.*shell=True"
# Dangerous eval/exec
git diff --cached | grep "^+" | grep -E "\beval\(|\bexec\("
# Unsafe deserialization
git diff --cached | grep "^+" | grep -E "pickle\.loads?\("
# SQL injection
git diff --cached | grep "^+" | grep -E "execute\(f\"|\.format\(.*SELECT|\.format\(.*INSERT"
```

## Step 3 — Baseline tests and linting

Stash changes, run tests, pop. Only NEW failures block.

```bash
# Auto-detect and run
python -m pytest --tb=no -q   # Python
npm test -- --passWithNoTests # Node
cargo test                     # Rust
go test ./...                  # Go

# Linting
which ruff && ruff check .
which mypy && mypy . --ignore-missing-imports
```

## Step 4 — Self-review checklist

- [ ] No hardcoded secrets
- [ ] Input validation on user data
- [ ] Parameterized SQL queries
- [ ] File operations validate paths
- [ ] External calls have error handling
- [ ] No debug print/console.log
- [ ] No commented-out code
- [ ] New code has tests

## Step 5 — Independent reviewer subagent

Call `delegate_task` with the diff and static scan results. Reviewer returns JSON:
```json
{"passed": true/false, "security_concerns": [], "logic_errors": [], "suggestions": [], "summary": "..."}
```

Fail-closed: non-empty security_concerns or logic_errors → passed=false.

## Step 6 — Evaluate results

All passed → commit. Any failures → report + auto-fix.

## Step 7 — Auto-fix loop

Max 2 fix-and-reverify cycles. Spawn third agent context (not implementer, not reviewer) to fix ONLY reported issues. Re-run Steps 1-6 after each fix.

## Step 8 — Commit

```bash
git add -A && git commit -m "[verified] <description>"
```

# Code Review

## Local Changes (Pre-Push)

```bash
# Get diff
git diff --staged                     # staged changes
git diff main...HEAD                  # full PR diff
git diff main...HEAD --name-only      # file names
git diff main...HEAD --stat           # stat summary
git log main..HEAD --oneline          # commit log

# Scan for issues
git diff main...HEAD | grep -n "print(\|console\.log\|TODO\|FIXME\|debugger"
git diff main...HEAD --stat | sort -t'|' -k2 -rn | head -10
git diff main...HEAD | grep -in "password\|secret\|api_key\|token.*=\|private_key"
git diff main...HEAD | grep -n "<<<<<<\|>>>>>>\|======="
```

## PR Review (GitHub)

```bash
# View PR
gh pr view 123
gh pr diff 123
gh pr diff 123 --name-only

# Check out locally
gh pr checkout 123
# or: git fetch origin pull/123/head:pr-123 && git checkout pr-123

# Check CI
gh pr checks 123

# Submit review
gh pr review 123 --approve --body "LGTM!"
gh pr review 123 --request-changes --body "See inline comments."
gh pr review 123 --comment --body "Some suggestions."
```

### Leave Inline Comments

```bash
HEAD_SHA=$(gh pr view 123 --json headRefOid --jq '.headRefOid')
gh api repos/$OWNER/$REPO/pulls/123/comments \
  --method POST \
  -f body="Use parameterized queries." \
  -f path="src/auth/login.py" \
  -f commit_id="$HEAD_SHA" \
  -f line=45 \
  -f side="RIGHT"
```

### Atomic Multi-Comment Review (curl)

```bash
HEAD_SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/pulls/$PR_NUMBER \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['head']['sha'])")

curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/pulls/$PR_NUMBER/reviews \
  -d "{
    \"commit_id\": \"$HEAD_SHA\",
    \"event\": \"REQUEST_CHANGES\",
    \"body\": \"Review from Hermes Agent\",
    \"comments\": [
      {\"path\": \"src/auth.py\", \"line\": 45, \"body\": \"Critical: SQL injection\"},
      {\"path\": \"src/models.py\", \"line\": 23, \"body\": \"Warning: plaintext password\"}
    ]
  }"
```

Events: `"APPROVE"`, `"REQUEST_CHANGES"`, `"COMMENT"`

## Review Checklist

- **Correctness** — edge cases, error paths, concurrent access
- **Security** — no hardcoded secrets, input validation, SQL injection, XSS
- **Quality** — clear naming, DRY, single responsibility, no unnecessary complexity
- **Testing** — new code paths tested, happy path + errors
- **Performance** — no N+1 queries, no blocking in async code
- **Documentation** — public APIs documented, README updated

## Review Output Format

```
## Code Review Summary

**Verdict: Changes Requested** (2 issues, 1 suggestion)

### 🔴 Critical
- **src/auth.py:45** — SQL injection vulnerability

### ⚠️ Warnings
- **src/models.py:23** — Plaintext password storage

### 💡 Suggestions
- **src/utils.py:8** — Duplicated logic

### ✅ Looks Good
- Clean API design, good test coverage
```

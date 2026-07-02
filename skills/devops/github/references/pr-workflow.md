# PR Workflow

## Complete Lifecycle

```bash
# 1. Start from clean main
git checkout main && git pull origin main

# 2. Branch
git checkout -b fix/login-redirect-bug

# 3. (Make changes, commit)
git add src/auth/login.py tests/test_login.py
git commit -m "fix: correct redirect URL after login"

# 4. Push
git push -u origin HEAD

# 5. Create PR
gh pr create \
  --title "fix: correct redirect URL after login" \
  --body "## Summary\nPreserves ?next= parameter.\n\nCloses #42" \
  --label "bug"

# 6. Monitor CI
gh pr checks --watch

# 7. Merge when green
gh pr merge --squash --delete-branch
```

## Branch Naming

- `feat/description` — new features
- `fix/description` — bug fixes
- `refactor/description` — code restructuring
- `docs/description` — documentation
- `ci/description` — CI/CD changes

## Commit Messages (Conventional Commits)

Format: `type(scope): description`

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `ci`, `chore`, `perf`, `style`, `build`

See `references/conventional-commits.md`.

## CI Monitoring

```bash
# With gh
gh pr checks
gh pr checks --watch

# With curl
SHA=$(git rev-parse HEAD)
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/commits/$SHA/status
```

## Auto-Fix CI Loop

1. Check CI → identify failures
2. Read failure logs → understand error
3. Fix code → `git add && git commit && git push`
4. Re-check CI
5. Repeat up to 3 attempts, then ask user

## Merging

```bash
# Squash + delete branch (cleanest)
gh pr merge --squash --delete-branch

# Auto-merge (merges when checks pass)
gh pr merge --auto --squash --delete-branch

# Options: --squash, --rebase, or omit for merge commit
```

## PR Commands Reference

| Action | gh | curl |
|--------|-----|------|
| List my PRs | `gh pr list --author @me` | `GET /repos/o/r/pulls` |
| View diff | `gh pr diff` | `git diff main...HEAD` |
| Add comment | `gh pr comment N --body "..."` | `POST /repos/o/r/issues/N/comments` |
| Request review | `gh pr edit N --add-reviewer user` | `POST /repos/o/r/pulls/N/requested_reviewers` |
| Close PR | `gh pr close N` | `PATCH /repos/o/r/pulls/N -d '{"state":"closed"}'` |
| Check out PR | `gh pr checkout N` | `git fetch origin pull/N/head:pr-N` |
| View CI | `gh pr checks` | `GET /repos/o/r/commits/sha/status` |

---
name: github
description: "Complete GitHub workflow: authentication, code review, issues, PR lifecycle, repository management, CI/CD, releases, and secrets. One-stop umbrella for all GitHub operations."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [GitHub, Git, Pull-Requests, Code-Review, Issues, CI/CD, Releases, Authentication]
    absorbed: [github-auth, github-code-review, github-issues, github-pr-workflow, github-repo-management]
---

# GitHub — Complete Workflow Umbrella

This is the unified umbrella skill for all GitHub operations. It replaces 5 separate skills (github-auth, github-code-review, github-issues, github-pr-workflow, github-repo-management). Each section below links to deeper reference files under `references/`, `templates/`, and `scripts/`.

**Authentication detection** — the helper script at `scripts/gh-env.sh` sets `GH_AUTH_METHOD`, `GITHUB_TOKEN`, `GH_USER`, `GH_OWNER`, `GH_REPO`:

```bash
source "${HERMES_HOME:-$HOME/.hermes}/skills/devops/github/scripts/gh-env.sh"
```

---

## 1. Authentication (`references/auth.md`)

Two paths: HTTPS (portable, no SSH config) or SSH (if the user prefers keys). Both require a GitHub personal access token or SSH key.

```bash
# Quick check
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  echo "Using gh CLI"
elif [ -n "$GITHUB_TOKEN" ]; then
  echo "Using curl with token"
else
  echo "Not authenticated — see references/auth.md"
fi
```

See `references/auth.md` for: HTTPS token setup, SSH key setup, gh CLI auth (interactive + token-based), credential helper configuration, troubleshooting table (permission denied, auth failure, SSH port 443, multiple accounts).

---

## 2. Code Review (`references/code-review.md`)

Perform code reviews on local changes (pre-push) or on open PRs.

- **Local review:** `git diff main...HEAD`, scan for debug statements, secrets, merge conflicts, large files
- **PR review:** `gh pr diff N` or `git fetch origin pull/N/head:pr-N` then review locally
- **Inline comments + formal review:** Submit APPROVE/REQUEST_CHANGES/COMMENT via gh or curl
- **Review checklist:** Correctness, Security, Code Quality, Testing, Performance, Documentation

See `references/code-review.md` for full diff commands, inline comment API, atomic multi-comment reviews, and the review-output-template.

---

## 3. Issues (`references/issues.md`)

Create, search, triage, label, assign, and manage issues.

```bash
# Create
gh issue create --title "Bug: login redirect broken" --body "..." --label "bug"

# List with filter
gh issue list --label "needs-triage" --state open

# Close
gh issue close 42 --reason "completed"
```

See `references/issues.md` for full API coverage, bulk operations, search syntax, and issue templates.

**Templates:**
- `templates/bug-report.md` — structured bug report
- `templates/feature-request.md` — feature request format

---

## 4. PR Workflow (`references/pr-workflow.md`)

Complete lifecycle: branch → commit → push → PR → CI → merge.

```bash
# Branch and push
git checkout -b feat/new-feature
git add -A && git commit -m "feat: add new feature"
git push -u origin HEAD

# Create PR
gh pr create --title "feat: add new feature" --body "Summary..." --label "enhancement"

# Monitor CI
gh pr checks --watch

# Merge
gh pr merge --squash --delete-branch
```

**Templates:**
- `templates/pr-body-feature.md` — feature PR description format
- `templates/pr-body-bugfix.md` — bug-fix PR description format

**References:**
- `references/ci-troubleshooting.md` — common CI failure patterns (test failures, lint, build, timeout, permissions)
- `references/conventional-commits.md` — commit message format (feat/fix/refactor/docs/test/ci/chore/perf)

---

## 5. Repository Management (`references/repo-management.md`)

Create, clone, fork, configure repos; manage releases, secrets, branch protection, and GitHub Actions.

```bash
# Clone
git clone https://github.com/owner/repo.git

# Create and push
gh repo create my-project --public --clone

# Fork and sync
gh repo fork owner/repo --clone
git fetch upstream && git merge upstream/main

# Release
gh release create v1.0.0 --title "v1.0.0" --generate-notes

# Secrets
gh secret set API_KEY --body "your-secret-value"

# Branch protection (via API, see references/repo-management.md)
```

**References:**
- `references/repo-management.md` — full repo operations (create, fork, settings, releases, secrets encryption, GitHub Actions workflows, gists)
- `references/github-api-cheatsheet.md` — condensed REST API endpoint reference for all GitHub operations
- `references/codebase-metrics.md` — pygount usage for repo language/code analysis

---

## Quick Reference: gh/curl Fallback Table

| Action | gh command | curl endpoint |
|--------|-----------|---------------|
| List issues | `gh issue list` | `GET /repos/{o}/{r}/issues` |
| Create issue | `gh issue create` | `POST /repos/{o}/{r}/issues` |
| View PR | `gh pr view N` | `GET /repos/{o}/{r}/pulls/N` |
| Create PR | `gh pr create` | `POST /repos/{o}/{r}/pulls` |
| Merge PR | `gh pr merge --squash` | `PUT /repos/{o}/{r}/pulls/N/merge` |
| Add labels | `gh issue edit N --add-label` | `POST /repos/{o}/{r}/issues/N/labels` |
| Create repo | `gh repo create` | `POST /user/repos` |
| Create release | `gh release create` | `POST /repos/{o}/{r}/releases` |
| List workflows | `gh workflow list` | `GET /repos/{o}/{r}/actions/workflows` |
| Rerun CI | `gh run rerun ID` | `POST /repos/{o}/{r}/actions/runs/ID/rerun` |
| Set secret | `gh secret set KEY` | `PUT /repos/{o}/{r}/actions/secrets/KEY` |

---

## Supporting Files

- `scripts/gh-env.sh` — auth detection + environment setup script (source before any GitHub workflow)
- `references/auth.md` — full authentication setup (HTTPS tokens, SSH keys, gh CLI, credential helpers)
- `references/code-review.md` — code review workflows (local, PR, inline comments, formal review, checklist)
- `references/issues.md` — issue lifecycle (create, search, triage, labels, assign, close, bulk ops)
- `references/pr-workflow.md` — PR lifecycle (branch, commit, push, open, CI monitor, merge, auto-fix)
- `references/repo-management.md` — repo lifecycle (clone, create, fork, settings, fork sync, releases)
- `references/ci-troubleshooting.md` — CI failure diagnosis (test failures, lint, build, permissions, timeouts)
- `references/conventional-commits.md` — commit message type reference
- `references/github-api-cheatsheet.md` — REST API endpoint cheatsheet
- `references/codebase-metrics.md` — pygount repo analysis
- `templates/bug-report.md` — issue bug report template
- `templates/feature-request.md` — issue feature request template
- `templates/pr-body-feature.md` — feature PR body template
- `templates/pr-body-bugfix.md` — bug-fix PR body template

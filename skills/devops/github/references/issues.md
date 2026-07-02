# Issues Management

## Viewing Issues

```bash
# With gh
gh issue list
gh issue list --state open --label "bug"
gh issue list --assignee @me
gh issue list --search "authentication error" --state all
gh issue view 42

# With curl
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GH_OWNER/$GH_REPO/issues?state=open&per_page=20" \
  | python3 -c "import sys, json
for i in json.load(sys.stdin):
    if 'pull_request' not in i:
        labels = ', '.join(l['name'] for l in i['labels'])
        print(f'#{i[\"number\"]:5}  {i[\"state\"]:6}  {labels:30}  {i[\"title\"]}')"
```

## Creating Issues

```bash
gh issue create \
  --title "Login redirect ignores ?next= parameter" \
  --body "## Description\n..." \
  --label "bug,backend" \
  --assignee "username"
```

### Bug Report Template
See `templates/bug-report.md`.

### Feature Request Template
See `templates/feature-request.md`.

## Managing Issues

```bash
# Labels
gh issue edit 42 --add-label "priority:high,bug"
gh issue edit 42 --remove-label "needs-triage"

# Assignment
gh issue edit 42 --add-assignee @me

# Comments
gh issue comment 42 --body "Investigated, root cause in auth middleware."

# Close / Reopen
gh issue close 42 --reason "completed"
gh issue reopen 42

# List available labels
gh label list  # or curl /repos/o/r/labels
```

## Linking Issues to PRs

Keywords in PR body auto-close issues on merge:
```
Closes #42
Fixes #42
Resolves #42
```

## Issue Triage Workflow

1. List untriaged: `gh issue list --label "needs-triage" --state open`
2. Read and categorize each issue
3. Apply labels and priority
4. Assign if owner is clear
5. Comment with triage notes

## Bulk Operations

```bash
# Close all issues with a label
gh issue list --label "wontfix" --json number --jq '.[].number' \
  | xargs -I {} gh issue close {} --reason "not planned"
```

## Quick Reference

| Action | gh | curl |
|--------|-----|------|
| List | `gh issue list` | `GET /repos/{o}/{r}/issues` |
| View | `gh issue view N` | `GET /repos/{o}/{r}/issues/N` |
| Create | `gh issue create` | `POST /repos/{o}/{r}/issues` |
| Add labels | `gh issue edit N --add-label` | `POST /repos/{o}/{r}/issues/N/labels` |
| Assign | `gh issue edit N --add-assignee` | `POST /repos/{o}/{r}/issues/N/assignees` |
| Comment | `gh issue comment N` | `POST /repos/{o}/{r}/issues/N/comments` |
| Close | `gh issue close N` | `PATCH /repos/{o}/{r}/issues/N` |
| Search | `gh issue list --search "..."` | `GET /search/issues?q=...` |

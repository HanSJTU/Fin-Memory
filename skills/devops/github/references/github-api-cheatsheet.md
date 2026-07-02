# GitHub REST API Cheatsheet

Base: `https://api.github.com` — Auth: `-H "Authorization: token $GITHUB_TOKEN"`

## Repositories

| Action | Method | Endpoint |
|--------|--------|----------|
| Get repo | GET | `/repos/{owner}/{repo}` |
| Create (user) | POST | `/user/repos` |
| Create (org) | POST | `/orgs/{org}/repos` |
| Update | PATCH | `/repos/{owner}/{repo}` |
| Fork | POST | `/repos/{owner}/{repo}/forks` |
| From template | POST | `/repos/{owner}/{template}/generate` |

## Pull Requests

| Action | Method | Endpoint |
|--------|--------|----------|
| List | GET | `/repos/{owner}/{repo}/pulls` |
| Create | POST | `/repos/{owner}/{repo}/pulls` |
| Get | GET | `/repos/{owner}/{repo}/pulls/{number}` |
| List files | GET | `/repos/{owner}/{repo}/pulls/{number}/files` |
| Merge | PUT | `/repos/{owner}/{repo}/pulls/{number}/merge` |
| Create review | POST | `/repos/{owner}/{repo}/pulls/{number}/reviews` |
| Inline comment | POST | `/repos/{owner}/{repo}/pulls/{number}/comments` |

## Issues

| Action | Method | Endpoint |
|--------|--------|----------|
| List | GET | `/repos/{owner}/{repo}/issues` |
| Create | POST | `/repos/{owner}/{repo}/issues` |
| Update | PATCH | `/repos/{owner}/{repo}/issues/{number}` |
| Comment | POST | `/repos/{owner}/{repo}/issues/{number}/comments` |
| Labels | POST | `/repos/{owner}/{repo}/issues/{number}/labels` |
| Remove label | DELETE | `/repos/{owner}/{repo}/issues/{number}/labels/{name}` |
| Assignees | POST | `/repos/{owner}/{repo}/issues/{number}/assignees` |
| Search | GET | `/search/issues?q={query}+repo:{o}/{r}` |

## CI / Actions

| Action | Method | Endpoint |
|--------|--------|----------|
| List workflows | GET | `/repos/{o}/{r}/actions/workflows` |
| List runs | GET | `/repos/{o}/{r}/actions/runs` |
| Download logs | GET | `/repos/{o}/{r}/actions/runs/{id}/logs` |
| Re-run | POST | `/repos/{o}/{r}/actions/runs/{id}/rerun` |
| Trigger dispatch | POST | `/repos/{o}/{r}/actions/workflows/{id}/dispatches` |
| Commit status | GET | `/repos/{o}/{r}/commits/{sha}/status` |

## Releases

| Action | Method | Endpoint |
|--------|--------|----------|
| List | GET | `/repos/{owner}/{repo}/releases` |
| Create | POST | `/repos/{owner}/{repo}/releases` |
| Upload asset | POST | `https://uploads.github.com/repos/{o}/{r}/releases/{id}/assets?name={fn}` |

## Secrets

| Action | Method | Endpoint |
|--------|--------|----------|
| List | GET | `/repos/{owner}/{repo}/actions/secrets` |
| Public key | GET | `/repos/{owner}/{repo}/actions/secrets/public-key` |
| Set | PUT | `/repos/{owner}/{repo}/actions/secrets/{name}` |

## Common curl Patterns

```bash
# GET
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO

# POST with JSON
curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/issues \
  -d '{"title": "...", "body": "..."}'

# PATCH
curl -s -X PATCH -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/issues/42 \
  -d '{"state": "closed"}'

# DELETE
curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/issues/42/labels/bug

# Parse JSON
curl -s ... | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['field'])"
```

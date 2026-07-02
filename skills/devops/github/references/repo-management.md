# Repository Management

## Cloning

```bash
git clone https://github.com/owner/repo.git
git clone --depth 1 https://github.com/owner/repo.git  # shallow
gh repo clone owner/repo
```

## Creating Repos

```bash
gh repo create my-project --public --clone
gh repo create my-org/my-project --public
gh repo create my-project --source . --public --push  # from existing dir

# From template
gh repo create my-app --template owner/template-repo --public --clone
```

## Forking

```bash
gh repo fork owner/repo --clone
git remote add upstream https://github.com/owner/repo.git

# Sync fork
git fetch upstream && git merge upstream/main && git push origin main
gh repo sync user/repo  # shortcut
```

## Repository Settings

```bash
gh repo edit --description "Updated description" --visibility public
gh repo edit --enable-wiki=false --enable-issues=true
gh repo edit --default-branch main
gh repo edit --add-topic "machine-learning,python"
```

## Branch Protection

```bash
# Set via curl
curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/branches/main/protection \
  -d '{
    "required_status_checks": {"strict": true, "contexts": ["ci/test", "ci/lint"]},
    "required_pull_request_reviews": {"required_approving_review_count": 1}
  }'
```

## Secrets Management

```bash
gh secret set API_KEY --body "your-secret-value"
gh secret set SSH_KEY < ~/.ssh/id_rsa
gh secret list
gh secret delete API_KEY
```

For curl (requires encryption with repo public key — use gh when possible).

## GitHub Actions

```bash
gh workflow list
gh run list --limit 10
gh run view <RUN_ID> --log-failed
gh run rerun <RUN_ID>
gh run rerun <RUN_ID> --failed
gh workflow run ci.yml --ref main
```

## Releases

```bash
gh release create v1.0.0 --title "v1.0.0" --generate-notes
gh release create v2.0.0-rc1 --draft --prerelease --generate-notes
gh release create v1.0.0 ./dist/binary --title "v1.0.0" --notes "Release notes"
gh release list
gh release download v1.0.0 --dir ./downloads
```

## Gists

```bash
gh gist create script.py --public --desc "Useful script"
gh gist list
```

## Codebase Metrics

```bash
pip install pygount
pygount --format=summary --folders-to-skip=".git,node_modules,venv" .
```

See `references/codebase-metrics.md` for full usage.

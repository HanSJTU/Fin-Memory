# GitHub Authentication Setup

## Detection Flow

```bash
# Check what's available
git --version
gh --version 2>/dev/null || echo "gh not installed"
gh auth status 2>/dev/null || echo "gh not authenticated"
git config --global credential.helper 2>/dev/null || echo "no git credential helper"
```

**Decision tree:**
1. If `gh auth status` shows authenticated → use `gh` for everything
2. If `gh` installed but not authenticated → use "gh auth" method
3. If `gh` not installed → use "git-only" method

## Method 1: Git-Only (HTTPS with PAT)

**Create a token** at https://github.com/settings/tokens — scope `repo` + `workflow`.

**Store it:**
```bash
git config --global credential.helper store
git ls-remote https://github.com/<user>/<any-repo>.git
# Enter username + token as password
```

**Cache in memory:**
```bash
git config --global credential.helper 'cache --timeout=28800'
```

**Embed in remote URL (per-repo):**
```bash
git remote set-url origin https://<user>:<token>@github.com/<owner>/<repo>.git
```

**Git identity:**
```bash
git config --global user.name "Their Name"
git config --global user.email "their-email@example.com"
```

## Method 2: SSH Key

```bash
ssh-keygen -t ed25519 -C "email@example.com" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub  # Add at https://github.com/settings/keys
ssh -T git@github.com
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

## Method 3: gh CLI

**Interactive:**
```bash
gh auth login
# Select: GitHub.com → HTTPS → Login via browser
```

**Token-based (headless):**
```bash
echo "TOKEN" | gh auth login --with-token
gh auth setup-git
```

## Using API Without gh

```bash
export GITHUB_TOKEN="<token>"
curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

Extract from git credentials:
```bash
grep "github.com" ~/.git-credentials | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|'
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `git push` asks for password | Use PAT as password, or switch to SSH |
| `Permission to X denied` | Token may lack `repo` scope |
| `Authentication failed` | Stale credentials — `git credential reject`, re-auth |
| `ssh: connect to host github.com port 22` | Use SSH over HTTPS port in `~/.ssh/config` |
| Multiple GitHub accounts | SSH aliases in `~/.ssh/config` or per-repo credential URLs |

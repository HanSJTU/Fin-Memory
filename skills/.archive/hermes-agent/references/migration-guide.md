# Hermes Agent Migration Guide

Use this when migrating Hermes Agent to a new machine — restoring memory, skills, config, and associated project repos.

## Migration Steps

### 1. Install Hermes Agent on new machine

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

### 2. Restore memory, skills, and config

If you keep a backup Git repo (e.g. `Fin-Memory`):

```bash
git clone git@github.com:YOUR_USER/YOUR_BACKUP_REPO.git ~/projects/backup
mkdir -p ~/.hermes/memories ~/.hermes/skills
cp ~/projects/backup/memories/MEMORY.md ~/.hermes/memories/
rsync -a --delete \
  --exclude='.hub/' --exclude='.usage.json' --exclude='.usage.json.lock' \
  ~/projects/backup/skills/ ~/.hermes/skills/
cp ~/projects/backup/config.yaml ~/.hermes/config.yaml
```

### 3. Clone associated project repos

```bash
git clone git@github.com:YOUR_USER/YOUR_PROJECT.git ~/projects/YOUR_PROJECT
```

### 4. Configure API keys

```bash
# Edit ~/.hermes/.env or use hermes auth
hermes model
```

### 5. Restore backup cron job

```bash
mkdir -p ~/.hermes/scripts
cp ~/projects/backup/sync-script.sh ~/.hermes/scripts/sync-backup.sh
chmod +x ~/.hermes/scripts/sync-backup.sh
```

Then create a cron job: schedule `0 5 * * *`, script `sync-backup.sh`, `no_agent=True`.

## Verification

```bash
hermes memory list          # Memories restored
hermes skills list          # Skills restored
hermes config check         # Config valid
```

## Auto-backup Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/home/ubuntu/projects/backup-repo"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

cd "$REPO_DIR"
git pull --rebase origin main 2>/dev/null || true

mkdir -p memories
cp "$HERMES_HOME/memories/MEMORY.md" memories/MEMORY.md
cp "$HERMES_HOME/config.yaml" config.yaml

rsync -a --delete \
    --exclude='.hub/' --exclude='.usage.json' --exclude='.usage.json.lock' --exclude='__pycache__/' \
    "$HERMES_HOME/skills/" skills/

TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')
git add -A
if git diff --cached --quiet; then
    echo "[sync] Nothing changed — skipping commit."
else
    git commit -m "auto-sync $TIMESTAMP"
    git push origin main
fi
```

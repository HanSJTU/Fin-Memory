# Fin-Memory Backup Setup

## What's backed up

| Asset | Path | Format |
|-------|------|--------|
| Memories | `~/.hermes/memories/MEMORY.md` | Single markdown file |
| Skills | `~/.hermes/skills/` (recursive, excluding `.hub/` and `.usage.*`) | Directory tree with SKILL.md + references/ + templates/ + scripts/ |
| Config | `~/.hermes/config.yaml` | YAML |

## The sync script

The sync script lives at `~/projects/fin-memory/sync-hermes-data.sh` (and
also at `~/.hermes/scripts/sync-fin-memory.sh` for cron job access).

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/home/ubuntu/projects/fin-memory"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

cd "$REPO_DIR"
git pull --rebase origin main 2>/dev/null || true

# Memories
mkdir -p memories
cp "$HERMES_HOME/memories/MEMORY.md" memories/MEMORY.md

# Config
cp "$HERMES_HOME/config.yaml" config.yaml

# Skills (excluding internal Hermes metadata)
rsync -a --delete \
    --exclude='.hub/' \
    --exclude='.usage.json' \
    --exclude='.usage.json.lock' \
    --exclude='__pycache__/' \
    "$HERMES_HOME/skills/" skills/

# Commit & push
TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')
git add -A
if git diff --cached --quiet; then
    echo "[sync] Nothing changed — skipping commit."
else
    git commit -m "auto-sync $TIMESTAMP"
    git push origin main
fi
```

## Cron job setup

Run this once after restoring the backup on a new machine:

```bash
# Copy the script into Hermes' scripts directory
mkdir -p ~/.hermes/scripts
cp ~/projects/fin-memory/sync-hermes-data.sh ~/.hermes/scripts/sync-fin-memory.sh
chmod +x ~/.hermes/scripts/sync-fin-memory.sh
```

Then create a cron job via the `cronjob` tool:

- **Schedule**: `0 5 * * *` (daily at 05:00 UTC+8)
- **Script**: `sync-fin-memory.sh`
- **Mode**: `no_agent=True` (pure script — no LLM needed)
- **Name**: "Fin-Memory daily sync"

## Verification

```bash
# Manual test
cd ~/projects/fin-memory && bash sync-hermes-data.sh

# Check last run
hermes cron list

# Verify repo content
git -C ~/projects/fin-memory log --oneline -3
git -C ~/projects/fin-memory diff --stat main..HEAD~1
```

## Tailoring for a different user

If you're forking this setup for your own use, change these in the script:
- `REPO_DIR` → your local clone path
- The remote URL → `git@github.com:YOUR_USER/Fin-Memory.git`

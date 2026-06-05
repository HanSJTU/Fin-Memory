#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
# Hermes Agent — daily memories & skills backup to Fin-Memory repo
#
# Run daily via cron. Backs up:
#   - MEMORY.md (persistent memory)
#   - config.yaml (Hermes configuration)
#   - all skills (SKILL.md + references/ + templates/ + scripts/)
#
# On a new machine:
#   git clone git@github.com:HanSJTU/Fin-Memory.git
#   cp -r Fin-Memory/memories/*   ~/.hermes/memories/
#   cp -r Fin-Memory/skills/*     ~/.hermes/skills/
#   cp    Fin-Memory/config.yaml  ~/.hermes/config.yaml
# ──────────────────────────────────────────────────────────────────────────

set -euo pipefail

REPO_DIR="/home/ubuntu/projects/fin-memory"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

cd "$REPO_DIR"

# Pull latest to minimise merge headaches
git pull --rebase origin main 2>/dev/null || true

# ── 1. Memories ──────────────────────────────────────────────────────────
mkdir -p memories
if [[ -f "$HERMES_HOME/memories/MEMORY.md" ]]; then
    cp "$HERMES_HOME/memories/MEMORY.md" memories/MEMORY.md
    echo "[sync] memories/MEMORY.md  ✓"
fi

# ── 2. Config ────────────────────────────────────────────────────────────
if [[ -f "$HERMES_HOME/config.yaml" ]]; then
    cp "$HERMES_HOME/config.yaml" config.yaml
    echo "[sync] config.yaml  ✓"
fi

# ── 3. Skills (excluding internal .hub / .usage files) ───────────────────
rsync -a --delete \
    --exclude='.hub/' \
    --exclude='.usage.json' \
    --exclude='.usage.json.lock' \
    --exclude='__pycache__/' \
    "$HERMES_HOME/skills/" skills/
echo "[sync] skills/  ✓ ($(find skills -name 'SKILL.md' | wc -l) skills)"

# ── 4. Commit & push ─────────────────────────────────────────────────────
TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')
git add -A
if git diff --cached --quiet; then
    echo "[sync] Nothing changed — skipping commit."
else
    git commit -m "auto-sync $TIMESTAMP"
    git push origin main 2>&1
    echo "[sync] Pushed ✓"
fi

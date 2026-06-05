---
name: hermes-migration-guide
description: Hermes Agent 跨机器迁移指南 — 在新服务器上丝滑恢复全部记忆、技能、配置和研究仓库
---

# Hermes Agent 迁移指南

## 使用场景

当你需要在一台**全新的机器**上复现当前的 Hermes Agent 环境时，按照以下步骤操作即可恢复全部记忆、技能和配置，无缝继续研究工作。

## 先决条件

- 新机器已安装 Python 3.11+
- 新机器已安装 `pip`
- 新机器的 SSH 公钥已添加到你的 GitHub 账户

## 迁移步骤

### Step 1: 安装 Hermes Agent

```bash
pip install hermes-agent
```

### Step 2: 克隆 Fin-Memory 仓库（恢复记忆+技能+配置）

```bash
git clone git@github.com:HanSJTU/Fin-Memory.git ~/projects/fin-memory
```

### Step 3: 恢复记忆、技能和配置

```bash
# 创建目标目录
mkdir -p ~/.hermes/memories ~/.hermes/skills

# 恢复记忆
cp ~/projects/fin-memory/memories/MEMORY.md ~/.hermes/memories/

# 恢复技能（所有自定义和内置技能）
rsync -a --delete \
  --exclude='.hub/' \
  --exclude='.usage.json' \
  --exclude='.usage.json.lock' \
  ~/projects/fin-memory/skills/ ~/.hermes/skills/

# 恢复配置文件
cp ~/projects/fin-memory/config.yaml ~/.hermes/config.yaml

# 恢复备份脚本
mkdir -p ~/.hermes/scripts
cp ~/projects/fin-memory/sync-hermes-data.sh ~/.hermes/scripts/sync-fin-memory.sh
chmod +x ~/.hermes/scripts/sync-fin-memory.sh
```

### Step 4: 克隆 Quant-Researcher 仓库（研究项目代码+数据）

```bash
git clone git@github.com:HanSJTU/Quant-Researcher.git ~/projects/Quant-Researcher
cd ~/projects/Quant-Researcher
python3 -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
```

### Step 5: 配置 API Key

```bash
# 方式A: DeepSeek（推荐，无需海外 API）
export LLM_PROVIDER=openai
export LLM_API_KEY=***
export LLM_BASE_URL=https://api.deepseek.com
export AI_QUANT_LAB_MODEL=deepseek-chat

# 方式B: Claude
cp .env.example .env
# 编辑 .env 填入 ANTHROPIC_API_KEY
```

### Step 6: 恢复每日备份 Cron Job

在 Hermes 中执行：
```
创建 cron job，每日 5:00 运行 sync-fin-memory.sh，使用 no_agent=True
```

### Step 7: 验证

```bash
# 验证记忆恢复
hermes memory list

# 验证技能恢复
hermes skill list

# 验证研究项目
cd ~/projects/Quant-Researcher
python -m pytest tests/ -q

# 快速测试研究循环（使用合成数据）
python -m ai_quant_lab.run --iterations 5 --target 1
```

## 仓库清单

| 仓库 | 用途 | 位置 |
|------|------|------|
| `HanSJTU/Fin-Memory` | Hermes 记忆、技能、配置备份 | `~/projects/fin-memory` |
| `HanSJTU/Quant-Researcher` | 量化策略研究项目 + BTC 行情数据 | `~/projects/Quant-Researcher` |

## 注意事项

- Fin-Memory 每天 5:00 UTC+8 自动同步，迁移前建议先手动运行一次备份脚本确保数据最新
- 市场数据文件（`market_data/`）已经包含在 Quant-Researcher 仓库中
- 项目使用 `feat/llm-provider` 分支，支持 DeepSeek / Claude 切换

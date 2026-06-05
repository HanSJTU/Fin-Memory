# Fin-Memory

> Hermes Agent 的持久化记忆、技能与配置备份仓库

每天自动同步，用于：
1. **跨机器迁移** — 在新服务器上部署 Hermes Agent 后，克隆此仓库即可恢复全部记忆和技能
2. **历史回溯** — 查看过去的记忆变更和技能演化

## 目录结构

```
├── memories/          Hermes 持久化记忆 (MEMORY.md)
├── skills/            Hermes 技能文件 (SKILL.md + 引用/模板/脚本)
├── config.yaml        Hermes Agent 配置文件
└── sync-hermes-data.sh  自动同步脚本
```

## 迁移到新机器

```bash
# 1. 部署 Hermes Agent
pip install hermes-agent

# 2. 克隆 Fin-Memory
git clone git@github.com:HanSJTU/Fin-Memory.git

# 3. 恢复数据
cp Fin-Memory/memories/MEMORY.md   ~/.hermes/memories/
cp -r Fin-Memory/skills/*          ~/.hermes/skills/
cp Fin-Memory/config.yaml          ~/.hermes/config.yaml

# 4. 同时克隆研究仓库
git clone git@github.com:HanSJTU/Quant-Researcher.git
```

# Agent Context Migrator (智能体上下文迁移器)

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/ides/openclaw.md)

> Languages: [English](README.md) · **中文** · [日本語](README.ja-JP.md) · [Español](README.es.md)

在 **Cursor、Claude Code、Codex、Cline、Windsurf、Copilot、Gemini CLI** 以及数十种主流 AI 编程工具之间，进行**离线、带预览、可回滚**的 Skills、规则/指令和 MCP 配置迁移与跨设备备份恢复。

---

## ⚡ 快速安装

通过 ClawHub / OpenClaw 一键安装：

```bash
openclaw skills install @luckycat133/agent-skills-setup
```

或直接从 GitHub 安装：

```bash
git clone --depth 1 --branch v0.9.1 https://github.com/Luckycat133/skills-repo.git

openclaw skills install \
  ./skills-repo/skills/agent-skills-setup \
  --as agent-skills-setup
```

---

## 💬 对你的 Agent 说这些话

> *“把当前项目 Cursor 的 Skills、规则和 MCP 迁到 Claude Code。”*

> *“我要换电脑，备份所有已安装 AI 编程工具的可迁移上下文。”*

> *“恢复这个 ACB 备份包到新电脑上已安装的 IDE。”*

---

## 🛡️ 迁移安全边界

| 分级 | 对象类型 | 行为说明 |
|---|---|---|
| **全自动迁移** | Skills、Instructions/Rules (`CLAUDE.md`, `.cursorrules`)、本地 stdio MCP | Skills 完整复制并验证，规则语义转换与损失报告，MCP 仅支持本地 stdio 子集安全转换。 |
| **显式授权迁移** | 插件包复制 (`--include-plugins`)、会话总结交接 (`--include-session`) | 需显式传参；仅传输结构化白名单字段，拒绝未审查状态。 |
| **手动核对清单** | 远程 MCP (HTTP/SSE)、云端/UI 配置、Prompts、Commands、Agents、Hooks | 生成具体的逐步重建清单；绝不自动写入未经验证的可执行脚本。 |
| **绝对不迁移** | API Key、OAuth Token、凭据、信任状态、原始聊天历史、生成式记忆 | 严格密钥扫描、子对象隔离与 Fail-closed 排除；字面凭据在迁移前自动剔除或脱敏。 |

---

## 🚀 核心命令

- **`migrate`**：一键端到端迁移：`detect` -> `inventory` -> `plan` -> `apply` -> `verify`。
- **`snapshot`**：捕获原子、便携的 **Agent Context Bundle (ACB)**，严格保持 1:1 清单文件绑定。
- **`restore`**：基于 ACB 备份包在目标设备上生成双端计划并执行恢复，带 TOCTOU 防篡改保护。
- **`bundle-sign` & `bundle-verify`**：使用 Ed25519 密钥签名并验证 ACB 备份包完整性。
- **`doctor`**：离线诊断 ACB 运行依赖及缺失的可执行工具。

---

## 🌟 支持与赞助

如果 Agent Context Migrator 帮您节省了配置或换机时间，欢迎 ⭐ **在 GitHub 上给本项目点个 Star**，让更多开发者发现它！

您也可以通过 [GitHub Sponsors](https://github.com/sponsors/Luckycat133) 或 [爱发电 (Afdian) / Ko-fi](https://afdian.com/a/Luckycat133) 支持持续开发。

---

## 仓库结构

```text
skills-repo/
├── docs/                         # 维护指南与发布检查清单
├── scripts/                      # 仓库级验证工具
└── skills/agent-skills-setup/    # 规范技能源码
    ├── SKILL.md                  # Skill 描述与入口
    ├── references/               # Profile 注册表 v2 与适配器规范
    └── scripts/                  # 迁移核心引擎与 ACB 工具
```

## 开发与验证

1. 请编辑 `skills/agent-skills-setup/`，不要直接修改根目录生成的仓库指针。
2. 运行全量测试：`bash validate-all.sh`。
3. 修改规范 Skill 后运行：`bash scripts/sync-root-mirror.sh` 更新根指针。
4. 所有验证通过后再提交合并。

## 项目资料

- [贡献指南](CONTRIBUTING.md)
- [安全策略](SECURITY.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [开源协议](LICENSE)

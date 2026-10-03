# Agent Skills Setup（智能体技能配置）

> 跨 Cursor、Claude Code、Codex、Cline、Windsurf、Copilot、Gemini CLI 等数十种 AI 编程工具的上下文迁移。

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/ides/openclaw.md)

> Languages: [English](README.md) · **中文** · [日本語](README.ja-JP.md) · [Español](README.es.md)

版本：**0.10.2**。变更见[发行记录](CHANGELOG.md#0102---2026-10-03)；GitHub 安装示例使用 `v0.10.2` 标签。

在 **Cursor、Claude Code、Codex、Cline、Windsurf、Copilot、Gemini CLI** 以及数十种主流 AI 编程工具之间，进行**离线、带预览、可回滚**的 Skills、规则/指令和 MCP 配置迁移与跨设备备份恢复。

![Agent Skills Setup — 15-second demo: detect → plan → secret redaction → apply → verify](skills/agent-skills-setup/assets/demo.gif)

---

## ⚡ 快速安装

通过 ClawHub / OpenClaw 一键安装：

```bash
openclaw skills install @luckycat133/agent-skills-setup
```

或直接从 GitHub 安装：

```bash
git clone --depth 1 --branch v0.10.2 https://github.com/Luckycat133/skills-repo.git

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

- **`migrate`**：清点选定产品，保存计划，再应用并校验结果。
- **`snapshot`**：捕获原子、便携的 **Agent Context Bundle (ACB)**，严格保持 1:1 清单文件绑定。
- **`restore`**：基于 ACB 备份包在目标设备上生成双端计划并执行恢复，带 TOCTOU 防篡改保护。
- **`bundle-keygen`、`bundle-sign` 和 `bundle-verify`**：生成 Ed25519 密钥、签名备份包，并通过可信公钥验证完整性。
- **`doctor`**：离线诊断 ACB 运行依赖及缺失的可执行工具。

ACB 保留普通文件权限（含可执行位），并兼容没有权限元数据的旧备份。
保存的恢复计划绑定备份身份；MCP 预览列出新增、移除及同名服务的字段变化，不展示凭据值。
指令/MCP 转换出现已报告损失时默认延后，明确接受后才应用。
`doctor` 同时列出包、扩展、平台和手动安装需求，可执行文件检查不代表运行验收。

`detect` / `inventory` 用于发现与清点，`plan` 保存预览，`apply` 执行已审阅计划，
`verify` / `rollback` 校验与恢复。完整示例见[命令指南](skills/agent-skills-setup/references/cli-workflow.md)，
各 profile 的验证范围见[兼容性矩阵](docs/agent-skills-setup/compatibility-matrix.md)。
远程 MCP 和云端设置生成手动重建清单；插件与交接迁移各自需要显式 opt-in。

---

## 🌟 支持与赞助

如果 Agent Skills Setup 帮您节省了配置或换机时间，欢迎 ⭐ **在 GitHub 上给本项目点个 Star**，让更多开发者发现它！

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
2. 修改规范 Skill 后运行：`bash scripts/sync-root-mirror.sh` 更新根指针。
3. 运行全量测试：`bash validate-all.sh`。
4. 所有验证通过后再提交合并。

规模测试使用 `python3 scripts/benchmark-scale.py --sizes 10,100,1000`，在隔离夹具中
检查迁移、保存计划后的恢复、完整内容及回滚。耗时仅作实测记录，不设置 CI 时间阈值。
可加 `--report /path/to/new-report.json` 和 `--keep-workspace` 保存证据；不读取真实 Agent 配置。

## 项目资料

- [更新记录](CHANGELOG.md)
- [发布检查清单](docs/agent-skills-setup/release-checklist.md)
- [贡献指南](CONTRIBUTING.md)
- [安全策略](SECURITY.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [开源协议](LICENSE)

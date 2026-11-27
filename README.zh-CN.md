# Agent Skills Setup

[English](README.md) · [日本語](README.ja-JP.md) · [Español](README.es.md)

`agent-skills-setup` 是一个面向现有 AI 编程代理的可移植
[Agent Skill](https://agentskills.io/specification)。它帮助宿主代理在不同 AI 编程 IDE、CLI
或新旧电脑之间迁移、转换或同步规则/指令、Agent Skills、MCP 服务配置、提示词、斜杠命令、
自定义子代理、Hooks、工作流、用户手写记忆以及 API Key / `.env` 密钥——**且全程不将任何明文密钥暴露给大模型上下文**。

## 架构与零上下文泄密设计

- **Agent-First + 零依赖标准库脚本**：仅分发精炼指令（`SKILL.md`）、按需加载参考文档
  （`references/`）、报告模板（`assets/`）以及单个 Python 3.11+ 标准库辅助脚本
  （`skills/agent-skills-setup/scripts/migrate_context.py`，含 PEP 723 元数据）。不包含已退役的
  `.acb` 私有包引擎、签名服务、SQLite 事务库、后台同步守护进程、自动安装器或遥测。
- **`0700`/`0600` 带外（Out-of-Band）安全密钥迁移**：默认通过磁盘到磁盘原子写入（目录 `0700`、
  文件与私有备份 `0600`）迁移 MCP `env`/`headers` 与 `.env*` 密钥，拦截向 Git 已追踪文件静默写入明文密钥，
  并在 `stdout` / `MIGRATION.md` 中**仅输出变量名、`has_secrets` 与 8 位 SHA-256 指纹前缀（`sha256[:8]`）**。
  若用户要求不复制密钥，传入 `--redact-secrets` 即可自动转为环境变量占位符。
- **90 个独立分体 IDE 参考文档 + 按类别渐进加载子文档（40 个声明式内置档案）**：将全部 90 个 IDE/CLI
  的路径与注意事项拆分为独立文档（`references/products/<id>.md`），并为主要多面体 IDE
  进一步拆分按类别按需读取的子文档（`references/products/<id>/<topic>.md`）；在脚本中以
  声明式配置驱动 **40** 个主流工具档案（通过 `inspect --list-profiles` 实时查看，
  包含 `antigravity`、`claude-code`、`codex`、`trae-cn`、`trae`、`kiro`、`junie`、
  `codebuddy`、`codebuddy-ide`、`qoder`、`qoder-cn`、`roo-code`、`augment-code`、
  `factory-droid`、`cursor`、`vscode`、`copilot-cli`、`gemini-cli`、`windsurf`、`cline`、
  `kilocode`、`zed`、`opencode`、`kimi-code`、`qwen-code`、`pi`、`continue`、`amp`、
  `goose`、`devin`、`warp`、`openhands`、`aider`、`comate`、`minimax-code`、
  `mistral-vibe`、`crush`、`forge`、`codely`、`zcode`），并配以通用原语 `sync-skills`、
  `patch-mcp`、`copy-files` 覆盖其余全部产品（目录收录仅代表文档路由，**不等同于真机运行时认证**）。
- **默认完整复制与零边界污染**：默认按值完整拷贝文件和目录（除非用户明确要求，绝不创建软链接），
  严格隔离未指定的 IDE，不自动生成 `.migration-review/` 或默认备份目录；对无法无损直转的
  配置输出 `agent_handoff` 交给宿主 Agent 结合对应 IDE 参考文档语义改写。

## 安装方式

只将 `skills/agent-skills-setup/` 复制到目标客户端官方支持的 Skills 目录（不要安装仓库根目录或 `dev/`）：

```bash
git clone https://github.com/Luckycat133/skills-repo.git
cp -R skills-repo/skills/agent-skills-setup /path/to/your-skills-dir/agent-skills-setup
```

## 一句话自然语言用法示例

- *“把我当前项目里的 Cursor 规则、Skills 和所有 MCP 配置（含 API Key）迁移到 Claude Code 和 Codex。”*
- *“导出我在 Antigravity、Claude Code 和 Codex 里的全部配置到 `~/context-transfer`，方便换电脑直接导入。”*
- *“在这台新电脑上从 `~/context-transfer` 恢复我的全部配置。”*
- *“把我在 Antigravity 的规则、Skills、Subagents、Workflows 和 MCP 等价迁移到 Claude Code 和 Codex。”*

## 验证与当前状态

运行 `bash validate-all.sh` 执行本地契约、极端边界、金丝雀密钥零泄漏、端到端工作流及打包边界校验。
候选版本 `0.11.0-dev` 尚未发布；原生 GUI/IDE 真机验收队列见 [docs/validation-status.md](docs/validation-status.md)。

[贡献](CONTRIBUTING.md) · [安全](SECURITY.md) · [许可证 (MIT)](LICENSE)

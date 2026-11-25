---
name: agent-skills-setup
description: >-
  Migrates, exports, restores, or syncs AI coding context — rules/instructions,
  Agent Skills, MCP servers, prompts, commands, workflows, custom agents, hooks,
  plugins, portable settings, scripts, user-authored memory, and .env secrets —
  across Antigravity, Claude Code, Codex, Trae CN, Cursor, VS Code, Gemini CLI,
  and 74+ tools without exposing secret values to LLM context. Make sure to use
  this skill whenever the user wants to export or back up IDE settings for a new
  computer, restore a transfer bundle, copy Skills or MCP across IDEs/CLIs, or
  convert rules (导出全部配置, 换电脑迁移, 迁移上下文, 技能迁移, 等价迁移,
  规则转换, MCP/密钥迁移).
license: MIT
metadata:
  version: "0.11.0-dev"
---

# Migrate AI Coding Context Safely

Use this skill to move prompts, commands, agents, hooks, workflows, plugins, portable
settings, scripts, manifests, rules, Skills, MCP configs, user-authored memory, and
`.env` / MCP credentials out-of-band on disk. Resolve `<SKILL_DIR>` relative to this
`SKILL.md` and run `python3 "<SKILL_DIR>/scripts/migrate_context.py"`.

## 1. Capability Tiers (pick the right path immediately)

| Tier | Tools | Supported actions |
| --- | --- | --- |
| **Deep full-sync** | `antigravity` (`anti`/`agy`), `claude-code` (`claude`/`cc`), `codex` (`cx`) | All categories + 3-way equivalent translation (`rules`, `SKILL.md`, workflows/commands/prompts, subagents, MCP, portable settings, `scripts/`, `plugins/`, manifests, memory). |
| **Standard built-in (16 total)** | Adds `trae-cn`, `cursor`, `vscode`, `copilot-cli`, `gemini-cli`, `windsurf`, `cline`, `kilocode`, `zed`, `opencode`, `kimi-code`, `qwen-code`, `pi` | Direct `inspect`, `migrate`, `export-device`, `import-device` across rules, Skills, commands/prompts, agents, hooks, MCP, and `.env` secrets. |
| **Other 74+ cataloged tools** | `codebuddy`, `qoder`, `kiro`, `trae`, `trae-work`, `junie`, `goose`, `warp`, etc. | Load only the matching `references/products/<family>.md`; use `sync-skills` for any `SKILL.md` dir and `patch-mcp` for any JSON/JSONC/TOML MCP map. |

## 2. Execution Loop (4 steps)

1. **Refresh & use the script as a black box**: Always pull the latest `skills/agent-skills-setup/`
   before running, and run `--help` instead of reading `migrate_context.py` source.
   Never open the secret files (`.env*`, credential-bearing `mcp*.json`, `~/.claude.json`,
   `~/.claude/settings.json`, `~/.codex/config.toml`) into LLM context — let the script transfer
   them in `0700`/`0600` mode (`sha256[:8]` stdout only) because raw keys poison prompt logs.
2. **Inspect & preview before mutating**: Run `inspect --summary` when inventory is unclear;
   add `--dry-run` whenever the user asks for a preview (preview requests make no target changes).
   Add `--redact-secrets` when told not to copy API keys.
3. **Run the exact subcommand from the Decision Tree**:

| Task | Command (`migrate` / `sync-skills` / `patch-mcp` write by default; add `--dry-run` to preview) |
| --- | --- |
| **Inspect** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" inspect --workspace . --profiles anti,claude,codex --summary` |
| **Export computer** (`--output` optional) | `python3 "<SKILL_DIR>/scripts/migrate_context.py" export-device --profiles anti,claude,codex --scope all --workspace . --output ~/context-transfer` |
| **Restore computer** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" import-device --input ~/context-transfer --target same --workspace .` |
| **Cross-IDE migrate** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" migrate --source claude --target trae-cn --workspace . --scope all` |
| **Copy Skills to any tool** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" sync-skills --src-profile claude --scope user --dst-dir ~/.trae-cn/skills` |
| **Copy MCP to any tool** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" patch-mcp --src-file ~/.claude.json --src-key-path mcpServers --dst-file ~/Library/Application\ Support/Trae\ CN/User/mcp.json --dst-key-path mcpServers` |

4. **Check exit codes & verify honestly**: Exit `0` prints `totals` (`migrated`/`noop`/`conflict`/`parked_draft`/`deferred`) plus `excluded` — never stop on an isolated `conflict` or `deferred`, report both clearly. Exit `2` means invalid flags or a safety refusal (stop and explain). Exit `3` occurs only with `--strict-conflicts`. Report Syntax / Native discovery / Activation / Runtime separately via [verification](references/verification.md).

## 3. Safety & Semantic Guardrails

- Re-read [CLI workflow](references/cli-workflow.md) for retired engine boundaries and [Registry v2](references/registry-v2.md) before citing archived claims.
- **Keep scope intact**: Never widen file-glob or `@Rule`/manual triggers into always-on rules (`--allow-broaden-scope` only if user asks). Park hooks, sidecars, and Codex `.rules` in `.migration-review/` unless `--activate-hooks` is authorized.
- **Always exclude**: Chat histories, `*.jsonl` transcripts, SQLite/LevelDB DBs, caches, OAuth/JWT tokens, built-in system skills, and `alwaysAllow`/`trust`/`permissions` grants.

## 4. On-Demand References (1-hop progressive disclosure)

- Core guides: [products.md](references/products.md), [discovery.md](references/discovery.md), [instructions.md](references/instructions.md), [mcp.md](references/mcp.md), [other-context.md](references/other-context.md), [device-transfer.md](references/device-transfer.md), [verification.md](references/verification.md).
- Templates: [device-readme.md](assets/device-readme.md), [migration-report.md](assets/migration-report.md).
- Product families (load only requested source/target): [Claude](references/products/anthropic.md), [Codex/ChatGPT](references/products/openai.md), [Cursor](references/products/cursor.md), [Copilot/VS Code](references/products/copilot.md), [Gemini CLI/Assist](references/products/google-cli-assist.md), [Google IDE/cloud](references/products/google-ide-cloud.md), [JetBrains/Xcode](references/products/jetbrains-xcode.md), [AWS/Kiro](references/products/aws.md), [Cline/Kilo/Roo](references/products/cline-kilo-roo.md), [Devin/Windsurf](references/products/devin-windsurf.md), [Continue/Zed](references/products/continue-zed.md), [OpenCode](references/products/opencode.md), [Alibaba/Qwen/Qoder](references/products/alibaba.md), [Tencent](references/products/tencent.md), [TRAE](references/products/trae.md), [China coding tools](references/products/china-coding.md), [China identity checks](references/products/china-discovery.md), [Terminal agents](references/products/terminal-agents.md), [Factory/Augment](references/products/factory-augment.md), [Amp/OpenHands](references/products/amp-openhands.md), [Warp](references/products/warp.md), [OpenClaw/Hermes](references/products/openclaw-hermes.md), [Letta](references/products/letta.md), [Enterprise clients](references/products/enterprise.md), [Zencoder](references/products/zencoder.md), [Cloud builders](references/products/cloud-builders.md), [Blackbox/Pieces](references/products/blackbox-pieces.md), [Editor plugins](references/products/editor-plugins.md), [Legacy tools](references/products/legacy.md), [New clients](references/products/new-clients.md).

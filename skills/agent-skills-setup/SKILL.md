---
name: agent-skills-setup
description: >-
  Migrates, exports, restores, or syncs AI coding context — rules/instructions,
  Agent Skills, MCP servers, prompts, commands, workflows, custom agents, hooks,
  plugins, portable settings, scripts, user-authored memory, and .env secrets —
  across Antigravity, Claude Code, Codex, Cursor, VS Code, Gemini CLI, and 75+
  tools without exposing secret values to LLM context. Use when exporting all IDE
  settings for a new computer, restoring a transfer bundle, or converting context
  across IDEs (导出全部配置, 换电脑迁移, 迁移上下文, 等价迁移, 规则转换, MCP/密钥迁移).
license: MIT
metadata:
  version: "0.11.0-dev"
---

# Migrate AI Coding Context Safely

Moves selected user-authored context — prompts, commands, agents, hooks, workflows,
plugins, portable settings, scripts, manifests, user-authored memory, and (unless told
otherwise) `.env` / MCP credentials out-of-band on disk — across IDEs or computers.
Resolve `<SKILL_DIR>` relative to this `SKILL.md`.

## Use the helper script as a black box

Run `python3 "<SKILL_DIR>/scripts/migrate_context.py" --help` (auto-bootstraps Python
3.11+ or `uv`; zero dependencies) instead of reading the script source or raw secrets:

- **Never read raw secret files into LLM context**: Do **not** `cat`, view, or print
  `.env*`, credential-bearing `mcp.json`, `mcp_config.json`, `~/.claude.json`,
  `~/.claude/settings.json`, or `~/.codex/config.toml` when migrating secrets. To pack,
  export, or import credentials, run `migrate_context.py` — never open the secret
  files yourself to move them (`0700` dirs, `0600` files, `sha256[:8]` stdout only).
- **Refresh before use**: pull the latest `skills/agent-skills-setup/` from upstream
  and check `metadata.version`; a stale copy misses path and schema fixes.
- Pass `--redact-secrets` when told not to copy keys.
  Preview requests make no target changes (`--dry-run`). For native commands/old CLI logs read
  [CLI workflow](references/cli-workflow.md); for archived claims read
  [Registry v2 interpretation](references/registry-v2.md).

## Decision tree (run directly)

| Task | Command (replace `<SKILL_DIR>` and paths) |
| --- | --- |
| **Inspect** (`--summary` for compact counts) | `python3 "<SKILL_DIR>/scripts/migrate_context.py" inspect --workspace . --profiles anti,claude,codex --summary` |
| **Export for new computer** (`--output` optional) | `python3 "<SKILL_DIR>/scripts/migrate_context.py" export-device --profiles anti,claude,codex --scope all --workspace . --output ~/context-transfer` |
| **Restore on new computer** (`--activate-hooks` if approved) | `python3 "<SKILL_DIR>/scripts/migrate_context.py" import-device --input ~/context-transfer --target same --workspace .` |
| **3-way / cross-IDE migration** (`anti`, `claude`, `codex`, `cursor`, `vscode`, `gemini`, `windsurf`, `cline`, `kilo`, `zed`, `opencode`, `kimi`, `qwen`, `pi`) | `python3 "<SKILL_DIR>/scripts/migrate_context.py" migrate --source anti --target claude,codex --workspace . --scope all` |
| **Other cataloged MCP client** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" patch-mcp --src-file ~/.junie/mcp/mcp.json --src-key-path mcpServers --dst-file .vscode/mcp.json --dst-key-path servers` |

## Semantic & safety invariants

- Re-read authorized source/target before writing; verify syntax, discovery, activation,
  and runtime separately via [verification](references/verification.md).
- **Preserve activation & scope**: Keep `always_on`, file-glob rules (Antigravity
  `trigger: glob`, Claude `paths`, Cursor `globs`, VS Code `applyTo`), model-selected
  rules (`trigger: model_decision` <-> on-demand `SKILL.md`), and manual rules
  (`trigger: manual` <-> `disable-model-invocation: true` / prompts) distinct. Never
  silently widen a file-scoped or manual rule into unconditional instructions.
- **3-way equivalence (`Antigravity <-> Claude Code <-> Codex`)**: Translates rules,
  Skills (synthesizing Antigravity `name`/`description` frontmatter when missing),
  workflows <-> commands <-> manual Skills, custom agent frontmatter/tools, and MCP
  (`serverUrl` / `timeoutSeconds` / `enabledTools` <-> `url` <-> TOML `[mcp_servers]`,
  deferring legacy SSE on Antigravity and renamed `env_vars` on Codex).
- **Isolate conflicts & keep untrusted code inactive**: Identical targets are `noop`;
  divergent targets record `conflict` per object while preserving siblings (`theme`,
  `approval_policy`, `permissions`, comments). Park hooks, sidecars, and Codex `.rules`
  in `.migration-review/` unless `--activate-hooks` is passed. Always exclude chat
  histories, `*.jsonl` transcripts, SQLite/LevelDB DBs, caches, OAuth tokens, and
  `alwaysAllow`/`trust`/`permissions` grants.

## Load only the reference needed (1-hop progressive disclosure)

- Core guides: [products.md](references/products.md), [discovery.md](references/discovery.md), [instructions.md](references/instructions.md), [mcp.md](references/mcp.md), [other-context.md](references/other-context.md), [device-transfer.md](references/device-transfer.md), [verification.md](references/verification.md).
- Templates: [device-readme.md](assets/device-readme.md), [migration-report.md](assets/migration-report.md).
- Product families (load only the requested source/target):
  - [Claude](references/products/anthropic.md), [Codex/ChatGPT](references/products/openai.md), [Cursor](references/products/cursor.md), [Copilot/VS Code](references/products/copilot.md).
  - [Gemini CLI/Assist](references/products/google-cli-assist.md), [Google IDE/cloud](references/products/google-ide-cloud.md), [JetBrains/Xcode](references/products/jetbrains-xcode.md), [AWS/Kiro](references/products/aws.md).
  - [Cline/Kilo/Roo](references/products/cline-kilo-roo.md), [Devin/Windsurf](references/products/devin-windsurf.md), [Continue/Zed](references/products/continue-zed.md), [OpenCode](references/products/opencode.md).
  - [Alibaba/Qwen/Qoder](references/products/alibaba.md), [Tencent](references/products/tencent.md), [TRAE](references/products/trae.md), [China coding tools](references/products/china-coding.md), [China identity checks](references/products/china-discovery.md).
  - [Terminal agents](references/products/terminal-agents.md), [Factory/Augment](references/products/factory-augment.md), [Amp/OpenHands](references/products/amp-openhands.md), [Warp](references/products/warp.md).
  - [OpenClaw/Hermes](references/products/openclaw-hermes.md), [Letta](references/products/letta.md), [Enterprise clients](references/products/enterprise.md), [Zencoder](references/products/zencoder.md).
  - [Cloud builders](references/products/cloud-builders.md), [Blackbox/Pieces](references/products/blackbox-pieces.md), [Editor plugins](references/products/editor-plugins.md), [Legacy tools](references/products/legacy.md), [New clients](references/products/new-clients.md).

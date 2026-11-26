---
name: agent-skills-setup
description: >-
  Migrates, exports, restores, or syncs AI coding context — rules and
  instructions, Agent Skills, MCP servers, prompts, commands, workflows, custom
  agents, hooks, plugins, portable settings, scripts, user-authored memory, and
  .env secrets — across 26 built-in IDEs/CLIs (Antigravity, Claude Code, Codex,
  Cursor, VS Code, Copilot CLI, Gemini CLI, Windsurf, Cline, Kilo, Zed,
  OpenCode, Kimi Code, Qwen Code, Pi, TRAE CN, TRAE, Kiro, Junie, CodeBuddy,
  CodeBuddy IDE, Qoder, Qoder CN/Lingma, Roo Code, Augment, Factory Droid) plus
  64+ cataloged tools via full-file copy and out-of-band secret handling without
  exposing secret values to LLM context. Use whenever migrating IDE setups,
  backing up or restoring AI configs across machines, or syncing Skills/MCP.
license: MIT
metadata:
  version: "0.11.0-dev"
---

# Migrate AI Coding Context Without Re-Searching Docs

Use `python3 "<SKILL_DIR>/scripts/migrate_context.py"` (resolve `<SKILL_DIR>` relative
to this `SKILL.md`) together with the self-contained cross-IDE mapping tables in
`references/` so you never need to re-read vendor docs on migration tasks.

## 1. Non-negotiable invariants

1. **Full copy by default**: Copy complete files and directories by value — never
   create symlinks unless the user explicitly asks for symlinked management.
2. **Script-mediated secret privacy**: Always pull the latest `skills/agent-skills-setup/`
   before running, run `--help` instead of reading `migrate_context.py` source, and
   never open the secret files (`.env*`, credential-bearing `mcp*.json`, `~/.claude.json`,
   `~/.claude/settings.json`, `~/.codex/config.toml`) into LLM context. The script moves
   secrets disk-to-disk (`0700`/`0600`, `sha256[:8]` stdout only).
3. **Strict boundary & zero stray folders**: Except `export-device`, never create staging
   or default backup directories (`.migration-review/`, `~/.agent-skills-setup-backups/`)
   or touch IDEs outside the requested `--source`/`--target`/`--profiles`/`--scope`.
   Pass `--backup-dir <dir>` only when backups of overwritten targets are desired.
4. **Script for lossless, Agent for lossy**: Let `migrate_context.py` execute all
   lossless transfers (`migrated`/`noop`). Whenever `agent_handoff` items appear (hooks,
   non-1:1 rule triggers, Codex TOML/restricted agents, incompatible commands), inspect the
   non-secret source file and apply the mapping tables in `references/` yourself rather
   than letting a script brute-force lossy rewrites.

## 2. Coverage tiers (26 built-in profiles + 64 cataloged tools)

- **Tier 1 (deep full-sync)**: `antigravity` (`anti`/`agy`), `claude-code` (`claude`/`cc`),
  `codex` (`cx`) — all 14 categories + 3-way rules/Skills/agents/workflows/settings/memory.
- **Tier 2 (standard built-in, 26 total)**: adds `trae-cn`, `trae`, `kiro`, `junie`,
  `codebuddy`, `codebuddy-ide`, `qoder`, `qoder-cn`, `roo-code`, `augment-code`,
  `factory-droid`, `cursor`, `vscode`, `copilot-cli`, `gemini-cli`, `windsurf`, `cline`,
  `kilocode`, `zed`, `opencode`, `kimi-code`, `qwen-code`, `pi`.
- **Tier 3 (other 64+ cataloged clients)**: load only the matching `references/products/*.md`
  and use composable `sync-skills` (any `SKILL.md` folder) and `patch-mcp` (any MCP file).

## 3. Execution workflow (4 steps)

1. Run `inspect --summary` when inventory is unclear; pass `--dry-run` whenever preview is
   requested (preview requests make no target changes). Add `--redact-secrets` when told not to copy keys.
2. Execute one command from the Decision Tree (writes directly unless `--dry-run`):

| Task | Command (replace `<SKILL_DIR>` and paths) |
| --- | --- |
| **Inspect inventory** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" inspect --workspace . --profiles anti,claude,codex --summary` |
| **Export computer** (`--output` optional) | `python3 "<SKILL_DIR>/scripts/migrate_context.py" export-device --profiles anti,claude,codex --scope all --workspace . --output ~/context-transfer` |
| **Restore computer** (`--profiles` scopes IDEs) | `python3 "<SKILL_DIR>/scripts/migrate_context.py" import-device --input ~/context-transfer --target same --profiles claude,codex --workspace .` |
| **Cross-IDE migrate** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" migrate --source claude --target trae-cn --workspace . --scope all` |
| **Copy Skills to any tool** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" sync-skills --src-profile claude --scope user --dst-dir ~/.trae-cn/skills` |
| **Copy MCP to any tool** | `python3 "<SKILL_DIR>/scripts/migrate_context.py" patch-mcp --src-file ~/.claude.json --src-key-path mcpServers --dst-file ~/Library/Application\ Support/Trae\ CN/User/mcp.json --dst-key-path mcpServers` |

3. Handle exit codes: `0` returns `totals`, `conflicts` (isolated), `agent_handoff`,
   `deferred`, and `excluded`; `2` indicates invalid flags or a safety refusal; `3` is
   only triggered by `--strict-conflicts`.
4. Adapt any `agent_handoff` items using `references/instructions.md` and
   `references/other-context.md`, never widening glob/manual rules into unconditional
   instructions unless explicitly approved, and never activating hooks without `--activate-hooks`.
   Verify Syntax / Native discovery / Activation / Runtime separately via [verification](references/verification.md).

## 4. Built-in mapping tables & progressive references (1-hop)

- **Self-contained cross-IDE mapping tables**: [instructions.md](references/instructions.md), [mcp.md](references/mcp.md), [other-context.md](references/other-context.md), [device-transfer.md](references/device-transfer.md), [products.md](references/products.md), [discovery.md](references/discovery.md), [verification.md](references/verification.md), [CLI workflow](references/cli-workflow.md), [Registry v2](references/registry-v2.md).
- **Templates**: [device-readme.md](assets/device-readme.md), [migration-report.md](assets/migration-report.md).
- **Per-family edge notes (load only the requested client if Tier 3)**: [Claude](references/products/anthropic.md), [Codex/ChatGPT](references/products/openai.md), [Cursor](references/products/cursor.md), [Copilot/VS Code](references/products/copilot.md), [Gemini CLI/Assist](references/products/google-cli-assist.md), [Google IDE/cloud](references/products/google-ide-cloud.md), [JetBrains/Xcode](references/products/jetbrains-xcode.md), [AWS/Kiro](references/products/aws.md), [Cline/Kilo/Roo](references/products/cline-kilo-roo.md), [Devin/Windsurf](references/products/devin-windsurf.md), [Continue/Zed](references/products/continue-zed.md), [OpenCode](references/products/opencode.md), [Alibaba/Qwen/Qoder](references/products/alibaba.md), [Tencent](references/products/tencent.md), [TRAE](references/products/trae.md), [China coding tools](references/products/china-coding.md), [China identity checks](references/products/china-discovery.md), [Terminal agents](references/products/terminal-agents.md), [Factory/Augment](references/products/factory-augment.md), [Amp/OpenHands](references/products/amp-openhands.md), [Warp](references/products/warp.md), [OpenClaw/Hermes](references/products/openclaw-hermes.md), [Letta](references/products/letta.md), [Enterprise clients](references/products/enterprise.md), [Zencoder](references/products/zencoder.md), [Cloud builders](references/products/cloud-builders.md), [Blackbox/Pieces](references/products/blackbox-pieces.md), [Editor plugins](references/products/editor-plugins.md), [Legacy tools](references/products/legacy.md), [New clients](references/products/new-clients.md).

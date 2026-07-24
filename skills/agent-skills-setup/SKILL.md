---
name: agent-skills-setup
version: 0.5.7
license: MIT
description: >
  Migrate ALL AI assistant context between IDEs — MCP servers, rules/instructions,
  skills, slash commands, agents, hooks, and memory. Detects installed IDEs,
  converts formats across platforms, merges with a safe default (backup-before-change)
  and an explicit overwrite mode (rsync --delete); always verifies results.
  WHEN TO USE: ONLY when the user explicitly asks to migrate, move, transfer, copy,
  convert, or sync AI assistant context between IDEs — e.g. "migrate MCP config",
  "move skills from Cursor to Claude", "transfer rules from Windsurf to Cursor",
  "copy agents between IDEs". The skill previews every change with --dry-run and never
  writes files without an explicit --yes confirmation; it must not activate on vague
  or unrelated prompts.
triggers:
  - migrate mcp config
  - migrate ai ide settings
  - move skills from cursor to claude
  - transfer mcp servers between ide
  - migrate rules from windsurf to cursor
  - copy mcp config to another ide
  - migrate ai assistant context
  - move skills between ide
  - migrate ai ide context
  - migrate memory bank
capabilities:
  - read:  IDE/agent config dirs (MCP, rules, skills, commands, agents, hooks, memory)
  - write: IDE/agent config dirs (gated by --strategy: skip|backup|overwrite; default backup)
  - exec:  rsync, curl, node, tar/unzip (local migration + verification)
  - install: global software (OpenClaw runtime, clawhub) — ONLY with explicit --yes AND mandatory SHA-256 verification
  - remote: download+execute OpenClaw install.sh — ONLY with --yes AND mandatory OPENCLAW_INSTALL_SHA256
  - network: outbound HTTPS for downloads (gated by consent)
---

# AI IDE Context Migration

Migrate AI assistant context (MCP, rules, skills, commands, agents, hooks, memory) between IDEs with format conversion, safe merging, and verification.

> **MCP Protocol**: 2025-11-25 (stable). SSE deprecated; use Streamable HTTP for remote servers.
> **Full IDE Registry**: Read `references/ide-registry.md` for detailed per-IDE paths of all migration objects.

---

## Migration Objects

| # | Object | Description |
|---|--------|-------------|
| 1 | **mcp** | MCP server configurations (stdio/HTTP) |
| 2 | **rules** | Instructions/rules/context files |
| 3 | **skills** | SKILL.md skill directories |
| 4 | **commands** | Slash commands / prompt templates |
| 5 | **agents** | Subagent definitions |
| 6 | **hooks** | Lifecycle event hooks |
| 7 | **memory** | Persistent memory / memory banks / context files |

**Never migrate live secrets**: API keys, tokens, and bearer/OAuth credentials are always **BLANKED** during mcp/config migration (key names kept, values set to `""`) — they are never copied as-is. Also never migrate: chat history/transcripts, IDE UI settings, built-in vector indexes, workspace storage, SQLite databases.

---

## Execution Workflow

```
1. DETECT    — Scan filesystem for installed IDEs using detect_dir in IDE Registry
2. IDENTIFY  — Ask user: source IDE(s) and target IDE(s)
3. SCAN      — Read references/ide-registry.md; scan ALL migration objects for source IDE
4. DRY-RUN   — Generate migration preview: list objects, conversion plan, conflicts
5. CONFIRM   — Show preview to user; wait for explicit approval before writing
6. BACKUP    — Create .bak.TIMESTAMP copies of existing target files that will be modified
7. MIGRATE   — Execute migrations with format conversion per Object Conversion Rules
8. VERIFY    — Validate output files parse correctly; run verification commands; report results
```

**Critical rules**:
- Default to DRY-RUN. Never write without user confirmation.
- Always backup before overwriting. Use `.bak.<YYYYMMDDHHMMSS>` suffix.
- Merge, never overwrite. Conflicts renamed to `<name>_migrated`.
- Blank all secret values during migration (keep key names, set values to `""`): env vars (API keys, tokens), `Authorization`/bearer headers, `user:pass@` or `?key=` credential URLs, and DB connection strings. Secrets are redacted BEFORE the config is written to the target; the `[SECURITY]` warning in the report confirms this happened.
- Default migration scope is **LOW-RISK ONLY** (`skills`, `rules`, `prompts`). `mcp`/`config`/`project` — which can carry live credentials — are NEVER migrated unless the user explicitly passes `--objects mcp|config|project`; a security warning is shown and secrets are redacted when they are in scope.
- If source or target config is invalid JSON/TOML/YAML, STOP and report.

---

## IDE Quick Reference

Root key and format differences cause the most common migration errors. The full per-IDE registry — paths for **all** migration objects (not just MCP) across 50+ IDEs — lives in `references/ide-registry.md`. Load only what you need, e.g.:

```bash
grep -nE '^### ' references/ide-registry.md   # list every IDE section
```

The highest-risk formats to get wrong (see `references/ide-registry.md` for the complete list):

| IDE | MCP Root Key | Format | Config Path | Key Pitfall |
|-----|-------------|--------|-------------|-------------|
| VS Code Copilot | `servers` | JSON | `.vscode/mcp.json` | `servers` NOT `mcpServers`; needs `type:'stdio'\|'http'` |
| GitHub Copilot CLI | `mcpServers` | JSON | `~/.copilot/mcp-config.json` | Root key `mcpServers` + REQUIRES `type:'local'\|'http'`; no longer reads `.vscode/mcp.json` |
| Kilo Code | `mcpServers` | JSON | `~/.config/kilo/kilo.jsonc` (global) / `.kilocode/mcp.json` (project) | Global is `kilo.jsonc`; project MCP is `.kilocode/mcp.json` (project-relative) |
| OpenCode | `mcp` | JSON | `opencode.json` | `mcp` not `mcpServers`; command is array; env is `environment` |
| Windsurf | `mcpServers` | JSON | `~/.codeium/windsurf/mcp_config.json` | Uses `serverUrl` not `url` for HTTP |
| Continue.dev | `mcpServers` | YAML | `~/.continue/config.yaml` | mcpServers is ARRAY not object (only IDE using array) |
| bolt.new/bolt.diy | `servers` | JSON | `~/.boltai/mcp.json` | Root key `servers` NOT `mcpServers`! |

---

## Universal Standard Locations

Migrate to these FIRST for maximum cross-IDE compatibility:

| Path | Purpose | Loaded By |
|------|---------|-----------|
| `AGENTS.md` | Universal project instructions | Claude Code, Cursor, Copilot, Codex, Gemini, Zed 1.4.2+, JetBrains/Goose/Kiro/Aider/OpenCode/Augment/Forge/Void/OpenHands/Kimi Code/ZCode/Qoder CN/veCLI |
| `.agents/skills/<name>/SKILL.md` | Universal skills | Cursor, Copilot, Codex, Trae, antigravity, OpenCode, Augment, Amp, Zed, Comate, Kimi Code |
| `.claude/skills/<name>/SKILL.md` | Claude-compatible skills | Claude Code, Cursor (loads natively), OpenCode, Augment, Copilot |
| `.mcp.json` | Universal project MCP | Claude Code, Copilot CLI |
| `.vscode/mcp.json` | VS Code Copilot project-level MCP | Copilot (project); shareable with VS Code/Cursor/Cline/Zed via mcphub-nvim |

---

## Object Conversion Rules

### MCP Server Conversion

```
CONVERT_MCP(source_config, source_ide, target_ide):

  1. Read source MCP config using source_ide paths and root_key
  2. For each server entry:
     a. Extract: command, args, env, url, headers
     b. BLANK all secret values in env (keep key names, set to "")
     c. Convert to target format per root_key:
        - mcpServers (JSON object): direct copy
        - servers (JSON, VS Code Copilot): rename mcpServers→servers; add type:'stdio'|'http'
        - context_servers (JSON): rename root key (Zed)
        - mcp.servers (JSON): rename root key (ZCode; also accepts mcpServers)
        - mcp (JSON): rename; add type:'local'|'remote'; command→array; env→environment (OpenCode)
        - mcpServers ARRAY: object → [{name,type,...}] (Continue.dev ONLY)
        - servers (JSON, bolt.new/bolt.diy): rename mcpServers→servers (NO type field needed)
        - mcp_servers (TOML): → [mcp_servers.<name>] table; underscores (Codex/Helix)
        - extensions (YAML): rename; command→cmd, env→envs; add type (Goose)
        - amp: via `amp mcp add` CLI command (Sourcegraph Amp)
     d. Handle special fields:
        - Windsurf HTTP: url → serverUrl
        - antigravity HTTP: url → serverUrl
        - Copilot CLI: add type:'local'|'http'
        - Codex HTTP: uses url+bearer_token_env_var or http_headers
        - Gemini CLI: server names underscores → hyphens
        - Continue.dev: convert object to array [{name,type,...}]
        - Goose: add type:'stdio'|'sse'|'streamable_http'
  3. Merge with existing target config (backup first; duplicates → <name>_migrated)
  4. Write; verify parses correctly
```

### Rules/Instructions Conversion

Rules are MARKDOWN. The BODY is always reusable — only frontmatter and filename need adaptation. `AGENTS.md` is the universal intermediate format.

| Source | Conversion |
|--------|------------|
| `.cursorrules` / `.windsurfrules` / `.clinerules` / `.voidrules` | Copy body; rename to target's rules file |
| `.cursor/rules/*.mdc` | Extract body; adapt frontmatter (description, globs, alwaysApply) |
| `CLAUDE.md` / `GEMINI.md` / `.codyrules` / `CODEBUDDY.md` / `HELIX.md` | Copy body; rename to target's filename |
| `AGENTS.md` | Copy directly (universal standard) |
| `.kiro/steering/*.md` | Copy body; note conditional steering (inclusion: always/fileMatch/auto/manual) |
| `.augment/rules/*.md` | Extract body; adapt frontmatter (always/auto/manual) |
| `.comate/rules/*.mdr` | Extract body; .mdr is Markdown with Comate extensions |
| `.junie/guidelines.md` | Copy body; single file not directory |
| `.tabnine/guidelines/rules.md` | Copy body |
| Any rules → Zed/ZCode/Kimi Code/Qoder CN/veCLI | Append to AGENTS.md (all use AGENTS.md as universal) |
| Any rules → Aider | Use CONVENTIONS.md; add to `read:` in .aider.conf.yml |
| Any rules → Goose | Copy to .goosehints or AGENTS.md |

### Skills Conversion

```
CONVERT_SKILL(source_skill_dir, target_skill_dir):
  1. Keep: name, description (universally supported per agentskills.io)
  2. Remove IDE-specific frontmatter: allowed-tools (Claude), agent/fork/color (Augment)
  3. Copy entire skill directory (SKILL.md + scripts/ + references/ + assets/)
  4. Also copy to .agents/skills/ (universal) and .claude/skills/ (Claude-compatible)
  5. Verify SKILL.md has required name + description
```

### Commands/Prompts Conversion

Commands are markdown files (filename = command name). Exceptions:
- **Gemini CLI**: commands are `.toml` files, not markdown
- **VS Code Copilot**: rename to `*.prompt.md`; add mode/model/tools frontmatter
- **Cody**: convert to JSON format (`{commands: {key: {prompt, description, mode, context}}}`)
- **OpenCode**: support $ARGUMENTS, $1, !`cmd`, @filepath templates
- **Kimi Code**: no standalone commands dir; use skills or plugin commands

### Agents Conversion

Copy markdown body; adapt frontmatter. Supported fields by IDE:
- **Claude Code**: name, description, model, tools
- **VS Code Copilot**: name, description, tools, model
- **OpenCode**: description, mode, model, tools, permission
- **Forge**: name, description
- **Tencent CodeBuddy**: name, description, tools, model
- **Kiro**: name, description, prompt, mcpServers, tools, hooks (JSON format)
- **Kimi Code**: YAML format (extend, name, system_prompt_path, tools, exclude_tools, subagents)
- **Roo Code/Kilo Code**: Modes system (`.roomodes`/`kilo.jsonc`) — per-mode tool permissions
- **Gemini CLI**: via `/agents` command and extensions
- **ZCode**: Markdown (global `~/.zcode/agents/` or project `.zcode/agents/`)
- **Qodo**: TOML format (`agents/<command-name>.toml`: instructions, tools, commands)

### Hooks Conversion

| Source | Target | Conversion |
|--------|--------|------------|
| Claude Code (`settings.json` hooks) | Cursor (`.cursor/hooks.json`) | Adapt event names; Cursor supports sessionStart/End, preToolUse/postToolUse, etc. |
| Claude Code hooks | VS Code Copilot (`.github/hooks/*.json`) | Shared format; 8 lifecycle events |
| Claude Code hooks | Kiro (`.kiro/hooks/*.kiro.hook`) | Convert to JSON; when.type→fileEdited/preToolUse/postToolUse; then.type→runCommand/askAgent |
| Claude Code hooks | OpenCode (`.opencode/plugins/*.ts`) | Convert to TypeScript event handlers |
| Claude Code hooks | Kimi Code (`config.toml [[hooks]]`) | Convert to TOML array; 13 events; blocking: PreToolUse/Stop/UserPromptSubmit |
| Any hooks | Others | Note as manual step |

### Memory Conversion

| Source | Target | Conversion |
|--------|--------|------------|
| Claude Code (`~/.claude/projects/<encoded>/memory/MEMORY.md` + user_*.md etc.) | Any rules | Copy MEMORY.md + relevant .md files as project context |
| Cline `memory-bank/*.md` (6 files: projectbrief, productContext, activeContext, systemPatterns, techContext, progress) | Any rules | Copy as project context; prepend "## Project Context" |
| Goose `~/.config/goose/memory/` (JSON shards) | Any rules | Extract text from JSON shards; convert to markdown |
| Trae `~/.trae/memory/user_profile.md` | Any rules | Copy directly |
| Windsurf memories (`~/.codeium/windsurf/memories/`) | Any rules | Copy global_rules.md; other memories are auto-generated |
| CodeBuddy `CODEBUDDY.md` | Any rules | Copy directly |
| Gemini CLI `/memory` | Any rules | Use `/memory show` to export; copy to target |
| MiniMax Code (3-tier memory) | Any rules | Export via MiniMax Code UI; convert to markdown |
| Cross-IDE: mem0 MCP / OpenMemory / Pieces LTM | Same | Install as MCP server in target IDE; memory follows API key/device |

**Key rule**: Memory files are markdown/context. Convert to target IDE's rules or memory format. For MCP-based memory (mem0, Pieces), install the MCP server in target IDE.

---

## Safety Boundaries

| Never do this | Why |
|--------------|-----|
| Copy/migrate API keys, tokens, secrets | Security; blank values, tell user to fill in |
| Overwrite existing config without backup | Data loss; always .bak.TIMESTAMP first |
| Overwrite existing entries | Merge only; conflicts → `<name>_migrated` |
| Execute package installs (global npm installs, or piping a remote script straight into a shell interpreter) | Don't modify user's system — NEVER silent; see the OpenClaw exception below |
| Modify shell rc files | PATH issues noted but not auto-fixed |
| Kill/restart IDE processes | Tell user to restart in manual steps |
| Migrate IDE UI settings / chat history / OAuth tokens / SQLite databases | Out of scope or privacy/security risk |
| Write in dry-run mode | Default to preview; write only after user confirms |
| Proceed when config is invalid JSON/TOML/YAML | Parse errors = corrupted; stop and report |

### Exception — OpenClaw auto-configuration (explicit, user-consented)

`scripts/auto-configure-openclaw-skills.sh` is the installer for **OpenClaw**, a
*target runtime* for this skill. It is the single deliberate, user-consented exception to the
"no global installs / no unverified remote-script execution" rule above. It MAY:

- run `npm install -g clawhub` (installs the ClawHub package manager), and
- download and execute `https://openclaw.ai/install.sh` (the OpenClaw runtime installer),

**but ONLY when ALL of the following hold:**

1. The user passes `--yes` (explicit, recorded consent to modify their system).
2. For `install.sh`, the script downloads to a temp file (it never pipes the download
   directly into a shell interpreter) and verifies its SHA-256 against `OPENCLAW_INSTALL_SHA256`.
   Setting this pin is **mandatory**: if it is unset, the script refuses to run the installer and
   exits, rather than trusting an unverified download — this prevents supply-chain tampering.
3. In `--dry-run` mode it only previews these actions and never executes them.

This exception applies **solely** to installing the OpenClaw runtime / ClawHub for this skill's own
target platform. It does **NOT** weaken the general rule for any other operation: no other command
may run silent global `npm install -g`, pipe a remote script to `sh`, or modify the user's system
without equivalent explicit consent and integrity verification.

**IDE-specific pitfalls** (will cause silent failure):

| IDE | Pitfall |
|-----|---------|
| VS Code Copilot | Root key `servers`; requires type:'stdio'\|'http' |
| Copilot CLI | Root key `mcpServers` + REQUIRES type:'local'\|'http'; no longer reads .vscode/mcp.json |
| Zed | Root key `context_servers`; 1.4.2+ uses AGENTS.md not @rule |
| Codex/Helix | TOML `[mcp_servers.<name>]` uses underscores; prompts deprecated→skills |
| Gemini CLI | Server names must use hyphens; commands are .toml files |
| OpenCode | Root key `mcp`; command must be array; requires type; env field is `environment` |
| Goose | Root key `extensions`; fields: cmd/args/envs; memory is directory not file |
| Continue.dev | mcpServers is ARRAY not OBJECT (only IDE using array) |
| Sourcegraph Cody | Free/Pro sunset 2025-06 (migrate to Amp); MCP via feature flag opt-in; agentic gathering NOT @mentions |
| Sourcegraph Amp | MCP via `amp mcp add` CLI, not config key |
| Windsurf | Uses `serverUrl` not `url` for HTTP |
| Kiro | Path has `settings/` subdir: `.kiro/settings/mcp.json`; hooks use .kiro.hook extension |
| Cline | VS Code extension uses globalStorage path; CLI uses ~/.cline/mcp.json separately |
| antigravity | Config at `~/.gemini/config/mcp_config.json`; antigravity/ dir is cache |
| PearAI | Config file is `config.json` not `mcp_config.json`; standard object format |
| Forge | Path is `~/.forge/` not `~/.config/forge/`; MCP file is `.mcp.json` |
| Void Editor | File is `mcp_servers.json` not `mcp.json`; .voidrules unconfirmed |
| Kilo Code | Global is `~/.config/kilo/kilo.jsonc`; agents evolved from modes |
| Roo Code | Archived 2026-05; migrate to Kilo Code |
| Aider | No native MCP; rules via CONVENTIONS.md read config |
| Trae | Project MCP requires manual toggle; SOLO mode unsupported |
| Kimi Code | Path `~/.kimi-code/` NOT `~/.kimi/`; config is `config.toml` NOT `config.json`; legacy kimi-cli deprecated |
| ZCode | Root key `mcp.servers` (dot notation); uses `AGENTS.md` not `CLAUDE.md`; ZCode ≠ CodeGeeX |
| mmx-cli | Region trap: global=api.minimax.io / cn=api.minimaxi.com (extra 'i'); Key+Host must match |
| MiniMax Code | Desktop config not file-exposed; official recommends mmx CLI over MCP |
| bolt.new/bolt.diy | Root key is `servers` NOT `mcpServers`; no type field needed (unlike VS Code Copilot) |
| Qodo | CodiumAI ≠ Codeium (Codeium→Windsurf); Enterprise has "Agentic Tools Allow List"; agents in .toml files |
| Devin/v0/Lovable | Cloud SaaS only (no local files); bidirectional MCP — distinguish client config from server endpoint |
| Qoder CN | Renamed from Tongyi Lingma 2026-05-20; path `~/.qoder/` not `~/.lingma/`; uses AGENTS.md |
| Baidu Comate IDE | Distinct from plugin version; global Rules/MCP only since 2025-08 late version; can't install MS Python/C++ plugins |
| veCLI | Distinct from Trae CLI (different ByteDance product lines: Volcano Engine vs Trae brand) |
| WorkBuddy | Config at `~/.workbuddy/settings.json`; skills under `~/.workbuddy/skills/`; MCP at `~/.workbuddy/.mcp.json` (root key `mcpServers`) |

---

## Verification

| IDE | Method |
|-----|--------|
| Claude Code | `claude mcp list` |
| Codex CLI | `codex mcp list` or `/mcp` |
| Copilot CLI | `copilot mcp list` |
| OpenCode | `opencode mcp list` |
| Kimi Code | `kimi mcp list` |
| Qoder CN | `qodercli mcp list` |
| Sourcegraph Amp | `amp mcp list` |
| OpenHands | `openhands mcp list` |
| Goose | `goose configure` |
| Cursor | GUI: Settings → MCP (hot reload) |
| Zed | GUI: Settings → AI → Context Servers (hot reload) |
| VS Code Copilot | Command Palette → "MCP: List Servers" |
| Windsurf | GUI: Settings → MCP panel |
| Trae | GUI: Settings → MCP |
| Cline | GUI: Cline sidebar → MCP Servers |
| ZCode | GUI: Settings → MCP Servers |
| WorkBuddy | `workbuddy mcp list` |
| Kilo Code | GUI: Kilo settings; or inspect `~/.config/kilo/kilo.jsonc` |
| mcphub-nvim | `:McpHub` in Neovim |
| codecompanion-nvim | `/mcp` in chat buffer |
| JSON/TOML/YAML | `python3 -c "import json/tomllib/yaml; ..."` parse check |
| All others | Check files exist, non-empty, parse without errors |

**Universal MCP debugger**: `npx @modelcontextprotocol/inspector`

---

## Existing Migration Script

`scripts/smart-ide-migration.sh` automates file operations between 40 IDEs. Use it for bulk file copying; use the IDE Registry for format conversion it doesn't handle.

The script never writes files without explicit approval: `--dry-run` previews with zero
writes; applying changes requires `--yes` (interactive terminals get a `[y/N]` prompt;
non-interactive runs without `--yes` abort before touching anything). Always preview first:

```bash
# 1) Preview (zero writes)
bash scripts/smart-ide-migration.sh --source cursor --target claude --dry-run
# 2) Apply after reviewing the plan (explicit consent)
bash scripts/smart-ide-migration.sh --source cursor --target claude --yes
bash scripts/smart-ide-migration.sh --source cursor --target windsurf --objects skills,rules --strategy backup --yes
```

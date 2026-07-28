---
name: agent-skills-setup
version: 0.6.1
license: MIT
description: >
  Migrate AI assistant context between IDEs — MCP servers, rules/instructions,
  skills, slash commands, agents, hooks, and memory. Resolves the user-specified
  source/target IDE paths, converts formats across platforms, merges with a safe default (backup-before-change)
  and an explicit overwrite mode (rsync --delete); always verifies results.
  WHEN TO USE: ONLY when the user explicitly asks to migrate, move, transfer, copy,
  convert, or sync AI assistant context between IDEs — e.g. "migrate MCP config",
  "move skills from Cursor to Claude", "transfer rules from Windsurf to Cursor",
  "copy agents between IDEs". The skill previews every change with --dry-run and never
  writes files without an explicit --yes confirmation; it must not activate on vague
  or unrelated prompts.
  DO NOT ACTIVATE ON: incidental mentions of MCP, skills, rules, or IDE names;
  questions about MCP/skill format; debugging requests; "how do I…" / "what is…"
  questions; or any prompt that does not explicitly request a cross-IDE migration.
  When in doubt, ask the user to confirm the source IDE, target IDE, and the
  migration objects they want before reading or writing any config.
triggers:
  - migrate mcp config
  - move skills from cursor to claude
  - transfer mcp servers between ide
  - migrate rules from windsurf to cursor
  - copy mcp config to another ide
  - migrate ai context from one ide to another
capabilities:
  - read:  IDE/agent config dirs (MCP, rules, skills, commands, agents, hooks, memory)
  - write: file-backed skills/rules/prompts/MCP/config/project objects (gated by --strategy: skip|backup|overwrite; default backup); agents/hooks/memory are diagnostic/manual only
  - exec:  rsync, curl, node, tar/unzip (local migration + verification)
  - install: global software (OpenClaw runtime, clawhub) — ONLY with explicit --yes AND mandatory SHA-256 verification
  - remote: download+execute OpenClaw install.sh — ONLY with --yes AND mandatory OPENCLAW_INSTALL_SHA256
  - network: outbound HTTPS for downloads (gated by consent)
---

# AI IDE Context Migration

Migrate AI assistant context (MCP, rules, skills, commands, agents, hooks, memory) between IDEs with format conversion, safe merging, and verification.

> **MCP**: Cursor's current docs describe stdio, SSE, and Streamable HTTP. This skill does not assert a protocol version or deprecation status; unsupported schema/transport combinations are manual.
> **Full IDE Registry**: Read `references/ide-registry.md` for detailed per-IDE paths of all migration objects.

## Security Model

This skill is **scope-narrow and consent-gated** by design. It does **not** enumerate the user's home directory or auto-discover every installed IDE; it only resolves the **two IDEs the user explicitly names** via `--source` / `--target` (plus an optional `--workspace` for project-level config) and reads/writes only those resolved paths.

- **MCP is opt-in.** `skills`, `rules`, and `prompts` migrate by default; MCP servers are touched only when the user explicitly passes `--objects mcp` or `--objects project-mcp`. Use `--scope global|project|both` for Skills/MCP; `project-mcp` always selects the explicit workspace file.
- **Preview is read-only.** `--dry-run` prints resolved source/target paths and a plan — it never writes files and never echoes raw config or secret values.
- **Writes require explicit confirmation.** A non-interactive run without `--yes` aborts with zero writes. With `--yes`, target changes follow `--strategy` (`skip` | `backup` | `overwrite`, **default `backup`** — a timestamped `.bak.<TS>` copy is taken before any overwrite; raw `--delete`/overwrite is never silent).
- **Secrets are redacted fail-closed.** Credential values are blanked from a *copy* of the data (the original source is never modified). If redaction cannot be completed for any file, the entire copied tree is removed and the migration is marked failed — no secret is ever left on disk.
- **Network is consent-gated.** Outbound downloads (e.g. OpenClaw runtime) run only with `--yes` and mandatory SHA-256 verification; there is no hidden outbound activity.

---

## Migration Objects

| # | Object | Description |
|---|--------|-------------|
| 1 | **mcp** | MCP server configurations (stdio/HTTP) |
| 2 | **rules** | Instructions/rules/context files |
| 3 | **skills** | SKILL.md skill directories |
| 4 | **commands** | Slash commands / prompt templates |
| 5 | **agents** | Subagent definitions — diagnostic/manual only; no generic cross-IDE converter |
| 6 | **hooks** | Lifecycle event hooks — diagnostic/manual only; never copied or executed |
| 7 | **memory** | Persistent memory / memory banks / context files — diagnostic/manual only; generated state is never copied |

**Never migrate live secrets**: API keys, tokens, and bearer/OAuth credentials are always **BLANKED** during mcp/config migration (key names kept, values set to `""`) — they are never copied as-is. Also never migrate: chat history/transcripts, IDE UI settings, built-in vector indexes, workspace storage, SQLite databases.

---

## Execution Workflow

```
1. RESOLVE   — Read the user-specified source/target IDE names; resolve their config paths from IDE Registry (no filesystem-wide scanning)
2. IDENTIFY  — Ask user: source IDE(s) and target IDE(s)
3. READ      — Read only the selected migration objects for the specified source IDE (default scope: skills, rules, prompts)
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
- Default migration scope is **LOW-RISK ONLY** (`skills`, `rules`, `prompts`). `mcp`/`project-mcp`/`config`/`project` — which can carry live credentials — are NEVER migrated unless the user explicitly passes the corresponding object; a security warning is shown and secrets are redacted when they are in scope. `agents`, `hooks`, and `memory` are explicit diagnostics and remain manual.
- If source or target config is invalid JSON/TOML/YAML, STOP and report.

---

## IDE Quick Reference

Root key and format differences cause the most common migration errors. The full per-IDE registry — paths for **all** migration objects (not just MCP) across 40 IDEs — lives in `references/ide-registry.md`. Load only what you need, e.g.:

```bash
grep -nE '^### ' references/ide-registry.md   # list every IDE section
```

The highest-risk formats to get wrong (see `references/ide-registry.md` for the complete list):

> **MCP is opt-in**: these paths are only read/written when the user passes `--objects mcp` or `--objects project-mcp`; use `--scope global|project|both` for the generic `mcp` object. Secret values are always blanked (never copied as-is). The skill never scans them by default.

| IDE | MCP Root Key | Format | Config Path | Key Pitfall |
|-----|-------------|--------|-------------|-------------|
| VS Code Copilot | `servers` | JSON | workspace `.vscode/mcp.json`; user via `MCP: Open User Configuration` | IDE schema is `servers`, not `mcpServers`; preserve documented `stdio`, `http`, or `sse` entries and do not send this schema to the CLI; user file path is manual because the official docs do not publish a portable OS path |
| GitHub Copilot CLI | `mcpServers` | JSON | `~/.copilot/mcp-config.json` | Canonical target `copilot`; documented transports are `local`/`stdio` (command+args) and `http`/`sse` (url); project MCP is `.mcp.json` or `.github/mcp.json`, not `.vscode/mcp.json` |
| Claude Code | `mcpServers` | JSON | user/local `~/.claude.json`; project `.mcp.json` | Do not substitute `.claude/settings.local.json` for local MCP. The mapper handles only the user server map; review project and local per-project entries manually. |
| Claude Desktop app | — (manual only) | UI / legacy local JSON | no automatic file target | Use Settings → Extensions for local desktop extensions and Settings → Connectors for remote MCP. `claude_desktop_config.json` is a separate local-only mechanism, but current official docs do not give this mapper a portable macOS/native-Windows path; Linux is unsupported/unverified. Sources: [local MCP](https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop), [remote connectors](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp), [MCP import](https://code.claude.com/docs/en/mcp). |
| Pieces for Developers | — (PiecesOS MCP server/provider) | PiecesOS/Desktop Settings → MCP or `pieces mcp setup` | no automatic file target | Pieces has no documented `~/.pieces`, `.pieces`, SKILL.md, rules, or client MCP/config path; configure the active PiecesOS endpoint in the consuming IDE and never migrate its local database |
| Kilo Code | `mcp` | JSONC | `~/.config/kilo/kilo.jsonc` (global) / `kilo.jsonc` or `.kilo/kilo.jsonc` (project) | `type: local|remote`; local command is an array and env is `environment` |
| OpenCode | `mcp` | JSON/JSONC | `~/.config/opencode/opencode.json` / project `opencode.json` | `mcp` not `mcpServers`; `type: local|remote`; local command is array and env is `environment` |
| Kimi Code | `mcpServers` | JSON | `~/.kimi-code/mcp.json` / `.kimi-code/mcp.json` | `KIMI_CODE_HOME` relocates user data; config.toml is separate from MCP |
| Kiro | `mcpServers` | JSON | `~/.kiro/settings/mcp.json` / `.kiro/settings/mcp.json` | Skills are `~/.kiro/skills` / `.kiro/skills`; steering is directory-scoped |
| Augment | `mcpServers` | JSON | `~/.augment/settings.json` / `.augment/settings.json` | `.augment/settings.local.json` has local project precedence; rules/skills are separate directories |
| Comate | `mcpServers` | JSON | `~/.comate/mcp.json` / `.comate/mcp.json` | Three scopes: global, project, experimental local; MCP type is required |
| CodeBuddy Code | `mcpServers` | JSON | user `~/.codebuddy/.mcp.json`; project `.mcp.json`; `--mcp-config` overrides | Skills are explicitly documented at `~/.codebuddy/skills/` and `.codebuddy/skills/`; review legacy MCP locations and project precedence manually |
| WorkBuddy | `mcpServers` | JSON | `~/.workbuddy/mcp.json` / `.workbuddy/mcp.json` | Desktop docs only establish local `command` + optional `args`/`env`; remote URL/headers/type/transport entries are manual/UI-only; Skills are UI/local-package import with no portable directory |
| ZCode | `mcp.servers` | JSON | `~/.zcode/cli/config.json` / `.zcode/config.json` | Native MCP is nested; `.agents/mcp.json` is a compatibility fallback |
| Void Editor | `mcpServers` | JSON | global `~/.void-editor/mcp.json` | Legacy custom store; local `command`/`args`/`env` is the safe automatic shape, URL-only remote is limited, headers/auth and inherited VS Code `.vscode/mcp.json` (`servers`) remain manual; no Agent Skills directory |
| OpenClaw | `mcp.servers` | JSON | `~/.openclaw/openclaw.json` | nested root; local uses `command`/`args`, remote requires `url` + `transport: "streamable-http"`; workspace skills/context are separate |
| Windsurf / Devin Desktop | `mcpServers` | JSON | `~/.codeium/windsurf/mcp_config.json` | Current docs accept remote `serverUrl` or `url`; do not guess a transport or rewrite either field |
| Continue.dev | `mcpServers` | YAML | `~/.continue/config.yaml` | `mcpServers` is an ARRAY; `.continue` is a mixed config-block namespace, not a skills directory; automatic YAML/array conversion is unsupported |
| bolt.new/bolt.diy | `servers` | JSON | `~/.boltai/mcp.json` | Root key `servers` NOT `mcpServers`! |
| Claude Desktop | UI-managed | N/A | N/A | Automatic config-file migration is unsupported: install local MCPs via Settings → Extensions; add remote MCPs via Settings → Connectors. Do not infer legacy JSON paths. |

---

## Universal Standard Locations

Migrate to these FIRST for maximum cross-IDE compatibility:

| Path | Purpose | Loaded By |
|------|---------|-----------|
| `AGENTS.md` | Universal project instructions | Claude Code, Cursor, Copilot, Codex, Gemini (when `context.fileName` includes it), Zed 1.4.2+, JetBrains/Goose/Kiro/OpenCode/Augment/Forge/Void/OpenHands/Kimi Code/ZCode/Qoder CN/veCLI |
| `.agents/skills/<name>/SKILL.md` | Universal skills | Cursor, Copilot, Codex, Antigravity IDE, OpenCode, Augment, Amp, Zed, Comate, Kimi Code (Trae may load this as a plugin directory; its canonical project Skills path is `.trae/skills`) |
| `.claude/skills/<name>/SKILL.md` | Claude-compatible skills | Claude Code, Cursor (loads natively), OpenCode, Augment, Copilot |
| `.mcp.json` | Universal project MCP | Claude Code, Copilot CLI |
| `.vscode/mcp.json` | VS Code/Copilot IDE project-level MCP | VS Code/Copilot IDE (not GitHub Copilot CLI); shareable with VS Code/Cursor/Cline/Zed via mcphub-nvim |

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
        - servers (JSON, VS Code Copilot): rename mcpServers→servers only after validating the documented server shape; preserve `stdio`/`http`/`sse` and fail closed when transport is ambiguous rather than guessing
        - context_servers (JSON): rename root key (Zed)
        - mcp.servers (JSON): write the nested `mcp.servers` path; OpenClaw remote entries require explicit `transport: "streamable-http"` (documented CLI `type: "http"` may be normalized); never infer transport from `url` alone
        - mcp (JSON): rename; add type:'local'|'remote'; command→array; env→environment (OpenCode)
        - mcpServers ARRAY: object → [{name,type,...}] (Continue.dev ONLY; not implemented by the generic converter)
        - servers (JSON, bolt.new/bolt.diy): rename mcpServers→servers (NO type field needed)
        - mcp_servers (TOML): manual conversion to `[mcp_servers.<name>]` (Codex/Helix; JSON↔TOML is not auto-converted)
        - extensions (YAML, Goose): manual only — rebuild each `extensions.<name>` entry in `~/.config/goose/config.yaml`; preserve Goose's type-specific `cmd`/`args` or `uri`/`headers`, `envs`, `enabled`, and timeout fields
        - amp: via `amp mcp add` CLI command (Sourcegraph Amp)
     d. Handle special fields:
        - Windsurf / Devin Desktop HTTP: preserve documented `serverUrl` or `url`; if transport/shape is unclear, mark manual
        - Antigravity IDE HTTP: url → serverUrl
        - Copilot CLI: preserve the documented `mcpServers` schema; accept only `local`/`stdio` (command+args) or `http`/`sse` (url), otherwise mark manual
        - Codex HTTP: uses url+bearer_token_env_var or http_headers
        - Gemini CLI: preserve `mcpServers` and validate each entry has `command`, `url`, or `httpUrl`; reject aliases containing `_` for manual renaming and policy review instead of silently changing names
        - Continue.dev: manual only — preserve YAML and the `mcpServers` array; fail closed when the generic JSON converter would be used
        - Goose: do not infer a JSON↔YAML conversion; current config uses `extensions` with type-specific fields (`stdio`, `streamable_http`, `builtin`, etc.), so MCP migration is manual and fail-closed
        - Claude Desktop: no automatic JSON-file target. Use Settings → Extensions for local MCPs or Settings → Connectors for remote MCPs; do not migrate into `claude_desktop_config.json`.
  3. Merge with existing target config (backup first; duplicates → <name>_migrated)
  4. Write; verify parses correctly
```

### Rules/Instructions Conversion

Rules are MARKDOWN. The BODY is always reusable — only frontmatter and filename need adaptation. `AGENTS.md` is the universal intermediate format.

| Source | Conversion |
|--------|------------|
| `.cursorrules` / `.windsurfrules` / `.clinerules` / `.voidrules` | Copy body; rename to target's rules file |
| `.cursor/rules/*.mdc` | Extract body; adapt frontmatter (description, globs, alwaysApply) |
| `CLAUDE.md` / `GEMINI.md` / `CODEBUDDY.md` / `HELIX.md` | Copy body; rename to target's filename |
| `AGENTS.md` | Copy directly (universal standard) |
| `.kiro/steering/*.md` | Copy body; note conditional steering (inclusion: always/fileMatch/auto/manual) |
| `.augment/rules/*.md` | Extract body; adapt frontmatter (always/auto/manual) |
| `.comate/rules/*.mdr` | Extract body; .mdr is Markdown with Comate extensions |
| `AGENTS.md` (Junie in JetBrains IDEs) | Copy directly; Junie project instructions are the repository-root file |
| `.junie/guidelines.md` (Junie CLI only) | Manual/unsupported for JetBrains IDE migration; do not treat as the IDE's canonical instructions file |
| `.tabnine/guidelines/*.md` | Tabnine guideline directory; preserve files and scope manually (not an Agent Skills format) |
| Any rules → Zed/ZCode/Kimi Code/Qoder CN/veCLI | Append to AGENTS.md (all use AGENTS.md as universal) |
| Any rules → Aider | Use CONVENTIONS.md; add to `read:` in .aider.conf.yml |
| Any rules → Goose | Copy local project context to `.goosehints` or `AGENTS.md`; review global `~/.config/goose/.goosehints` and `CONTEXT_FILE_NAMES` manually |

### Skills Conversion

```
CONVERT_SKILL(source_skill_dir, target_skill_dir):
  1. Keep the skill directory and its required SKILL.md entrypoint. Keep description when present; name is optional in Claude Code and defaults to the directory name.
  2. Review target-specific frontmatter before copying; do not require or invent fields that the target has not documented.
  3. Copy entire skill directory (SKILL.md + scripts/ + references/ + assets/)
  4. Also copy to .agents/skills/ (universal) and .claude/skills/ (Claude-compatible)
  5. Verify SKILL.md exists and preserve the source frontmatter unless the target explicitly requires adaptation
```

### Commands/Prompts Conversion

Commands are markdown files (filename = command name). Exceptions:
- **Claude Code**: `.claude/commands/*.md` remains legacy compatibility; prefer `.claude/skills/<name>/SKILL.md` for new work. Do not assume an undocumented global commands directory is a migration target.
- **Gemini CLI**: commands are `.toml` files, not markdown
- **GitHub Copilot IDEs**: use `*.prompt.md` in `.github/prompts`; frontmatter fields such as `description`, `name`, `agent`, `model`, and `tools` are optional in VS Code. Prompt files are not supported by Copilot CLI.
- **Cody**: manual only; current prompts are managed in Cody's Enterprise Prompt Library. Do not infer legacy `cody.json` or a workspace command directory as a portable target.
- **OpenCode**: support $ARGUMENTS, $1, !`cmd`, @filepath templates
- **Kimi Code**: no standalone commands dir; use skills or plugin commands

### Agents Conversion

The script exposes `agents` as a diagnostic/manual object only. Do not generate a target agent file or copy a complete definition across IDEs: the official surfaces disagree on Markdown/JSON/TOML format, tool grammar, permissions, MCP, hooks, handoffs, model IDs, and trust scope. During manual review, the only generally reusable material is the human-readable identity and prompt body; validate the target's required fields first. Examples of documented target-specific contracts:
- **Claude Code**: `name` and `description` are required; preserve other documented subagent fields only after target review (for example `tools`, `disallowedTools`, `model`, `permissionMode`, `mcpServers`, `hooks`, `skills`, and `memory`).
- **GitHub Copilot CLI**: required `description`; optional `name`, `infer`, `mcp-servers`, `model`, `tools`. IDE/cloud agent fields (for example `target`, `disable-model-invocation`, `user-invocable`) are surface-specific; do not copy them to CLI without reviewing that surface's documentation.
- **OpenCode**: description, mode, model, tools, permission
- **Forge**: name, description
- **Tencent CodeBuddy**: name, description, tools, model
- **Kiro IDE**: Markdown/YAML frontmatter and body; Kiro CLI: separate JSON agent files. Keep both manual and never convert one format into the other automatically.
- **Kimi Code**: current Markdown files with `description`, optional `name`, `whenToUse`, `override`, `model_preference`, `tools`, `disallowedTools`, and `subagents`; legacy YAML/`system_prompt_path` files require manual review.
- **Roo Code/Kilo Code**: Modes system (`.roomodes`/`kilo.jsonc`) — per-mode tool permissions
- **Gemini CLI**: via `/agents` command and extensions
- **ZCode**: Markdown user-level `~/.zcode/agents/`; current Beta does not publish a stable project agents directory
- **Qodo**: TOML format (`agents/<command-name>.toml`: instructions, tools, commands)

### Hooks Conversion

The script exposes `hooks` as a diagnostic/manual object only. Hooks execute commands and the documented products use incompatible event names, scopes, file formats, matchers, approval models, and shell semantics (for example VS Code/Copilot `.github/hooks/*.json`, Trae `.trae/hooks.json`, Kiro `.kiro/hooks/*.json`, Windsurf `.windsurf/hooks.json`, and Codex `hooks.json`). Never auto-copy, rewrite, or execute a hook; rebuild it manually after reviewing the target's current official hook reference.

### Memory Conversion

| Source | Target | Conversion |
|--------|--------|------------|
| Claude Code auto memory (`~/.claude/projects/<project>/memory/`) | Any rules | Do not auto-migrate auto memory; it is machine-local and its contents require manual review before converting selected context into rules |
| Cline `memory-bank/*.md` (community methodology) | Any rules | Review selected files manually; this is not an official portable Cline memory contract |
| Goose `~/.config/goose/memory/` / `.goose/memory/` | Any rules | Memory extension-managed directories; review/export selected content manually before converting it to target Markdown rules |
| Amazon Q Memory Bank (`.amazonq/rules/memory-bank/`) | Any rules | Official project path is confirmed, but the contents are generated project-rule state; review selected Markdown manually and never copy the whole memory-bank directory |
| Trae memory | Any rules | Official international file path/schema is not established; review manually in Trae |
| Windsurf / Devin Desktop memories (`~/.codeium/windsurf/memories/`) | Any rules | Select context manually; memories are generated and workspace-isolated |
| CodeBuddy `CODEBUDDY.md` / Auto Memory | Any rules | Review CLI and IDE surfaces separately; do not assume the same schema or overwrite generated memory |
| Gemini CLI `/memory` | Any rules | Export/rebuild manually through the current CLI surface; do not copy private/runtime memory state |
| MiniMax Code (3-tier memory) | Any rules | Export via MiniMax Code UI; convert to markdown |
| Cross-IDE: mem0 MCP / OpenMemory / Pieces LTM | Same | Install/configure the MCP server in the target IDE; for Pieces, copy the active endpoint from PiecesOS/Desktop MCP settings or use `pieces mcp setup`, not a guessed file path |

**Key rule**: `memory` is diagnostic/manual only in this script. Generated memory, project identity keys, sessions, databases, and cloud/UI state are never copied. If the user selects context for a rules file, review and rewrite that selection manually. For MCP-based memory (mem0, OpenMemory, Pieces), install/configure the MCP server in the target IDE; PiecesOS data directories are local databases, not portable memory or skill files.

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
| VS Code Copilot | Root key `servers`; documented transport type is `stdio` / `http` / `sse` — preserve or review it rather than inferring a CLI transport |
| Copilot CLI | Canonical `copilot` target: root key `mcpServers`; project MCP is `.mcp.json` / `.github/mcp.json`; do not send VS Code's `servers` schema unchanged |
| Zed | Root key `context_servers`; 1.4.2+ uses AGENTS.md not @rule |
| Codex/Helix | TOML MCP uses `[mcp_servers.<name>]`; Codex supports stdio and Streamable HTTP. For Codex, use user `~/.codex/config.toml` or trusted-project `.codex/config.toml`; never auto-copy JSON `mcpServers` into TOML. |
| Gemini CLI | Canonical Skills paths are `~/.gemini/skills` / `.gemini/skills`; MCP is `settings.json` with root `mcpServers` and `command`/`url`/`httpUrl`; aliases containing `_` are rejected for manual review; commands are `.toml` files |
| OpenCode | Root key `mcp`; command must be array; requires type; env field is `environment` |
| OpenClaw | Config is `~/.openclaw/openclaw.json`; managed MCP is nested at `mcp.servers`; active workspace is configured by `agents.defaults.workspace`; context is `AGENTS.md`; workspace/project-agent/personal/managed skill roots are distinct |
| Goose | Skills use `~/.agents/skills` / `.agents/skills`; config is YAML at `~/.config/goose/config.yaml` with `extensions` and type-specific `cmd`/`args` or `uri`/`headers`; MCP/config conversion is manual; recipes/prompts/memory are separate objects |
| Continue.dev | Current config is YAML; `mcpServers` is ARRAY not OBJECT, `config.json` is deprecated, and `.continue` is not a skills format |
| Blackbox AI CLI / VS Code Agent | First-party docs only publish project `.blackbox/skills/<name>/SKILL.md`; no global Skills, rules, prompt, portable MCP, or configure-file path/schema is documented. Keep Skills project-scoped/manual and never infer `~/.blackbox` or `.blackbox` config files. |
| Sourcegraph Cody | Enterprise-only current surface; Free/Pro/Enterprise Starter ended 2025-07-23. MCP is a local, tools-only `cody.mcpServers` extension setting, disabled by default and feature-flagged. Prompts use the Enterprise Prompt Library; skills, agents, `.codyrules`, and portable config paths are unsupported/manual. |
| Sourcegraph Amp | MCP via `amp mcp add` CLI, not config key |
| Windsurf / Devin Desktop | `mcpServers` uses local `command`/`args`/`env` or remote exactly one of `serverUrl`/`url` plus optional `headers`; do not copy VS Code `type`/`transport`, and do not copy the mixed `.windsurf` namespace wholesale |
| JetBrains Junie | Canonical project instructions are `.junie/AGENTS.md` (root `AGENTS.md`/legacy guidelines are fallbacks); MCP auto-conversion is local `command`/optional `args`/`env` only, while remote/whole `.junie` migration is manual |
| Replit Agent | Project Skills are `.agents/skills`; `.local/secondary_skills` is a separate compatibility directory; `replit.md` is a living Agent-maintained document and must never be overwritten automatically; MCP is cloud/UI-managed |
| Kiro | MCP path has `settings/` subdir: `.kiro/settings/mcp.json`; current IDE hooks use `.kiro/hooks/*.json` v1, while `.kiro/hooks/*.kiro.hook` is legacy; IDE custom agents are Markdown and Kiro CLI custom agents are separate JSON |
| Cline | VS Code extension uses globalStorage `cline_mcp_settings.json`; CLI uses `~/.cline/data/settings/cline_mcp_settings.json` separately; both use `mcpServers` but scopes must not be conflated |
| Antigravity IDE | Global Skills: `~/.gemini/antigravity/skills/`; workspace Skills: `.agents/skills/`; rules: `~/.gemini/GEMINI.md` (global) / `.agents/rules/` (workspace); MCP: `~/.gemini/config/mcp_config.json` (global) / `.agents/mcp_config.json` (workspace), remote uses `serverUrl`; plugins and hooks remain manual targets in this script |
| PearAI | Official PearAI repositories document VS Code/Continue forks but no portable skills, rules, prompts, MCP, or config paths/schema; automatic migration is disabled and UI/extension-managed settings require manual review |
| Blackbox AI | Official CLI Skills live at project `.blackbox/skills/`; the generic `skills` operation only handles global directories, so Blackbox project Skills require manual review. Rules, prompts, MCP, whole-project `.blackbox`, and `blackbox configure` storage are manual/unsupported because current first-party docs publish no portable path/schema. Sources: [Skills Management](https://docs.blackbox.ai/features/blackbox-cli/skills), [Commands reference](https://docs.blackbox.ai/features/blackbox-cli/commands-reference), [CLI getting started](https://docs.blackbox.ai/features/blackbox-cli/getting-started), [VS Code Agent key features](https://docs.blackbox.ai/features/vscode-agent/key-features) |
| Supermaven | Completion/host-editor plugin only: official sources publish no portable Skills, rules, prompts, MCP, or standalone config path/schema; `~/.supermaven` is runtime/binary storage and `.supermavenignore` is an indexing-exclusion file, so automatic migration is disabled |
| Forge | Path is `~/.forge/` not `~/.config/forge/`; MCP file is `.mcp.json` |
| Void Editor | First-party source maps the legacy custom MCP store to `~/.void-editor/mcp.json` with root `mcpServers`; local `command`/`args`/`env` is the safe automatic shape, URL-only remote is narrow, header/auth entries and inherited VS Code `.vscode/mcp.json` (`servers`) remain manual; `.voidrules` is a workspace-root plaintext file and no Agent Skills directory is documented |
| Kilo Code | Global `~/.config/kilo/kilo.jsonc`; project `kilo.jsonc`/`.kilo/kilo.jsonc`; root key `mcp`; agents evolved from modes |
| Roo Code | Project MCP is `.roo/mcp.json` with root key `mcpServers`; global MCP is extension-settings/UI managed and its exact filesystem path is not established by the official docs used here, so the mapper leaves global `mcp` unsupported/manual. Skills use `~/.roo/skills` and `.roo/skills`; `.roorules` is the single-file automatic rules target, while scoped rules, custom modes, and global settings require manual review. Roo Code is not Cline, and its MCP config is not VS Code's `servers` schema. Archived 2026-05; migrate to Kilo Code. |
| Aider | No native MCP, Skills directory, or prompt directory; use `.aider.conf.yml`, `CONVENTIONS.md`, CLI flags, `AIDER_*` environment variables, or `.env` |
| Trae | Project `.trae/mcp.json`, `.trae/rules/`, and `.trae/commands/` are documented but directory/schema-aware operations remain manual; global MCP/Rules, custom Agents, global Subagents, native config, Hooks, and Memory are UI/manual or partially specified; global/project Skills are the safe file-backed surface |
| Trae CN | China build: project Skills `.trae/skills` (plus documented `.agents/skills` compatibility), Rules `.trae/rules`, Commands `.trae/commands`, MCP `.trae/mcp.json`; global Skills/Commands/Subagents use `~/.trae-cn/{skills,commands,agents}`. Global Rules/MCP and Custom Agents are UI/manual; `.trae/skill-config.json`, Memory, Hooks, and Subagents remain manual because the generic converter has no safe object handlers; `argv.json` is unsupported |
| Kimi Code | Path `~/.kimi-code/` NOT `~/.kimi/`; MCP is `mcp.json`, config is `config.toml`; project MCP is `.kimi-code/mcp.json` |
| ZCode | Root key `mcp.servers`; user `~/.zcode/cli/config.json`, workspace `.zcode/config.json`; uses `AGENTS.md` not `CLAUDE.md` |
| mmx-cli | Region trap: global=api.minimax.io / cn=api.minimaxi.com (extra 'i'); Key+Host must match |
| MiniMax Code | Desktop config not file-exposed; official recommends mmx CLI over MCP |
| bolt.new/bolt.diy | Root key is `servers` NOT `mcpServers`; no type field needed (unlike VS Code Copilot) |
| Qodo | CodiumAI ≠ Codeium (Codeium→Windsurf); Enterprise has "Agentic Tools Allow List"; agents in .toml files |
| Devin/v0/Lovable | Cloud SaaS only (no local files); bidirectional MCP — distinguish client config from server endpoint |
| Qoder CN | Renamed from Tongyi Lingma 2026-05-20; path `~/.qoder/` not `~/.lingma/`; uses AGENTS.md |
| Baidu Comate IDE | Distinct from plugin version; global Rules/MCP only since 2025-08 late version; can't install MS Python/C++ plugins |
| veCLI | Distinct from Trae CLI (different ByteDance product lines: Volcano Engine vs Trae brand) |
| WorkBuddy | MCP at `~/.workbuddy/mcp.json` / `.workbuddy/mcp.json`; automatic conversion accepts only the desktop-documented local `command`/optional `args`/`env` shape; remote entries and Skills/whole settings remain UI/manual |

---

## Verification

| IDE | Method |
|-----|--------|
| Claude Code | `claude mcp list` |
| Codex CLI | `codex mcp list` or `/mcp` |
| Copilot CLI | `copilot mcp list` |
| OpenCode | `opencode mcp list` |
| OpenClaw | Static JSON/frontmatter checks; official runtime checks are `openclaw mcp list` / `openclaw mcp doctor`, and skill installation is `openclaw skills install <slug>` (not run automatically) |
| Kimi Code | `kimi mcp list` |
| Qoder CN | `qodercli mcp list` |
| Sourcegraph Amp | `amp mcp list` |
| Sourcegraph Cody | Manual: verify the Enterprise extension's MCP Settings / `cody.mcpServers`; no portable file or `cody mcp list` verifier is supported by this mapper |
| OpenHands | `openhands mcp list` |
| Goose | `goose configure` |
| Cursor | GUI: Settings → MCP (hot reload) |
| Zed | GUI: Settings → AI → Context Servers (hot reload) |
| VS Code Copilot | Command Palette → "MCP: List Servers" |
| Windsurf | GUI: Settings → MCP panel |
| Trae | GUI: Settings → MCP; do not infer a global MCP file or `argv.json` path |
| Cline | VS Code extension: Cline sidebar → MCP Servers; CLI: `cline mcp` / static validation of `~/.cline/data/settings/cline_mcp_settings.json` |
| Supermaven | Manual: verify settings in the host editor or `supermaven-nvim` `setup()` configuration; this skill has no automatic Supermaven file target |
| ZCode | GUI: Settings → MCP Servers |
| WorkBuddy | GUI: Settings → MCP; no verified portable CLI verifier |
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

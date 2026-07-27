# IDE Registry — Full Migration Object Reference

Detailed per-IDE paths for all migration objects. Read this when executing STEP 3 (SCAN) of the migration workflow.

> **Verified**: 2026-07-27 via official docs. All paths are macOS/Linux unless noted.
> Objects not listed for an IDE = not supported by that IDE.
> Entries that intentionally expose no automatic path (for example Codeium legacy, Supermaven, Pieces, and cloud/UI-managed Replit surfaces) are fail-closed by design. Each such boundary is tied to an official source or an explicit absence of a portable file contract below; an empty path is not a guessed fallback.

---

## Claude Family

### claude-desktop (Claude Desktop app)
- **Automatic migration**: unsupported/manual in both directions. The current official local-MCP workflow is UI/package based, and the current official page does not publish a stable portable path for the legacy JSON mechanism. The mapper therefore leaves both `mcp` and `config` empty.
- **Local MCP**: **Settings → Extensions** is the current UI workflow: browse/install an extension or select a custom `.mcpb` package from Advanced settings. The page tells users to configure extension fields in the UI and does not establish `claude_desktop_config.json` as a portable automatic target. Source: [local MCP servers](https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop).
- **Remote MCP**: use **Customize → Connectors → Add custom connector** (or organization connector settings for Team/Enterprise); the remote URL is configured through that UI, not by this migration script. Remote connector traffic originates from Anthropic's cloud, whereas the legacy Desktop JSON mechanism uses the local network. Source: [remote MCP connectors](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp).
- Other migration objects: unsupported (desktop app; no project-level context mapping).

### claude (Claude Code)
- **detect**: `~/.claude/`
- **settings**: user `~/.claude/settings.json` · project `.claude/settings.json` · local `.claude/settings.local.json`.
- **mcp**: user and local scopes are stored in `~/.claude.json`; shared project scope is `.mcp.json` at the project root. The server-map key is `mcpServers`. The migration mapper's `mcp` path is the user file and its `project-mcp` diagnostic path is `.mcp.json`; it does not select or rewrite local per-project entries in `~/.claude.json`, so review those manually. Local MCP scope is distinct from local settings.
- **rules**: user `~/.claude/CLAUDE.md` / `~/.claude/rules/*.md` · project `CLAUDE.md`, `.claude/CLAUDE.md`, or `.claude/rules/*.md` · local `CLAUDE.local.md`.
- **skills**: project `.claude/skills/<name>/SKILL.md` · user `~/.claude/skills/<name>/SKILL.md`. `SKILL.md` is required; `description` is recommended and `name` is optional (defaults to the directory name).
- **commands**: `.claude/commands/*.md` is legacy compatibility. Prefer skills for new commands; this registry does not claim an unverified global commands path.
- **agents**: project `.claude/agents/*.md` · user `~/.claude/agents/*.md`. `name` and `description` are required; consult the current subagent frontmatter reference before copying additional fields.
- **hooks**: the `hooks` key in user, project, or local settings JSON; no standalone hooks file is documented.
- **memory**: auto memory is machine-local at `~/.claude/projects/<project>/memory/`. Do not auto-migrate auto memory or assume fixed topic filenames; use `/memory` to inspect it and manually select portable context.
- **sources**: [settings](https://code.claude.com/docs/en/settings), [MCP](https://code.claude.com/docs/en/mcp), [memory](https://code.claude.com/docs/en/memory), [skills](https://code.claude.com/docs/en/slash-commands), [subagents](https://code.claude.com/docs/en/sub-agents), [hooks](https://code.claude.com/docs/en/hooks).

### cursor
- **detect**: no stable, documented installation-detection path used by this mapper; manual only
- **mcp**: global `~/.cursor/mcp.json` · project `.cursor/mcp.json` · root_key `mcpServers` · JSON · official docs describe stdio, SSE, and Streamable HTTP
- **rules**: canonical project directory `.cursor/rules/*.mdc` · frontmatter includes `description`, `globs`, and `alwaysApply`; root `.cursorrules` is legacy/deprecated compatibility
- **skills**: project `.cursor/skills/<name>/SKILL.md` · global `~/.cursor/skills/<name>/SKILL.md`; `.agents/skills/` is a separate cross-tool compatibility location, not the Cursor canonical project path
- **commands**: project `.cursor/commands/*.md` · plain Markdown commands; command-to-skill conversion is not performed automatically here
- **agents**: project `.cursor/agents/*.md`, `.claude/agents/*.md`, or `.codex/agents/*.md`; user `~/.cursor/agents/*.md`, `~/.claude/agents/*.md`, or `~/.codex/agents/*.md`; Markdown frontmatter/body is documented, but tools, MCP inheritance, permissions, and model fields are surface-specific and manual in this mapper
- **hooks**: `.cursor/hooks.json` project and `~/.cursor/hooks.json` global are documented; hook schema/events are not converted by this mapper, so manual/unsupported
- **plugins**: Cursor supports plugins, but this registry does not claim a portable package path or `plugin.json` schema; manual/unsupported
- **memory**: Cursor Memories are managed by Cursor and scoped to repositories; no portable file migration target is claimed
- **other**: `.cursorignore` is not AI context migration data

### cline
- **detect**: `~/.cline/`
- **mcp** (VS Code extension, automatic target): `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` (mac) · `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` (linux) · `%APPDATA%\Code\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json` (win) · root key `mcpServers` · JSON; validate each server as exactly one `command` or `url`, with typed `args`, `env`, `autoApprove`, `disabled`, and `timeout`
- **mcp** (CLI, manual boundary): `~/.cline/data/settings/cline_mcp_settings.json`, same `mcpServers` JSON format. The generic mapper targets the extension path only so VS Code extension storage and CLI data scope are not conflated; use `CLINE_DATA_DIR`/`--config` when the CLI is customized.
- **rules**: project `.clinerules/` (extension-compatible) and CLI `.cline/rules/`; Cline also reads `.cursorrules`, `.windsurfrules`, and `AGENTS.md`. The generic single-file rules mapper targets `.clinerules` and leaves `.cline/rules/` manual.
- **project config**: generic `.cline/` copying is unsupported/manual because the directory mixes rules, skills, hooks, plugins, agents, cron, and other state; dedicated object mappings are required.
- **skills**: project `.cline/skills/` (also `.clinerules/skills/` and `.claude/skills/`) · global `~/.cline/skills/`
- **workflows/prompts**: Cline workflows are not a generic prompt-template directory: project `.clinerules/workflows/`, global `~/.cline/data/workflows/` (also `~/Documents/Cline/Workflows/`). Prompt migration is manual/unsupported.
- **settings/config**: `~/.cline/data/settings/global-settings.json` and `providers.json` are CLI/shared state; provider settings can contain credentials. Whole-config migration is unsupported; do not copy `config.json`, settings, providers, sessions, or secrets automatically.
- **memory**: no official portable memory-bank contract; `memory-bank/*.md` is a community methodology and manual context review only
- **other**: `.clineignore`

### roo-code (archived 2026-05)
- **detect**: `~/.roo/`
- **mcp**: project `.roo/mcp.json` is a documented JSON file with root key `mcpServers`; global MCP is stored in Roo's extension settings directory, but Roo's official docs do not publish a stable literal filesystem path. The mapper exposes project MCP diagnostically/manual-only and leaves global `mcp` empty; no VS Code/Cline globalStorage path is inferred.
- **rules**: project `.roorules` is the single-file compatibility target used by this mapper; Roo also loads the scoped collections `.roo/rules/*.md`, `.roo/rules-{mode}/`, and global `~/.roo/rules/`, which require manual review because the converter only copies one file and cannot preserve scope/mode activation.
- **skills**: project `.roo/skills/<name>/SKILL.md` and global `~/.roo/skills/<name>/SKILL.md`; `.agents/skills/` is a separate cross-agent compatibility location. The mapper's skills operation uses the Roo-specific directories.
- **commands**: project `.roo/commands/*.md` (documented; exposed through the mapper's `prompts` object).
- **modes**: project `.roomodes` and global `custom_modes.yaml`/`custom_modes.json`; these are YAML-or-JSON mode collections with per-mode tool permissions, but no automatic mode converter exists here, so migration is manual.
- **project namespace**: `.roo/` mixes skills, scoped rules, commands, MCP, modes, and other state; whole-directory project migration is manual/unsupported in this mapper.
- **memory**: `memory-bank/*.md` (community methodology, inherited from Cline; not an automatic mapper object).
- **note**: Migrate to Kilo Code: `.roo/`→`.kilocode/`, `.roomodes`→`.kilocodemodes`; review modes, scoped rules, and extension-managed global MCP manually.
- **sources**: [Roo Code Skills](https://roocodeinc.github.io/Roo-Code/features/skills/), [Custom Instructions](https://roocodeinc.github.io/Roo-Code/features/custom-instructions/), [Customizing Modes](https://roocodeinc.github.io/Roo-Code/features/custom-modes/), [Marketplace MCP locations](https://roocodeinc.github.io/Roo-Code/features/marketplace/), [Roo Code repository archive](https://github.com/RooVetGit/Roo-Code)

---

## VS Code Ecosystem

### vscode (VS Code + GitHub Copilot IDE; not cloud agent or the `copilot` script target)
- **detect**: no stable portable VS Code installation/config path is used by this mapper; `~/.vscode/` is application data, not a Skills or whole-project target
- **mcp**: workspace `.vscode/mcp.json` · root_key `servers` · JSON. User MCP is opened with `MCP: Open User Configuration` in the active VS Code profile; the official docs do not publish a portable OS-specific user path. Local entries use `command`/`args`/`env` and optional `type: stdio`; remote entries use `type: http|sse` plus `url`/optional `headers`/`oauth`. This schema is distinct from CLI `mcpServers`; the converter validates it and fails closed on foreign `transport`/`serverUrl` fields.
- **rules**: `.github/copilot-instructions.md` · `.github/instructions/**/*.instructions.md` (frontmatter: `applyTo`) · other agent instruction files are surface-specific and require manual review
- **skills**: project `.github/skills/<name>/SKILL.md` / `.claude/skills/<name>/SKILL.md` / `.agents/skills/<name>/SKILL.md` · personal `~/.copilot/skills/<name>/SKILL.md` / `~/.claude/skills/<name>/SKILL.md` / `~/.agents/skills/<name>/SKILL.md`
- **prompts**: workspace `.github/prompts/*.prompt.md`; user-level prompt files are supported by the UI, but the official docs do not publish a portable user path, so user prompt migration is manual. VS Code frontmatter fields including `description`, `name`, `agent`, `model`, and `tools` are optional · not supported by Copilot CLI
- **extensions**: manual only. Extensions are installed and managed by VS Code; extension-contributed skills are declared by the extension's `package.json` `chatSkills` contribution point, not in a portable user/workspace file. Do not copy extension storage or invent an extension registry path.
- **note**: The `vscode` mapper key is VS Code/Copilot IDE only. GitHub Copilot CLI remains the separate `copilot` target with `~/.copilot/mcp-config.json` and `mcpServers`.
- **agents/hooks/plugins**: `.github/agents/*.agent.md`, `.github/hooks/*.json`, and plugin manifests/settings belong to the selected Copilot agent/cloud/CLI surface, not a portable VS Code extension config. Agent `description`/other frontmatter is surface/version-specific; review these files manually and do not assume a required hook `version` or a VS Code user path.
- **sources**: [VS Code MCP](https://code.visualstudio.com/docs/agent-customization/mcp-servers), [custom instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions), [agent skills](https://code.visualstudio.com/docs/agent-customization/agent-skills), [prompt files](https://code.visualstudio.com/docs/agent-customization/prompt-files), [custom agents](https://code.visualstudio.com/docs/agent-customization/custom-agents), [hooks](https://code.visualstudio.com/docs/agent-customization/hooks)

### copilot-cli
- **detect**: `~/.copilot/`
- **alias**: migration-script key `copilot` (GitHub Copilot CLI, not VS Code Copilot)
- **mcp**: global `~/.copilot/mcp-config.json` · project `.mcp.json` / `.github/mcp.json` · root_key `mcpServers` · JSON. CLI transports: `local` / `stdio` (command + args) and `http` / `sse` (url); `tools` is required. Project files take precedence over user definitions on a name collision. The generic mapper migrates only the global file and leaves both project files for manual review.
- **rules**: project `.github/copilot-instructions.md` · `.github/instructions/**/*.instructions.md` · agent instructions `AGENTS.md` / root `CLAUDE.md` / `GEMINI.md` · personal `~/.copilot/copilot-instructions.md` / `~/.copilot/instructions/**/*.instructions.md`
- **skills**: project `.github/skills/<name>/SKILL.md` / `.claude/skills/<name>/SKILL.md` / `.agents/skills/<name>/SKILL.md` · personal `~/.copilot/skills/<name>/SKILL.md` / `~/.agents/skills/<name>/SKILL.md`
- **prompts**: unsupported — `.github/prompts/*.prompt.md` is for Copilot IDE surfaces, not Copilot CLI
- **agents**: project `.github/agents/*.agent.md` / `.claude/agents/*.agent.md` · personal `~/.copilot/agents/*.agent.md`
- **hooks**: project `.github/hooks/*.json` · personal `~/.copilot/hooks/*.json` or `~/.copilot/settings.json` `hooks` key
- **plugins**: configure declaratively with `enabledPlugins` in `~/.copilot/settings.json` or `.github/copilot/settings.json`; installed-plugin state under `~/.copilot/` is application-managed, not a migration target
- **note**: `.vscode/mcp.json` is VS Code's distinct `servers` schema. Its entries require transport/schema review before placing them in a CLI `mcpServers` file; never copy it unchanged or let the generic mapper choose between `.mcp.json` and `.github/mcp.json`.

### windsurf
- **detect**: `~/.codeium/windsurf/` (the current Devin Desktop/Windsurf storage namespace)
- **mcp**: global `~/.codeium/windsurf/mcp_config.json` · root_key `mcpServers` · JSON · local entries use `command`/`args`/`env`; remote entries use exactly one of `serverUrl` or `url` plus optional string `headers`; do not add VS Code `type` or an inferred `transport`
- **rules**: preferred project `.devin/rules/*.md` · legacy fallback `.windsurf/rules/*.md` · legacy root `.windsurfrules` · global `~/.codeium/windsurf/memories/global_rules.md` · workspace frontmatter uses `trigger` and optional `description`
- **skills**: project `.windsurf/skills/<name>/SKILL.md` · global `~/.codeium/windsurf/skills/<name>/SKILL.md` · required frontmatter `name`, `description`; `.agents/skills`/`~/.agents/skills` and optional `.claude/skills` are compatibility locations and are not merged blindly
- **workflows**: project `.windsurf/workflows/*.md` · global `~/.codeium/windsurf/global_workflows/*.md` · manual slash invocation `/[name]`; prompt/workflow migration remains manual
- **memory**: `~/.codeium/windsurf/memories/` (auto-generated, workspace-isolated; not committed)
- **project namespace**: `.windsurf` mixes Skills, rules, workflows, and application state; no automatic whole-project or project-MCP path is claimed. The `codeium` namespace above is the current official app storage path, not a separate legacy Codeium target.
- **note**: 6000-char global-rule / 12000-char workspace-rule and workflow limits; 100-tool limit.
- **sources**: [Cascade Skills](https://docs.windsurf.com/windsurf/cascade/skills), [Cascade MCP](https://docs.windsurf.com/windsurf/cascade/mcp), [Devin rules](https://docs.devin.ai/desktop/cascade/rules), [workflows](https://docs.devin.ai/desktop/cascade/workflows)

### codeium (Codeium → Windsurf)
- **status**: legacy product name; the current product/plugin is Windsurf (formerly Codeium)
- **detection**: no automatic legacy path is claimed. `~/.codeium/` is a shared historical/current namespace and must not be treated as a standalone Codeium installation; review any pre-rebrand residue manually, excluding `~/.codeium/windsurf/`.
- **skills / rules / mcp / config**: unsupported/empty in this mapper. No standalone Codeium Skills, MCP, or portable config path is evidenced by the current official docs; current Windsurf mappings are listed only under `### windsurf`.
- **migration boundary**: the `codeium` CLI token remains only so an explicitly selected legacy source fails closed with a manual/unsupported result. Do not use generic `.codeium` state as Skills or copy it as opaque project config.
- **sources**: [Windsurf Plugins — formerly Codeium](https://docs.windsurf.com/plugins/getting-started), [Cascade Skills](https://docs.windsurf.com/windsurf/cascade/skills), [Cascade MCP Integration](https://docs.windsurf.com/windsurf/cascade/mcp)

### continue
- **detect**: `~/.continue/`
- **config**: global `~/.continue/config.yaml` · current YAML schema requires `name`, `version`, and `schema`; legacy `config.json` is deprecated and `.continuerc.json` is a separate legacy workspace override
- **project blocks**: `.continue/models/`, `.continue/rules/`, `.continue/prompts/`, and `.continue/mcpServers/`; these are block directories, not one generic project config file
- **mcp**: global `~/.continue/config.yaml` or project `.continue/mcpServers/<name>.yaml` · root_key `mcpServers` · YAML · ARRAY format (not object), with each server requiring `name` and `command` for local stdio entries
- **rules**: project `.continue/rules/*.md` (Markdown with YAML frontmatter; `name`, `globs`, `regex`, `alwaysApply`, `description` are documented fields); no official `CONTINUE.md` path
- **prompts**: `.continue/prompts/*.md` · prompt files use YAML frontmatter and can be invoked as slash commands
- **skills**: unsupported; Continue docs do not define a `SKILL.md` skill directory
- **automatic boundary**: this mapper exposes paths for diagnosis but does not automatically copy Continue `config.yaml`, MCP, rules, or the mixed `.continue` project namespace; its generic JSON converter cannot safely convert YAML or an `mcpServers` array
- **sources**: [config.yaml reference](https://docs.continue.dev/reference), [configuration](https://docs.continue.dev/customize/deep-dives/configuration), [MCP](https://docs.continue.dev/customize/deep-dives/mcp), [rules](https://docs.continue.dev/customize/deep-dives/rules), [prompts](https://docs.continue.dev/customize/prompts), [YAML migration](https://docs.continue.dev/reference/yaml-migration), [config.json reference](https://docs.continue.dev/reference/json-reference)

### emacs (GNU Emacs)
- **detect**: no AI-assistant configuration directory claimed by native GNU Emacs
- **native configuration**: initialization file is selected from `~/.emacs.el`, `~/.emacs`, `~/.emacs.d/init.el`, or the XDG-compatible `~/.config/emacs/init.el`; `.dir-locals.el` provides per-directory Emacs Lisp variables
- **skills / rules / mcp / project config**: unsupported by native GNU Emacs; the mapper leaves these paths empty
- **config**: unsupported for automatic migration. Init files and `.dir-locals.el` are Emacs Lisp with user-selected locations and semantics; review and adapt them manually rather than copying another IDE's config
- **third-party boundary**: packages such as `gptel` and `mcp.el` can add AI/MCP features, but their package-specific paths and schemas are not native Emacs mappings and are outside this registry's automatic migration
- **sources**: [The Emacs Initialization File](https://www.gnu.org/software/emacs/manual/html_node/emacs/Init-File.html), [How Emacs Finds Your Init File](https://www.gnu.org/software/emacs/manual/html_node/emacs/Find-Init.html), [Per-Directory Local Variables](https://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html)

### augment-code
- **detect**: `~/.augment/`
- **mcp**: global `~/.augment/settings.json` · project `.augment/settings.json` / `.augment/settings.local.json` · root_key `mcpServers` · JSON · stdio+HTTP/SSE
- **rules**: user `~/.augment/rules/*.md` · workspace `.augment/rules/*.md` · `.augment-guidelines`; frontmatter: always_apply, agent_requested (manual is IDE-only)
- **skills**: project `.augment/skills/<name>/SKILL.md` · global `~/.augment/skills/` · also loads `~/.claude/skills/`, `~/.agents/skills/` · frontmatter: name, description, agent, fork, color
- **commands**: global `~/.augment/commands/`
- **other**: `~/.augment-plugin/` (plugins marketplace)
- **sources**: [Augment Skills](https://docs.augmentcode.com/using-augment/skills), [Augment Rules](https://docs.augmentcode.com/cli/rules), [Augment MCP](https://docs.augmentcode.com/cli/integrations), [Augment config scopes](https://docs.augmentcode.com/cli/config)

### kilocode
- **detect**: project `.kilo/` · global `~/.config/kilo/`
- **mcp**: global `~/.config/kilo/kilo.jsonc` · project `kilo.jsonc` or `.kilo/kilo.jsonc` · root_key `mcp` · JSONC · local `type: local` + command array + environment; remote `type: remote` + url/headers
- **skills**: global `~/.kilo/skills/<name>/SKILL.md` · project `.kilo/skills/<name>/SKILL.md` · compatibility `.agents/skills` and `.claude/skills`
- **rules/agents**: `.kilo/rules/`, `.kilo/agents/`, `AGENTS.md`, and `kilo.jsonc` instructions/agent fields; these are mixed scopes and manual in this mapper
- **sources**: [Kilo Skills](https://kilo.ai/docs/customize/skills), [Kilo MCP](https://kilo.ai/docs/automate/mcp/using-in-kilo-code)

---

## Standalone IDEs

### zed
- **detect**: `~/.config/zed/` (mac/linux/win — Zed stores `settings.json` here cross-platform; `~/Library/Application Support/Zed/` holds extensions/data only)
- **mcp**: global `~/.config/zed/settings.json` · project `.zed/settings.json` (diagnostic/manual scope) · root_key `context_servers` · JSON · local `command`/`args`/`env` or remote `url`/`headers`
- **rules**: project `AGENTS.md`; personal `~/.config/zed/AGENTS.md` (since 1.4.2; compatible project instruction files remain supported)
- **skills**: global `~/.agents/skills/<name>/SKILL.md` · project `.agents/skills/<name>/SKILL.md`
- **prompts**: no documented standalone prompt-template directory; MCP Prompts are server-provided and are not file prompt templates
- **config**: unsupported for generic cross-IDE copying; `settings.json` is Zed's native settings/MCP file, not a portable whole-IDE config target
- **agents**: via `agent_servers` config (ACP protocol to external agents)
- **note**: GUI-launched Zed lacks shell PATH — use absolute paths

### trae
- **detect**: `~/.trae/`
- **mcp**: project `.trae/mcp.json` is the only file path exposed by this mapper, as a manual/diagnostic path; root key `mcpServers` · JSON. The official international docs do not publish a stable global MCP file path, so global MCP is UI/manual only.
- **skills**: global `~/.trae/skills/<name>/SKILL.md` · project `.trae/skills/<name>/SKILL.md`; `.agents/skills/` is an opt-in project compatibility directory and `.trae/skills` takes precedence. `SKILL.md` requires `name`/`description` frontmatter; `.trae/skill-config.json` is a narrow disabled-Skills file with undocumented schema.
- **rules**: project `.trae/rules/` with Markdown frontmatter (`alwaysApply`, `globs`, `description`, optional `scene: git_message`); nested directories are supported up to three levels. Root `AGENTS.md`, `CLAUDE.md`, and `CLAUDE.local.md` can be imported through Settings; global Rules remain UI-managed with no portable path.
- **commands**: project `.trae/commands/*.md`; global macOS/Linux `~/.trae/commands/` and Windows `%userprofile%/.trae/commands/`; nesting is supported up to three levels, but the richer command schema is only partially documented and remains manual.
- **subagents**: project `.trae/agents/<name>.md`; the international page publishes a conflicting `~/.trae-cn/agents/` user path, so global Subagents remain manual/unconfirmed. Frontmatter requires `name`/`description` and may include `model`, `tools`, `disallowedTools`, and `mcpServers`.
- **hooks**: global `~/.trae/hooks.json`; project `$PROJECT_FOLDER/.trae/hooks.json` on macOS/Linux; JSON root `version: 1` plus `hooks`, with command hooks and lifecycle matchers. Hooks execute shell commands and remain manual; the Windows project row is not documented.
- **memory**: global `~/.trae/memory/user_profile.md`; project `~/.trae/memory/projects/{project_path}/project_memory.md`; Markdown paths are documented but project-path encoding/portability is not, so manual only.
- **config**: unsupported. Do not infer `~/.trae/argv.json` or any other global argv/settings file.
- **product boundary**: TRAE Work/Desktop/Web/Mobile, TRAE Plugin, and the separate `bytedance/trae-agent` project must not inherit this IDE's `.trae` paths or schemas.
- **sources**: [TRAE MCP](https://docs.trae.ai/ide/model-context-protocol?_lang=en), [TRAE Skills](https://docs.trae.ai/ide/skills?_lang=en), [TRAE Rules](https://docs.trae.ai/ide/rules?_lang=en), [TRAE Commands](https://docs.trae.ai/ide/slash-commands?_lang=en), [TRAE Hooks](https://docs.trae.ai/ide/automate-actions-with-hooks?_lang=en), [TRAE Memories](https://docs.trae.ai/ide/memories?_lang=en), [TRAE Subagents](https://docs.trae.ai/ide/subagents?_lang=en), [TRAE settings](https://docs.trae.ai/ide/ide-settings-overview?_lang=en).

### trae-work (separate product; not a supported mapper target)
- TRAE Work is a separate Web/Desktop/Mobile product with Work/Code/Design modes; it has no `SUPPORTED_IDES` key in this script.
- Do not reuse TRAE IDE/CN `.trae` paths or schemas for Work. Its cloud/runtime state, rules, MCP, commands, hooks, memory, and Subagents require product-specific documentation and manual review.
- Never copy the whole `.trae` namespace between TRAE products. If a future Work document establishes a file-backed object, add it as a separate mapping only after official path/schema evidence is available.

### trae-cn
- **product distinction**: Trae CN is the China build; do not reuse the international build's undocumented global MCP/config assumptions. The CN docs use the `~/.trae-cn/` namespace for user Skills, Commands, Memory, and Hooks.
- **global skills**: `~/.trae-cn/skills/<name>/SKILL.md` (macOS/Linux) / `%userprofile%/.trae-cn/skills/<name>/SKILL.md` (Windows); **project skills**: `.trae/skills/<name>/SKILL.md`.
- **skills compatibility**: `.agents/skills/` is supported when enabled in Settings, with `.trae/skills/` taking precedence on duplicate names; `.trae/skill-config.json` records disabled project Skills but its schema is undocumented and remains manual.
- **project rules**: `.trae/rules/` (Markdown with documented `alwaysApply`, `globs`, `description`, and optional `scene` frontmatter); global rules are managed in the UI and have no documented portable file path, so global rules remain manual.
- **commands/prompts**: project `.trae/commands/`; global `~/.trae-cn/commands/` (macOS/Linux) / `%userprofile%/.trae-cn/commands/` (Windows). The mapper's prompt object is project-scoped only; global Commands require manual review.
- **subagents**: project `.trae/agents/<name>.md`; global `~/.trae-cn/agents/<name>.md` (macOS/Linux) / `%userprofile%/.trae-cn/agents/<name>.md` (Windows); required frontmatter is `name` and `description`, with optional `model`, `tools`, `disallowedTools`, and `mcpServers`. The feature may require the Subagents setting/Beta capability, so this mapper leaves it manual.
- **mcp**: project `.trae/mcp.json` (when project MCP is enabled), root key `mcpServers`, JSON. The official CN MCP page documents the project file and UI/raw-JSON workflow but does not publish a stable user-global MCP filesystem path; the mapper leaves global MCP empty and manual/UI-only. Community/forum paths are not promoted to automatic mappings.
- **config/argv**: empty/unsupported. Do not infer `~/.trae-cn/argv.json` or any other settings/argv file.
- **memory**: documented but not an automatic migration object: global `~/.trae-cn/memory/user_profile.md`; project `~/.trae-cn/memory/projects/{project_path}/project_memory.md`. The `{project_path}` encoding/keying is not specified, so review/copy manually.
- **hooks**: documented but not an automatic migration object: global `~/.trae-cn/hooks.json`; project `.trae/hooks.json`. The JSON root is `version` plus `hooks`; hook commands execute arbitrary shell commands, so never copy or run them automatically.
- **product boundary**: do not merge TRAE CLI (`trae_cli.yaml`/YAML MCP), TRAE Plugin, or TRAE Work/Desktop paths into this IDE entry.
- **sources**: [TRAE CN Skills](https://docs.trae.cn/ide/skills), [TRAE CN Rules](https://docs.trae.cn/ide/rules), [TRAE CN MCP](https://docs.trae.cn/ide/add-mcp-servers), [TRAE CN Commands](https://docs.trae.cn/ide/slash-commands), [TRAE CN Memory](https://docs.trae.cn/ide_memories), [TRAE CN Hooks](https://docs.trae.cn/ide/hook-configuration-reference), [TRAE CN Subagents](https://docs.trae.cn/ide_subagents), [TRAE CN changelog](https://docs.trae.cn/ide_changelog).

### jetbrains (Junie in JetBrains IDEs; not JetBrains AI Assistant)
- **detect**: `~/.junie/` is a Junie home heuristic; IDE settings themselves are managed by JetBrains UI and have no verified portable file path
- **mcp**: project `.junie/mcp/mcp.json` · user `~/.junie/mcp/mcp.json` · root_key `mcpServers` · JSON · project/user scopes are documented by Junie
- **skills**: project `.junie/skills/<name>/SKILL.md` · user `~/.junie/skills/<name>/SKILL.md` · open Agent Skills format; project skill takes precedence when names collide
- **rules**: preferred project `.junie/AGENTS.md`; root `AGENTS.md` is the documented fallback; legacy `.junie/guidelines.md` / `.junie/guidelines/` and custom Project Settings paths remain compatibility/manual inputs, not CLI-only files
- **MCP conversion boundary**: automatic conversion handles only local `command`/optional `args`/`env`; remote/headers/type/transport/unknown fields fail closed for manual review. Project MCP remains manual in this generic user-scope operation.
- **project namespace**: `.junie/` mixes Skills, AGENTS/guidelines, MCP, and IDE state; whole-directory migration is blocked. Junie CLI `~/.junie/config.json` and project `.junie/config.json` are separate CLI configuration and remain unsupported here.
- **config**: empty/manual for this IDE mapper. Junie CLI documents `~/.junie/config.json` and `<project-root>/.junie/config.json`, but that is CLI configuration, not a verified JetBrains IDE settings file
- **JetBrains AI Assistant**: separate product surface. Its MCP servers and agent settings are configured in Settings → Tools → AI Assistant → Model Context Protocol (MCP)/Agents; no portable global/project path is claimed here. Treat GUI-only settings and migrations as manual/unsupported.
- **sources**: [Junie Skills](https://junie.jetbrains.com/docs/agent-skills.html), [Junie IDE plugin](https://junie.jetbrains.com/docs/junie-ide-plugin.html), [Junie Project Settings](https://junie.jetbrains.com/docs/junie-plugin-project-settings.html), [Junie MCP Settings](https://junie.jetbrains.com/docs/junie-plugin-mcp-settings.html), [Junie CLI config](https://junie.jetbrains.com/docs/junie-cli-configuration.html)

### kiro
- **detect**: `~/.kiro/`
- **mcp**: global `~/.kiro/settings/mcp.json` · project `.kiro/settings/mcp.json` · root_key `mcpServers` · JSON · stdio+HTTP+OAuth
- **rules**: project `.kiro/steering/*.md` · global `~/.kiro/steering/*.md` · frontmatter: inclusion (always|fileMatch|auto|manual)
- **skills**: global `~/.kiro/skills/<name>/SKILL.md` · project `.kiro/skills/<name>/SKILL.md`
- **agents (IDE)**: project `.kiro/agents/*.md` · user `~/.kiro/agents/*.md` · Markdown/YAML frontmatter; current IDE custom-agent files use prompt/body plus Kiro-specific tool tags and permissions, so only identity/body is potentially reusable and the mapper keeps them manual
- **agents (CLI)**: Kiro CLI custom agents use a separate JSON configuration under the CLI agent surface; fields can include prompt, tools, allowedTools, toolAliases, mcpServers, hooks, resources, and model. Do not convert CLI JSON to IDE Markdown or treat the two paths as one contract
- **hooks**: current IDE `.kiro/hooks/*.json` uses the v1 hook-object schema (`version: "v1"`, `trigger`, `action`); older `.kiro/hooks/*.kiro.hook` files use the legacy `when`/`then` schema. Kiro 1.0 also documents global hooks, but the reviewed page does not publish a stable literal user path; the two formats/events and global scope are therefore manual and are not silently converted.
- **specs**: `.kiro/specs/<feature>/{requirements,design,tasks}.md` — spec-driven dev docs
- **sources**: [Kiro Skills](https://kiro.dev/docs/skills/), [Kiro MCP](https://kiro.dev/docs/mcp/configuration/), [Kiro steering](https://kiro.dev/docs/steering/), [Kiro IDE custom agents](https://kiro.dev/docs/custom-agents/), [Kiro CLI custom-agent configuration](https://kiro.dev/docs/cli/custom-agents/configuration-reference/), [Kiro IDE hooks](https://kiro.dev/docs/hooks/), [Kiro IDE changelog](https://kiro.dev/changelog/ide/)

---

## CLI Agents

### codex
- **detect**: `~/.codex/`
- **config / MCP**: user `~/.codex/config.toml` · project `.codex/config.toml` (loaded only for trusted projects) · root key `mcp_servers` · TOML · stdio + Streamable HTTP · `codex mcp add`, `codex mcp list`, `codex mcp --help`. This mapper reports project config diagnostically only and leaves every Codex MCP/config transfer manual; it never converts JSON `mcpServers` into TOML.
- **rules**: project `AGENTS.md` · global `~/.codex/AGENTS.md`
- **skills**: project `.agents/skills/<name>/SKILL.md` · global `~/.agents/skills/<name>/SKILL.md` (documented Codex skill locations; do not treat them as an undocumented compatibility alias)
- **commands / prompts**: no standalone migration target documented; use skills for reusable workflows instead.
- **hooks**: global `~/.codex/hooks.json` or `~/.codex/config.toml` · project `.codex/hooks.json` or `.codex/config.toml` (project layer requires trust)
- **note**: configure each MCP server in TOML as `[mcp_servers.<server-name>]`; stdio uses `command` and Streamable HTTP uses `url`, with optional `bearer_token_env_var` or `http_headers`. Hooks can be `hooks.json` or inline `[hooks]` beside the active config layer; project hooks also require trust. JSON↔TOML MCP migration is unsupported by the script and must be rebuilt manually. Sources: [config reference](https://developers.openai.com/codex/config-reference/), [MCP](https://developers.openai.com/codex/mcp/), [advanced config](https://developers.openai.com/codex/config-advanced/), [customization / skills](https://developers.openai.com/codex/concepts/customization/).

### gemini-cli
- **detect**: `~/.gemini/` is the user configuration namespace; this mapper does not infer an installation path from it.
- **settings / config**: user `~/.gemini/settings.json` · project `.gemini/settings.json` · JSON settings schema · project settings override user settings. The mapper exposes the user file as `config`, and the project file as `project-config`/`project-mcp` diagnostics; it does not copy a whole `.gemini` namespace or choose a project scope automatically.
- **mcp**: user `~/.gemini/settings.json` · project `.gemini/settings.json` · root key `mcpServers` · JSON. Each server must provide at least one documented endpoint: `command` (stdio), `url` (SSE), or `httpUrl` (Streamable HTTP); optional documented fields include `args`, `headers`, `env`, `cwd`, `timeout`, `trust`, `includeTools`, and `excludeTools`. The generic mapper converts only the user file and validates the target shape; project MCP remains manual because the workflow has no scope selector.
- **rules**: global `~/.gemini/GEMINI.md` plus project/ancestor `GEMINI.md` files; the filename can be changed with `context.fileName`. The mapper's `rules` path is the repository-root `GEMINI.md`; global context and alternate filenames require manual review.
- **skills**: global `~/.gemini/skills/<name>/SKILL.md` (or the documented `~/.agents/skills/` alias) · project `.gemini/skills/<name>/SKILL.md` (or `.agents/skills/` alias). The mapper uses the canonical `.gemini/skills` paths for this target.
- **commands**: global `~/.gemini/commands/*.toml` · project `.gemini/commands/*.toml` · TOML with required `prompt` and optional `description`; `{{args}}`, `!{...}`, and namespaced subdirectories are documented. The generic prompts copier is Markdown-only, so Gemini commands are manual rather than copied as prompts.
- **agents**: global `~/.gemini/agents/*.md` · project `.gemini/agents/*.md`; YAML frontmatter requires `name` and `description`. The generic mapper has no agents object and leaves these files manual.
- **memory**: `/memory show`/`/memory add` manage hierarchical `GEMINI.md` context and private memory; memory state is not a portable automatic migration object.
- **note**: Official docs warn against underscores in MCP server aliases because policy FQN parsing can misidentify the server. The converter rejects aliases containing `_` and requires manual renaming plus review of allowlists/policies; it does not silently rewrite names.
- **sources**: [configuration](https://geminicli.com/docs/reference/configuration) · [MCP servers](https://geminicli.com/docs/tools/mcp-server/) · [Agent Skills](https://geminicli.com/docs/cli/using-agent-skills/) · [creating skills](https://geminicli.com/docs/cli/creating-skills/) · [GEMINI.md context](https://geminicli.com/docs/cli/gemini-md/) · [custom commands](https://geminicli.com/docs/cli/custom-commands/) · [subagents](https://geminicli.com/docs/core/subagents/)

### antigravity (IDE)
- **detect**: no officially documented IDE installation-detection path. Do not infer one from Antigravity IDE app data such as `~/.gemini/antigravity-ide/`.
- **mcp**: global `~/.gemini/config/mcp_config.json` · workspace `.agents/mcp_config.json` · root_key `mcpServers` · JSON · remote uses `serverUrl` (NOT `url`). The global file is shared by Antigravity 2.0, IDE, and CLI; the workspace file is an IDE-supported project scope.
- **rules**: global `~/.gemini/GEMINI.md` · workspace `.agents/rules/` (legacy `.agent/rules/` remains supported). Do not invent `.agents/AGENTS.md`.
- **skills**: global `~/.gemini/antigravity/skills/<name>/` · workspace `.agents/skills/<name>/SKILL.md` (legacy `.agent/skills/` remains supported).. The global scope is available across IDE workspaces; the workspace scope is project-only.
- **workflows**: global `~/.gemini/config/global_workflows/<name>.md` · workspace `.agents/workflows/`
- **plugins**: global `~/.gemini/config/plugins/<plugin>/` · workspace `.agents/plugins/<plugin>/` or `_agents/plugins/<plugin>/`. A plugin requires `plugin.json` and may contain `mcp_config.json`, `hooks.json`, `skills/<skill>/SKILL.md`, and `rules/<rule>.md`.
- **hooks**: global `~/.gemini/config/hooks.json` · workspace `.agents/hooks.json` · JSON object keyed by hook name. Supported events are `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation`, and `Stop`.
- **migration note**: `smart-ide-migration.sh` has only global MCP and global skills object handlers. It does not yet provide isolated plugin, hook, workspace-MCP, or workspace-rule-directory migration; use the documented locations above for manual review instead of treating them as unsupported IDE features.
- **sources**: [Antigravity IDE skills](https://antigravity.google/docs/ide/skills) · [Antigravity IDE rules](https://antigravity.google/docs/ide/rules) · [Antigravity MCP](https://antigravity.google/docs/mcp) · [Antigravity IDE plugins](https://antigravity.google/docs/ide/plugins) · [Antigravity IDE hooks](https://antigravity.google/docs/ide/hooks)

### amazon-q
- **detect**: `~/.aws/amazonq/`
- **project namespace**: `.amazonq/` (manual/diagnostic only; it contains separate rules and MCP scopes and must not be copied as one opaque directory)
- **mcp (IDE)**: project `.amazonq/default.json` and legacy `.amazonq/mcp.json` are documented, with root key `mcpServers` · JSON. Global automatic migration is disabled because AWS currently has conflicting official pages: the dedicated IDE page says `~/.aws/amazonq/default.json`, while the overview page says `~/.aws/amazonq/agents/default.json`. Review the active IDE UI and choose the version-appropriate file manually. Legacy `mcp.json` at either scope is supported only when `useLegacyMcpJson:true` is enabled in the applicable default configuration.
- **current IDE agents**: global `~/.aws/amazonq/agents/default.json` · project `.amazonq/agents/default.json`; these files combine prompt, tools, permissions, resources, hooks, and `mcpServers`, so they are manual and must not be flattened into a generic MCP file.
- **rules (IDE)**: project `.amazonq/rules/*.md` · Markdown files · directory migration is manual because the generic mapper only copies one file
- **prompts (IDE)**: global `~/.aws/amazonq/prompts/*.md` · `@PromptName` in the IDE · global/cross-project and manual in this mapper
- **personas**: global `~/.aws/amazonq/personas/default.json` · project `.amazonq/personas/default.json`; permissions and MCP references are security-sensitive and manual
- **agents/MCP (CLI)**: global `~/.aws/amazonq/cli-agents/` · separate CLI custom-agent/MCP scope; manual only and never confused with generic AWS CLI configuration or IDE `default.json`
- **skills**: no official Amazon Q Agent Skills path was found in the primary AWS docs reviewed; registry and automatic mapper leave global/project skills empty
- **product boundary**: Q CLI agent files `~/.aws/amazonq/cli-agents/*.json` / `.amazonq/cli-agents/*.json` are historical CLI state, distinct from IDE `agents/default.json`; Q CLI is now superseded by Kiro.
- **memory bank (IDE)**: project `.amazonq/rules/memory-bank/` · generated Markdown under the project-rules namespace. The path is official, but generated content/lifecycle is not a portable cross-IDE memory contract; keep it manual and never copy the whole directory automatically.
- **config/hooks**: no portable whole-config or standalone hook path/schema established for this mapper; keep manual/empty
- **sources**: [MCP in the IDE](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/mcp-ide.html) · [project rules](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/context-project-rules.html) · [saved prompts](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/context-prompt-library.html) · [memory bank](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/context-memory-bank.html) · [MCP with Amazon Q / CLI and IDE scopes](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/qdev-mcp.html) · [AWS language-server MCP source](https://raw.githubusercontent.com/aws/language-servers/main/server/aws-lsp-codewhisperer/src/language-server/agenticChat/tools/mcp/mcpUtils.ts) · [CLI agent locations](https://raw.githubusercontent.com/aws/amazon-q-developer-cli/main/docs/agent-file-locations.md) · [Amazon Q CLI repository](https://github.com/aws/amazon-q-developer-cli)

### opencode
- **detect**: `~/.config/opencode/`
- **mcp**: global `~/.config/opencode/opencode.json` · project `opencode.json` · root_key `mcp` · JSON · REQUIRES type:'local'|'remote' · command is ARRAY · env field is `environment`
- **rules**: `AGENTS.md` (via instructions field in config)
- **skills**: project `.opencode/skills/` · global `~/.config/opencode/skills/` · also loads `.claude/skills/`, `.agents/skills/`
- **commands**: project `.opencode/commands/*.md` · global `~/.config/opencode/commands/*.md` · frontmatter: description, agent, model · $ARGUMENTS, !`cmd`, @file templates
- **agents**: project `.opencode/agents/*.md` · global `~/.config/opencode/agents/*.md` · frontmatter: description, mode, model, tools, permission
- **hooks**: via `.opencode/plugins/*.ts` (TypeScript event-driven)
- **memory**: via plugins (OpenMemory, short-term-memory, agent-memory)
- **note**: Config is MERGED not replaced
- **sources**: [OpenCode Skills](https://opencode.ai/docs/skills/), [OpenCode MCP](https://opencode.ai/docs/mcp/), [OpenCode config](https://opencode.ai/docs/config/)

### goose-cli (Goose CLI)
- **status**: current Goose CLI/desktop documentation is published by the Agentic AI Foundation at `goose-docs.ai`; the CLI and desktop share core config/extension storage
- **detect/config**: POSIX primary config `~/.config/goose/config.yaml`; Windows `%APPDATA%\Block\goose\config\config.yaml` (the mapper's `~/.config/goose` path is the documented macOS/Linux form)
- **mcp/config**: global `~/.config/goose/config.yaml` · root key `extensions` · YAML, not JSON · extension entries use documented type-specific fields such as `builtin`/`platform`/`stdio`/`streamable_http`/`frontend`/`inline_python`, `cmd`, `args`, `envs`, `uri`, `headers`, `enabled`, `timeout`, and `available_tools`; legacy `sse` may appear for compatibility
- **skills**: global `~/.agents/skills/` · project `.agents/skills/` · `SKILL.md` in each named subdirectory; `.goose/skills/`, `.claude/skills/`, `~/.claude/skills/`, and platform-specific config directories are documented backward-compatible discovery locations, not this mapper's canonical targets
- **rules/context**: global `~/.config/goose/.goosehints`; local `.goosehints` at project/root or nested directories; `AGENTS.md` and other names are loaded when selected through `CONTEXT_FILE_NAMES` (default context names are `AGENTS.md` then `.goosehints`)
- **recipes**: global `~/.config/goose/recipes/` · local `.goose/recipes/` · YAML/JSON recipe files with instructions/extensions/parameters; NOT skills or MCP config
- **prompt templates**: global `~/.config/goose/prompts/` · no documented project prompt-template directory; custom slash commands are `slash_commands` entries in `~/.config/goose/config.yaml` pointing to recipe files
- **memory**: global `~/.config/goose/memory/` · local `.goose/memory/` · Memory extension-managed files; this is a directory/object store, not a portable rules or Skills path
- **other**: `~/.config/goose/permission.yaml` · `~/.config/goose/secrets.yaml` (or keyring); never copy secrets automatically
- **automatic migration boundary**: Skills and local `.goosehints` can use the dedicated low-risk paths. MCP/config/project/prompt operations involving Goose are manual because the format is YAML, scopes are mixed, and `config.yaml`/`secrets.yaml` are not interchangeable with another IDE's JSON schema
- **sources**: [Agent Skills](https://goose-docs.ai/docs/guides/context-engineering/using-skills/), [goosehints](https://goose-docs.ai/docs/guides/context-engineering/using-goosehints/), [configuration files](https://goose-docs.ai/docs/guides/config-files/), [using extensions](https://goose-docs.ai/docs/getting-started/using-extensions/), [prompt templates](https://goose-docs.ai/docs/guides/context-engineering/prompt-templates/), [recipes](https://goose-docs.ai/docs/guides/recipes/storing-recipes/), [slash commands](https://goose-docs.ai/docs/guides/context-engineering/slash-commands/), [Memory extension](https://goose-docs.ai/docs/mcp/memory-mcp/)

### openclaw (OpenClaw)
- **detect**: `~/.openclaw/`
- **mcp**: global `~/.openclaw/openclaw.json` · root_key `mcp.servers` (nested JSON path) · local `command` + `args`; remote `url` + `transport: "streamable-http"` · static config only
- **rules/context**: active workspace `AGENTS.md`; default `~/.openclaw/workspace`, configurable through `agents.defaults.workspace` in `openclaw.json`
- **skills**: workspace `<workspace>/skills/` · project-agent `<workspace>/.agents/skills/` · personal `~/.agents/skills/` · managed `~/.openclaw/skills/`; precedence is workspace, project-agent, personal, managed
- **config**: `~/.openclaw/openclaw.json`
- **project config root**: unsupported/manual; OpenClaw has no fixed project config directory. The active workspace is selected by `agents.defaults.workspace`, so do not infer a repository-relative config root.
- **validation/installation**: static JSON/frontmatter checks are safe. `openclaw mcp list`/`openclaw mcp doctor` and `openclaw skills install <slug>` are official runtime operations but are not run by this migration mapper; no install or live probe is automatic.
- **sources**: [skills](https://docs.openclaw.ai/tools/skills), [agent workspace](https://docs.openclaw.ai/concepts/agent-workspace), [MCP](https://docs.openclaw.ai/cli/mcp), [configuration](https://docs.openclaw.ai/gateway/configuration)

### aider
- **config**: `~/.aider.conf.yml` in the home directory, plus `.aider.conf.yml` in the git repository root or current directory; later-loaded files override earlier ones. An explicit file may be selected with `--config <filename>`.
- **rules/context**: `CONVENTIONS.md` is an ordinary read-only file; load it with `aider --read CONVENTIONS.md` or set `read: CONVENTIONS.md` in `.aider.conf.yml`.
- **global/environment config**: `.env` is searched in home, git root, and current directory; shell/environment configuration uses `AIDER_*` variables. CLI flags and `--env-file <filename>` are also supported. These are configuration mechanisms, not portable skills or prompt stores.
- **skills/prompts/commands**: no official Aider Skills directory or standalone prompt directory is documented. `/load <file>` loads commands from a user-selected file; no fixed `.aider.commands.md` path is claimed.
- **mcp/tools**: no native Aider MCP client/configuration is documented in the official configuration or command references; MCP migration is unsupported/manual.
- **automatic boundary**: only the path to `.aider.conf.yml` and `CONVENTIONS.md` is exposed for diagnostics. YAML/YML config, `.env`, environment variables, CLI flags, and `/load` command files require manual review; this mapper must not copy or rewrite another IDE's schema into Aider's YAML.
- **sources**: [configuration](https://aider.chat/docs/config.html), [YAML config file](https://aider.chat/docs/config/aider_conf.html), [environment/.env config](https://aider.chat/docs/config/dotenv.html), [coding conventions](https://aider.chat/docs/usage/conventions.html), [in-chat commands](https://aider.chat/docs/usage/commands.html), [options reference](https://aider.chat/docs/config/options.html)

### openhands
- **detect**: `~/.openhands/`
- **mcp** (CLI 1.0+): `~/.openhands/mcp.json` · root_key `mcpServers` · JSON · `openhands mcp list`
- **mcp** (GUI/legacy): `config.toml` [mcp] section · `sse_servers`/`shttp_servers`/`stdio_servers` arrays
- **rules**: `AGENTS.md`
- **skills**: project skills (via `load_project_skills()`, agentskills.io standard)
- **agents**: `~/.openhands-cli/persist/agent_settings.json`
- **memory**: Condenser system (config.toml [condenser]: type=amortized/llm_attention/llm_summarizing)

### replit (Replit AI)
- **project skills**: `.agents/skills/<name>/SKILL.md` · Agent Skills are project-scoped and follow the Agent Skills specification; `.local/secondary_skills/` is an official compatibility/discovery directory and must not be blindly merged with `.agents/skills/`.
- **rules/instructions**: `replit.md` at the project root · Agent reads, generates, and updates this living project context document; it does not automatically read arbitrary nested copies. The generic mapper therefore never overwrites it automatically.
- **enterprise template instructions**: `custom_instruction/instructions.md` can be included in a custom template; it is a project template file, not a user-global Replit settings path.
- **project app config**: `.replit` · runtime/app configuration such as run commands, ports, and modules; `replit.nix` is Nix/system-package configuration. These are not AI skills or portable AI config and are manual-only.
- **global skills/config**: no portable filesystem path documented for the user-level or enterprise/cloud-managed scopes; do not infer `~/.replit`, `~/.agents/skills`, or `~/.replit/replit.nix`.
- **MCP/integrations**: cloud/UI-managed through Replit Integrations and Agent MCP settings; no local MCP file target is exposed by this mapper. Custom MCP servers are added by HTTPS URL and may use custom headers; connections are shared across projects in Agent.
- **prompts**: Agent prompts are chat/UI input, not a documented portable prompt-file directory; automatic prompt migration is unsupported.
- **automatic boundary**: project paths are diagnostic/manual in this mapper; `.replit`/`replit.nix` project/runtime files, cloud-managed MCP/integrations, user/enterprise scopes, `custom_instruction/instructions.md`, and chat prompts remain manual or UI-managed. Never copy build/config files as skills.
- **sources**: [replit.md](https://docs.replit.com/features/project-setup/replit-dot-md), [Agent Skills](https://docs.replit.com/features/agent/skills), [Skills directory](https://docs.replit.com/features/agent/skills-directory), [Agent customization](https://docs.replit.com/features/agent/agent-customization), [project configuration](https://docs.replit.com/features/project-setup/configuration), [MCP integrations](https://docs.replit.com/build/connect-via-mcp), [custom templates and scopes](https://docs.replit.com/teams/custom-templates)

### sourcegraph-amp
- **detect**: `~/.config/amp/`
- **mcp**: via `amp mcp add <name> <url>` CLI (NOT config key) · `amp mcp list`
- **rules**: `AGENTS.md`
- **skills**: project `.amp/skills/<name>/SKILL.md` · global `~/.config/amp/skills/` / `~/.amp/skills/` / `~/.agents/skills/`
- **commands**: `~/.config/amp/` (slash commands)
- **agents**: built-in Oracle, Librarian, Painter, Code Review; custom via plugin API
- **hooks**: `~/.config/amp/plugins/*.ts` (TypeScript; events: session.start, agent.start/end, tool.result)
- **note**: Native HTTP+OAuth+DCR; no mcp-remote needed

### sourcegraph-cody
- **status**: Current official docs support Cody on Sourcegraph Enterprise (VS Code, JetBrains, Visual Studio, Web, and an experimental CLI). Free, Pro, and Enterprise Starter access ended July 23, 2025; Amp is the documented replacement for those tiers. See [Cody](https://sourcegraph.com/docs/cody), [Cody FAQs](https://sourcegraph.com/docs/cody/faq), and [Cody clients](https://sourcegraph.com/docs/cody/clients).
- **mcp**: unsupported for automatic file migration. Cody MCP is configured in the editor extension setting `cody.mcpServers` (VS Code `settings.json` or JetBrains `cody_settings.json`), or through the Cody MCP Settings UI; it is disabled by default, supports local servers and tools only, and requires the Enterprise `agentic-context-mcp-enabled` feature flag. See [Agentic Context Fetching](https://sourcegraph.com/docs/cody/capabilities/agentic-context-fetching). No portable standalone Cody MCP file is established here.
- **commands/prompts**: manual only. Current Cody prompts are created and stored in the Enterprise Prompt Library; the docs link legacy custom-command migration to that library and do not establish a portable workspace command file. See [Prompts](https://sourcegraph.com/docs/cody/capabilities/prompts).
- **skills/agents/rules/config/project**: unsupported/manual. Current official docs do not establish Cody Agent Skills, subagent definitions, `.codyrules`, a portable whole-Cody config file, or a portable project-instructions file. Do not infer `.cody`, `.codyrules`, `~/.config/cody/`, `~/.vscode/cody.json`, or `.vscode/cody.json` as automatic targets.
- **related product**: Sourcegraph MCP Server is a separate Enterprise server for external agents; it is configured in the client (for example `amp mcp add`), not as Cody's local MCP store. See [Sourcegraph MCP Server](https://sourcegraph.com/docs/api/mcp).

---

## Forge / PearAI / Void

### forge
- **detect**: `~/.forge/` (FORGE_CONFIG env var can override)
- **mcp**: global `~/.forge/.mcp.json` · project `./.mcp.json` · root_key `mcpServers` · JSON · `forge mcp import/list`
- **rules**: `forge.yaml` custom_rules field · also `AGENTS.md`
- **skills**: project `.forge/skills/<name>/SKILL.md` · global `~/forge/skills/` · also `~/.agents/skills/`
- **commands**: `forge.yaml` commands array
- **agents**: `.forge/agents/<name>.md` · built-in: Forge, Sage, Muse
- **other**: `forge.yaml` (main config) · `.forge/templates/`

### pearai
- **official evidence**: [PearAI app repository](https://github.com/trypear/pearai-app) documents PearAI as a VS Code fork; [PearAI submodule repository](https://github.com/trypear/pearai-submodule) documents the bundled AI extension as a Continue fork.
- **automatic paths**: none documented by PearAI. Do not infer `~/.pearai`, `.pearai`, `.pearairules`, or any VS Code/Continue path as a PearAI contract.
- **mcp**: manual/UI/extension-managed only; PearAI's official repositories do not publish a portable MCP file, root key, or server schema.
- **rules/skills/prompts/config**: manual only; no PearAI-owned portable paths or file schemas are documented in the official repositories.
- **evidence gap**: the repositories establish provenance (VS Code + Continue forks), not PearAI storage paths or configuration schemas. The mapper therefore fails closed rather than treating PearAI as VS Code, Cursor, or Continue.

### void-editor
- **status**: the official repository is archived and its README says Void is deprecated, although the official website still advertises a beta; treat the Void-specific store as a legacy target and do not copy its whole data directory
- **mcp (Void-specific)**: global `~/.void-editor/mcp.json` · root key `mcpServers` · JSON · local `command`/`args`/`env`; remote `url` is recognized, but authenticated/header-bearing remote entries are manual because the archived runtime does not reliably pass headers to the transport
- **mcp (inherited VS Code)**: project `.vscode/mcp.json` with root key `servers`, plus profile/UI-managed user MCP and multi-root workspace settings; this is a distinct inherited VS Code surface and is diagnostic/manual here, never written by the Void-specific global converter
- **rules**: `.voidrules` is read at the workspace-folder root and concatenated across multi-root folders; it is plain text/Markdown without a frontmatter contract. Global AI Instructions remain UI-managed.
- **skills/config/commands/agents/hooks/memory**: no first-party portable Agent Skills, whole-config, user command, agent, hook, or portable memory path was established; manual/UI only
- **sources**: [Void official site](https://voideditor.com/), [Void repository](https://github.com/voideditor/void), [product.json](https://raw.githubusercontent.com/voideditor/void/main/product.json), [custom MCP service](https://github.com/voideditor/void/blob/main/src/vs/workbench/contrib/void/common/mcpService.ts), [native MCP discovery](https://github.com/voideditor/void/blob/main/src/vs/workbench/contrib/mcp/common/discovery/configMcpDiscovery.ts), [`.voidrules` consumer](https://github.com/voideditor/void/blob/main/src/vs/workbench/contrib/void/browser/convertToLLMMessageService.ts), [Void changelog](https://voideditor.com/changelog)

---

## Tabnine / Helix / Neovim

### tabnine
- **detect**: `~/.tabnine/`
- **mcp**: global `~/.tabnine/mcp_servers.json` · project `.tabnine/mcp_servers.json` · root_key `mcpServers` · JSON · stdio auto from command, HTTP from url
- **rules**: `.tabnine/guidelines/`
- **other**: Enterprise MCP Governance (Admin Console whitelist)

### supermaven
- **official evidence**: [Supermaven Download](https://supermaven.com/download) lists JetBrains, VS Code, and Neovim host integrations; the [official supermaven-nvim README](https://github.com/supermaven-inc/supermaven-nvim#readme) configures the plugin through Neovim's `setup()` call and reports logs under Neovim's `stdpath("cache")`. The [official maintainer issue](https://github.com/supermaven-inc/supermaven-nvim/issues/85) describes `~/.supermaven` as the `sm-agent` runtime/binary location and `.supermavenignore` as an indexing-exclusion file.
- **automatic paths**: none documented. Do not treat `~/.supermaven` as a global Skills/config directory, `.supermaven` as a project namespace, or `.supermavenignore` as instruction rules.
- **skills/rules/prompts/MCP/config/project**: manual/host-editor only; no portable Supermaven-owned file schema is published by the first-party sources above.
- **evidence gap**: Supermaven's official web and host-plugin documentation do not publish a portable per-OS Skills, rules, MCP, prompt, or standalone config path/schema. The mapper therefore leaves every automatic object unsupported and fails closed.

### blackbox (Blackbox AI)
- **scope**: This mapper token covers the Blackbox CLI/project Skills surface. The standalone AI-Native IDE and VS Code Agent docs describe editor/UI features but do not publish a portable local configuration layout.
- **detect**: project `.blackbox/` only (the parent namespace shown by the official Skills examples); no global detection path is claimed
- **project skills**: `.blackbox/skills/<name>/SKILL.md` · JSON path value `.blackbox/skills` · the official `/skill` guide says Skills are stored there, auto-discovered, and the generated `SKILL.md` uses YAML frontmatter with `name` and `description`
- **global skills**: unsupported/empty; current first-party docs do not publish a user-global Skills directory
- **rules / prompts**: unsupported/empty; `/skill` is an in-session command, not a portable prompt or rules directory
- **MCP**: unsupported/empty; `blackbox mcp` is documented as running bundled MCP servers, not as reading a portable user/project MCP file or a published server-map root/schema
- **config**: unsupported/empty; `blackbox configure` is interactive, but current first-party docs do not publish its storage path or schema
- **automatic migration boundary**: `.blackbox/skills/` is exposed for diagnosis, but the generic `skills` operation only migrates global directories and has no project-scope selector. Review/copy the project Skills subtree manually. Never infer `~/.blackbox`, `.blackbox/mcp.json`, `.blackbox/rules`, or copy the whole `.blackbox` namespace as opaque configuration.
- **sources**: [Skills Management](https://docs.blackbox.ai/features/blackbox-cli/skills), [Commands reference](https://docs.blackbox.ai/features/blackbox-cli/commands-reference), [CLI getting started](https://docs.blackbox.ai/features/blackbox-cli/getting-started), [VS Code Agent key features](https://docs.blackbox.ai/features/vscode-agent/key-features), [AI-Native IDE](https://www.blackbox.ai/ide)

### pieces (Pieces for Developers)
- **role**: PiecesOS + Pieces Desktop/CLI + editor integrations; Pieces is the local MCP **server/provider**, not a file-backed MCP client or portable Agent Skills host.
- **automatic migration**: **unsupported/empty for every object** (`skills`, `rules`, `prompts`, `mcp`, `config`, `project`, `project-mcp`, and `project-config`). The official docs do not define `~/.pieces`, `.pieces`, a `SKILL.md` directory, a project rules file, or a Pieces-owned MCP/config file; the mapper must not infer any of them.
- **MCP setup**: enable PiecesOS/LTM and configure the consuming client from PiecesOS/Desktop **Settings → MCP** (the active port/endpoint is copied from that UI), or use the Pieces CLI's `pieces mcp setup`. Current official examples include Streamable HTTP `http://localhost:39300/model_context_protocol/2025-03-26/mcp` and legacy SSE `http://localhost:39300/model_context_protocol/2024-11-05/sse`; the port may vary and these are server endpoints, not Pieces path mappings. Sources: [Pieces MCP overview](https://docs.pieces.app/products/mcp), [Cursor setup](https://docs.pieces.app/products/mcp/cursor), [Claude Code setup](https://docs.pieces.app/products/mcp/claude-code), [Pieces CLI](https://docs.pieces.app/products/cli/get-started).
- **local data (reference only)**: PiecesOS stores its database/logs in platform-specific application data locations such as macOS `~/Library/com.pieces.os/`, Linux `~/.local/share/com.pieces.os/`, and the documented Windows application-data directory. These are non-portable databases, not skills/rules/config, and must never be migrated. Source: [Pieces on-device storage](https://docs.pieces.app/extensions-plugins/raycast/troubleshooting).
- **editor integrations**: Pieces' VS Code integration is an extension backed by PiecesOS; project materials are managed through the extension/Drive/Copilot rather than a documented `.pieces` project namespace. Source: [Pieces VS Code extension](https://docs.pieces.app/extensions-plugins/vscode).

### helix
- **detect**: `~/.config/helix/`
- **mcp**: `~/.config/helix/config.toml` · root_key `mcp_servers` · TOML · via helix-ai plugin · tools-only (no Resources/Prompts/Sampling)
- **rules**: `HELIX.md` (via helix-ai plugin, project-level)
- **other**: `~/.config/helix/languages.toml` (LSP config)

### neovim
- **detect**: `~/.config/nvim/` is the documented Unix user config directory (the effective path is XDG/NVIM_APPNAME-dependent)
- **config**: `~/.config/nvim/init.lua` (or `init.vim`) is Neovim editor configuration; `init.lua` and `init.vim` cannot both be used as the startup config
- **skills / rules / prompts / MCP / project config**: unsupported by core Neovim and intentionally empty in `ide-paths.json`; plugin-specific AI integrations are separate products and are not treated as native Neovim mappings
- **automatic migration**: config path is diagnostic-only. The generic mapper fails closed for any migration involving Neovim because it cannot safely convert another IDE's schema into Lua or replace an existing Neovim config without manual review
- **sources**: [Neovim startup and standard paths](https://neovim.io/doc/user/starting/), [Neovim Lua guide](https://neovim.io/doc/user/lua-guide/), [Neovim Nvim introduction](https://neovim.io/doc/user/nvim/)

### mcphub-nvim
- **detect**: `~/.config/nvim/`
- **mcp**: `~/.config/mcphub/servers.json` · root_key `mcpServers` (also supports `servers` for VS Code compat) · JSON5 · `${env:VAR}` variables · verify: `:McpHub`
- **note**: Compatible with `.vscode/mcp.json`; can share config with VS Code/Cursor/Cline/Zed

### codecompanion-nvim
- **detect**: `~/.config/nvim/`
- **mcp**: Lua config · `mcp.servers` key · verify: `/mcp` in chat buffer
- **rules**: reads `.clinerules`, `.cursorrules`, `AGENTS.md`, `CLAUDE.md`, `.goosehints` (configurable)
- **commands**: `prompt_library` Lua table · `.prompts/*.md` (v18.0.0+)
- **hooks**: Events/Hooks system (Lua callbacks)

---

## Chinese AI Assistants

### tongyi-lingma (DEPRECATED — renamed to Qoder CN on 2026-05-20, see `qoder-cn`)
- **status**: legacy installs only; new installs use `~/.qoder/`. Paths below remain valid for pre-rename installs.
- **detect**: `~/.lingma/`
- **mcp**: project `.lingma/mcp-settings.json` · root_key `mcpServers` · JSON · GUI primary · ModelScope MCP plaza 3000+
- **rules**: project `.lingma/<rulename>.md`
- **skills**: project `.lingma/skills/<name>/SKILL.md` · global `~/.lingma/skills/`
- **commands**: project `.lingma/commands/` · global `~/.lingma/commands/`
- **agents**: project `.lingma/agents/<name>.md` · global `~/.lingma/agents/` · frontmatter: name, description, tools

### baidu-comate
- **detect**: `~/.comate/`
- **mcp**: global `~/.comate/mcp.json` · project `.comate/mcp.json` · local `.comate/mcp.local.json` · root_key `mcpServers` · JSON · type `stdio|sse|streamableHttp`
- **rules**: `.comate/rules/*.mdr` — unique .mdr format (Markdown + Comate extensions) · Cursor Rules compatible · 4 activation modes
- **skills**: `.agents/skills/` or `.comate/skills/` · global `~/.comate/skills/`
- **agents**: `.comate/agents/` · global `~/.comate/agents/`
- **note**: Three-tier config (global/project/local); .mdr is unique format
- **sources**: [Comate Skills](https://cloud.baidu.com/doc/COMATE/s/Nmma28iqe), [Comate MCP.json](https://cloud.baidu.com/doc/COMATE/s/Ymir0x2ye)

### tencent-codebuddy
- **product boundary**: this mapper ID is **CodeBuddy Code CLI**. The standalone CodeBuddy IDE is the separate `tencent-codebuddy-ide` section below and is not a `SUPPORTED_IDES` target; never reuse the CLI's `.mcp.json`/settings paths for the IDE UI.
- **detect**: `~/.codebuddy/`
- **mcp**: user `~/.codebuddy/.mcp.json` (recommended; legacy `~/.codebuddy/mcp.json` and `~/.codebuddy.json` are fallback locations) · project `.mcp.json` (legacy `mcp.json` fallback) · root_key `mcpServers` · JSON. The generic mapper auto-handles only the recommended user file; project/legacy/`--mcp-config` precedence remains manual.
- **rules**: project/user `CODEBUDDY.md`; global `~/.codebuddy/settings.json`, project `.codebuddy/settings.json`, and `.codebuddy/settings.local.json` are separate security/config scopes
- **skills**: project `.codebuddy/skills/<name>/SKILL.md` · global `~/.codebuddy/skills/` · frontmatter: name, description, allowed-tools, context, agent, model, hooks
- **commands**: project `.codebuddy/commands/`
- **agents**: project `.codebuddy/agents/*.md` · global `~/.codebuddy/agents/*.md` · frontmatter: name, description, tools, model
- **memory**: CLI static context `CODEBUDDY.md`; CLI auto memory `~/.codebuddy/memories/{project-id}/` and `global/` is generated state; CodeBuddy IDE memory is UI-managed. Do not copy either memory store automatically.
- **hooks**: CLI settings JSON hooks in `~/.codebuddy/settings.json`, `.codebuddy/settings.json`, or local settings; IDE hooks/events are a separate UI/product schema. Do not copy or execute hooks automatically.
- **other**: `settings.json` / `settings.local.json`
- **sources**: [CodeBuddy CLI Skills](https://www.codebuddy.cn/docs/cli/skills), [CodeBuddy CLI MCP](https://www.codebuddy.cn/docs/cli/mcp), [CodeBuddy CLI Memory](https://www.codebuddy.cn/docs/cli/memory), [CodeBuddy CLI Hooks](https://www.codebuddy.cn/docs/cli/hooks), [CodeBuddy CLI Sub-agents](https://www.codebuddy.cn/docs/cli/sub-agents), [CodeBuddy IDE Skills](https://www.codebuddy.cn/docs/ide/Features/Skills), [CodeBuddy IDE MCP](https://www.codebuddy.cn/docs/ide/User-guide/MCP), [CodeBuddy IDE Subagents](https://www.codebuddy.cn/docs/ide/Features/Subagents)

### kimi-code (Moonshot AI)
- **detect**: `~/.kimi-code/` (env var `KIMI_CODE_HOME` overrides; legacy kimi-cli used `~/.kimi/` with `KIMI_SHARE_DIR`)
- **mcp**: global `~/.kimi-code/mcp.json` · project `<cwd>/.kimi-code/mcp.json` · root_key `mcpServers` · JSON · stdio+HTTP+SSE · `kimi mcp list`
- **rules**: global `~/.kimi-code/AGENTS.md` · project `AGENTS.md` (also `.kimi-code/AGENTS.md`, any subdir) · `/init` auto-generates
- **skills**: global `~/.kimi-code/skills/` / `~/.agents/skills/` · project `.kimi-code/skills/` / `.agents/skills/` · extra dirs via `config.toml extra_skill_dirs`
- **commands**: built-in slash commands (`/mcp`, `/init`, `/skill:<name>`, `/hooks`, `/config`) · plugin commands (`<plugin>:<cmd>`) · NO standalone commands dir
- **agents**: current custom agents are recursively discovered Markdown files in `$KIMI_CODE_HOME/agents/` (default `~/.kimi-code/agents/`) and project `.kimi-code/agents/` / `.agents/agents/`; generic user `~/.agents/agents/` also remains supported. Frontmatter requires `description` and may include `name`, `whenToUse`, `override`, `model_preference`, `tools`, `disallowedTools`, and `subagents`. Explicit `--agent-file` Markdown has highest priority; older YAML/`system_prompt_path` agent-file formats are legacy and manual.
- **hooks**: `~/.kimi-code/config.toml` `[[hooks]]` array · 13 events (PreToolUse, PostToolUse, PostToolUseFailure, UserPromptSubmit, Stop, StopFailure, SessionStart, SessionEnd, SubagentStart, SubagentStop, PreCompact, PostCompact, Notification) · blocking: PreToolUse, Stop, UserPromptSubmit
- **memory**: no native memory · sessions at `~/.kimi-code/sessions/<workDirKey>/<id>/` (context.jsonl, wire.jsonl, state.json) · plans at `~/.kimi-code/plans/<slug>.md`
- **other**: `~/.kimi-code/config.toml` (main config, TOML NOT JSON) · `~/.kimi-code/tui.toml` · `~/.kimi-code/credentials/` · `~/.kimi-code/mcp-oauth/`
- **note**: Path is `~/.kimi-code/` NOT `~/.kimi/`; config is `config.toml` NOT `config.json`; legacy kimi-cli deprecated

### workbuddy (WorkBuddy)
- **detect**: `~/.workbuddy/`
- **mcp**: global `~/.workbuddy/mcp.json` · project `.workbuddy/mcp.json` · root_key `mcpServers` · JSON · the official desktop example is local command-based (`command`, optional `args`, optional `env`); remote URL/headers/type/transport fields are not established by the desktop docs and are rejected by automatic conversion; configured in the WorkBuddy UI
- **skills**: built-in/marketplace Skills and local Skill-package import through the Skills UI; the official desktop docs describe `skill.yml` packages and import/install flows but publish no portable global/project Skills directory
- **memory**: generated private memory is managed in the WorkBuddy UI; the official page documents nightly summaries and an interactive import flow, not a portable filesystem path or schema. Keep memory manual and never copy generated state.
- **settings**: UI-managed; the official release notes confirm an independent `.workbuddy/` namespace but do not establish a portable whole-settings file for this mapper
- **sources**: [WorkBuddy MCP](https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/MCP-Guide), [WorkBuddy Skills](https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/Skills-Market), [WorkBuddy custom Skills](https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Practice-Cases/Create-Skills), [WorkBuddy memory](https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/Memory), [WorkBuddy task bar/OpenClaw import](https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/Task-Bar), [CodeBuddy/WorkBuddy config separation](https://www.workbuddy.ai/docs/cli/release-notes/v2.48.0)

### zcode (Zhipu AI)
- **detect**: `~/.zcode/`
- **mcp**: global `~/.zcode/cli/config.json` · project `.zcode/config.json` · root_key `mcp.servers` (dot-path; also accepts `mcpServers`) · JSON · stdio+SSE+HTTP · can import from ~/.claude, ~/.codex, ~/.config/opencode, ~/.agents
- **rules**: global `~/.zcode/AGENTS.md` · project `AGENTS.md` (uses AGENTS.md NOT CLAUDE.md; onboarding one-time CLAUDE.md import only)
- **skills**: global `~/.zcode/skills/<name>/SKILL.md`; project import target is UI-managed and no stable project Skills path is published in the reviewed docs
- **commands**: user-level + project-level commands dirs (Markdown)
- **agents**: user-only `~/.zcode/agents/<name>.md` (Markdown); current Beta Settings flow does not provide a stable project `.zcode/agents/` creation path. Plugin-bundled subagents are managed by the plugin/UI and are not a portable project-agent directory.
- **hooks**: plugin-bundled/UI automation; no stable standalone global/project hooks file was established in the reviewed ZCode docs, so hooks remain manual-only
- **memory**: no stable portable memory directory/schema was established in the reviewed official docs; treat any agent-memory/UI state as manual
- **other**: API Key config via GUI (BigModel / Z.AI / Anthropic / OpenRouter / custom)
- **note**: Root key `mcp.servers` (dot notation); uses `AGENTS.md` not `CLAUDE.md`; ZCode ≠ CodeGeeX (CodeGeeX has NO MCP/skills/rules)
- **sources**: [ZCode Skills](https://zcode.z.ai/en/docs/skill), [ZCode MCP](https://zcode.z.ai/cn/docs/mcp-services), [ZCode Agent instructions](https://zcode.z.ai/en/docs/agents), [ZCode Subagents](https://zcode.z.ai/en/docs/subagents), [ZCode Plugins](https://zcode.z.ai/en/docs/plugin)

### minimax-code (MiniMax)
- **detect**: MiniMax Code desktop app (user data dir, path not publicly documented)
- **mcp**: MCP client capability not officially documented; built-in Agent Team / Skills / Memory system instead
- **skills**: built-in Skills system (domain capabilities: doc processing, table analysis, PDF parsing, content writing)
- **agents**: Agent Team (multi-agent cluster, auto task decomposition, parallel sub-agents)
- **memory**: 3-tier: session-level + agent-level + global-level (experience accumulation, long-term knowledge)
- **schedule**: built-in task scheduler (daily reports, email checks, periodic inspection)
- **note**: Official recommends mmx CLI over MCP; desktop config not file-exposed

### mmx-cli (MiniMax CLI)
- **detect**: `~/.mmx/`
- **mcp**: N/A (mmx IS the tool, not an MCP client) · config `~/.mmx/config.json` · JSON · Zod validated
- **skills**: `npx skills add MiniMax-AI/cli` symlinks to `~/.claude/skills/`, `~/.openclaw/skills/`, TRAE, OpenCode, etc.
- **commands**: `mmx text chat`, `mmx image generate`, `mmx video generate`, `mmx speech synthesize`, `mmx music generate`, `mmx vision describe`, `mmx search query`
- **note**: Region trap: global=api.minimax.io / cn=api.minimaxi.com (extra 'i'); API Key + Host must match region; `mmx config set --key region --value global|cn` if 401

### qoder-cn (Alibaba — formerly Tongyi Lingma, renamed 2026-05-20)
- **detect**: `~/.qoder/` (formerly `~/.lingma/`)
- **mcp** (IDE): Settings → MCP Servers UI panel · root_key `mcpServers` · JSON
- **mcp** (CLI): `qodercli mcp add <name> -- <command> <args>` · config at `~/.qoder/`
- **rules**: project `AGENTS.md` (universal standard, not .cursorrules)
- **skills**: Quest 2.0 system · Experts (specialist agents) · Subagent system
- **commands**: `qodercli` CLI commands
- **agents**: Quest 2.0 multi-agent · Experts (specialist team)
- **note**: Renamed from Tongyi Lingma on 2026-05-20; Qoder CN (GLM/DeepSeek/Kimi/MiniMax models) vs Qoder (qoder.com, GPT/Claude); supports ModelScope MCP plaza

### baidu-comate-ide (Baidu — standalone IDE, distinct from plugin)
- **detect**: Comate AI IDE desktop app (download from comate.baidu.com)
- **mcp**: Zulu agent dialog → MCP icon config · root_key `mcpServers` · JSON · stdio+HTTP
- **rules**: `.mdr` files · 3 activation modes (always/manual/fileMatch) · same .mdr format as plugin version
- **agents**: Zulu multi-agent system (default entry) · Custom Agent · domain agents
- **commands**: slash commands
- **note**: Standalone IDE (2025-06-23 released) distinct from plugin version; global Rules/MCP config only since 2025-08 late version; cannot install official MS Python/C++ plugins (use BasedPyright/clangd)

### tencent-codebuddy-ide (Tencent — standalone IDE, distinct from plugin)
- **detect**: CodeBuddy IDE desktop app
- **mcp**: IDE Settings → MCP · root_key `mcpServers` · JSON · the standalone IDE docs show the JSON schema and UI, but do not publish a portable user/project MCP file path; manual/UI-only
- **project rules**: `.codebuddy/rules/<name>/RULE.mdc` · project rules are version-controlled and use Markdown plus CodeBuddy frontmatter (`description`, `alwaysApply`, `enabled`, `updatedAt`, optional `provider`)
- **project/user skills**: `.codebuddy/skills/` is the canonical project location; the IDE exposes user Skills through its Settings path picker, but the reviewed official docs do not publish a stable user filesystem path
- **context**: project-root `CODEBUDDY.md` is supported; `AGENTS.md` is a compatibility fallback when `CODEBUDDY.md` is absent
- **commands/agents/hooks/memory**: UI/IDE-managed or not given a portable standalone path in the reviewed IDE docs; do not reuse the CLI's global MCP/settings paths for the IDE
- **note**: Standalone IDE is distinct from CodeBuddy Code CLI/plugin. Sources: [CodeBuddy IDE overview](https://www.codebuddy.cn/docs/ide/User-guide/Overview), [IDE Skills](https://www.codebuddy.cn/docs/ide/Features/Skills), [IDE Rules](https://www.codebuddy.cn/docs/ide/User-guide/Rules), [IDE MCP](https://www.codebuddy.cn/docs/ide/User-guide/MCP), [IDE slash commands](https://www.codebuddy.cn/docs/ide/User-guide/Slash-Commands)

### iflycode (iFlytek)
- **detect**: iFlyCode desktop client / plugin
- **mcp**: via UI config bar (paste JSON) · root_key `mcpServers` · JSON
- **rules/skills/commands/agents/hooks/memory**: primarily UI-configured; no documented file-level project config paths
- **note**: Limited public docs on file-level config; MCP via UI only

### raccoon-ai (SenseTime)
- **detect**: Raccoon AI desktop client
- **mcp**: via UI config bar (paste JSON) · root_key `mcpServers` · JSON
- **rules/skills**: UI-configured; no documented file-level project config paths
- **note**: Limited public docs on file-level config; MCP via UI only

### monkeycode (Chaitin Tech)
- **detect**: `~/.monkeycode/` (AGPL-3.0 open source, private deploy supported)
- **mcp**: root_key `mcpServers` · JSON · multi-model dispatch middleware
- **rules**: SDD (Spec-Driven Development) specification files
- **skills**: MonkeyScan security scanning · Git async workflow (@Monickname task dispatch)
- **note**: Enterprise security-focused; AGPL-3.0 fully open source; supports offline private deployment

### vecli (Volcano Engine)
- **detect**: `~/.vecli/` (npm `@volcengine/vecli`, 2025-09 released)
- **mcp**: root_key `mcpServers` · JSON · deep integration with Volcano cloud services · AK/SK or SSO auth
- **rules**: `AGENTS.md`
- **models**: Doubao 1.6, Kimi-K2, DeepSeek v3.1 (via Volcano Ark)
- **note**: Distinct from Trae CLI (different ByteDance product line: Volcano Engine vs Trae brand); `ve`/`@volcengine/cli` is cloud-resource CLI (NOT AI tool) — do not confuse

---

## Cloud / Web AI Platforms

### bolt-new (StackBlitz)
- **detect**: `~/.boltai/`
- **mcp**: `~/.boltai/mcp.json` · root_key `servers` (NOT `mcpServers`!) · JSON · stdio · supports import from Cursor/Claude Desktop · Smithery CLI auto-config · remote MCP via `mcp-remote`
- **note**: bolt.diy (open source) uses same `servers` root key; UI Plugin Dropdown to enable/disable; API key/MCP OAuth/None auth

### qodo (formerly CodiumAI)
- **detect**: VS Code/JetBrains plugin (Qodo Gen) + CLI (Qodo Command)
- **mcp**: IDE Tools Management UI · root_key `mcpServers` · JSON · local (stdio) + remote SSE (`url` field) · Qodo CLI supports `--mcp` (self as MCP server)
- **agents**: `agents/<command-name>.toml` (TOML format: instructions, tools, commands)
- **note**: CodiumAI ≠ Codeium (Codeium→Windsurf); Enterprise has "Agentic Tools Allow List"; open-aware context engine at `https://open-aware.qodo.ai/mcp/`

### devin (Cognition)
- **detect**: Cloud SaaS (dashboard config, no local files)
- **mcp**: Devin dashboard → MCP marketplace (50+ servers) · root_key `mcpServers` · JSON · stdio+SSE+HTTP · also exposes `https://mcp.devin.ai/mcp` as server
- **note**: Cloud-config only; bidirectional MCP (client + server); Devin's wiki exposed via MCP

### v0 (Vercel)
- **detect**: Web platform (`v0.app/chat/settings/mcp-connections`)
- **mcp**: UI config (chat connectors) · auth: No Auth / Custom Headers / Bearer Token / OAuth 2.1 · also exposes `https://mcp.v0.dev` / `https://mcp.vercel.com` as server
- **note**: Bidirectional MCP; Vercel MCP server only supports whitelisted AI clients; v0+MCP is 2026-03 feature

### lovable
- **detect**: Web platform (`lovable.dev`)
- **mcp**: Chat Connectors UI (client side) · built-in connectors: Notion, Linear, Jira, Confluence, n8n, Miro, Sentry · auth: OAuth/Bearer/None · also exposes `https://mcp.lovable.dev` as server (Research Preview, 2026-05)
- **note**: Bidirectional MCP; server-side OAuth limited to ChatGPT/Claude/Claude Code/Cursor/VS Code; Enterprise server disabled by default

### gptel-mcp-el (third-party Emacs packages)
- **status**: manual/unsupported by the native Emacs mapper
- **mcp**: `mcp.el`/gptel integration is package-specific Emacs Lisp configuration; no native GNU Emacs MCP path or schema is claimed here
- **note**: package installation, init-file snippets, server registration, and any package state require manual review; do not treat `~/.emacs.d/` as a native AI skills directory

---

## Cross-IDE Memory Solutions

| Solution | Type | Setup | Privacy | Cross-IDE |
|----------|------|-------|---------|-----------|
| **mem0 Cloud** | MCP server (HTTP) | `https://mcp.mem0.ai/mcp` + API key | Cloud | All MCP clients |
| **OpenMemory MCP** | MCP server (local Docker) | `http://localhost:8765` | Local | All MCP clients |
| **Pieces LTM-2.7** | MCP server (local PiecesOS) | Configure the active endpoint from PiecesOS/Desktop Settings → MCP; examples `http://localhost:{port}/model_context_protocol/2025-03-26/mcp` or legacy `/2024-11-05/sse` | Local | All MCP clients |
| **Cline memory-bank** | Markdown files | `memory-bank/*.md` in project | Local | Manual copy |
| **Claude Code memory** | Markdown files | `~/.claude/projects/<encoded>/memory/` | Local | Manual copy |

For MCP-based memory (mem0, OpenMemory, Pieces): install/configure the MCP server in the target IDE via its standard MCP config. Pieces is configured as a server endpoint supplied by PiecesOS/Desktop, not by copying a Pieces-owned database or guessed path; memory stays on device unless the user enables cloud features.

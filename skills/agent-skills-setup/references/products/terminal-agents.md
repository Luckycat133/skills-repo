# Terminal agents and their native context

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## mistral-vibe

**Mistral Vibe Code and Vibe Work** · Evidence: `documented-subset` · Runtime: `not-run`.

Vibe Code has CLI, IDE and web surfaces; Vibe Work is a separate product. Inventory `~/.vibe/config.toml` and project/admin layers, Skills in native `.vibe` and shared `.agents` locations, configured skill paths, agents, MCP, hooks and plugins.

Agent configuration can enable/disable Skills and change tools/permissions. Preserve user-invocable versus model-selected behavior. Plugins can supply Skills, MCP, agents and hooks; a user-named MCP server may shadow a plugin server. Do not copy approvals or assume every plugin component is available in every surface.

Use version-matched TOML schema and actual config roots. Verify Skill discovery plus agent-level availability, selected MCP source, and unrelated settings. For Vibe Work, confirm supported UI/export/import mechanisms instead of writing Code CLI files into its application data.

Official sources: [1](https://docs.mistral.ai/vibe/code/overview) · [2](https://docs.mistral.ai/vibe/code/cli/configuration) · [3](https://docs.mistral.ai/vibe/code/cli/skills) · [4](https://docs.mistral.ai/vibe/code/cli/agents) · [5](https://docs.mistral.ai/vibe/code/cli/plugins)

## forge

**ForgeCode, not another Forge product** · Evidence: `version-sensitive` · Runtime: `not-run`.

Inventory AGENTS, `.forge/skills`, commands, agents, MCP and TOML configuration. Current docs use `.forge.toml`, not a universal `forge.yaml`. Official pages show differing home examples (`~/forge` versus `~/.forge`); resolve `FORGE_CONFIG` and the installed CLI's active file before writing.

Do not derive a global root from the repository name. MCP JSON, agent definitions and command/config TOML need separate parsing. Forge permissions for built-in tools are not necessarily equivalent to MCP approval policy. Preserve user/system instructions and project scope; keep package installation out of migration.

Check the native config loader, Skill discovery and selected MCP container. Record the version/path decision in MIGRATION.md so another device does not recreate the conflicting documentation default.

Official sources: [1](https://forgecode.dev/docs/skills/) · [2](https://forgecode.dev/docs/forge-config/) · [3](https://forgecode.dev/docs/zsh-support/) · [4](https://forgecode.dev/docs/permissions/)

## aider

**Aider** · Evidence: `documented-subset` · Runtime: `not-run`.

Aider's conventions are read-only context files explicitly loaded through `--read`, `/read` or the `read` configuration entry. A filename such as CONVENTIONS.md is not magically loaded merely because it exists.

Inventory layered `.aider.conf.yml`, selected read-only conventions, custom prompts/commands and ignore settings. Provider configuration, chat/input history, caches and checkpoints are not portable instructions. Aider does not become a native Agent Skills/MCP host just because another tool can wrap it.

Translate reviewed rules into a read-only convention document and bind that document explicitly in the destination configuration. Preserve YAML and paths relative to the proper scope. Check a harmless rule is present in the active read-only context; do not run source commands during migration.

Official sources: [1](https://aider.chat/docs/usage/conventions.html) · [2](https://aider.chat/docs/config/aider_conf.html) · [3](https://aider.chat/docs/faq.html)

## pi

**Pi coding agent** · Evidence: `version-sensitive` · Runtime: `not-run`.

Current Pi documentation includes native Skills and native MCP. The old blanket assertion that Pi lacks MCP is stale. Inventory native/shared Skill roots, AGENTS/context files, prompt templates, extensions, packages and settings. Subagents or extra tools may come from installed extensions, not built-in file contracts.

Current MCP uses user `~/.pi/agent/mcp.json` and project `.pi/mcp.json`, with project trust and documented transport/auth rules. Project server definitions normally replace user definitions; knob-only overrides for enablement/exposure can preserve base connection fields. Do not flatten those into a naive union.

Skills can disable model invocation and still have explicit invocation behavior. TypeScript extensions and packages are executable. Check the installed Pi version, Skills listing, effective MCP definition and plugin-owned capabilities; preserve extension origin and never migrate remembered trust.

Official sources: [1](https://pi.dev/docs/latest/skills) · [2](https://pi.dev/docs/latest/mcp) · [3](https://pi.dev/docs/latest/extensions)

## crush

**Charm Crush** · Evidence: `documented-subset` · Runtime: `not-run`.

Use the current official repository's configuration and schema. Inventory project/user config (`crush.json` or documented alternatives), instructions/context attachments, Skills if enabled in that build, MCP, LSP and agent/provider settings.

Do not copy a whole config to another host: provider credentials, permissions and UI preferences can share it with MCP. LSP servers are not MCP servers. Preserve command arrays, environment references and user/project precedence according to the selected version.

Check the native config schema and actual Skill/instruction discovery. The existence of a Skill-installer target is not evidence of every Crush context category, invocation syntax or hook capability.

Official sources: [1](https://github.com/charmbracelet/crush)

## goose

**Goose CLI and Desktop** · Evidence: `documented-subset` · Runtime: `not-run`.

Goose documentation has moved to the AAIF Goose/goose-docs site; follow canonical redirects. Inventory `.goosehints`, configurable context files, Skills, recipes, extensions/MCP, permissions and user settings. Skills may be provided through the built-in Skills extension; that is distinct from an MCP server exposing Skills.

Recipes are structured workflows with parameters and tool/extension configuration, not just prompt text. `.goosehints` imports and hierarchical loading depend on the Developer extension and configured context filenames. User `config.yaml` extension entries are not a generic JSON `mcpServers` map.

Check the active extension set, recipe arguments, context imports and Skill discovery. Do not enable an extension or recipe with executable steps merely by placing its config in a live path. Desktop preferences and session memory remain separate.

Official sources: [1](https://goose-docs.ai/docs/getting-started/using-extensions/) · [2](https://goose-docs.ai/docs/guides/context-engineering/using-skills/) · [3](https://goose-docs.ai/docs/mcp/skills-mcp/) · [4](https://github.com/aaif-goose/goose)

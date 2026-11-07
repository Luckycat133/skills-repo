# Cline, Kilo and Roo

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## cline

**Cline IDE, CLI and SDK** · Evidence: `documented-subset` · Runtime: `not-run`.

Current shared configuration distinguishes `~/.cline/skills`, `rules`, `workflows`, `hooks`, `agents`, `plugins` and `cron` from private state in `~/.cline/data`. Project equivalents under `.cline/` and legacy `.clinerules`/Documents-based roots have different roles; inspect the selected version and overrides.

The documented user MCP file is `~/.cline/data/settings/cline_mcp_settings.json`. Extract its MCP map only; never copy `.cline/data` or all settings because useful config sits next to private state. Track workflow invocation, rule activation, agent tools and plugin components separately.

Check which aliases are actually enabled before merging duplicates. Use the IDE/CLI customization view to verify discovery. Do not infer installed Cline solely from a shared `.agents/skills` directory. Hooks, cron and plugins are executable/configuration state and must not activate during transfer.

Official sources: [1](https://docs.cline.bot/getting-started/config) · [2](https://docs.cline.bot/features/skills) · [3](https://docs.cline.bot/features/cline-rules)

## kilocode

**Kilo IDE and CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

Current Kilo uses `.kilo/skills` and `~/.kilo/skills`, with documented `.agents`/`.claude` compatibility roots and configurable Skill paths. Do not assume the old `.kilocode`/Roo fork structure is still canonical.

Inventory native rules/instructions, commands/workflows, agents, hooks, Skills, MCP and plugins. Current custom-agent docs use `.kilo/agents/*.md`; old custom modes are a versioned input, not an identical schema. Workflows can collide with Skill commands. Dynamic shell content inside a Skill is executable.

Kilo MCP uses its native configuration shape, including command arrays where documented, not arbitrary `mcpServers` text pasted into settings. Inspect `kilo.jsonc` and active project settings before edits. Preserve approved content but reauthorize tools and privileges. Check native agent/Skill discovery and the exact slash-command selected on collision.

Official sources: [1](https://kilo.ai/docs/customize/skills) · [2](https://kilo.ai/docs/customize/custom-modes) · [3](https://kilo.ai/docs/customize/workflows) · [4](https://kilo.ai/articles/claude-code-to-kilo-code-migration-guide)

## roo-code

**Roo Code archived upstream; installed forks remain version-specific** · Evidence: `legacy-source` · Runtime: `not-run`.

The upstream repository is archived (2026-05-15). Treat existing installations as version-pinned sources; do not recommend fresh writes into an unmaintained target without the user's explicit choice of fork/build.

Inventory `.roo/skills`, personal Skills, mode-specific Skills/rules, custom modes, commands, workflows and MCP using that build's UI/schema. Preserve mode scope: global/project and generic/mode-specific precedence can select different Skill bodies. Do not reinterpret custom mode permissions as portable grants.

Export selected authored files and rebuild supported target objects. A maintained fork may differ from the final upstream release; inspect its documentation instead of inheriting upstream support automatically.

Official sources: [1](https://github.com/RooCodeInc/Roo-Code) · [2](https://roocodeinc.github.io/Roo-Code/features/skills/)

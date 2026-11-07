# Anthropic: Code is not Desktop Chat

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## claude-code

**Claude Code CLI, IDE integration, Desktop Code** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory instructions (`CLAUDE.md`, `.claude/CLAUDE.md`, local overrides and imported files), scoped `.claude/rules/*.md`, Skills (`.claude/skills/`, `~/.claude/skills/`), legacy slash commands, `.claude/agents/`, hooks, plugins, MCP and reviewed authored memory. Keep managed settings, auto-memory, credentials and session databases separate.

`paths` frontmatter narrows a rule; an unscoped rule is not equivalent to a model-selected Skill. Commands and Skills have converged in current Code, but legacy `.claude/commands/` remains a versioned input. Preserve arguments, invocation controls, tool/model choices, `context: fork` and any shell interpolation rather than copying only Markdown body. Skill hooks and dynamic shell content are executable.

Project MCP uses `.mcp.json`; user/local settings may share `.claude.json`. Resolve actual scope and extract only selected server definitions. Never transfer approvals. Desktop's **Code** surface may use this harness, but its filesystem and sandbox must be checked independently.

Check: target discovers the Skill by name; a scoped rule loads on a matching path and not an unrelated one; imported files resolve; all unrelated settings and authored memory remain unchanged.

Official sources: [1](https://code.claude.com/docs/en/features-overview) · [2](https://code.claude.com/docs/en/memory) · [3](https://code.claude.com/docs/en/skills) · [4](https://code.claude.com/docs/en/mcp)

## claude-desktop

**Claude Desktop Chat, web Projects and Cowork** · Evidence: `discovery-required` · Runtime: `not-run`.

Do not treat Chat, Projects, Cowork and the Code tab as one profile. Inventory uploaded Skills, project instructions/knowledge, connectors, desktop extensions and any selected local MCP definitions through the actual product UI. A valid Skill directory does not prove a particular account supports file installation.

Import reviewed instruction text and Skill packages through the documented UI when available. MCPB/desktop extensions are executable packages, not JSON server records. Reauthorize connectors on the new device. Do not copy a Desktop application-data tree or use Claude Code's `.claude/` as a presumed Chat installation directory. Legacy `claude_desktop_config.json` only applies when that installed build actually exposes it.

Check: the intended Chat/Project/Code surface, not a neighboring surface, can see the transferred object. This review does not establish a universal Desktop filesystem contract; use the vendor help center and the selected client's current settings before writing.

Official sources: [1](https://support.claude.com/) · [2](https://code.claude.com/docs/en/desktop)

# tencent-codebuddy

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.codebuddy/skills` |
| Project skills | `.codebuddy/skills` |
| Rules | `CODEBUDDY.md` |
| MCP | `~/.codebuddy/.mcp.json` |
| Project MCP | `.mcp.json` |
| Project config | `.codebuddy/settings.json` |
| Config | `~/.codebuddy/settings.json` |

<!-- END GENERATED: ide-paths.json summary -->
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

# zcode (Zhipu AI)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.zcode/skills` |
| Project skills | Not mapped |
| Rules | `AGENTS.md` |
| MCP | `~/.zcode/cli/config.json` |
| Project MCP | `.zcode/config.json` |
| Project config | `.zcode/config.json` |
| Config | `~/.zcode/cli/config.json` |

<!-- END GENERATED: ide-paths.json summary -->
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

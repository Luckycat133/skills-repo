# kiro

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.kiro/skills` |
| Project skills | `.kiro/skills` |
| Rules | Not mapped |
| MCP | `~/.kiro/settings/mcp.json` |
| Project MCP | `.kiro/settings/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.kiro/`
- **mcp**: global `~/.kiro/settings/mcp.json` · project `.kiro/settings/mcp.json` · root_key `mcpServers` · JSON · stdio+HTTP+OAuth. Migrate only reviewed endpoint metadata; do not copy OAuth/token state or infer a remote transport from a URL, and authorize again in Kiro.
- **rules**: project `.kiro/steering/*.md` · global `~/.kiro/steering/*.md` · frontmatter: inclusion (always|fileMatch|auto|manual)
- **skills**: global `~/.kiro/skills/<name>/SKILL.md` · project `.kiro/skills/<name>/SKILL.md`
- **agents (IDE)**: project `.kiro/agents/*.md` · user `~/.kiro/agents/*.md` · Markdown/YAML frontmatter; current IDE custom-agent files use prompt/body plus Kiro-specific tool tags and permissions, so only identity/body is potentially reusable and the mapper keeps them manual
- **agents (CLI)**: Kiro CLI custom agents use a separate JSON configuration under the CLI agent surface; fields can include prompt, tools, allowedTools, toolAliases, mcpServers, hooks, resources, and model. Do not convert CLI JSON to IDE Markdown or treat the two paths as one contract
- **hooks**: current IDE `.kiro/hooks/*.json` uses the v1 hook-object schema (`version: "v1"`, `trigger`, `action`); older `.kiro/hooks/*.kiro.hook` files use the legacy `when`/`then` schema. Kiro 1.0 also documents global hooks, but the reviewed page does not publish a stable literal user path; the two formats/events and global scope are therefore manual and are not silently converted.
- **specs**: `.kiro/specs/<feature>/{requirements,design,tasks}.md` — spec-driven dev docs
- **sources**: [Kiro Skills](https://kiro.dev/docs/skills/), [Kiro MCP](https://kiro.dev/docs/mcp/configuration/), [Kiro steering](https://kiro.dev/docs/steering/), [Kiro IDE custom agents](https://kiro.dev/docs/custom-agents/), [Kiro CLI custom-agent configuration](https://kiro.dev/docs/cli/custom-agents/configuration-reference/), [Kiro IDE hooks](https://kiro.dev/docs/hooks/), [Kiro IDE changelog](https://kiro.dev/changelog/ide/)

---

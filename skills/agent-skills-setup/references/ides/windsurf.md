# windsurf

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.codeium/windsurf/skills` |
| Project skills | `.windsurf/skills` |
| Rules | `.devin/rules` |
| MCP | `~/.codeium/windsurf/mcp_config.json` |
| Project MCP | Not mapped |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.codeium/windsurf/` (the current Devin Desktop/Windsurf storage namespace)
- **mcp**: global `~/.codeium/windsurf/mcp_config.json` · root_key `mcpServers` · JSON · local entries use `command`/`args`/`env`; remote entries use exactly one of `serverUrl` or `url` plus optional string `headers`; do not add VS Code `type` or an inferred `transport`
- **rules**: preferred project `.devin/rules/*.md` · legacy fallback `.windsurf/rules/*.md` · legacy root `.windsurfrules` · global `~/.codeium/windsurf/memories/global_rules.md` · workspace frontmatter uses `trigger` and optional `description`
- **skills**: project `.windsurf/skills/<name>/SKILL.md` · global `~/.codeium/windsurf/skills/<name>/SKILL.md` · required frontmatter `name`, `description`; `.agents/skills`/`~/.agents/skills` and optional `.claude/skills` are compatibility locations and are not merged blindly
- **workflows**: project `.windsurf/workflows/*.md` · global `~/.codeium/windsurf/global_workflows/*.md` · manual slash invocation `/[name]`; prompt/workflow migration remains manual
- **memory**: `~/.codeium/windsurf/memories/` (auto-generated, workspace-isolated; not committed)
- **project namespace**: `.windsurf` mixes Skills, rules, workflows, and application state; no automatic whole-project or project-MCP path is claimed. The `codeium` namespace above is the current official app storage path, not a separate legacy Codeium target.
- **note**: 6000-char global-rule / 12000-char workspace-rule and workflow limits; 100-tool limit.
- **sources**: [Cascade Skills](https://docs.windsurf.com/windsurf/cascade/skills), [Cascade MCP](https://docs.windsurf.com/windsurf/cascade/mcp), [Devin rules](https://docs.devin.ai/desktop/cascade/rules), [workflows](https://docs.devin.ai/desktop/cascade/workflows)

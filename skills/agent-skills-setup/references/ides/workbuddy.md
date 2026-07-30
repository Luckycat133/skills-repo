# workbuddy (WorkBuddy)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | Not mapped |
| Project skills | Not mapped |
| Rules | Not mapped |
| MCP | `~/.workbuddy/mcp.json` |
| Project MCP | `.workbuddy/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.workbuddy/`
- **mcp**: global `~/.workbuddy/mcp.json` · project `.workbuddy/mcp.json` · root_key `mcpServers` · JSON · the official desktop example is local command-based (`command`, optional `args`, optional `env`); remote URL/headers/type/transport fields are not established by the desktop docs and are rejected by automatic conversion; configured in the WorkBuddy UI
- **skills**: built-in/marketplace Skills and local Skill-package import through the Skills UI; the official desktop docs describe a Skill package as three components — **`skill.yml`** (metadata, description, configuration), **implementation files** (scripts/tools the Skill uses), and **`README`** (Skill documentation) — but publish no portable global/project Skills directory
- **memory**: generated private memory is managed in the WorkBuddy UI; the official page documents nightly summaries and an interactive import flow, not a portable filesystem path or schema. Keep memory manual and never copy generated state.
- **settings**: UI-managed; the official release notes confirm an independent `.workbuddy/` namespace but do not establish a portable whole-settings file for this mapper
- **sources**: [WorkBuddy MCP](https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/MCP-Guide), [WorkBuddy Skills](https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/Skills-Market), [WorkBuddy custom Skills](https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Practice-Cases/Create-Skills), [WorkBuddy memory](https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/Memory), [WorkBuddy task bar/OpenClaw import](https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/Task-Bar), [CodeBuddy/WorkBuddy config separation](https://www.workbuddy.ai/docs/cli/release-notes/v2.48.0)

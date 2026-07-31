# openclaw (OpenClaw)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.openclaw/skills` |
| Project skills | `skills` |
| Rules | `AGENTS.md` |
| MCP | `~/.openclaw/openclaw.json` |
| Project MCP | Not mapped |
| Project config | Not mapped |
| Config | `~/.openclaw/openclaw.json` |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.openclaw/`
- **mcp**: global `~/.openclaw/openclaw.json` · root_key `mcp.servers` (nested JSON path) · local `command` + `args`; remote `url` + `transport: "streamable-http"` · static config only. The explicit transport is required; do not substitute a legacy SSE URL or add protocol/session headers to this static client configuration.
- **rules/context**: active workspace `AGENTS.md`; default `~/.openclaw/workspace`, configurable through `agents.defaults.workspace` in `openclaw.json`
- **skills**: workspace `<workspace>/skills/` · project-agent `<workspace>/.agents/skills/` · personal `~/.agents/skills/` · managed `~/.openclaw/skills/`; precedence is workspace, project-agent, personal, managed
- **config**: `~/.openclaw/openclaw.json`
- **project config root**: unsupported/manual; OpenClaw has no fixed project config directory. The active workspace is selected by `agents.defaults.workspace`, so do not infer a repository-relative config root.
- **validation/installation**: static JSON/frontmatter checks are safe. `openclaw mcp list`/`openclaw mcp doctor` and `openclaw skills install <slug>` are official runtime operations but are not run by this migration mapper; no install or live probe is automatic.
- **sources**: [skills](https://docs.openclaw.ai/tools/skills), [agent workspace](https://docs.openclaw.ai/concepts/agent-workspace), [MCP](https://docs.openclaw.ai/cli/mcp), [configuration](https://docs.openclaw.ai/gateway/configuration)

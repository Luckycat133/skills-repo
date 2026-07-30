# baidu-comate

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.comate/skills` |
| Project skills | `.comate/skills` |
| Rules | Not mapped |
| MCP | `~/.comate/mcp.json` |
| Project MCP | `.comate/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.comate/`
- **mcp**: global `~/.comate/mcp.json` · project `.comate/mcp.json` · local `.comate/mcp.local.json` · root_key `mcpServers` · JSON · type `stdio|sse|streamableHttp`
- **rules**: `.comate/rules/*.mdr` — unique .mdr format (Markdown + Comate extensions) · Cursor Rules compatible · 4 activation modes
- **skills**: `.agents/skills/` or `.comate/skills/` · global `~/.comate/skills/`
- **agents**: `.comate/agents/` · global `~/.comate/agents/`
- **note**: Three-tier config (global/project/local); .mdr is unique format
- **sources**: [Comate Skills](https://cloud.baidu.com/doc/COMATE/s/Nmma28iqe), [Comate MCP.json](https://cloud.baidu.com/doc/COMATE/s/Ymir0x2ye)

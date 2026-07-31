# opencode

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.config/opencode/skills` |
| Project skills | `.opencode/skills` |
| Rules | `AGENTS.md` |
| MCP | `~/.config/opencode/opencode.json` |
| Project MCP | `opencode.json` |
| Project config | `opencode.json` |
| Config | `~/.config/opencode/opencode.json` |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.config/opencode/`
- **mcp**: global `~/.config/opencode/opencode.json` · project `opencode.json` · JSON/JSONC. V1 stores server names directly under `mcp`; native V2 stores them under `mcp.servers`. Both require `type: local|remote`, local command ARRAY, `environment`, and `{env:NAME}` interpolation. A `remote` entry is not proof that a foreign bare URL or legacy SSE endpoint is compatible: retain only target-documented connection metadata, never add protocol runtime fields, and complete OAuth again in OpenCode. The mapper defaults to V1-compatible output and emits native V2 with `--opencode-version v2`, including `enabled` → inverse `disabled`, scalar timeout → catalog/execution timeouts, and OAuth camelCase → snake_case conversion. When changing versions, it replaces the selected MCP container without mixing V1/V2 keys, while preserving unrelated top-level config and the requested backup strategy.
- **rules**: `AGENTS.md` (via instructions field in config)
- **skills**: project `.opencode/skills/` · global `~/.config/opencode/skills/` · also loads `.claude/skills/`, `.agents/skills/`
- **commands**: project `.opencode/commands/*.md` · global `~/.config/opencode/commands/*.md` · frontmatter: description, agent, model · $ARGUMENTS, !`cmd`, @file templates
- **agents**: project `.opencode/agents/*.md` · global `~/.config/opencode/agents/*.md` · frontmatter: description, mode, model, tools, permission
- **hooks**: via `.opencode/plugins/*.ts` (TypeScript event-driven)
- **memory**: via plugins (OpenMemory, short-term-memory, agent-memory)
- **note**: V2 currently reads the same config locations and translates V1-shaped files in memory. Do not mix V1 and V2 field names in one file. MCP migration preserves unrelated top-level settings; `backup` merges same-version servers after a snapshot, while an explicit version change replaces only the MCP container.
- **sources**: [OpenCode V1 Skills](https://opencode.ai/docs/skills/), [OpenCode V1 MCP](https://opencode.ai/docs/mcp/), [OpenCode V1 config](https://opencode.ai/docs/config/), [OpenCode V2 MCP](https://opencode.ai/v2/docs/mcp-servers), [V1 → V2 migration](https://opencode.ai/v2/docs/migrate-v1)

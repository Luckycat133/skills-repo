# OpenCode version boundary

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## opencode

**OpenCode V1 and V2** · Evidence: `version-sensitive` · Runtime: `not-run`.

Resolve the runtime major version and documentation version first. V1 Skills use `.opencode/skills`/user config roots plus `.agents`/`.claude` compatibility; permissions can use `permission.skill`. V1 local MCP uses its native `mcp` records and command arrays.

V2 documentation changes more than a root key: Skill identifiers derive from directory identity and are case-sensitive; display name is not necessarily invocation ID. Explicit `@id`, `opencode/autoinvoke`, standalone Markdown support and ordered permission behavior need V2-specific handling. The V2 MCP container and agents/plugins schema must be checked independently.

Inventory AGENTS/instructions globs, Skills, commands, agents, plugins, MCP and permissions. Do not treat a same-named field as equivalent across major versions. Preserve source package identity and record transformed invocations. Do not copy trust grants or silently enable autoinvocation.

Check native version and schema, effective Skill ID, invocation, permission order and actual loaded MCP list. If the installed version is unknown, park a reviewed draft rather than select whichever docs URL is easier to fetch.

Official sources: [1](https://opencode.ai/docs/skills/) · [2](https://opencode.ai/v2/docs/skills) · [3](https://opencode.ai/docs/mcp-servers/) · [4](https://opencode.ai/v2/docs/mcp-servers) · [5](https://opencode.ai/v2/docs/migrate-v1)

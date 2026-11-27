# windsurf

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Windsurf / legacy Cascade and Devin Desktop transition** · Evidence: `version-sensitive` · Runtime: `not-run`.

- **Harness & candidate paths**: Windsurf docs redirect to Devin Desktop, but installed builds may run **legacy Cascade** or **Devin Local** — confirm before writing. Legacy Cascade uses `.windsurf/rules/*.md` (12k-char cap; `.devin/rules/*.md` and legacy `.windsurfrules` also read), `AGENTS.md`, user `~/.codeium/windsurf/memories/global_rules.md` (6k-char cap; migrate **only** `global_rules.md`), `.windsurf/skills/<name>/SKILL.md`, `~/.codeium/windsurf/skills`, `.windsurf/workflows/*.md`, and `~/.codeium/windsurf/mcp_config.json` (`mcpServers`, remote HTTP `serverUrl`, 100-tool limit; `.devin/mcp_config.json` legacy project read). Built-in profile: `windsurf` (`codeium`).
- **Deep dives (progressive load per category)**: [Rules, Workflows & Skills](windsurf/rules-workflows.md) · [MCP](windsurf/mcp.md).
- **Devin Local & check**: If the active harness is Devin Local, use the `devin` profile paths below instead and avoid double-importing shared roots.

Official sources: [1](https://docs.devin.ai/desktop/devin-desktop-faq) · [2](https://docs.devin.ai/desktop/devin-local/overview) · [3](https://docs.devin.ai/desktop/cascade) · [4](https://docs.windsurf.com/windsurf/cascade/memories)

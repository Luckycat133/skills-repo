# Continue and Zed

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## continue

**Continue IDE extension and cn CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

Current Continue configuration is YAML (`~/.continue/config.yaml` with appropriate Windows home), with named blocks including an MCP server array and project `.continue/mcpServers` blocks. Older JSON/TypeScript configuration is a versioned input; do not execute `config.ts` while inspecting it.

Inventory `.continue/rules`, prompt files, context providers, models/data configuration and CLI workflow/headless settings. A context provider, MCP server and on-demand prompt are not synonyms. No universal native Skill-root guarantee is made by this review; check current CLI/IDE customization discovery before installing standard Skills.

Use a real YAML-aware edit for the selected block; preserve anchors, IDs, unrelated providers and environment references. Convert rule/frontmatter activation rather than rename a file. Check config loads in the selected Continue profile and a scoped rule stays scoped. Never turn an unavailable automatic parser into a blanket refusal to prepare valid YAML guidance.

Official sources: [1](https://docs.continue.dev/customize/deep-dives/configuration) · [2](https://docs.continue.dev/customize/deep-dives/mcp) · [3](https://docs.continue.dev/customize/deep-dives/rules) · [4](https://docs.continue.dev/customize/prompts)

## zed

**Zed native agent versus external ACP agent** · Evidence: `documented-subset` · Runtime: `not-run`.

Native Skills use documented Agent Skills roots including `.agents/skills` and `~/.agents/skills`; personal instructions use `~/.config/zed/AGENTS.md` (Windows `%APPDATA%\Zed\AGENTS.md`). Project instructions use first-match compatibility discovery. Existing `.rules`, `.cursorrules`, `.windsurfrules`, `.clinerules`, Copilot instructions, AGENT/AGENTS/CLAUDE/GEMINI files can change which file wins.

MCP is `context_servers` in Zed settings, not a generic `mcpServers` map. Local and remote entries have distinct schemas. Inventory agent-server/ACP configuration, prompts, Skills and authored rules separately from settings/private state.

An external Claude/Codex/Devin ACP agent may load its own instructions and MCP; Zed's native rules are not automatically forwarded. Check the actual agent process/home and host capabilities. Before writing AGENTS.md, verify no higher-precedence legacy file shadows it; after writing, prove discovery with a harmless marker.

Official sources: [1](https://zed.dev/docs/ai/instructions) · [2](https://zed.dev/docs/ai/skills) · [3](https://zed.dev/docs/ai/mcp) · [4](https://zed.dev/docs/ai/external-agents)

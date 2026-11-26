# opencode

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**OpenCode V1 and V2** · Evidence: `version-sensitive` · Runtime: `not-run`.

- **Version check & candidate paths**: Confirm V1 vs V2 first. Config `opencode.json` / `opencode.jsonc` and `~/.config/opencode/opencode.json`; Instructions `AGENTS.md`, `~/.config/opencode/AGENTS.md` (and `instructions` globs in config); Skills `.opencode/skills/<id>/SKILL.md`, `~/.config/opencode/skills/<id>/SKILL.md` (plus `.agents/skills`, `.claude/skills`); Commands `.opencode/commands/*.md`, `~/.config/opencode/commands/*.md`; Agents `.opencode/agents/*.md`, `~/.config/opencode/agents/*.md`. Built-in profile: `opencode`.
- **V1 vs V2 schema differences**: V1 MCP uses root key **`mcp`** (`{"type": "local", "command": ["bin", "arg"], "environment": {...}, "enabled": true}` or `{"type": "remote", "url": "...", "headers": {...}}`); V2 uses **`mcp.servers`** (`migrate_context.py` preserves existing `mcp.servers` vs `mcp`). In V2, Skill IDs come from **case-sensitive directory names**, `@id` invocation, and `opencode/autoinvoke` plus ordered `permission` rules — never rename solely from display `name` or silently enable autoinvoke.

Official sources: [1](https://opencode.ai/docs/skills/) · [2](https://opencode.ai/v2/docs/skills) · [3](https://opencode.ai/docs/mcp-servers/) · [4](https://opencode.ai/v2/docs/mcp-servers) · [5](https://opencode.ai/v2/docs/migrate-v1)

# trae

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**TRAE International IDE and TRAE Agent CLI** · Evidence: `discovery-required` · Runtime: `not-run` · Built-in IDE profile: `trae`.

International TRAE IDE (`docs.trae.ai`, using `.trae/{skills,rules,commands,agents,hooks.json,mcp.json}` + `~/.trae/*` + OS `Trae/User/mcp.json`, covered by built-in `trae` while excluding `trae-jwt-token`, `builtin_skills`, caches, and auto `memory`) is distinct from TRAE China (`trae-cn`) and open-source `bytedance/trae-agent` CLI (`trae_config.yaml` / JSON). Inspect CLI vs IDE settings before writing, use `agent_handoff` for unverified fields, and never certify International TRAE from a China IDE run. Progressive guides: [Rules, Skills, Commands & Agents](trae/rules-skills.md) · [MCP & Hooks](trae/mcp-and-hooks.md).

Official sources: [1](https://docs.trae.ai/) · [2](https://github.com/bytedance/trae-agent)

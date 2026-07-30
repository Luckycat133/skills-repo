# forge
- **detect**: `~/.forge/` (FORGE_CONFIG env var can override)
- **mcp**: global `~/.forge/.mcp.json` · project `./.mcp.json` · root_key `mcpServers` · JSON · `forge mcp import/list`
- **rules**: `forge.yaml` custom_rules field · also `AGENTS.md`
- **skills**: project `.forge/skills/<name>/SKILL.md` · global `~/forge/skills/` · also `~/.agents/skills/`
- **commands**: `forge.yaml` commands array
- **agents**: `.forge/agents/<name>.md` · built-in: Forge, Sage, Muse
- **other**: `forge.yaml` (main config) · `.forge/templates/`

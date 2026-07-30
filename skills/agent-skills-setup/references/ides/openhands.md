# openhands
- **detect**: `~/.openhands/`
- **mcp** (CLI 1.0+): `~/.openhands/mcp.json` · root_key `mcpServers` · JSON · `openhands mcp list`
- **mcp** (GUI/legacy): `config.toml` [mcp] section · `sse_servers`/`shttp_servers`/`stdio_servers` arrays
- **rules**: `AGENTS.md`
- **skills**: project skills (via `load_project_skills()`, agentskills.io standard)
- **agents**: `~/.openhands-cli/persist/agent_settings.json`
- **memory**: Condenser system (config.toml [condenser]: type=amortized/llm_attention/llm_summarizing)

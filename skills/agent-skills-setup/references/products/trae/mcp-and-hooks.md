# TRAE (China & International): MCP & Lifecycle Hooks

Parents: [trae-cn.md](../trae-cn.md) · [trae.md](../trae.md)

## MCP Config Paths (`mcpServers`)

- **Project**: `.trae/mcp.json`
- **Global (OS-specific User Data)**:
  - **macOS**: `~/Library/Application Support/Trae CN/User/mcp.json` (`trae-cn`) / `~/Library/Application Support/Trae/User/mcp.json` (`trae`)
  - **Linux**: `~/.config/Trae CN/User/mcp.json` / `~/.config/Trae/User/mcp.json`
  - **Windows**: `%APPDATA%\Trae CN\User\mcp.json` / `%APPDATA%\Trae\User\mcp.json`

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."],
      "env": {
        "API_TOKEN": "${API_TOKEN}"
      }
    }
  }
}
```

## Lifecycle Hooks (`hooks.json`)

- **Paths**: `.trae/hooks.json`, `~/.trae-cn/hooks.json` (legacy `~/.trae/hooks.json` fallback), `~/.trae/hooks.json`.
- **Supported events**: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, `Notification`.
- **Policy**: Keep hooks parked via `agent_handoff` unless `--activate-hooks` is passed cleanly on compatible same-schema restores.

Official sources: [TRAE CN Hooks](https://docs.trae.cn/ide_automate-actions-with-hooks) · [TRAE CN Changelog](https://docs.trae.cn/ide_changelog) · [TRAE Intl Docs](https://docs.trae.ai/)

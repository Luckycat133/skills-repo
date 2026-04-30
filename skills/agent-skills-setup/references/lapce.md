# Lapce MCP Setup

## MCP Support Status

**Lapce 目前没有原生 MCP 支持。**

## Current Alternatives

### Option 1: External MCP Client

使用外部 MCP 客户端连接 Lapce:

1. 配置外部 MCP 服务器
2. 使用 MCP 客户端工具连接

### Option 2: LSP-based Extensions

Lapce 支持 LSP (Language Server Protocol)，可以使用 LSP 扩展替代部分 MCP 功能。

## Lapce Features

| 特性 | 说明 |
|------|------|
| 平台 | Rust-based |
| 性能 | GPU 渲染 |
| 远程开发 | 支持 |
| 终端 | 内置 |
| LSP | 支持 |
| MCP | ❌ 不支持 |

## Alternative Editors with MCP Support

如果需要 MCP 支持，建议使用:
- **Cursor** - `~/.cursor/mcp.json`
- **Zed** - `~/.config/zed/settings.json`
- **Claude Code** - `~/.claude.json`

## Future MCP Support

Lapce 社区正在讨论 MCP 支持，可能在未来的版本中添加。

跟踪进度: https://github.com/lapce/lapce/discussions

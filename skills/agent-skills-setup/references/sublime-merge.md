# Sublime Merge MCP Setup

## MCP Support Status

**Sublime Merge 没有原生 MCP 支持。**

## Official Statement

> "Currently, Sublime Merge does not have a plugin API, nor a built-in package manager."
> — Sublime Merge Documentation

## Alternative: MCPServer Package

Sublime Merge 可以通过 Sublime Text 的 MCPServer 插件间接支持 MCP：

### For Sublime Text (not Merge)

1. 安装 Package Control
2. 安装 MCPServer 包
3. 配置 MCP 服务器

### Package Control

https://packagecontrol.io/packages/MCPServer

## Alternative: Git GUI with MCP Support

如果需要 Git GUI + MCP 支持:

| Tool | MCP Support | Notes |
|------|-------------|-------|
| **Fork** | Via extension | macOS/Windows |
| **GitKraken** | Via integration | Cross-platform |
| **SourceTree** | ❌ | No MCP support |
| **SmartGit** | ❌ | No MCP support |

## Use Cases for Git GUI + MCP

- AI-powered commit analysis
- Code review suggestions
- Repository insights

## Recommendation

对于 MCP + Git 功能，建议:
1. 使用支持 MCP 的代码编辑器 (Cursor, Zed, Claude Code)
2. 使用命令行 Git 配合 MCP 服务器
3. 使用专门的 Git 分析 MCP 服务器

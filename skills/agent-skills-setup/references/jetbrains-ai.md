# JetBrains AI MCP Setup

Configure MCP servers in JetBrains AI Assistant.

## Config Method

**JetBrains 使用 GUI 配置，不支持手动编辑配置文件。**

## Config Path (GUI)

`Settings > Tools > AI Assistant > Model Context Protocol (MCP)`

## Setup Steps

### Method 1: GUI Configuration (Recommended)

1. 打开 Settings (`Ctrl+Alt+S` / `Cmd+,`)
2. 导航到 `Tools > AI Assistant > Model Context Protocol (MCP)`
3. 点击 `+` 添加 MCP 服务器
4. 配置服务器命令和参数

### Method 2: Import from Claude Desktop

1. 在 Claude Desktop 中配置 MCP 服务器
2. 导出配置
3. 在 JetBrains 中导入

## Config Format (JSON)

```json
{
  "mcpServers": {
    "server-name": {
      "command": "uvx",
      "args": ["mcp-server-package"]
    }
  }
}
```

## Supported Products

- IntelliJ IDEA 2025.1+
- PyCharm 2025.1+
- WebStorm 2025.1+
- PhpStorm 2025.1+
- RubyMine 2025.1+
- GoLand 2025.1+
- CLion 2025.1+
- Rider 2025.1+
- DataSpell 2025.1+
- DataGrip 2025.1+

## Junie (JetBrains AI Agent)

**Path:** `~/.junie/mcp/mcp`

Junie 使用不同的配置路径。

## Troubleshooting

### MCP 服务器不启动

1. 检查命令路径是否正确
2. 确保 `uvx` 或 `npx` 已安装
3. 重启 JetBrains IDE

### 权限问题

确保 IDE 有足够的权限执行命令。

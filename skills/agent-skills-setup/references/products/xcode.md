# xcode

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Xcode Coding Intelligence and external-agent bridge** · Evidence: `documented-subset` · Runtime: `not-run`.

Identify Xcode release and agent harness (built-in Claude/Codex, external ACP, or external client calling Xcode MCP). Apple stores agent-specific configs under `~/Library/Developer/Xcode/CodingAssistant/` (e.g., `ClaudeAgentConfig`), distinct from normal `$HOME`. Inventory project instructions, custom Skills/subagents/plugins, and MCP/ACP entries; check `xcrun mcpbridge` vs Xcode 27 MCP server release notes locally, and never copy simulator state, Apple-built Skills, or keychain/security grants.

Official sources: [1](https://developer.apple.com/documentation/xcode/extending-and-customizing-agents/) · [2](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode) · [3](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes)

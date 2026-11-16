# Blackbox and Pieces

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## blackbox

**Blackbox CLI and agent platform** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory `.blackbox/skills/<name>/SKILL.md`, project instructions, commands/recipes, custom agents, MCP (`mcpServers` via `patch-mcp`), hooks/plugins, schedules, and underlying ACP harness settings. Preserve explicit slash invocation, keep schedules/plugins inactive during migration, resolve WSL vs Windows `HOME` accurately, and exclude session history/provider tokens.

Official sources: [1](https://www.blackbox.ai/cli) · [2](https://docs.blackbox.ai/features/blackbox-cli/skills) · [3](https://docs.blackbox.ai/features/blackbox-cli/commands-reference) · [4](https://docs.blackbox.ai/features/blackbox-cli/getting-started)

## pieces

**PiecesOS and Pieces MCP/Memory provider** · Evidence: `provider-or-installer` · Runtime: `not-run`.

PiecesOS is a local memory/MCP **provider**, not an IDE rules target. Rebind the consuming IDE/CLI's Pieces MCP server entry on the new device with fresh local endpoint/auth, export only user-selected saved notes via approved Pieces UI/API, and never copy PiecesOS long-term capture databases.

Official sources: [1](https://docs.pieces.app/products/mcp) · [2](https://docs.pieces.app/products/desktop/configuration) · [3](https://docs.pieces.app/products/core-dependencies/pieces-os)

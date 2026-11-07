# Blackbox and Pieces

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## blackbox

**Blackbox CLI and agent platform** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory `.blackbox/skills/<name>/SKILL.md`, project instructions, commands/recipes, schedules, custom agents/orchestration, MCP, hooks/plugins and ACP integrations where documented. The active underlying agent can change which native context is loaded.

Preserve explicit invocation, parameter handling and multi-step workflow behavior. Do not convert a schedule to an on-demand prompt or enable a plugin/agent with code execution during migration. Some Windows workflows require WSL; resolve the actual process filesystem instead of writing a Windows path into Linux config.

Check native Skill/command discovery and effective agent/tool selection. Keep account/provider secrets, task histories and platform session state outside the transfer.

Official sources: [1](https://www.blackbox.ai/cli) · [2](https://docs.blackbox.ai/features/blackbox-cli/skills) · [3](https://docs.blackbox.ai/features/blackbox-cli/commands-reference) · [4](https://docs.blackbox.ai/features/blackbox-cli/getting-started)

## pieces

**PiecesOS and Pieces MCP/Memory provider** · Evidence: `provider-or-installer` · Runtime: `not-run`.

Pieces is primarily a context/memory provider and application, not a generic IDE configuration destination. Inventory selected user-authored saved material and the consuming client's MCP definition. PiecesOS long-term memory databases and captures are not ordinary rule files.

Reconfigure the destination client's MCP connection to the new local PiecesOS instance through supported setup. Reauthorize access rather than copy tokens or process endpoints. Export selected authored knowledge only through approved UI/API, with provenance and privacy review.

Check the intended client resolves the provider and, only if authorized, can query a harmless selected item. Do not copy Pieces databases, captured desktop history or all application data as a shortcut.

Official sources: [1](https://docs.pieces.app/products/mcp) · [2](https://docs.pieces.app/products/desktop/configuration) · [3](https://docs.pieces.app/products/core-dependencies/pieces-os)

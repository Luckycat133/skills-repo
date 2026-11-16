# Compatibility is per object, not a green product-pair matrix

The generated matrix is retired. Its presence did not prove a real client loaded
the result. The Skill now discovers the selected source/target and consults only
the relevant conversion guidance.

See [discovery](../../skills/agent-skills-setup/references/discovery.md),
[rules](../../skills/agent-skills-setup/references/instructions.md), and
[MCP](../../skills/agent-skills-setup/references/mcp.md).

The Skill ships 15 built-in deterministic profiles in
[`scripts/migrate_context.py`](../../skills/agent-skills-setup/scripts/migrate_context.py)
(`cursor`, `claude-code`, `codex`, `vscode`, `copilot-cli`, `gemini-cli`, `antigravity`,
`windsurf`, `cline`, `kilocode`, `zed`, `opencode`, `kimi-code`, `qwen-code`, `pi`) plus
composable `patch-mcp` and 30 on-demand
[`references/products/*.md`](../../skills/agent-skills-setup/references/products.md)
family guides across 90 cataloged profiles. Offline parser and script tests do not
certify live GUI/IDE loading; other surfaces require source verification and real
client checks. See [validation status](../validation-status.md).

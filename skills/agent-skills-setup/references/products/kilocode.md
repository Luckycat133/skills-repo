# kilocode

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Kilo IDE and CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Skills `.kilo/skills/<name>/SKILL.md`, `~/.kilo/skills/<name>/SKILL.md` (plus `.agents`/`.claude` compatibility and legacy `.kilocode/skills`); Rules `.kilo/rules/*.md`, `~/.kilo/rules/*.md`, `AGENTS.md`; Agents `.kilo/agents/*.md`, `~/.kilo/agents/*.md` (legacy custom modes `.kilocodemodes` are a different schema); Workflows `.kilo/workflows/*.md`, `~/.kilo/workflows/*.md`; Config/MCP `kilo.jsonc` and `.kilo/mcp.json` / `~/.kilo/mcp.json` (`mcpServers` or native command arrays — inspect active file). Built-in profile: `kilocode` (`kilo`).
- **Cautions & check**: Check workflow vs Skill slash-command collisions, keep dynamic shell blocks inactive, and strip tool auto-approvals.

Official sources: [1](https://kilo.ai/docs/customize/skills) · [2](https://kilo.ai/docs/customize/custom-modes) · [3](https://kilo.ai/docs/customize/workflows) · [4](https://kilo.ai/articles/claude-code-to-kilo-code-migration-guide)

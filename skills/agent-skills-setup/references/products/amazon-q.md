# amazon-q

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Amazon Q Developer IDE and legacy/current CLI profiles** · Evidence: `version-sensitive` · Runtime: `not-run`.

- **Candidate paths & official path conflict**: Project rules `.amazonq/rules/*.md`; Project MCP `.amazonq/mcp.json` or `.amazonq/default.json`. Official AWS docs disagree on global IDE MCP (`~/.aws/amazonq/default.json` on the IDE page vs `~/.aws/amazonq/agents/default.json` on the overview; CLI agents use `~/.aws/amazonq/cli-agents/*.json`).
- **Resolution rule**: Inspect which global file the installed IDE/CLI actually reads before running `patch-mcp`; never write all candidate paths blindly, relabel Amazon Q as Kiro, or copy AWS SSO/IAM credentials.

Official sources: [1](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/mcp-ide.html) · [2](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/qdev-mcp.html) · [3](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/context-project-rules.html)

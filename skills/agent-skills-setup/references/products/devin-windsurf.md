# Devin, Windsurf and Codeium identities

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## windsurf

**Windsurf / legacy Cascade and Devin Desktop transition** · Evidence: `version-sensitive` · Runtime: `not-run`.

- **Harness & candidate paths**: Windsurf docs redirect to Devin Desktop, but installed builds may run **legacy Cascade** or **Devin Local** — confirm before writing. Legacy Cascade uses `.windsurf/rules/*.md` (`trigger: always_on | glob | model_decision | manual`, `globs`, legacy `.windsurfrules`), `AGENTS.md`, user `~/.codeium/windsurf/memories/global_rules.md` (migrate **only** `global_rules.md`, never auto-generated memory files), `.windsurf/skills/<name>/SKILL.md`, `~/.codeium/windsurf/skills`, `.windsurf/workflows/*.md`, and `~/.codeium/windsurf/mcp_config.json` (`mcpServers`; remote HTTP uses `serverUrl`). Built-in profile: `windsurf` (`codeium`).
- **Devin Local & check**: If the active harness is Devin Local, use the `devin` profile paths below instead and avoid double-importing shared roots.

Official sources: [1](https://docs.devin.ai/desktop/devin-desktop-faq) · [2](https://docs.devin.ai/desktop/devin-local/overview) · [3](https://docs.devin.ai/desktop/cascade) · [4](https://docs.windsurf.com/windsurf/cascade/memories)

## devin

**Devin CLI, Desktop Local and Cloud** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: User config `~/.config/devin/config.json` (Windows `%APPDATA%\devin\config.json`), project `.devin/config.json`; Project MCP `.devin/mcp_config.json` (`mcpServers` — compatible with `migrate_context.py patch-mcp`); Rules via global/project `AGENTS.md`, Skills, subagent profiles, hooks, and plugins. Cloud Knowledge, Playbooks, and schedules are UI/API objects.
- **Cautions & check**: Never invoke `/handoff` (network/cloud session transfer) as a local file migration step; exclude auth, sandbox grants, and session state. Verify CLI vs Desktop Local discovery separately.

Official sources: [1](https://docs.devin.ai/cli/extensibility/configuration) · [2](https://docs.devin.ai/cli/extensibility/rules) · [3](https://docs.devin.ai/cli/extensibility/index) · [4](https://docs.devin.ai/cli/handoff)

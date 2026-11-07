# Devin, Windsurf and Codeium identities

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## windsurf

**Windsurf / legacy Cascade and Devin Desktop transition** · Evidence: `version-sensitive` · Runtime: `not-run`.

Old Windsurf documentation now redirects into Devin Desktop documentation. Do not use that redirect to silently rewrite every existing Windsurf installation to a Devin layout. Record installed app name/build and whether the active agent is legacy Cascade or Devin Local.

For a legacy workspace inspect its existing `.windsurf` rules, Skills/workflows, AGENTS and MCP configuration, user Rules UI and generated memories. Migrate authored rules/workflows while preserving trigger behavior; do not copy generated memories. Old Codeium is a brand/extension alias, not proof of the new Desktop harness.

For Devin Local, follow its current CLI harness/configuration instead. A setting that imports another tool's config is not ownership of that source; avoid double-importing shared Skills. Check a new session loads only the chosen canonical rules and that old and new compatibility paths do not shadow each other.

Official sources: [1](https://docs.devin.ai/desktop/devin-desktop-faq) · [2](https://docs.devin.ai/desktop/devin-local/overview) · [3](https://docs.devin.ai/desktop/cascade) · [4](https://docs.windsurf.com/windsurf/cascade/memories)

## devin

**Devin CLI, Desktop Local and Cloud** · Evidence: `documented-subset` · Runtime: `not-run`.

CLI current user config is `~/.config/devin/config.json` (Windows `%APPDATA%\devin\config.json`), project `.devin/config.json`; project MCP uses `.devin/mcp_config.json` with `mcpServers`. Global/project AGENTS are documented rule sources. Resolve local overrides rather than copying all config.

Inventory Skills, rules, subagent profiles, plugins, hooks, MCP and import settings; cloud Knowledge, Playbooks, schedules and integrations are separate UI/API objects. Convert selected definitions, not auth, sandbox grants or stored session state.

Native `/handoff` transfers session/Git context to cloud; running it is a network/action authorization, not an innocent file conversion. For a generic device move use a reviewed summary and files instead. Check CLI versus Desktop harness discovery independently; cloud re-creation needs cloud-side evidence.

Official sources: [1](https://docs.devin.ai/cli/extensibility/configuration) · [2](https://docs.devin.ai/cli/extensibility/rules) · [3](https://docs.devin.ai/cli/extensibility/index) · [4](https://docs.devin.ai/cli/handoff)

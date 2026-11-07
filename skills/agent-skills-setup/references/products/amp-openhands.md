# Amp and OpenHands

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## amp

**Amp CLI/editor/cloud surfaces** · Evidence: `documented-subset` · Runtime: `not-run`.

Amp is not Sourcegraph Cody. Current documentation covers AGENTS hierarchy, Skills and compatibility roots, MCP/OAuth, permissions, plugins, subagents and scheduled/remote work. Inventory each requested category rather than leave Amp as an empty manual-reference entry.

Resolve the selected Amp profile's native settings and all Skill roots from current docs. An MCP server bundled in a Skill is a distinct origin and may require separate trust/auth. Plugins can be executable TypeScript; migrating their text does not authorize loading them. System/organization guidance and generated cloud work are not personal context.

Check native discovery and effective precedence, particularly duplicate Skills across native/shared roots. Move authored guidance and selected server definitions; reauthorize OAuth and permissions. Do not copy schedules or running job/session state without an explicit independent request.

Official sources: [1](https://ampcode.com/docs) · [2](https://ampcode.com/docs/customize/skills) · [3](https://ampcode.com/docs/customize/mcp)

## openhands

**OpenHands local CLI, SDK, hosted app and agent canvas** · Evidence: `documented-subset` · Runtime: `not-run`.

Current docs support root AGENTS and standard `.agents/skills/<name>/SKILL.md`, plus user Skills; legacy `.openhands/skills` and microagents are versioned compatibility inputs. Do not label OpenHands unverified merely because old notes did.

Skill activation has product extensions: `triggers` can use keywords, while `paths` binds file encounters and takes precedence over triggers. Legacy flat Markdown without triggers can behave as always-loaded context. Renaming every microagent to a Skill can therefore change behavior.

Inventory Skills, instructions, agents, MCP, hooks, setup scripts, plugins and condenser/generated memory independently for CLI/SDK/hosted app. Prepare selected authored definitions; do not copy sessions/indexes. Check matching and nonmatching path activation plus keyword/manual behavior in the actual runtime. API/app MCP configuration need not share the CLI's schema.

Official sources: [1](https://docs.openhands.dev/overview/skills) · [2](https://docs.openhands.dev/)

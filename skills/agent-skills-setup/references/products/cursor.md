# Cursor

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## cursor

**Cursor IDE, CLI and cloud agents** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory `.cursor/rules/*.mdc`, root/nested `AGENTS.md` where supported, `.cursor/skills/`, user Skills, slash commands, subagents, hooks, plugins, MCP and any UI/team rules. User settings, project rules and cloud task configuration are different scopes. Resolve MCP through the actual user/project settings; the local JSON server map is not a cloud connector export.

MDC activation matters: `alwaysApply: true` means always-on; glob-attached, model-selected and manual rules are different. A `.md` file put beside `.mdc` is not automatically a Cursor rule. Preserve folder scope and existing rules.

Cursor's documented rule/command-to-Skill migration targets on-demand rules and commands. It is not a blanket conversion for always-on or file-scoped rules. Preserve manual invocation with the target's verified invocation controls; do not assume the same frontmatter fields exist in all hosts. Hooks and shell-evaluated Skill content require separate execution approval.

Check: rule type displayed by Cursor; matching/nonmatching path behavior; Skill discovery/invocation; MCP config syntax without connecting. For CLI/cloud, verify which customizations that exact harness loads rather than inheriting every IDE capability.

Official sources: [1](https://cursor.com/docs/rules) · [2](https://cursor.com/docs/skills) · [3](https://cursor.com/docs/hooks) · [4](https://cursor.com/docs/mcp) · [5](https://cursor.com/docs/customize-cursor)

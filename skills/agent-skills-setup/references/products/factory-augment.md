# Factory Droid and Augment

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## factory-droid

**Factory Droid CLI, desktop and cloud** · Evidence: `documented-subset` · Runtime: `not-run`.

The executable is `droid`, not `factory`. Current documentation is organized around the Factory harness. Inventory `.factory/skills` and user Skills, AGENTS, custom droids, commands, hooks, MCP, output styles and plugins.

Factory plugins use `.factory-plugin/plugin.json` plus component directories/files. Preserve the manifest namespace and droid/Skill references; do not reduce a plugin to the manifest alone. Project versus user droids have separate discovery and tool constraints. CLI, desktop and cloud jobs may run under different homes/workspaces.

Copy selected inert Skills with resources; translate agent/model/tool fields deliberately. MCP config and hooks inside plugins remain executable/auth-bearing components. Check target package import, `/` invocation and droid visibility in the intended harness; never migrate allowlists or auto-run hook installation.

Official sources: [1](https://docs.factory.com/harness/skills) · [2](https://docs.factory.com/harness/plugins) · [3](https://docs.factory.com/harness/subagents) · [4](https://docs.factory.com/droid-cli/overview)

## augment-code

**Auggie CLI, Augment IDE and Cosmos** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory Skills, rules/guidelines, commands, agents, hooks, MCP, plugins and settings. CLI Skill precedence is not the common project-wins assumption: official docs prioritize user `~/.augment/skills` before workspace/compatibility roots; explicit Skill paths also matter.

Rules include `.augment/rules`, user rules, AGENTS/CLAUDE discovery, legacy `.augment-guidelines` and system-prompt add/replace mechanisms. User rules are documented as always-apply; copying file-scoped frontmatter there does not preserve scope. At a directory where both AGENTS and CLAUDE exist, follow the documented fallback, not additive concatenation.

CLI, IDE and Cosmos cloud context must be checked separately. Do not copy enterprise context indexes or permission state. Check selected rule activation, winning Skill definition, command references and actual MCP subobject while preserving the rest of settings.

Official sources: [1](https://docs.augmentcode.com/cli/skills) · [2](https://docs.augmentcode.com/cli/rules) · [3](https://docs.augmentcode.com/)

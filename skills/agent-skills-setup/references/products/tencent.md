# Tencent CodeBuddy and WorkBuddy

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## codebuddy

**CodeBuddy Code CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory CODEBUDDY/AGENTS instructions, Skills, commands, agents, hooks, plugins, MCP, LSP and user/project/local settings. Use CLI documentation, not the standalone IDE's RULE.mdc or UI-only controls.

Current Skills may carry `context: fork` and Skill-scoped hooks; those hooks can run in the subagent context and lifecycle mapping differs from main-agent hooks. `allowUntrustedFrontmatterHooks` is a trust setting, not portable metadata. Hook types include command, prompt, agent and HTTP: copying their text must not activate them.

Plugin packages can include multiple executable components. Preserve package identity only where supported and keep uncertain components outside live discovery paths. Check Skill invocation and expected agent context; test hook event/input/output only in an explicitly authorized sandbox.

Official sources: [1](https://www.codebuddy.cn/docs/cli/skills) · [2](https://www.codebuddy.cn/docs/cli/hooks) · [3](https://www.codebuddy.cn/docs/cli/plugins-reference)

## codebuddy-ide

**CodeBuddy IDE and IDE plugins** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory project/user Skills, rules and custom instructions, MCP, prompts/commands, agents, hooks and memory. IDE release notes document compatibility roots and new features; supported hook events and memory behavior differ from CLI.

Native `.codebuddy/skills` and documented shared aliases are candidates, not proof that all installations load the same roots. Resolve rules and MCP using the installed IDE customization UI; do not substitute a CLI path. Generated Memory is not the same as explicit user rules. Preserve file activation and project versus user scope when translating.

Check the IDE version and actual extension host (local/remote). A CLI parsing test does not validate IDE hook support, `RULE.mdc` activation or UI-managed memory. Review credential requirements without copying existing auth.

Official sources: [1](https://www.codebuddy.cn/docs/ide/Features/Hooks) · [2](https://www.codebuddy.cn/docs/ide/User-guide/Memory) · [3](https://www.codebuddy.cn/docs/ide/release-notes/release-notes)

## workbuddy

**WorkBuddy desktop/workspace** · Evidence: `documented-subset` · Runtime: `not-run`.

Current official Skill import/market guidance uses `SKILL.md` packages. Do not repeat the historical assertion that every WorkBuddy Skill is a special `skill.yml` package.

Inventory installed/imported Skills and enable controls, MCP integrations, reviewed user preferences and workspace instructions. Resolve local versus cloud installation via the actual app; do not copy its whole data store. Marketplace metadata, connection tokens and generated memory are not the Skill body.

Import the reviewed package through supported app controls, reauthorize integrations and verify the Skill appears and is enabled only as requested. Exact disk paths and any `.agents` compatibility must be confirmed on the installed version before direct filesystem edits.

Official sources: [1](https://www.codebuddy.cn/docs/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/Skills-Market)

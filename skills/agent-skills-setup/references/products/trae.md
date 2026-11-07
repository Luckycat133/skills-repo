# TRAE IDE and Work

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## trae-cn

**TRAE China IDE** · Evidence: `documented-subset` · Runtime: `not-run`.

Current China IDE docs describe `.trae/skills` and `.trae/rules`, plus commands, custom agents/subagents, hooks and memory. Rules have always/file/model/manual use cases; `@Rule`-style manual selection must not become always-on instructions after conversion. Resolve aliases and duplicate names before installing Skills.

Inventory MCP and selected user/project settings separately; exporting `.trae` wholesale can include generated state. Keep auto-generated Memory distinct from user rules. Verify native rule matching, Skill discovery and supported hook events for the installed release. A prepared hook is parked outside live discovery until separately approved.

Official sources: [1](https://docs.trae.cn/ide_skills) · [2](https://docs.trae.cn/ide_rules) · [3](https://docs.trae.cn/ide_changelog) · [4](https://docs.trae.cn/ide_automate-actions-with-hooks)

## trae

**TRAE International IDE and TRAE Agent CLI** · Evidence: `discovery-required` · Runtime: `not-run`.

International documentation and feature rollout must be checked independently of China IDE. The reviewed China docs are not evidence of identical International MCP, memory or hook schemas. The open-source TRAE Agent CLI is a separate runtime, not an alias for IDE context files.

Inventory Skills, rules, commands, agents, hooks, MCP, memory and settings on the actual product. Use `docs.trae.ai` or the CLI's official repository/version; when pages are unavailable, keep a specific documentation-access gap and inspect local settings/schema before writing. Preserve reviewed text and prepare a target draft, not guessed `.trae` paths.

Check real native discovery and invocation. Do not mark International support passed using a China IDE test or a CLI fixture.

Official sources: [1](https://docs.trae.ai/) · [2](https://github.com/bytedance/trae-agent)

## trae-work

**TRAE Work** · Evidence: `documented-subset` · Runtime: `not-run`.

Current China Work docs expose Skills and rules, including `.trae/skills` and `.trae/rules`; the older assumption that Work is entirely UI-only is no longer reliable. Do not infer identical International Work behavior.

Inventory Work/Code/Design context, project/user rules, Skills, integrations, authored preferences and scheduled tasks. UI/cloud memory and live task state are separate from portable files. Preserve scope and selected package content; recreate connections and schedules through current controls only after consent.

Check Work, not the IDE, actually loads the transferred rule/Skill. Shared path spelling does not mean shared activation or installation ownership.

Official sources: [1](https://docs.trae.cn/work_skills) · [2](https://docs.trae.cn/work_rules)

# replit (Replit AI)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | Not mapped |
| Project skills | `.agents/skills` |
| Rules | `replit.md` |
| MCP | Not mapped |
| Project MCP | Not mapped |
| Project config | `.replit` |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **project skills**: `.agents/skills/<name>/SKILL.md` · Agent Skills are project-scoped and follow the Agent Skills specification; `.local/secondary_skills/` is an official compatibility/discovery directory and must not be blindly merged with `.agents/skills/`.
- **rules/instructions**: `replit.md` at the project root · Agent reads, generates, and updates this living project context document; it does not automatically read arbitrary nested copies. The generic mapper therefore never overwrites it automatically.
- **enterprise template instructions**: `custom_instruction/instructions.md` can be included in a custom template; it is a project template file, not a user-global Replit settings path.
- **project app config**: `.replit` · runtime/app configuration such as run commands, ports, and modules; `replit.nix` is Nix/system-package configuration. These are not AI skills or portable AI config and are manual-only.
- **global skills/config**: no portable filesystem path documented for the user-level or enterprise/cloud-managed scopes; do not infer `~/.replit`, `~/.agents/skills`, or `~/.replit/replit.nix`.
- **MCP/integrations**: cloud/UI-managed through Replit Integrations and Agent MCP settings; no local MCP file target is exposed by this mapper. Custom MCP servers are added by HTTPS URL and may use custom headers; connections are shared across projects in Agent.
- **prompts**: Agent prompts are chat/UI input, not a documented portable prompt-file directory; automatic prompt migration is unsupported.
- **automatic boundary**: project paths are diagnostic/manual in this mapper; `.replit`/`replit.nix` project/runtime files, cloud-managed MCP/integrations, user/enterprise scopes, `custom_instruction/instructions.md`, and chat prompts remain manual or UI-managed. Never copy build/config files as skills.
- **sources**: [replit.md](https://docs.replit.com/features/project-setup/replit-dot-md), [Agent Skills](https://docs.replit.com/features/agent/skills), [Skills directory](https://docs.replit.com/features/agent/skills-directory), [Agent customization](https://docs.replit.com/features/agent/agent-customization), [project configuration](https://docs.replit.com/features/project-setup/configuration), [MCP integrations](https://docs.replit.com/build/connect-via-mcp), [custom templates and scopes](https://docs.replit.com/teams/custom-templates)

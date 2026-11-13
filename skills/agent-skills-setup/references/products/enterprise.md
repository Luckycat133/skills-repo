# Rovo, IBM Bob, GitLab Duo, Tabnine, Qodo and Cody

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## rovodev

**Atlassian Rovo Dev CLI, IDE and cloud** · Evidence: `documented-subset` · Runtime: `not-run`.

Rovo Dev CLI documents Skills in `.rovodev/skills` and shared `.agents/skills` roots, user/project AGENTS and local instructions, saved `.rovodev/prompts.yml` with referenced Markdown, subagents, MCP and `~/.rovodev/config.yml`.

Resolve the configured `mcpConfigPath` instead of choosing between historical `mcp.json`/`mcp_config.json` examples. Preserve YAML prompt parameters and relative files. Agent/subagent tools and run settings are separate from Skills.

Rovo Studio Skills and an A2A AgentCard's advertised skills are not automatically filesystem Agent Skills. IDE/cloud product settings must be checked independently. Exclude sessions and Atlassian tokens. Check the chosen Dev client lists and invokes the migrated object with the expected scope.

Official sources: [1](https://support.atlassian.com/rovo/docs/extend-rovo-dev-cli-with-agent-skills/) · [2](https://support.atlassian.com/rovo/docs/manage-rovo-dev-cli-settings/) · [3](https://support.atlassian.com/rovo/docs/connect-to-an-mcp-server-in-rovo-dev-cli/) · [4](https://support.atlassian.com/rovo/docs/use-subagents-in-rovo-dev-cli/)

## ibm-bob

**IBM Bob IDE and Bob Shell** · Evidence: `version-sensitive` · Runtime: `not-run`.

Inventory `.bob/skills`/user Skills, general and mode-specific rules, AGENTS, modes/subagents, MCP, plugins and permissions. Bob Shell 1 and Shell 2 differ; do not assume every historical Shell build loads IDE Skills.

Current IDE docs place global MCP under `~/.bob/settings/mcp.json`; older notes used other locations. Shell's MCP storage must be read from its own current docs/settings, not copied from IDE. September plugin support includes project/user `.bob/plugins` packages containing Skills/modes/rules/MCP.

Preserve mode scope and package references. `alwaysAllow`, remembered tool decisions and security configuration are not portable grants. Check native discovery in the actual IDE/Shell version, selected mode behavior and MCP schema without connecting.

Official sources: [1](https://bob.ibm.com/docs/ide/features/skills) · [2](https://bob.ibm.com/docs/shell/features/skills) · [3](https://bob.ibm.com/docs/ide/configuration/mcp/mcp-in-bob) · [4](https://bob.ibm.com/docs/shell/configuration/mcp/mcp-bobshell) · [5](https://bob.ibm.com/blog/september-2026-release/)

## gitlab-duo

**GitLab Duo IDE, CLI, web and agent flows** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory user/project/nested AGENTS, `.gitlab/duo` custom rules, Skills, subagents, MCP and flow definitions. Availability varies by IDE/CLI/web/flow version; use the official customization table before writing.

User AGENTS paths have platform/config overrides (`GLAB_CONFIG_DIR`, XDG, Windows application data), so do not substitute Linux HOME on Windows. Documented workspace Skills use `skills/<name>/SKILL.md` in their supported clients; inspect current settings before assuming another vendor's `.agents/skills` path. MCP client configuration and GitLab's MCP server are different roles.

Flows combine instructions and executable orchestration; keep their triggers and credentials separate. Check the intended client loads a rule/Skill and preserves subdirectory scope. Do not copy organization policies, cloud histories or access tokens.

Official sources: [1](https://docs.gitlab.com/user/duo_agent_platform/customize/) · [2](https://docs.gitlab.com/user/duo_agent_platform/customize/agent_skills/) · [3](https://docs.gitlab.com/user/duo_agent_platform/customize/agents_md/) · [4](https://docs.gitlab.com/user/gitlab_duo/model_context_protocol/mcp_clients/)

## tabnine

**Tabnine IDE/CLI and enterprise context** · Evidence: `version-sensitive` · Runtime: `not-run`.

Inventory guidelines, TABNINE.md where documented, commands/prompts, Skills or Skill integrations, MCP and enterprise Context Engine inputs. Current product generations/harnesses must be identified before choosing file layouts; an official Skill collection is not proof of a native installation root.

Separate local authored conventions from organization policy and server-side indexes. Do not copy model-provider config, credentials, enterprise permissions or the context database. UI-managed customization can be recreated through the selected client rather than guessed paths.

Check current CLI/IDE release and native settings. This review does not assert that older and newer Tabnine CLI schemas are interchangeable; document unresolved harness/version evidence before automatic edits.

Official sources: [1](https://docs.tabnine.com/main/getting-started/tabnine-agent/agent-settings) · [2](https://docs.tabnine.com/main/getting-started/tabnine-cli/features/commands) · [3](https://docs.tabnine.com/main/getting-started/tabnine-cli/getting-started/quickstart) · [4](https://github.com/tabnine/skills)

## qodo

**Qodo code review, IDE/Command and toolbox integrations** · Evidence: `version-sensitive` · Runtime: `not-run`.

Qodo is a product family, not one universal local host. Inventory repository review instructions/rules and Skills, organization review configuration, IDE prompts/agents, MCP toolbox integrations and legacy Command agent definitions.

Current code-review Skill guidance describes ordered discovery across `.qodo/skills`, `.claude/skills`, `.cursor/skills`, `.agents/skills` and `skills`; these do not imply every Qodo client supports local agent invocation. Legacy TOML agents and new toolbox plugins need version-specific import semantics.

Translate the selected review task's instructions and preserve priority. Do not migrate enterprise allowlists or infer a local MCP config from a hosted review service. Check the actual review/IDE/toolbox profile consumes the chosen file and reports any missing features.

Official sources: [1](https://www.qodo.ai/glossary/what-is-agent-skills/) · [2](https://www.qodo.ai/blog/introducing-qodos-agentic-toolbox/) · [3](https://github.com/qodo-ai/agents)

## cody

**Sourcegraph Cody, not Amp** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory Prompt Library, pre-instructions, explicit context attachments and any enabled MCP/OpenCtx integration through the selected Sourcegraph instance and IDE client. Enterprise code context and policies are server-managed, not an exportable local rules tree.

Copy reviewed prompts/instructions through supported interfaces. Keep repository/context bindings as a reconstruction list, not a copied index. Resolve feature flags and account permissions before claiming a tool can be installed. Do not map Amp Skills/settings to Cody because both share historical branding.

Check the current IDE and Sourcegraph deployment see the intended prompt/context scope. Never copy instance tokens or private code indexes into a general device package.

Official sources: [1](https://sourcegraph.com/docs/cody/capabilities) · [2](https://sourcegraph.com/docs/cody/clients/install-vscode) · [3](https://sourcegraph.com/docs/cody/capabilities/agentic-context-fetching)

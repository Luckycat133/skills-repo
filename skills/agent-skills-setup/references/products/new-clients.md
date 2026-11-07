# Additional clients found in this review

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## codebuff

**Codebuff / Freebuff CLI and SDK** · Evidence: `documented-subset` · Runtime: `not-run`.

Codebuff documents Skills in `.agents/skills` or `.claude/skills`, with on-demand selection and explicit `/skill:name` invocation. Project knowledge is provided through `knowledge.md` files and hierarchy; it is not just another name for AGENTS with identical loading.

Inventory knowledge files, Skills/resources, custom agent definitions, MCP and ignored paths. Freebuff is the current official repository lineage; inspect runtime/package version instead of changing product identity by name alone. Agents may contain executable definitions/tools; preserve prompt intent but reauthorize capabilities.

Check knowledge near subtrees, Skill identifier/directory validity, invocation and MCP settings. Preserve authored knowledge while excluding generated chat/state and provider secrets.

Official sources: [1](https://www.codebuff.com/docs/tips/skills) · [2](https://www.codebuff.com/docs/tips/knowledge-files) · [3](https://www.codebuff.com/docs/agents/agent-reference) · [4](https://github.com/CodebuffAI/freebuff)

## iflow

**iFlow CLI** · Evidence: `version-sensitive` · Runtime: `not-run`.

Inventory IFLOW.md, Skills, MCP, Sub Agents, Sub Commands, Hooks and Workflows. Current Skill docs specify `.iflow/skills` and `~/.iflow/skills` with project precedence. They also describe marketplace packaging/setup behavior and show historical `skill.toml` alongside SKILL.md authoring: inspect the actual package/version, do not assume a text-only install.

A marketplace install can execute setup scripts. A request to migrate an existing Skill does not authorize downloading or running those scripts. Prepare reviewed SKILL.md/resources and note package dependencies. Translate command/workflow arguments and hook lifecycle explicitly.

Check native Skill listing, IFLOW context discovery and MCP schema. Keep auth/provider/session records outside the transfer; verify any marketplace wrapper behavior before using native import.

Official sources: [1](https://docs.iflow.cn/cli/examples/skill/) · [2](https://docs.iflow.cn/cli/quickstart/) · [3](https://docs.iflow.cn/cli/examples/mcp/) · [4](https://docs.iflow.cn/cli/changelog/)

## codearts

**Huawei CodeArts Agent IDE and console** · Evidence: `documented-subset` · Runtime: `not-run`.

CodeArts documents Skills, Rules and MCP, plus custom agents and enterprise/team/project/user scope. User scope can be local or cloud; built-in Skills and marketplace packages are separate sources.

Skills are SKILL.md directories with resources, while rules are persistent behavior constraints. Console imports and IDE-local customizations have different authority and storage. Do not copy an enterprise rule as a personal rule or change a team object without admin authorization. MCP supports local stdio and documented remote transports; reauthorize connections.

Use actual IDE settings or console import/export rather than guess a filesystem root. Check object scope, source, enable state and native discovery after import. No rule/Skill upload should silently execute package setup or grant MCP access.

Official sources: [1](https://support.huaweicloud.com/intl/en-us/usermanual-codeartsagent/codeartsagent_ug_0027.html) · [2](https://support.huaweicloud.com/intl/en-us/usermanual-codeartsagent/codeartsagent_ug_0024.html) · [3](https://support.huaweicloud.com/intl/en-us/usermanual-codeartsagent/codeartsagent_ug_0019.html) · [4](https://support.huaweicloud.com/intl/en-us/usermanual-enterprise/codeartsagent_enterprise_0028.html)

## ona

**Ona / former Gitpod and its agent harnesses** · Evidence: `version-sensitive` · Runtime: `not-run`.

Current Ona agent overview redirects to a Codex-harness page; older Ona-native agent guidance is not automatically the current harness contract. Inventory repository AGENTS, Skills, organization Skills, MCP, environment configuration and automations for the selected runner/agent.

Project/user Skill directories and organization Skills must be verified against that agent version. A generic installer listing `.ona/skills` is not sufficient evidence that the current Codex harness loads it. Gitpod Classic `.gitpod.yml` and new devcontainer/automation configuration are environment objects, not agent instructions.

Recreate selected authored guidance and MCP connections through current project/organization controls. Keep runner secrets, session state and guardrail policy separate. Check the actual remote environment sees the files and selected harness discovers them; local editor discovery is insufficient.

Official sources: [1](https://ona.com/docs/ona/agents/codex) · [2](https://ona.com/docs/ona/agents/skills) · [3](https://ona.com/docs/ona/skills) · [4](https://ona.com/docs/ona/agents-md) · [5](https://ona.com/docs/ona/mcp)

## t3-code

**T3 Code desktop/web and providers** · Evidence: `documented-subset` · Runtime: `not-run`.

T3 Code manages agent sessions and can run installed ACP providers. Skills and credentials remain owned by the provider or its wrapper; do not invent a single T3-native Skill directory for every agent.

Inventory provider-specific Skills/plugins/MCP/instructions, T3 composer commands and environment configuration. Thread-scoped MCP registration differs from an underlying agent's directory-scoped config. After changing Skills/plugins/MCP, the official composer guide requires restarting the agent session to refresh discovery.

Use the real provider's configuration and preserve T3's scoped integration. Do not copy internal thread tokens, chat state or provider profiles wholesale. Check the selected provider inside T3 sees the intended Skill; an outside CLI test alone is not enough.

Official sources: [1](https://github.com/pingdotgg/t3code/blob/main/docs/user/providers-acp.md) · [2](https://github.com/pingdotgg/t3code/blob/main/docs/user/composer.md) · [3](https://github.com/pingdotgg/t3code/blob/main/docs/user/outside-agents.md)

## coder-xum

**Coder Xum / former coder/mux** · Evidence: `version-sensitive` · Runtime: `not-run`.

The official `coder/mux` repository now redirects to `coder/xum`. Do not confuse it with unrelated Mux or AgentMux products, and do not assume every `.mux` path was renamed.

Inventory the installed desktop build, selected agent definitions, Skills, AGENTS/project guidance, MCP and local/SSH workspace settings. Resolve current paths from that build's docs/config; this review establishes identity and relevant categories, not a complete new-root map.

Move selected authored objects while preserving their workspace/agent association. Recreate remote-host connections and credentials separately. Check actual target discovery; retain explicit unknowns until version-specific path evidence is available.

Official sources: [1](https://github.com/coder/xum) · [2](https://coder.com/docs/ai-coder/agents/extending-agents)

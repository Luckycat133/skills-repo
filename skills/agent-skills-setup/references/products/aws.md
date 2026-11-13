# Kiro and Amazon Q

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## kiro

**Kiro IDE, CLI, web/mobile and Crew** · Evidence: `version-sensitive` · Runtime: `not-run`.

Steering lives in `.kiro/steering` and user steering directories; preserve inclusion mode, file matching and imports. AGENTS is always-included where documented. Skills use `.kiro/skills`/`~/.kiro/skills`, but CLI custom-agent resource declarations can control what is loaded. A Skill copied into a directory is not proof that every agent selects it.

Inventory Skills, steering, Specs, hooks, Powers, custom agents, MCP and settings. Specs are task artifacts; Powers bundle knowledge and tools. They are not ordinary rules. Current CLI 3 agent config differs from CLI 2: permissions/excluded tools and inclusion controls are not the old allowedTools/toolsSettings schema. Use version-matched examples; never translate broad tool approval blindly.

CLI positional Skill arguments and resources may not work identically in IDE/web/mobile. Crew is another scope, not a new local path inferred from the name. Check the selected agent's loaded resources, positive/negative steering examples and the actual MCP config; keep hooks inactive and authored Specs separate from generated work history.

Official sources: [1](https://kiro.dev/docs/steering) · [2](https://kiro.dev/docs/skills) · [3](https://kiro.dev/docs/custom-agents) · [4](https://kiro.dev/docs/mcp/configuration) · [5](https://kiro.dev/docs/)

## amazon-q

**Amazon Q Developer IDE and legacy/current CLI profiles** · Evidence: `version-sensitive` · Runtime: `not-run`.

Project instructions include `.amazonq/rules`. Inventory saved prompts, custom agents/personas, MCP, memory/context features and hooks separately for IDE versus CLI. Do not relabel an Amazon Q configuration as Kiro solely because the products are related.

Official MCP pages disagree on the global IDE default: the IDE page describes `~/.aws/amazonq/default.json`, while the overview lists `~/.aws/amazonq/agents/default.json`. Project `.amazonq/default.json` and older `mcp.json` are also versioned inputs. **Resolve the active file through the installed IDE/config schema before writing.** Record which page/version applies; do not write every candidate path.

Extract selected MCP definitions only, preserve unrelated AWS config and rebind authentication. Check the native MCP settings view, not just JSON syntax. If the active scope cannot be established, prepare the reviewed server definition and an exact unresolved-location note rather than claim full migration.

Official sources: [1](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/mcp-ide.html) · [2](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/qdev-mcp.html) · [3](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/context-project-rules.html)

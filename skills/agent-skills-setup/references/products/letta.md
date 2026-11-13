# Letta memory-first agents

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## letta-code

**Letta Code CLI/desktop and hosted agent** · Evidence: `version-sensitive` · Runtime: `not-run`.

Inventory Skills, AGENTS/workspace context, agent-specific memory files, subagents, schedules and tools/MCP. Skill discovery may include `${MEMORY_DIR}/skills`, global Letta and project `.agents` locations; these have different ownership and precedence.

Current Letta Code documentation removes/deprecates legacy AgentFile `.af` export/import. Do not present `.af` as the normal current device-transfer format. A historical `.af` is a version-specific source containing state that must be reviewed, not blindly imported into an IDE.

Prepare selected authored memory/Skills as files plus scope and provenance. Keep recall databases, chat histories, tokens and cloud agent IDs out of the default transfer. Check the target agent's actual memory filesystem and Skill discovery; an unrelated Letta agent must not inherit another agent's private memory.

Official sources: [1](https://docs.letta.com/configuration/skills) · [2](https://github.com/letta-ai/letta-code/blob/main/README.md)

## letta

**Letta platform/API agents** · Evidence: `documented-subset` · Runtime: `not-run`.

The Letta platform manages stateful agents, memory blocks, tools and model configuration. This is not one local IDE directory. Inventory selected authored system instructions/memory, tool definitions and Skills through the authorized platform surface.

Map reviewed durable facts to destination instructions or user-authored memory. Do not make complete agent state, chat history or database export the default. Legacy AgentFile support is version-dependent and does not establish current Letta Code support.

Check agent ownership, memory sharing and tool permissions before re-creating anything. Preserve the distinction between exported text and a live platform agent; reconnect tools and secrets separately.

Official sources: [1](https://docs.letta.com/) · [2](https://docs.letta.com/configuration/skills)

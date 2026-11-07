# Discover the actual context, not a guessed IDE brand

Consulted official documentation on 2026-11-07. These are starting points, not a
compatibility certification. Check the installed version and actual files before
writing. Public docs can change independently of the installed client.

## Resolve identity and scope

Separate CLI, IDE extension/harness, desktop chat, cloud session, and remote
extension host. VS Code running a Claude or Codex harness is not necessarily a
Copilot session. Resolve HOME, XDG, product overrides and workspace from the
host's tools; do not expand a Windows path using a Linux home. If the environment
is unavailable, prepare reviewed target files without claiming installation.

Inspect only relevant paths and schema keys. An installed app, enabled extension,
user-confirmed profile, and existing config are different evidence. A shared
`.agents/skills` or `AGENTS.md` does not mean every compatible app is installed.
For an authorized all-tools request, list detected candidates and distinguish
installed, configured, shared-only, and unknown before choosing targets.

## Source-backed starting points

| Product/profile | Useful starting point | Evidence |
| --- | --- | --- |
| Cursor project | `.cursor/rules/*.mdc`; `.cursor/skills/`; inspect MCP config separately | [Rules](https://cursor.com/docs/rules), [Skills](https://cursor.com/docs/skills), [MCP](https://cursor.com/docs/mcp) |
| Claude Code | `CLAUDE.md`, `.claude/rules/*.md`, `.claude/skills/`, `.mcp.json` project MCP | [Memory](https://code.claude.com/docs/en/memory), [Skills](https://code.claude.com/docs/en/skills), [MCP](https://code.claude.com/docs/en/mcp) |
| Codex CLI/local extension | hierarchical `AGENTS.md`; MCP tables in `~/.codex/config.toml` or project `.codex/config.toml` | [Instructions](https://developers.openai.com/codex/guides/agents-md), [MCP](https://developers.openai.com/codex/mcp) |
| VS Code Copilot/local harness | `.github/instructions/*.instructions.md`; project `.vscode/mcp.json`; active user profile is separately resolved | [Instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions), [MCP](https://code.visualstudio.com/docs/agent-customization/mcp-servers) |
| Gemini CLI | `GEMINI.md`; MCP is the `mcpServers` subobject of user/project `.gemini/settings.json` | [Configuration](https://geminicli.com/docs/get-started/configuration/), [MCP](https://geminicli.com/docs/tools/mcp-server/) |

Do not infer the absence of commands, agents, hooks, memory, extensions, plugins,
team policy, or cloud knowledge from this short table. Open the product's current
customization index and enumerate those categories when the user requests all
context. Do not copy a whole `.claude.json`, `settings.json`, `.codex`, or app-data
tree. Shared settings may contain account state next to useful configuration.

## Any other IDE or an uncertain path

1. Identify the vendor and exact product/profile. Similar names are not aliases.
2. Open its official documentation index, installed schema, or vendor repository.
   Search rules/instructions/steering, skills, commands/prompts, agents/modes,
   hooks/workflows, MCP/tools, memory/knowledge, plugins/extensions, and scope.
3. Record the evidence URL or local schema path, retrieval date, version when
   known, storage location, loading behavior, precedence, and supported fields.
4. Inspect the user's actual files. Resolve disagreements instead of choosing a
   convenient path. UI-only storage needs UI/export guidance, not invented files.
5. Apply the relevant conversion reference using existing agent tools. Where
   evidence is insufficient, preserve the reviewed source and describe the exact
   missing contract. Do not label the whole IDE unsupported or invent support.

If public lookup is unavailable or forbidden, say so and use only local evidence.
Never send usernames, private repository names, config values, or file contents
as search terms. Product/version/field names are normally sufficient.

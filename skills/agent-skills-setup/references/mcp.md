# MCP migration: translate a server definition, not an entire settings file

Treat name, transport, command/arguments, working directory, environment references,
URL/headers, timeout units, enablement, tool restrictions, and authentication as
separate fields. Consult the target's installed schema/current vendor docs.
JSON, JSONC, TOML, YAML and UI configuration are not unsupported merely because
there is no bundled converter: use the host agent's existing parser/edit tools.

## Field-by-field procedure

1. Read only the selected server definitions into the proposed output. Do not
   export sibling settings, account data, approvals, trust, provider keys, caches,
   or machine state. Preserve unrelated destination values and comments.
2. Retain literal non-secret values only. Replace credential values with the
   target's supported variable/input mechanism; record variable names, never
   values. Search args and URL userinfo/query strings as well as env/headers.
3. Map the transport explicitly. A URL does not prove SSE versus Streamable HTTP.
   Retain a supported remote transport rather than pretending all remote MCP is
   impossible. OAuth must be authorized again; do not move access/refresh tokens.
4. Rebase local command/args/cwd paths for the destination. Keep arguments as an
   array, not a shell-joined command. Missing binaries and packages become named
   prerequisites, not automatic downloads or installations.
5. Preserve disabled state and restrictive tool filters. Do not import trust or
   auto-approval. Unrepresentable restrictions require a parked draft or explicit
   resolution, not silently broader permissions. Convert timeout units explicitly.
6. Merge by server name: identical normalized definitions deduplicate; different
   definitions conflict. Keep other servers. Resolve all source contributions
   before writing a destination file once.

## Worked example: JSON stdio to Codex TOML

A reviewed definition from a `mcpServers` map:

```json
{
  "mcpServers": {
    "project-tools": {
      "command": "node",
      "args": ["tools/project-server.mjs"],
      "env": {"PROJECT_TOKEN": "${PROJECT_TOKEN}"}
    }
  }
}
```

For a verified Codex config, merge this table into `.codex/config.toml` (project)
or `~/.codex/config.toml` (user), never replace the entire file:

```toml
[mcp_servers.project-tools]
command = "node"
args = ["tools/project-server.mjs"]
env_vars = ["PROJECT_TOKEN"]
```

This example assumes the command runs from the same intended project root;
otherwise resolve `cwd` or a new approved path first. `env_vars` forwards the
**same-named** environment variable. It is not an arbitrary mapping: converting
`SERVER_TOKEN = ${DIFFERENT_HOST_TOKEN}` to `env_vars = ["DIFFERENT_HOST_TOKEN"]`
changes the server-visible name and is wrong. Leave a precise rebinding step or
use a documented target mapping mechanism. Do not put a literal `${...}` string
into TOML and assume interpolation.

For a verified VS Code workspace target, use `.vscode/mcp.json`, a `servers` map,
and the target's documented `type`/input/environment syntax. Renaming the root
key alone does not convert auth, inputs, transport, or lifecycle fields.
Gemini CLI stores a `mcpServers` subobject inside `.gemini/settings.json` and
`~/.gemini/settings.json`; do not invent a separate `mcp.json` there.

## Review and validation

Parse the final JSON/JSONC/TOML/YAML with a suitable parser. Show only a redacted
semantic diff: added/changed server names, transport, referenced variable names,
and losses. Check unrelated settings before/after. A valid file is not proof the
host loads it, and a listed config is not proof a server connects. Some status/list
commands start servers or contact endpoints: inspect their documented behavior
and obtain separate authorization before any execution or connection test.

Do not run npx/uvx/installers, authenticate, or start a copied command merely to
validate migration. Native UI-only imports should be explained as UI steps;
never edit an application's internal database.

## Evidence

Consulted 2026-11-07:
[Codex MCP](https://developers.openai.com/codex/mcp),
[VS Code MCP](https://code.visualstudio.com/docs/agent-customization/mcp-servers),
[Gemini CLI MCP](https://geminicli.com/docs/tools/mcp-server/),
[Claude Code MCP](https://code.claude.com/docs/en/mcp).

## Configuration is per client and harness

Read the [catalog](products.md) before choosing a root key. Examples: Codex uses
TOML `mcp_servers`; Local VS Code uses JSON `servers`; Zed uses `context_servers`;
Continue uses YAML blocks/arrays; OpenCode has major-version-specific layouts.
Gateway, node-host, CLI, IDE and cloud MCP belong to different scopes. A shared
protocol does not make their configuration interchangeable.

Normalize all selected servers before writing one destination file. Same name and
same effective definition is a no-op; same name with different transport, command,
arguments, working directory, environment, auth or exposure is a conflict. Preserve
all independent servers and target neighbors. Do not silently drop timeout, disabled,
tool allow/deny or trust-related fields: distinguish content losses from grants
that must be reacquired. References to a secret must preserve both the host variable
name and the server-visible name; record rebinding when that mapping cannot be kept.

Current Pi scope overrides and ZCode native-versus-shared precedence are not generic
merge semantics. Inspect effective configuration rather than concatenate files.
For a remote Skill extension, keep server identity and do not assume filesystem
Skill discovery implements the extension. Config validation is separate from any
server connection, OAuth flow, tool call or dependency installation.

---
name: agent-skills-setup
version: 0.6.6
license: MIT
description: >
  Migrate AI assistant context between IDEs — MCP servers, rules/instructions,
  skills, slash commands, agents, hooks, and memory. Resolves only the
  user-specified source/target paths, converts supported formats, previews every
  change, preserves or backs up existing data according to an explicit strategy,
  and verifies the result. WHEN TO USE: ONLY when the user explicitly asks to
  migrate, move, transfer, copy, convert, or sync AI assistant context between
  IDEs, for example “migrate MCP config”, “move skills from Cursor to Claude”,
  or “transfer rules from Windsurf to Cursor”. Never write without a reviewed
  --dry-run and explicit approval. DO NOT ACTIVATE ON: incidental mentions of
  MCP, skills, rules, or IDE names; format questions; debugging requests;
  “how do I…” / “what is…” questions; or any prompt that does not explicitly
  request a cross-IDE migration. When source, target, objects, or scope are
  unclear, ask before reading configuration.
triggers:
  - migrate mcp config
  - move skills from cursor to claude
  - transfer mcp servers between ide
  - migrate rules from windsurf to cursor
  - copy mcp config to another ide
  - migrate ai context from one ide to another
capabilities:
  - read: user-selected IDE/agent config paths
  - write: file-backed migration objects, gated by dry-run, consent, and strategy
  - exec: local migration and verification scripts
  - install: OpenClaw runtime or clawhub only through the consent and SHA-256 exception below
  - network: outbound HTTPS only for an explicitly approved, integrity-verified download
---

# AI IDE Context Migration

Migrate only the context the user names. Treat path, scope, schema, secrets, and
conflicts as part of the migration contract rather than assuming two IDEs store
equivalent files.

## Load references progressively

Keep the first response fast and focused:

1. Read only the source and target sections in
   [references/ide-registry.md](references/ide-registry.md).
2. Use [references/ide-paths.json](references/ide-paths.json) or
   **scripts/smart-ide-migration.sh --print-path** for deterministic lookup.
3. Read other registry sections only when a referenced compatibility surface is
   actually involved. Do not load the complete registry by default.

The registry is the detailed source for platform paths, schemas, precedence,
verification commands, and manual boundaries. The script is the executable
contract. If prose and executable behavior disagree, stop and report the drift.

## Security model

- Resolve only the two IDEs and optional workspace the user specifies. Never
  enumerate the home directory or auto-discover every installed IDE.
- Default objects are low risk: **skills,rules,prompts**. MCP, config, project,
  agents, hooks, and memory require explicit selection.
- Start with **--dry-run**. It may parse the selected source but creates no
  workspace or target output and never prints raw configuration values.
- A write requires explicit approval and **--yes**. A non-interactive run
  without it exits before any target write.
- Literal credentials are blanked in a copy. Preserve or translate only an exact
  documented environment reference; mixed/default/command-substitution syntax is
  blank/manual. If redaction fails, delete the target copy and fail closed.
- Reject source/target paths that resolve to the same file, including symlinks.
- Stop on invalid JSON/JSONC/TOML/YAML or an unsupported schema/transport. Never
  fall back to copying an explicit input as-is.
- Do not migrate chat history, OAuth state, databases, vector indexes, workspace
  storage, UI settings, or generated memory.

## Migration objects

| Object | Automatic scope |
|---|---|
| **skills** | File-backed Skill directories; preserve the complete directory |
| **rules** | Supported Markdown instruction files/directories |
| **prompts** | Supported prompt/command Markdown with target review |
| **mcp** | Supported JSON/JSONC server maps; explicit opt-in |
| **project-mcp** | One explicit workspace MCP file; explicit opt-in |
| **config / project** | Narrow file/tree copy with backup and redaction; explicit opt-in |
| **agents / hooks / memory** | Diagnostic/manual only; never generic-copy or execute |

## Response staging

### First response: preview only

1. Restate source, target, objects, scope, and workspace.
2. State any manual boundary or credential risk in a few lines.
3. Give the exact **--dry-run** command.
4. Do not claim a migration happened and do not present an apply command as an
   action already taken.

For explicit MCP input, say all three facts: **--source-mcp-file** changes only
the input location; **--source** still selects the source schema/root; workspace
plus the target registry still select the output path.

### After approval: apply and prove

Run the reviewed command with **--yes**, preferably with **--json**. Report the
resolved source/target paths, parse status, source-before/source-after SHA-256,
whether the source stayed unchanged, target existence/hash, backup path, and
manual follow-ups. Do not improvise a separate evidence harness when the JSON
report already provides these fields.

## Execution workflow

~~~text
1. CONFIRM  source, target, workspace, objects, and scope
2. RESOLVE  only the selected registry paths
3. READ     only selected objects; validate schema and path identity
4. PREVIEW  value-free --dry-run with zero target writes
5. APPROVE  wait for explicit user confirmation
6. PROTECT  apply skip/backup/overwrite to the selected object
7. MIGRATE  convert, redact, and write
8. VERIFY   parse output and emit deterministic evidence
~~~

## Conflict strategies

| Strategy | Existing selected object |
|---|---|
| **skip** | Preserve it and do not migrate that object |
| **backup** (default) | Create .bak.<timestamp>, then merge; same-name source entries become active |
| **overwrite** | No backup; replace only the selected object |

For MCP inside a shared config file, every strategy preserves unrelated
top-level settings. **overwrite** replaces the selected server map, not the
whole file. For directory-backed skills/projects, the selected same-name
directory/tree is the object. Never invent a **<name>_migrated** entry.

## MCP conversion

Automatic conversion is limited to validated JSON/JSONC server maps.

| Target | Automatic root/shape | Boundary |
|---|---|---|
| Cursor and common clients | **mcpServers** | Validate command or URL shape |
| VS Code workspace | **servers** in .vscode/mcp.json | User MCP is active-Profile/UI managed; never guess a global path |
| OpenCode V1 | direct servers under **mcp** | Default legacy-compatible target |
| OpenCode V2 | servers under **mcp.servers** | Pass --opencode-version v2; convert enabled, timeout, and OAuth fields |
| OpenClaw / ZCode | **mcp.servers** | Apply each target's documented transport rules |
| Codex | **[mcp_servers.<name>]** TOML | Manual reconstruction and TOML validation |
| Continue | YAML mcpServers array / project blocks | Manual; do not claim object-map conversion |
| Goose | YAML extensions with type-specific fields | Manual; do not copy JSON into YAML |

For the **Claude Desktop app**, the legacy local JSON is only one surface.
Review local integrations in **Settings → Extensions** and remote MCP in
**Settings → Connectors**; do not infer or rewrite those UI-managed entries
from the JSON file.

For each automatic server:

1. Extract command/args/env or URL/headers only after validating exactly one
   endpoint shape.
2. Blank literal secrets before target write. Translate exact Cursor
   ${env:NAME} to OpenCode {env:NAME} when applicable.
3. Convert the root and target-specific fields. Reject ambiguous transport,
   conflicting old/new fields, or invalid existing target JSON.
4. Apply the conflict strategy to the selected server map while preserving
   unrelated settings.
5. Parse the written target and emit JSON evidence.

**--source-mcp-file <file>** accepts one readable JSON/JSONC file and one scope.
It rejects **--scope both**, resolves symlinks, requires the declared source
root/schema, and has no copy-as-is fallback. Continue/Goose YAML and Codex TOML
remain manual even when the user points to a file.

When a YAML/TOML boundary is manual, finish with reconstruction and validation.
For Codex, rebuild **[mcp_servers.<name>]** in the reviewed user or trusted
project config.toml, validate TOML, then run **codex mcp list**.

## Other object rules

- **Skills:** copy the whole named directory, including SKILL.md, scripts,
  references, and assets. Preserve source frontmatter unless the target
  documents a required adaptation.
- **Rules:** reuse the Markdown body; adapt only documented filenames and
  frontmatter. Prefer AGENTS.md as an intermediate when both products load it.
  Do not overwrite living/generated instruction files such as Replit's
  replit.md.
- **Prompts:** copy only documented file-backed prompt formats. Gemini TOML
  commands and UI/enterprise prompt libraries remain manual.
- **Agents:** formats, permissions, tools, models, hooks, and MCP differ too
  widely for a generic converter. Recreate reviewed prompt content manually.
- **Hooks:** never copy or execute a hook. Rebuild it after reviewing target
  event names, matchers, command semantics, and trust scope.
- **Memory:** generated or private runtime state is not portable. A user may
  manually select human-readable context and rewrite it as rules.

## OpenClaw installation exception

**scripts/auto-configure-openclaw-skills.sh** may install the OpenClaw runtime
or clawhub only when the user explicitly requests it and passes **--yes**.
Remote install.sh must be downloaded to a temporary file and match the mandatory
**OPENCLAW_INSTALL_SHA256** value before execution. **--dry-run** previews
without installing. This exception does not authorize any other global install,
shell-rc edit, remote-script pipe, or IDE restart.

## Verification

Use **--json** for automation. Its MCP evidence array contains:

- effective scope and status;
- canonical source and target paths;
- source SHA-256 before/after and source_unchanged;
- target existence, SHA-256, and parse validation;
- backup path when one was created.

Then use the target's native discovery surface when available, for example
**claude mcp list**, **codex mcp list**, **opencode mcp list**,
**opencode2 mcp list**, **copilot mcp list**, or the IDE MCP panel. Read the
target registry section for the authoritative method. Static parse success does
not prove credentials, OAuth, permissions, or server connectivity.

## Migration script

Always run from this Skill directory or use an absolute script path.

~~~bash
# Resolve one documented path without side effects.
bash scripts/smart-ide-migration.sh --print-path cursor project-mcp

# Preview low-risk context.
bash scripts/smart-ide-migration.sh \
  --source cursor --target claude --workspace /path/to/project \
  --objects skills,rules --scope project --dry-run

# Preview an explicit MCP export.
bash scripts/smart-ide-migration.sh \
  --source cursor --target opencode --workspace /path/to/project \
  --objects project-mcp --source-mcp-file /path/to/export.json \
  --dry-run --json

# Apply only after the user approves the preview.
bash scripts/smart-ide-migration.sh \
  --source cursor --target opencode --workspace /path/to/project \
  --objects project-mcp --source-mcp-file /path/to/export.json \
  --strategy backup --yes --json

# Request native OpenCode V2 output explicitly.
bash scripts/smart-ide-migration.sh \
  --source cursor --target opencode --opencode-version v2 \
  --workspace /path/to/project --objects project-mcp \
  --source-mcp-file /path/to/export.json --strategy backup --yes --json
~~~

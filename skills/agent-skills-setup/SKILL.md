---
name: agent-skills-setup
version: 0.6.9
license: MIT
description: >
  Use this skill when a user explicitly asks to migrate, move, transfer, copy,
  convert, or sync AI-assistant context between IDEs or agents, including MCP
  servers, rules, skills, prompts, commands, or project configuration. Offer a
  scoped plan, relevant compatibility notes, and a preview before writing; then
  adapt the process to the user's stated goals and risk tolerance. It is not
  needed for explanations, setup, debugging, validation, installation, or a
  same-tool copy unless that work is part of an explicit migration.
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
---

# AI IDE Context Migration

Use the user's requested scope as the starting point. Paths, schemas,
credentials, and conflicts often differ between IDEs, so surface those
differences early instead of assuming equivalent files or formats.

## Start with the smallest relevant context

1. Clarify the source, target, objects, scope, and (when relevant) workspace.
   If a detail is missing but a safe assumption is obvious, state it; otherwise
   ask a focused question.
2. Start with [references/ides/<source>.md](references/ides/) and
   [references/ides/<target>.md](references/ides/), substituting the selected
   IDE identifiers. Use [references/ide-paths.json](references/ide-paths.json)
   or `bash scripts/smart-ide-migration.sh --print-path` when a deterministic
   path lookup would help.
3. Load the conditional reference that fits the task. The index in
   [references/ide-registry.md](references/ide-registry.md) is useful when an
   IDE identifier is unfamiliar, but it is not required for ordinary work.

| Situation | Read this additional reference |
|---|---|
| Every migration before preview or apply | [references/migration-safety.md](references/migration-safety.md) |
| `mcp` or `project-mcp`, or `--source-mcp-file` | [references/mcp-migration.md](references/mcp-migration.md) |
| `skills`, `rules`, `prompts`, `config`, `project`, `agents`, `hooks`, or `memory` | [references/object-migration.md](references/object-migration.md) |
| After an approved apply, or when reporting proof | [references/verification.md](references/verification.md) |
| OpenClaw is source or target | [references/openclaw.md](references/openclaw.md) |

The per-IDE references provide platform paths, schemas, precedence, native
verification, and portability notes. The script describes what can be automated
today. If they disagree, point out the mismatch and suggest a review before
applying changes.

## Recommended safeguards

These are recommendations, not a substitute for the user's judgment about the
scope and risk of their own configuration.

- Prefer the named source, target, and workspace over broad discovery. This
  keeps a migration easy to review and avoids pulling in unrelated context.
- A practical default is `skills,rules,prompts`. Call out that MCP, config,
  project, agents, hooks, and memory can carry more product-specific behavior.
- Offer a value-free `--dry-run` first. The bundled script requires `--yes` for
  writes, so a reviewed preview is the natural handoff point for consent.
- Treat chat history, OAuth state, databases, vector indexes, workspace
  storage, UI settings, and generated memory as poor portability candidates;
  help the user select human-readable context instead when appropriate.
- **The Claude Desktop app MCP surface is partly UI-managed:** suggest reviewing
  **Settings → Extensions** and **Settings → Connectors** rather than inferring
  or rewriting those entries from its legacy local JSON.

## Workflow

1. **Clarify** the migration goal and consult the two selected IDE references.
2. **Plan** likely source/target paths and the object list; load the
   relevant conditional reference.
3. **Preview** with `--dry-run` when writes are in scope; report boundaries and
   credential handling rather than implying completion.
4. **Apply** after the user is comfortable with the plan, using the reviewed
   command with `--yes` and normally `--json`.
5. **Verify** with the JSON evidence and the target's native discovery method.

For fragile configuration migrations, a preview gives the user a chance to
catch a wrong path, scope, or conflict strategy. Preserve an existing target
unless the chosen strategy and the user’s intent make replacement appropriate.

## Script entry points

- `scripts/smart-ide-migration.sh` — resolve paths, preview, apply, redact, and
  emit JSON evidence. Run `bash scripts/smart-ide-migration.sh --help` when its
  flags or supported objects are uncertain.
- `scripts/test-ide-paths.sh` — maintainer regression that compares every
  resolver result with `references/ide-paths.json` and its generated reference
  summaries; it is useful when changing mappings, not for a user's migration.

Run commands from this Skill directory, or use absolute script paths.

~~~bash
# Resolve one documented path without side effects.
bash scripts/smart-ide-migration.sh --print-path cursor project-mcp

# Preview an explicitly scoped low-risk migration.
bash scripts/smart-ide-migration.sh \
  --source cursor --target claude --workspace /path/to/project \
  --objects skills,rules --scope project --dry-run
~~~

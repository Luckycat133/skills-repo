# File-backed object migration

Read with [migration-safety.md](migration-safety.md) for non-MCP objects.

| Object | Handling |
| --- | --- |
| Skills | Preflight all source text, then copy credential-free named directories as units. |
| Rules | Parse and emit the selected product's native frontmatter; never flatten conditional activation into an unconditional file. |
| Prompts | Use the target's documented format; review Gemini TOML and UI/enterprise libraries. |
| Config / project | Manual-only; never copy whole config or opaque trees. |
| Agents / hooks | Recreate reviewed content against target permission, event, and command schemas. |
| Memory | Do not copy private/generated state; rewrite selected context as rules. |

Treat living or generated files, including Replit `replit.md`, as manual conversation state rather than overwrite targets. When no compatible target format is documented, describe reconstruction instead of an unvalidated copy. There is no generic embedded-config exception: a sub-object is automatic only when Registry v2 names a reviewed source and target adapter for the exact profile/version.

The reviewed instruction adapters use native fields for Augment (`type`), Cline/Claude (`paths`), Cursor and Continue (`alwaysApply`/`globs`), Kiro (`inclusion`/`fileMatchPattern`), Copilot (`applyTo`), and Windsurf (`trigger`). Unknown frontmatter is reported as loss. A conversion becomes manual when the target cannot preserve `always`, glob, model-decided, or manual activation semantics.

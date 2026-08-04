# File-backed object migration

Read with [migration-safety.md](migration-safety.md) for non-MCP objects.

| Object | Handling |
| --- | --- |
| Skills | Preflight all source text, then copy credential-free named directories as units. |
| Rules | Reuse Markdown, adapting documented filename/frontmatter. |
| Prompts | Use the target's documented format; review Gemini TOML and UI/enterprise libraries. |
| Config / project | Manual-only; never copy whole config or opaque trees. |
| Agents / hooks | Recreate reviewed content against target permission, event, and command schemas. |
| Memory | Do not copy private/generated state; rewrite selected context as rules. |

Treat living or generated files, including Replit `replit.md`, as manual conversation state rather than overwrite targets. When no compatible target format is documented, describe reconstruction instead of an unvalidated copy.

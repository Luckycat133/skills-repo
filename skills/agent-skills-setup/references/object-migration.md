# File-backed object migration

Use this reference when the selected object is not MCP. These notes describe
portable defaults and the kinds of product-specific behavior worth reviewing.

| Object | Automatic scope |
|---|---|
| **skills** | File-backed Skill directories; preserve the complete directory. |
| **rules** | Supported Markdown instruction files/directories. |
| **prompts** | Supported prompt/command Markdown with target review. |
| **config / project** | Narrow file/tree copy with backup and redaction. |
| **agents / hooks / memory** | Diagnostic/manual by default; product-specific review is usually clearer than a generic copy. |

- **Skills:** preserve the whole named directory, including `SKILL.md`, scripts,
  references, and assets. Preserve source frontmatter unless the target
  documents a required adaptation.
- **Rules:** reuse the Markdown body and adapt documented filenames or
  frontmatter. Prefer `AGENTS.md` as an intermediate when both products load
  it. Treat living/generated instruction files such as Replit's `replit.md` as
  a conversation with the user rather than an ordinary overwrite.
- **Prompts:** documented file-backed prompt formats are the most portable.
  Gemini TOML commands and UI/enterprise prompt libraries benefit from review.
- **Config / project:** prefer the selected narrow file or tree, using the
  conflict and redaction rules in [migration-safety.md](migration-safety.md).
- **Agents:** permission, tool, model, hook, and MCP formats differ too widely
  for a generic converter. Recreate reviewed prompt content deliberately.
- **Hooks:** rebuild a hook after reviewing the
  target event names, matchers, command semantics, and trust scope.
- **Memory:** generated or private runtime state is rarely portable. A user may
  manually select human-readable context and rewrite it as rules.

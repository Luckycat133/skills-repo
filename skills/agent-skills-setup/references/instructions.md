# Rules and instructions: preserve when and where they apply

Check text, scope, activation, pattern base, hierarchy/precedence, imports, and
local overrides. A file rename is not a semantic conversion. Keep language and
technical requirements intact; do not rewrite the user's policy for style.

## Mapping decisions

| Source behavior | Safe destination strategy |
| --- | --- |
| Always-on project instructions | Merge a reviewed section into the target's project instructions, preserving existing sections |
| File-pattern rule | Use the target's real pattern-scoped format and equivalent base directory |
| Relevance/model-selected rule | A target on-demand skill with a matching description may work, but disclose changed selection behavior |
| Manually invoked rule/command | Preserve explicit invocation; do not turn it into an always-on rule or auto-invoked skill |
| Subdirectory instruction | Keep hierarchy; flattening into the repository root changes scope |
| User preference | Keep user scope; do not commit it to the project without permission |
| Imported instruction | Rebase relative references or copy only authorized dependencies; do not inline private external files silently |

Cursor uses `.mdc` rule metadata `alwaysApply`, `globs`, and `description`.
`alwaysApply: true` takes priority over a supplied glob. Claude rules use `paths`;
putting Cursor's `alwaysApply` into Claude frontmatter does not preserve it.
VS Code scoped instructions use `applyTo`. Check target matching semantics rather
than assuming the three pattern syntaxes are interchangeable.

## Worked example: Cursor scoped rule to Claude Code

Source `.cursor/rules/python-tests.mdc` (project root is the pattern base):

```mdc
---
globs: "tests/**/*.py"
alwaysApply: false
---
Use pytest fixtures and do not add network calls to unit tests.
```

Candidate destination `.claude/rules/python-tests.md`:

```markdown
---
paths:
  - "tests/**/*.py"
---
Use pytest fixtures and do not add network calls to unit tests.
```

Keep `CLAUDE.md` unchanged for this scoped rule. Check at least
`tests/test_api.py` (match), `tests/unit/test_api.py` (match), and
`src/api.py` (non-match). Matching files does not prove equal trigger timing:
Cursor's contextual attachment and Claude's file-read activation are not identical.
Report the difference if the task depends on that timing. Parse the YAML: invalid
Claude frontmatter can cause the rule to load without the intended scope.

If source has `alwaysApply: true` plus `globs`, it is always-on. Do not convert
that to a scoped Claude rule. If it has neither globs nor description and is not
always-on, it is manually selected; do not omit frontmatter and make it always-on.

## Other target formats

For a verified VS Code Copilot/local target, the scoped example becomes
`.github/instructions/python-tests.instructions.md` with
`applyTo: "tests/**/*.py"`. Check description-based activation separately.
For Codex, `AGENTS.md` is directory-scoped, not a general glob container.
A `tests/AGENTS.md` can express all files in `tests/`, but not necessarily only
Python files: do not claim exact conversion for extension-specific patterns.
Keep a draft or ask whether the broader scope is acceptable.

For unconditional content, merge rather than replace existing root instructions.
Inspect existing `AGENTS.override.md`, nested instructions, local variants, and
imports first. Never introduce an override file merely to make the migration win.
On a second run, detect an already-migrated equivalent section and do not append it
again. One conflicting instruction must not suppress independent rules.

## Evidence

Consulted 2026-11-07; document-backed examples, not end-to-end client certification:
[Cursor rules](https://cursor.com/docs/rules),
[Claude memory and rule frontmatter](https://code.claude.com/docs/en/memory),
[VS Code instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions),
[Codex instructions](https://developers.openai.com/codex/guides/agents-md).

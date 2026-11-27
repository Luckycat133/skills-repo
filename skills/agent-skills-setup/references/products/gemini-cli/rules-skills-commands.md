# Gemini CLI: `GEMINI.md`, Skills & Custom TOML Commands

Parent: [gemini-cli.md](../gemini-cli.md)

## Context Files (`GEMINI.md`)

- Paths: Project `GEMINI.md` and User `~/.gemini/GEMINI.md` (supports configurable filenames and `@file.md` imports).
- No native glob-scoped rule directory (`rules/*.md` with path matchers): convert `model_selected` rules to on-demand Skills and park glob/manual rules via `agent_handoff` unless `--allow-broaden-scope`.

## Agent Skills & Agents

- **Skills**: Project `.gemini/skills/<name>/SKILL.md` (and `.agents/skills`), User `~/.gemini/skills/<name>/SKILL.md` (plus fallback `~/.agents/skills/<name>/SKILL.md` and extensions). Precedence (lowest -> highest): built-in < extension < user < workspace.
- **Custom Agents**: `.gemini/agents/*.md` and `~/.gemini/agents/*.md`.

## Custom Commands (`.toml`)

- Paths: `.gemini/commands/*.toml` and `~/.gemini/commands/*.toml`.
- TOML schema uses `description`, `prompt`, `{{args}}`, and `!{shell cmd}` shell injections — incompatible directly with Markdown `.md` command targets, so cross-IDE conversions require semantic adaptation (`agent_handoff`) while keeping `!{...}` blocks inactive.

Official sources: [GEMINI.md](https://geminicli.com/docs/cli/gemini-md/) · [skills](https://geminicli.com/docs/cli/skills/) · [custom commands](https://geminicli.com/docs/cli/custom-commands/)

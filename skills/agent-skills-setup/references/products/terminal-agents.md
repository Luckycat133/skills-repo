# Terminal agents and their native context

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## mistral-vibe

**Mistral Vibe Code and Vibe Work** · Evidence: `documented-subset` · Runtime: `not-run`.

Keep Vibe Code (CLI/IDE/web) distinct from Vibe Work. Vibe Code uses `~/.vibe/config.toml` and `.vibe/config.toml` (TOML `mcp_servers`, agents, skill paths), Skills in `.vibe/skills/<name>/SKILL.md`, `~/.vibe/skills`, and `.agents/skills`, plus agents, hooks, and plugins. Preserve `user-invocable` vs model-selected flags, check user-vs-plugin MCP shadowing, and exclude approval state.

Official sources: [1](https://docs.mistral.ai/vibe/code/overview) · [2](https://docs.mistral.ai/vibe/code/cli/configuration) · [3](https://docs.mistral.ai/vibe/code/cli/skills) · [4](https://docs.mistral.ai/vibe/code/cli/agents) · [5](https://docs.mistral.ai/vibe/code/cli/plugins)

## forge

**ForgeCode, not another Forge product** · Evidence: `version-sensitive` · Runtime: `not-run`.

Inventory `AGENTS.md`, `.forge/skills/<name>/SKILL.md`, commands, agents, MCP (`.mcp.json` / native MCP JSON via `patch-mcp`), and `.forge.toml` (not legacy `forge.yaml`). Official docs show conflicting global home examples (`~/forge` vs `~/.forge`): check `$FORGE_CONFIG` and active CLI output before writing, and record the chosen path in `MIGRATION.md`.

Official sources: [1](https://forgecode.dev/docs/skills/) · [2](https://forgecode.dev/docs/forge-config/) · [3](https://forgecode.dev/docs/zsh-support/) · [4](https://forgecode.dev/docs/permissions/)

## aider

**Aider** · Evidence: `documented-subset` · Runtime: `not-run`.

Aider does **not** auto-load `CONVENTIONS.md` or Agent Skills/MCP natively: convention files must be bound via `read: [CONVENTIONS.md]` in `.aider.conf.yml` / `~/.aider.conf.yml` (or `--read`). Migrate rules into a read-only convention Markdown file and add its `read:` entry surgically while excluding `.aider.chat.history.md`, `.aider.input.history`, caches, and API keys in `.aider.conf.yml` unless requested.

Official sources: [1](https://aider.chat/docs/usage/conventions.html) · [2](https://aider.chat/docs/config/aider_conf.html) · [3](https://aider.chat/docs/faq.html)

## pi

**Pi coding agent** · Evidence: `version-sensitive` · Runtime: `not-run`.

- **Candidate paths & schemas**: Native MCP `~/.pi/agent/mcp.json` and `.pi/mcp.json` (`mcpServers`; sparse project knob-only overrides such as `{"enabled": false}` inherit user server connection fields — **never** discard them as malformed!); Instructions `AGENTS.md`, `~/.pi/agent/AGENTS.md`; Skills `.pi/skills/<name>/SKILL.md`, `~/.pi/agent/skills/<name>/SKILL.md`, `.agents/skills` (`disable-model-invocation` supported); Prompts `.pi/prompts/*.md`, `~/.pi/agent/prompts/*.md`. Built-in profile: `pi`.
- **Cautions**: Keep TypeScript extensions/packages inactive during transfer and never copy project trust or OAuth tokens.

Official sources: [1](https://pi.dev/docs/latest/skills) · [2](https://pi.dev/docs/latest/mcp) · [3](https://pi.dev/docs/latest/extensions)

## crush

**Charm Crush** · Evidence: `documented-subset` · Runtime: `not-run`.

Inspect `crush.json` / `.crush.json` and `~/.config/crush/crush.json` (`mcp` server map with command arrays and env bindings — keep `lsp` servers, provider credentials, and UI prefs separate), context attachments (`AGENTS.md` / `CRUSH.md`), and Skills if enabled in the installed build. Patch only the MCP subobject out-of-band.

Official sources: [1](https://github.com/charmbracelet/crush)

## goose

**Goose CLI and Desktop** · Evidence: `documented-subset` · Runtime: `not-run`.

Follow canonical `goose-docs.ai` docs: instructions `.goosehints` / `~/.config/goose/.goosehints` (loaded via Developer extension), Skills (`.goose/skills`, `.agents/skills` via built-in Skills extension vs remote MCP Skills), structured YAML recipes (`recipes/*.yaml`), and `extensions:` in `~/.config/goose/config.yaml` (YAML map, **not** JSON `mcpServers`). Keep executable recipes/extensions inactive until approved and exclude session DBs.

Official sources: [1](https://goose-docs.ai/docs/getting-started/using-extensions/) · [2](https://goose-docs.ai/docs/guides/context-engineering/using-skills/) · [3](https://goose-docs.ai/docs/mcp/skills-mcp/) · [4](https://github.com/aaif-goose/goose)

# Continue and Zed

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## continue

**Continue IDE extension and cn CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: User YAML `~/.continue/config.yaml` (Windows `%USERPROFILE%\.continue\config.yaml`), project blocks `.continue/rules/*.md` (`globs`, `regex`, `alwaysApply`), `.continue/prompts/*.md`, and `.continue/mcpServers/*.yaml` (or `mcpServers:` list in `config.yaml`). Legacy `config.json` / `config.ts` are versioned inputs — never execute `config.ts` during inspection.
- **Cautions & check**: Context providers, MCP servers, and prompts are distinct; verify Continue Skill discovery in the installed `cn` / IDE version before placing `SKILL.md` folders. Edit YAML blocks surgically while keeping `${{ secrets.NAME }}` / env bindings intact and secrets out of LLM stdout.

Official sources: [1](https://docs.continue.dev/customize/deep-dives/configuration) · [2](https://docs.continue.dev/customize/deep-dives/mcp) · [3](https://docs.continue.dev/customize/deep-dives/rules) · [4](https://docs.continue.dev/customize/prompts)

## zed

**Zed native agent versus external ACP agent** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Native Skills `.agents/skills/<name>/SKILL.md`, `~/.agents/skills/<name>/SKILL.md`; Personal instructions `~/.config/zed/AGENTS.md` (Windows `%APPDATA%\Zed\AGENTS.md`); Project instructions `AGENTS.md` with **first-match** fallback across `.rules`, `.cursorrules`, `.windsurfrules`, `.clinerules`, `.github/copilot-instructions.md`, `AGENT.md`, `CLAUDE.md`, `GEMINI.md`; MCP **`context_servers`** subobject in `.zed/settings.json` and `~/.config/zed/settings.json` (JSONC; stdio uses `command: {"path", "args", "env"}`). Built-in profile: `zed`.
- **Cautions & check**: Warn if a higher-precedence legacy file shadows `AGENTS.md`. External ACP agents (Claude, Codex, Gemini, Devin) load their own host configs rather than Zed native rules. Preserve all non-`context_servers` Zed settings.

Official sources: [1](https://zed.dev/docs/ai/instructions) · [2](https://zed.dev/docs/ai/skills) · [3](https://zed.dev/docs/ai/mcp) · [4](https://zed.dev/docs/ai/external-agents)

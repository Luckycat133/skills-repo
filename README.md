# Agent Skills Setup

[中文](README.zh-CN.md) · [日本語](README.ja-JP.md) · [Español](README.es.md)

`agent-skills-setup` is a portable [Agent Skill](https://agentskills.io/specification)
for existing AI coding agents. It helps an agent migrate, convert, sync, or transfer
rules/instructions, Agent Skills, MCP server definitions, prompts, slash commands,
custom agents, hooks, workflows, authored memory, and API keys / `.env` secrets across
AI coding IDEs, CLIs, and computers — **without exposing raw secret values to LLM
prompt context**.

## Architecture & Zero-Context-Leak Design

- **Agent-First + Self-Contained Stdlib Helper**: Ships concise instructions
  (`SKILL.md`), progressive references (`references/`), templates (`assets/`), and a
  single zero-dependency Python 3.11+ stdlib script
  (`skills/agent-skills-setup/scripts/migrate_context.py` with PEP 723 metadata). No
  proprietary `.acb` archive engine, signing service, SQLite store, background sync
  daemon, auto-installer, or telemetry.
- **Out-of-Band `0700`/`0600` Secret Transfer**: By default, `migrate_context.py` moves
  API keys, MCP `env`/`headers`, and `.env*` files disk-to-disk in `0600` mode (`0700`
  private directories and backups), guards Git-tracked files against silent secret
  leaks, and prints **only** variable names, `has_secrets`, and 8-char SHA-256 prefixes
  (`sha256[:8]`) on `stdout`. Pass `--redact-secrets` whenever you want placeholders
  instead of copying keys.
- **90-Profile On-Demand Catalog**: Routes 15 built-in profiles (`cursor`,
  `claude-code`, `codex`, `vscode`, `copilot-cli`, `gemini-cli`, `antigravity`,
  `windsurf`, `cline`, `kilocode`, `zed`, `opencode`, `kimi-code`, `qwen-code`, `pi`)
  plus 75+ cataloged clients via `patch-mcp` and progressive `references/products/*.md`
  files (review date: 2026-11-07). Listing a product is documentation routing, **not**
  runtime certification.

## Install

Copy `skills/agent-skills-setup/` into your agent's documented Skills directory
(for example `.agents/skills/agent-skills-setup`, `.claude/skills/agent-skills-setup`,
or `.cursor/skills/agent-skills-setup`):

```bash
git clone https://github.com/Luckycat133/skills-repo.git
cp -R skills-repo/skills/agent-skills-setup /path/to/your-skills-dir/agent-skills-setup
```

Only `skills/agent-skills-setup/` is distributed to end users (`dev/`, `evals/`,
`docs/`, and `tests/` stay repository-only).

## Single-Sentence Usage Examples

Ask your host agent in natural language:

- *"Migrate all my Cursor rules, Skills, and MCP configs (including API keys) in this repo to Claude Code and Codex."*
- *"Migrate my Cursor MCP servers to VS Code, but redact all secrets into env placeholders."*
- *"I'm changing computers — export all my AI coding configs and keys into `~/context-transfer`."*
- *"Restore `~/context-transfer` onto this new computer."*

Or run the deterministic helper directly (`--dry-run` previews with zero writes):

```bash
python3 skills/agent-skills-setup/scripts/migrate_context.py inspect --workspace . --scope all
python3 skills/agent-skills-setup/scripts/migrate_context.py migrate --source cursor --target claude-code --workspace . --dry-run
python3 skills/agent-skills-setup/scripts/migrate_context.py export-device --output ~/context-transfer --profiles all
python3 skills/agent-skills-setup/scripts/migrate_context.py import-device --input ~/context-transfer --target same
```

## Validation & Current Status

```bash
bash validate-all.sh
```

See [docs/validation-status.md](docs/validation-status.md) for what has been verified
locally (unit, torture, canary zero-leak, end-to-end CLI workflows, `package_skill.py`,
and official `skills-ref validate`) versus pending live native-IDE runtime checks
(`evals/client-matrix.json`). Source version: `0.11.0`.

## License

[MIT](LICENSE)

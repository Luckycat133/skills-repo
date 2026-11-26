# aider

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Aider** · Evidence: `documented-subset` · Runtime: `not-run`.

Aider does **not** auto-load `CONVENTIONS.md` or Agent Skills/MCP natively: convention files must be bound via `read: [CONVENTIONS.md]` in `.aider.conf.yml` / `~/.aider.conf.yml` (or `--read`). Migrate rules into a read-only convention Markdown file and add its `read:` entry surgically while excluding `.aider.chat.history.md`, `.aider.input.history`, caches, and API keys in `.aider.conf.yml` unless requested.

Official sources: [1](https://aider.chat/docs/usage/conventions.html) · [2](https://aider.chat/docs/config/aider_conf.html) · [3](https://aider.chat/docs/faq.html)

# Editor hosts and concrete plugins

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## editor-hosts

**Emacs, Neovim and Helix editor** · Evidence: `host-only` · Runtime: `not-run`.

Editors do not define a built-in AI context schema (`helix` is Helix editor, not HelixML/HelixAgent; no `HELIX.md` contract exists). Identify the installed AI plugin or ACP client (`codecompanion-nvim`, `mcphub-nvim`, `avante`, `gptel`, etc.) before writing, and never evaluate untrusted `.el` / `.lua` files during inspection.

Official sources: [1](https://www.gnu.org/software/emacs/) · [2](https://neovim.io/doc/) · [3](https://docs.helix-editor.com/)

## codecompanion-nvim

**CodeCompanion.nvim** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & `.mdc` scope trap**: Supports rules (`AGENTS.md`, `CLAUDE.md`, configured rule groups), Skills (`.agents/skills/<name>/SKILL.md`), prompt library, workflows, HTTP/ACP adapters, and MCP. Adding `.cursor/rules/**/*.mdc` to an autoload rule group **ignores Cursor `globs`/`alwaysApply`**, silently making scoped rules unconditional — park or bind scoped rules explicitly, and never execute Lua callbacks during transfer.

Official sources: [1](https://codecompanion.olimorris.dev/guides/sharing-rules-and-skills) · [2](https://codecompanion.olimorris.dev/configuration/mcp) · [3](https://codecompanion.olimorris.dev/usage/skills)

## mcphub-nvim

**MCPHub.nvim** · Evidence: `documented-subset` · Runtime: `not-run`.

Manages MCP servers (`~/.config/mcphub/servers.json` and `.mcphub/servers.json` using JSON5/JSONC `mcpServers` + `nativeMCPServers`). Use `migrate_context.py patch-mcp --src-format jsonc` so `//` comments and trailing commas parse cleanly, strip `autoApprove` arrays, and keep Lua-defined `nativeMCPServers` unexecuted.

Official sources: [1](https://ravitemer.github.io/mcphub.nvim/configuration.html) · [2](https://ravitemer.github.io/mcphub.nvim/mcp/servers_json.html) · [3](https://github.com/ravitemer/mcphub.nvim)

## gptel

**gptel, mcp.el and gptel-agent** · Evidence: `documented-subset` · Runtime: `not-run`.

Keep the three Emacs packages distinct: `gptel` directives/presets/tools, `mcp.el` (`mcp-hub-servers` Lisp alist), and `gptel-agent` (`SKILL.md` / agent definitions). Inspect `.el` / Org declarations as inert text without `eval`, exclude `auth-source` credentials and saved chat buffers, and map presets field-by-field.

Official sources: [1](https://github.com/karthink/gptel) · [2](https://github.com/karthink/gptel-agent) · [3](https://github.com/lizqwerscott/mcp.el)

## avante

**Avante.nvim** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory `.avanterules` / custom `avante.md` templates, Lua prompt/tool configs, ACP settings, and MCPHub-owned `servers.json` when integrated with `mcphub.nvim` (do not invent a separate Avante Skill folder). Keep Lua config functions unexecuted during inspection.

Official sources: [1](https://github.com/avante-corp/avante.nvim) · [2](https://github.com/avante-corp/avante.nvim/wiki)

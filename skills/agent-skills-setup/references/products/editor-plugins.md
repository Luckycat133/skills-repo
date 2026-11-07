# Editor hosts and concrete plugins

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## editor-hosts

**Emacs, Neovim and Helix editor** · Evidence: `host-only` · Runtime: `not-run`.

These names identify editors, not a universal AI context schema. Select the actual plugin/ACP agent before mapping Skills, rules, MCP or memory. In particular, Helix editor is not HelixML, Tray Helix, HelixAgent or another similarly named AI platform; no native `HELIX.md`/`mcp_servers` contract is asserted here.

Inventory the installed package name/version, configuration language and effective runtime. Emacs Lisp and Neovim Lua can execute code while being loaded; do not evaluate imported configuration merely to inspect it. Preserve harmless declarations and park uncertain code.

Check the actual plugin's discovery/import view. The editor's own repository AGENTS.md is developer guidance for that repository, not evidence the editor loads user AGENTS files.

Official sources: [1](https://www.gnu.org/software/emacs/) · [2](https://neovim.io/doc/) · [3](https://docs.helix-editor.com/)

## codecompanion-nvim

**CodeCompanion.nvim** · Evidence: `documented-subset` · Runtime: `not-run`.

Current CodeCompanion supports rules, Skills, prompt library, slash commands, workflows, MCP, adapters (HTTP/ACP), extensions and callbacks. Its default rule group loads several compatibility files. Additional Cursor `.cursor/rules/**/*.mdc` files can be added, but **Cursor `globs`/`alwaysApply` are not interpreted**: an autoload group can make every rule unconditional.

Skill directories and duplicate precedence are documented separately from rules; preserve invocation and selected adapter. A custom directory such as `~/.config/codecompanion/rules` has no native meaning until configured. Lua configuration, callbacks and extensions are executable.

Check a scoped source rule is not widened by autoload; test both matching and nonmatching files. For ACP, verify which context the external agent actually receives. Do not transfer session buffers or tokens.

Official sources: [1](https://codecompanion.olimorris.dev/guides/sharing-rules-and-skills) · [2](https://codecompanion.olimorris.dev/configuration/mcp) · [3](https://codecompanion.olimorris.dev/usage/skills)

## mcphub-nvim

**MCPHub.nvim** · Evidence: `documented-subset` · Runtime: `not-run`.

MCPHub manages MCP servers and integrates with chat plugins; it is not itself a general Skills/rules agent. Inspect its selected `servers.json`/JSON5 path and project discovery (`.mcphub/servers.json`, supported VS Code/Cursor imports). Preserve native server definitions and imported origin.

Server maps, resources/prompts, native Lua servers, environment references and auto-approval UI metadata are distinct. JSON5 comments/trailing commas require a real parser; do not treat the filename as strict JSON. Do not transfer auto-approval fields.

Check the hub recognizes the selected configuration and that the consuming chat plugin exposes the intended tools. Starting a server or invoking a prompt that performs actions requires separate approval.

Official sources: [1](https://ravitemer.github.io/mcphub.nvim/configuration.html) · [2](https://ravitemer.github.io/mcphub.nvim/mcp/servers_json.html) · [3](https://github.com/ravitemer/mcphub.nvim)

## gptel

**gptel, mcp.el and gptel-agent** · Evidence: `documented-subset` · Runtime: `not-run`.

Separate the packages: gptel has directives/system prompts, presets, context attachments, tool definitions and buffer/Org-local settings; mcp.el adds MCP connectivity; gptel-agent adds its own agent/Skill conventions. None implies a universal Emacs MCP file.

Translate a selected preset's prompt, tools and model intent into the target's supported fields. Function-valued directives, Lisp tools and package hooks are executable. User-authored Org instructions can be portable, but conversation buffers and saved chats are not default context exports.

Check variable values/configuration without evaluating untrusted Lisp. Verify the intended preset/agent sees its Skill and tools. Keep auth-source/keychain tokens and Emacs session state separate.

Official sources: [1](https://github.com/karthink/gptel) · [2](https://github.com/karthink/gptel-agent) · [3](https://github.com/lizqwerscott/mcp.el)

## avante

**Avante.nvim** · Evidence: `documented-subset` · Runtime: `not-run`.

Avante uses Lua configuration, system prompts and project rule/template mechanisms such as `.avanterules` or mode-specific templates; inspect the installed version and overrides. MCP can be supplied through MCPHub.nvim, whose server configuration remains owned by MCPHub.

Inventory prompts/rules, tool/provider declarations, ACP/integration settings if present and explicitly selected memory/context files. Do not claim a generic Agent Skills directory solely from a neighboring plugin. Preserve template substitution and mode binding.

Check native prompt loading and MCPHub-to-Avante tool exposure independently. Imported Lua/config functions and prompt shell content must not execute during inspection.

Official sources: [1](https://github.com/avante-corp/avante.nvim) · [2](https://github.com/avante-corp/avante.nvim/wiki)

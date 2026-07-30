# neovim

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | Not mapped |
| Project skills | Not mapped |
| Rules | Not mapped |
| MCP | Not mapped |
| Project MCP | Not mapped |
| Project config | Not mapped |
| Config | `~/.config/nvim/init.lua` |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.config/nvim/` is the documented Unix user config directory (the effective path is XDG/NVIM_APPNAME-dependent)
- **config**: `~/.config/nvim/init.lua` (or `init.vim`) is Neovim editor configuration; `init.lua` and `init.vim` cannot both be used as the startup config
- **skills / rules / prompts / MCP / project config**: unsupported by core Neovim and intentionally empty in `ide-paths.json`; plugin-specific AI integrations are separate products and are not treated as native Neovim mappings
- **automatic migration**: config path is diagnostic-only. The generic mapper fails closed for any migration involving Neovim because it cannot safely convert another IDE's schema into Lua or replace an existing Neovim config without manual review
- **sources**: [Neovim startup and standard paths](https://neovim.io/doc/user/starting/), [Neovim Lua guide](https://neovim.io/doc/user/lua-guide/), [Neovim Nvim introduction](https://neovim.io/doc/user/nvim/)

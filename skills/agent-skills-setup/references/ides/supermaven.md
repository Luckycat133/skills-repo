# supermaven

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
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **official evidence**: [Supermaven Download](https://supermaven.com/download) lists JetBrains, VS Code, and Neovim host integrations; the [official supermaven-nvim README](https://github.com/supermaven-inc/supermaven-nvim#readme) configures the plugin through Neovim's `setup()` call and reports logs under Neovim's `stdpath("cache")`. The [official maintainer issue](https://github.com/supermaven-inc/supermaven-nvim/issues/85) describes `~/.supermaven` as the `sm-agent` runtime/binary location and `.supermavenignore` as an indexing-exclusion file.
- **automatic paths**: none documented. Do not treat `~/.supermaven` as a global Skills/config directory, `.supermaven` as a project namespace, or `.supermavenignore` as instruction rules.
- **skills/rules/prompts/MCP/config/project**: manual/host-editor only; no portable Supermaven-owned file schema is published by the first-party sources above.
- **evidence gap**: Supermaven's official web and host-plugin documentation do not publish a portable per-OS Skills, rules, MCP, prompt, or standalone config path/schema. The mapper therefore leaves every automatic object unsupported and fails closed.

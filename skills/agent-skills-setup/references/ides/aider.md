# aider

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | Not mapped |
| Project skills | Not mapped |
| Rules | `CONVENTIONS.md` |
| MCP | Not mapped |
| Project MCP | Not mapped |
| Project config | Not mapped |
| Config | `~/.aider.conf.yml` |

<!-- END GENERATED: ide-paths.json summary -->
- **config**: `~/.aider.conf.yml` in the home directory, plus `.aider.conf.yml` in the git repository root or current directory; later-loaded files override earlier ones. An explicit file may be selected with `--config <filename>`.
- **rules/context**: `CONVENTIONS.md` is an ordinary read-only file; load it with `aider --read CONVENTIONS.md` or set `read: CONVENTIONS.md` in `.aider.conf.yml`.
- **global/environment config**: `.env` is searched in home, git root, and current directory; shell/environment configuration uses `AIDER_*` variables. CLI flags and `--env-file <filename>` are also supported. These are configuration mechanisms, not portable skills or prompt stores.
- **skills/prompts/commands**: no official Aider Skills directory or standalone prompt directory is documented. `/load <file>` loads commands from a user-selected file; no fixed `.aider.commands.md` path is claimed.
- **mcp/tools**: no native Aider MCP client/configuration is documented in the official configuration or command references; MCP migration is unsupported/manual.
- **automatic boundary**: only the path to `.aider.conf.yml` and `CONVENTIONS.md` is exposed for diagnostics. YAML/YML config, `.env`, environment variables, CLI flags, and `/load` command files require manual review; this mapper must not copy or rewrite another IDE's schema into Aider's YAML.
- **sources**: [configuration](https://aider.chat/docs/config.html), [YAML config file](https://aider.chat/docs/config/aider_conf.html), [environment/.env config](https://aider.chat/docs/config/dotenv.html), [coding conventions](https://aider.chat/docs/usage/conventions.html), [in-chat commands](https://aider.chat/docs/usage/commands.html), [options reference](https://aider.chat/docs/config/options.html)

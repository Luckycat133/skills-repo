# gemini-cli

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.gemini/skills` |
| Project skills | `.gemini/skills` |
| Rules | `GEMINI.md` |
| MCP | `~/.gemini/settings.json` |
| Project MCP | `.gemini/settings.json` |
| Project config | `.gemini/settings.json` |
| Config | `~/.gemini/settings.json` |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.gemini/` is the user configuration namespace; this mapper does not infer an installation path from it.
- **settings / config**: user `~/.gemini/settings.json` · project `.gemini/settings.json` · JSON settings schema · project settings override user settings. The mapper exposes the user file as `config`, and the project file as `project-config`/`project-mcp` diagnostics; it does not copy a whole `.gemini` namespace or choose a project scope automatically.
- **mcp**: user `~/.gemini/settings.json` · project `.gemini/settings.json` · root key `mcpServers` · JSON. Each server must provide at least one documented endpoint: `command` (stdio), `url` (SSE), or `httpUrl` (Streamable HTTP); optional documented fields include `args`, `headers`, `env`, `cwd`, `timeout`, `trust`, `includeTools`, and `excludeTools`. The generic mapper converts only the user file and validates the target shape; project MCP remains manual because the workflow has no scope selector.
- **rules**: global `~/.gemini/GEMINI.md` plus project/ancestor `GEMINI.md` files; the filename can be changed with `context.fileName`. The mapper's `rules` path is the repository-root `GEMINI.md`; global context and alternate filenames require manual review.
- **skills**: global `~/.gemini/skills/<name>/SKILL.md` (or the documented `~/.agents/skills/` alias) · project `.gemini/skills/<name>/SKILL.md` (or `.agents/skills/` alias). The mapper uses the canonical `.gemini/skills` paths for this target.
- **commands**: global `~/.gemini/commands/*.toml` · project `.gemini/commands/*.toml` · TOML with required `prompt` and optional `description`; `{{args}}`, `!{...}`, and namespaced subdirectories are documented. The generic prompts copier is Markdown-only, so Gemini commands are manual rather than copied as prompts.
- **agents**: global `~/.gemini/agents/*.md` · project `.gemini/agents/*.md`; YAML frontmatter requires `name` and `description`. The generic mapper has no agents object and leaves these files manual.
- **memory**: `/memory show`/`/memory add` manage hierarchical `GEMINI.md` context and private memory; memory state is not a portable automatic migration object.
- **note**: Official docs warn against underscores in MCP server aliases because policy FQN parsing can misidentify the server. The converter rejects aliases containing `_` and requires manual renaming plus review of allowlists/policies; it does not silently rewrite names.
- **sources**: [configuration](https://geminicli.com/docs/reference/configuration) · [MCP servers](https://geminicli.com/docs/tools/mcp-server/) · [Agent Skills](https://geminicli.com/docs/cli/using-agent-skills/) · [creating skills](https://geminicli.com/docs/cli/creating-skills/) · [GEMINI.md context](https://geminicli.com/docs/cli/gemini-md/) · [custom commands](https://geminicli.com/docs/cli/custom-commands/) · [subagents](https://geminicli.com/docs/core/subagents/)

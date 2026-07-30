# kimi-code (Moonshot AI)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.kimi-code/skills` |
| Project skills | `.kimi-code/skills` |
| Rules | `AGENTS.md` |
| MCP | `~/.kimi-code/mcp.json` |
| Project MCP | `.kimi-code/mcp.json` |
| Project config | Not mapped |
| Config | `~/.kimi-code/config.toml` |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.kimi-code/` (env var `KIMI_CODE_HOME` overrides; legacy kimi-cli used `~/.kimi/` with `KIMI_SHARE_DIR`)
- **mcp**: global `~/.kimi-code/mcp.json` · project `<cwd>/.kimi-code/mcp.json` · root_key `mcpServers` · JSON · stdio+HTTP+SSE · `kimi mcp list`
- **rules**: global `~/.kimi-code/AGENTS.md` · project `AGENTS.md` (also `.kimi-code/AGENTS.md`, any subdir) · `/init` auto-generates
- **skills**: global `~/.kimi-code/skills/` / `~/.agents/skills/` · project `.kimi-code/skills/` / `.agents/skills/` · extra dirs via `config.toml extra_skill_dirs`
- **commands**: built-in slash commands (`/mcp`, `/init`, `/skill:<name>`, `/hooks`, `/config`) · plugin commands (`<plugin>:<cmd>`) · NO standalone commands dir
- **agents**: current custom agents are recursively discovered Markdown files in `$KIMI_CODE_HOME/agents/` (default `~/.kimi-code/agents/`) and project `.kimi-code/agents/` / `.agents/agents/`; generic user `~/.agents/agents/` also remains supported. Frontmatter requires `description` and may include `name`, `whenToUse`, `override`, `model_preference`, `tools`, `disallowedTools`, and `subagents`. Explicit `--agent-file` Markdown has highest priority; older YAML/`system_prompt_path` agent-file formats are legacy and manual.
- **hooks**: `~/.kimi-code/config.toml` `[[hooks]]` array · 13 events (PreToolUse, PostToolUse, PostToolUseFailure, UserPromptSubmit, Stop, StopFailure, SessionStart, SessionEnd, SubagentStart, SubagentStop, PreCompact, PostCompact, Notification) · blocking: PreToolUse, Stop, UserPromptSubmit
- **memory**: no native memory · sessions at `~/.kimi-code/sessions/<workDirKey>/<id>/` (context.jsonl, wire.jsonl, state.json) · plans at `~/.kimi-code/plans/<slug>.md`
- **other**: `~/.kimi-code/config.toml` (main config, TOML NOT JSON) · `~/.kimi-code/tui.toml` · `~/.kimi-code/credentials/` · `~/.kimi-code/mcp-oauth/`
- **note**: Path is `~/.kimi-code/` NOT `~/.kimi/`; config is `config.toml` NOT `config.json`; legacy kimi-cli deprecated

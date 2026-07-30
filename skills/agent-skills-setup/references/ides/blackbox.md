# blackbox (Blackbox AI)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | Not mapped |
| Project skills | `.blackbox/skills` |
| Rules | Not mapped |
| MCP | Not mapped |
| Project MCP | Not mapped |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **scope**: This mapper token covers the Blackbox CLI/project Skills surface. The standalone AI-Native IDE and VS Code Agent docs describe editor/UI features but do not publish a portable local configuration layout.
- **detect**: project `.blackbox/` only (the parent namespace shown by the official Skills examples); no global detection path is claimed
- **project skills**: `.blackbox/skills/<name>/SKILL.md` · JSON path value `.blackbox/skills` · the official `/skill` guide says Skills are stored there, auto-discovered, and the generated `SKILL.md` uses YAML frontmatter with `name` and `description`
- **global skills**: unsupported/empty; current first-party docs do not publish a user-global Skills directory
- **rules / prompts**: unsupported/empty; `/skill` is an in-session command, not a portable prompt or rules directory
- **MCP**: unsupported/empty; `blackbox mcp` is documented as running bundled MCP servers, not as reading a portable user/project MCP file or a published server-map root/schema
- **config**: unsupported/empty; `blackbox configure` is interactive, but current first-party docs do not publish its storage path or schema
- **automatic migration boundary**: `.blackbox/skills/` is exposed for diagnosis, but the generic `skills` operation only migrates global directories and has no project-scope selector. Review/copy the project Skills subtree manually. Never infer `~/.blackbox`, `.blackbox/mcp.json`, `.blackbox/rules`, or copy the whole `.blackbox` namespace as opaque configuration.
- **sources**: [Skills Management](https://docs.blackbox.ai/features/blackbox-cli/skills), [Commands reference](https://docs.blackbox.ai/features/blackbox-cli/commands-reference), [CLI getting started](https://docs.blackbox.ai/features/blackbox-cli/getting-started), [VS Code Agent key features](https://docs.blackbox.ai/features/vscode-agent/key-features), [AI-Native IDE](https://www.blackbox.ai/ide)

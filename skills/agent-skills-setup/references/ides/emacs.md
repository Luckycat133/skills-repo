# emacs (GNU Emacs)

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
- **detect**: no AI-assistant configuration directory claimed by native GNU Emacs
- **native configuration**: initialization file is selected from `~/.emacs.el`, `~/.emacs`, `~/.emacs.d/init.el`, or the XDG-compatible `~/.config/emacs/init.el`; `.dir-locals.el` provides per-directory Emacs Lisp variables
- **skills / rules / mcp / project config**: unsupported by native GNU Emacs; the mapper leaves these paths empty
- **config**: unsupported for automatic migration. Init files and `.dir-locals.el` are Emacs Lisp with user-selected locations and semantics; review and adapt them manually rather than copying another IDE's config
- **third-party boundary**: packages such as `gptel` and `mcp.el` can add AI/MCP features, but their package-specific paths and schemas are not native Emacs mappings and are outside this registry's automatic migration
- **sources**: [The Emacs Initialization File](https://www.gnu.org/software/emacs/manual/html_node/emacs/Init-File.html), [How Emacs Finds Your Init File](https://www.gnu.org/software/emacs/manual/html_node/emacs/Find-Init.html), [Per-Directory Local Variables](https://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html)

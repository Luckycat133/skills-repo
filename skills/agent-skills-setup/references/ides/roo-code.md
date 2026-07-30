# roo-code (archived 2026-05)

<!-- GENERATED: ide-paths.json summary; do not edit this block -->

## Generated path summary

This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.
Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.

| Object | Documented path |
| --- | --- |
| Global skills | `~/.roo/skills` |
| Project skills | `.roo/skills` |
| Rules | `.roorules` |
| MCP | Not mapped |
| Project MCP | `.roo/mcp.json` |
| Project config | Not mapped |
| Config | Not mapped |

<!-- END GENERATED: ide-paths.json summary -->
- **detect**: `~/.roo/`
- **mcp**: project `.roo/mcp.json` is a documented JSON file with root key `mcpServers` and is convertible only with explicit project scope; global MCP is stored in Roo's extension settings directory, but Roo's official docs do not publish a stable literal filesystem path, so global `mcp` remains UI/manual. No VS Code/Cline `globalStorage` path is inferred.
- **rules**: project `.roorules` is the single-file compatibility target used by this mapper; Roo also loads the scoped collections `.roo/rules/*.md`, `.roo/rules-{mode}/`, and global `~/.roo/rules/`, which require manual review because the converter only copies one file and cannot preserve scope/mode activation.
- **skills**: project `.roo/skills/<name>/SKILL.md` and global `~/.roo/skills/<name>/SKILL.md`; `.agents/skills/` is a separate cross-agent compatibility location. The mapper's skills operation uses the Roo-specific directories.
- **commands**: project `.roo/commands/*.md` (documented; exposed through the mapper's `prompts` object with a manual semantic review).
- **modes**: project `.roomodes` and global `custom_modes.yaml`/`custom_modes.json`; these are YAML-or-JSON mode collections with per-mode tool permissions, but no automatic mode converter exists here, so migration is manual.
- **project namespace**: `.roo/` mixes skills, scoped rules, commands, MCP, modes, and other state; whole-directory project migration is manual/unsupported in this mapper.
- **memory**: `memory-bank/*.md` (community methodology, inherited from Cline; not an automatic mapper object).
- **note**: Roo Code was shut down on 2026-05-15 and the upstream repository was archived the same day (read-only). The README mentions two possible replacements: **ZooCode** (described as "a fork started by the Roo Code community") and **Cline** (the project from which Roo Code originated). **Note on ZooCode**: as of 2026-07-28 verification no live ZooCode project repo, VS Code marketplace listing, or independent community presence was found via web search; the repository referenced by the Roo Code README appears not to exist or has never been published, so the Roo Code team's claim of "ZooCode is a viable replacement" is itself a stale or speculative recommendation. Treat **Cline** as the only verified Roo Code replacement. Do not interpret this as a "Migrate to Kilo Code" recommendation: Kilo Code's current README describes itself as a fork of OpenCode (earliest release v1.0.25 dates to 2026-02; release notes show no Roo Code fork origin) and Chinese-language community write-ups only describe Kilo Code as having "integrated core features of Cline and Roo Code," not a fork chain. Always review `.roo/` modes, scoped rules, custom slash commands, and the extension-managed global MCP manually because none of them have a stable cross-IDE schema.
- **sources**: [Roo Code announcement](https://roocodeinc.github.io/Roo-Code/), [Roo Code Skills](https://roocodeinc.github.io/Roo-Code/features/skills/), [Custom Instructions](https://roocodeinc.github.io/Roo-Code/features/custom-instructions/), [Customizing Modes](https://roocodeinc.github.io/Roo-Code/features/custom-modes/), [Slash Commands](https://roocodeinc.github.io/Roo-Code/features/slash-commands/), [MCP](https://roocodeinc.github.io/Roo-Code/features/mcp/using-mcp-in-roo/), [Roo Code repository archive](https://github.com/RooCodeInc/Roo-Code)

---

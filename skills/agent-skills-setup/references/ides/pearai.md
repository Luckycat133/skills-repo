# pearai

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
- **official evidence**: [PearAI app repository](https://github.com/trypear/pearai-app) documents PearAI as a VS Code fork; [PearAI submodule repository](https://github.com/trypear/pearai-submodule) documents the bundled AI extension as a Continue fork.
- **automatic paths**: none documented by PearAI. Do not infer `~/.pearai`, `.pearai`, `.pearairules`, or any VS Code/Continue path as a PearAI contract.
- **mcp**: manual/UI/extension-managed only; PearAI's official repositories do not publish a portable MCP file, root key, or server schema.
- **rules/skills/prompts/config**: manual only; no PearAI-owned portable paths or file schemas are documented in the official repositories.
- **evidence gap**: the repositories establish provenance (VS Code + Continue forks), not PearAI storage paths or configuration schemas. The mapper therefore fails closed rather than treating PearAI as VS Code, Cursor, or Continue.

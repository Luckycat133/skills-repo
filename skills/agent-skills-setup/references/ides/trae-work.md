# trae-work (separate product; not a supported mapper target)
- TRAE Work is a separate Web/Desktop/Mobile product with Work/Code/Design modes; it has no `SUPPORTED_IDES` key in this script.
- Do not reuse TRAE IDE/CN `.trae` paths or schemas for Work. Its cloud/runtime state, rules, MCP, commands, hooks, memory, and Subagents require product-specific documentation and manual review.
- Never copy the whole `.trae` namespace between TRAE products. If a future Work document establishes a file-backed object, add it as a separate mapping only after official path/schema evidence is available.

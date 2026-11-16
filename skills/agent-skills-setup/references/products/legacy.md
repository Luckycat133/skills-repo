# Legacy and uncertain product lifecycles

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## void-editor

**Void editor archived upstream** · Evidence: `legacy-source` · Runtime: `not-run`.

`voideditor/void` archived 2026-06-02; read `.voidrules` and local Void MCP/prompt settings as a version-pinned **source** only (unless a maintained fork is specified), keep existing user files intact, and never copy Void's VS Code `state.vscdb` / app-data directories.

Official sources: [1](https://github.com/voideditor/void)

## supermaven

**Supermaven sunset service** · Evidence: `legacy-source` · Runtime: `not-run`.

Per the 2025-11-21 sunset notice, Supermaven agent chat ended while free autocomplete remained active for existing users. Extract only user-authored custom prompts/notes to a modern target; never invent Supermaven Skill/MCP/hook paths or copy login state.

Official sources: [1](https://supermaven.com/blog/sunsetting-supermaven)

## pearai

**PearAI VS Code/Continue-derived editor** · Evidence: `discovery-required` · Runtime: `not-run`.

PearAI forks VS Code with a Continue-derived submodule (do **not** label archived without evidence, and do **not** assume parity with current `~/.continue/config.yaml` or native Skills). Inspect `~/.pearai/` / workspace schema on the installed build, extract reviewed prompts/rules/MCP to the chosen target, and exclude app caches/chat DBs.

Official sources: [1](https://github.com/trypear/pearai-app) · [2](https://github.com/trypear/pearai-submodule)

# Legacy and uncertain product lifecycles

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## void-editor

**Void editor archived upstream** · Evidence: `legacy-source` · Runtime: `not-run`.

The official repository is archived as of 2026-06-02. Inspect the installed build's rules/MCP/settings only as a version-pinned source, or a separately identified maintained fork.

Export selected authored rules/prompts and server definitions. Do not use generic VS Code storage assumptions to copy the application-data tree. Recreate target configuration from the actual destination's current schema; keep private state and credentials out.

Check source format locally because current upstream support cannot be assumed. A read-only upstream does not mean the user's existing files should be deleted.

Official sources: [1](https://github.com/voideditor/void)

## supermaven

**Supermaven sunset service** · Evidence: `legacy-source` · Runtime: `not-run`.

The official 2025-11-21 announcement sunsets the product and agent conversations, but says free autocomplete continues for existing customers. Do not inaccurately claim every function shut down on that day.

Inventory only user-selected authored prompts/configuration that still exists. Autocomplete model state and subscription/login data are not portable context. Treat migration as extraction to a supported agent, not creation of a new Supermaven agent target.

Check the actual plugin build and selected content. Do not fabricate Skills, hooks, MCP or instruction contracts for a retired conversation feature.

Official sources: [1](https://supermaven.com/blog/sunsetting-supermaven)

## pearai

**PearAI VS Code/Continue-derived editor** · Evidence: `discovery-required` · Runtime: `not-run`.

The official repository identifies a VS Code fork with a Continue-derived submodule. That inheritance does not prove compatibility with today's Continue configuration. This review does not label the repository archived without evidence.

Record the installed build and submodule version; inventory its actual authored prompts/rules, MCP/provider settings and context attachments. Use the bundled schema/configuration view. Keep update/account state, caches and histories out.

Prefer reviewed extraction into a current target. If the user explicitly retains PearAI, validate the file contract in that exact build before writing; do not substitute current Continue YAML or invent a PearAI Skill root.

Official sources: [1](https://github.com/trypear/pearai-app) · [2](https://github.com/trypear/pearai-submodule)

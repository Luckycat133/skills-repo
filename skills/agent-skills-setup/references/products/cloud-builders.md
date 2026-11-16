# Cloud and application builders

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## replit

**Replit Agent** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory Agent Skills (`.agents/skills/<name>/SKILL.md`), `replit.md` (filter authored instructions from noisy historical state), project knowledge, and cloud MCP integrations. Keep `.replit` / `replit.nix` runtime configs, Replit Secrets (unless exporting reviewed `.env` out-of-band), deployments, and chat history separate.

Official sources: [1](https://docs.replit.com/replitai/skills) · [2](https://docs.replit.com/features/project-setup/replit-dot-md) · [3](https://docs.replit.com/replitai/agent)

## bolt-new

**Bolt.new / StackBlitz** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory `.bolt/prompt` / project knowledge instructions, design assets, and UI connectors/MCP (never invent a local `.bolt/mcp.json` file). Transfer reviewed instructions via Git/project settings, reauthorize connectors on the destination, and exclude deployment secrets and chat history.

Official sources: [1](https://support.bolt.new/building/using-bolt/project-settings) · [2](https://bolt.new/blog/introducing-connectors)

## v0

**v0 projects, Skills and API** · Evidence: `documented-subset` · Runtime: `not-run`.

Distinguish team/user/project custom instructions, Skills (slash-invocable & design-system Skills), and v0 as an MCP client vs v0's outbound MCP/API server. Transfer reviewed instructions and Skill packages via documented UI/API (API mutations require explicit authorization) without copying cloud env secrets or chat threads.

Official sources: [1](https://v0.app/docs/faqs) · [2](https://v0.app/changelog) · [3](https://v0.app/docs/api/v2/guides/design-systems) · [4](https://v0.app/docs/MCP) · [5](https://v0.app/docs/api/v2/guides/mcp-server)

## lovable

**Lovable workspace/project instructions and Skills** · Evidence: `documented-subset` · Runtime: `not-run`.

Keep **workspace-level** and **project-level** Instructions (formerly Knowledge) separate so a project migration never overwrites team-wide defaults. Import reviewed Skills + resources via supported GitHub/archive flows, distinguish Lovable's own MCP server from in-chat MCP connectors, reauthorize connectors, and exclude chat history/Supabase keys.

Official sources: [1](https://docs.lovable.dev/features/knowledge) · [2](https://docs.lovable.dev/features/skills) · [3](https://lovable.dev/mcp)

## monkeycode

**Chaitin MonkeyCode platform** · Evidence: `documented-subset` · Runtime: `not-run`.

MonkeyCode is a cloud/self-hosted coding agent platform that orchestrates underlying coding harnesses in remote workspaces. Identify both MonkeyCode's UI/API objects (Skills, Specs, MCP integrations, agent resources) and the underlying workspace harness before mapping instruction files; exclude server admin configs, model keys, and task DBs.

Official sources: [1](https://github.com/chaitin/MonkeyCode/blob/main/frontend/doc.md) · [2](https://monkeycode.docs.baizhi.cloud/node/019ea688-4dc6-78ee-bcec-21a97baf0734) · [3](https://www.monkeycode.docs.baizhi.cloud/landing/monkeycode)

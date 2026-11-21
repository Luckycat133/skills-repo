# Google IDEs and cloud development

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## android-studio

**Gemini in Android Studio** · Evidence: `documented-subset` · Runtime: `not-run`.

Separate bundled Gemini in Android Studio from Gemini CLI and generic Code Assist. Inventory `AGENTS.md` files, Agent Skills (`SKILL.md` on current releases; verify Studio build before assuming legacy experimental Skill schemas), saved UI prompts/rules, and MCP/device bindings. Keep emulator/device permissions, signing keys, and IDE indexes out of transfers; verify discovery in a fresh session without running builds or device actions unapproved.

Official sources: [1](https://developer.android.com/studio/gemini/skills) · [2](https://developer.android.com/studio/gemini/agent-files) · [3](https://developer.android.com/studio/gemini/features)

## antigravity

**Antigravity IDE, App and CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Keep IDE, App, and CLI distinct. Project Skills `.agents/skills/<name>/SKILL.md` (legacy `.agent/skills`); User Skills `$ANTIGRAVITY_SKILLS_DIR` or `~/.gemini/antigravity/skills` (legacy `~/.gemini/config/skills`); Rules `.agents/rules/*.md`, `GEMINI.md` / `~/.gemini/GEMINI.md`; Workflows `.agents/workflows/*.md` (legacy `.agent/workflows`); Hooks `.agents/hooks.json`, `~/.gemini/config/hooks.json`; MCP `~/.gemini/antigravity/mcp_config.json` (legacy `~/.gemini/config/mcp_config.json`) and `.agents/mcp_config.json` (`mcpServers` root key; remote HTTP uses `serverUrl`). Built-in profile: `antigravity`.
- **Cautions & check**: Workflow-to-Skill migration applies to Antigravity App 2.12+ on-demand workflows (`disable-model-invocation` / slash arguments preserved), never persistent rules. Keep imported hooks/scripts parked until approved.

Official sources: [1](https://antigravity.google/docs/skills) · [2](https://antigravity.google/docs/customization-discovery) · [3](https://antigravity.google/docs/migration/workflows-to-skills) · [4](https://antigravity.google/changelog)

## firebase-studio

**Firebase Studio / former IDX** · Evidence: `documented-subset` · Runtime: `not-run`.

Shutdown is scheduled for **2027-03-22** (future as of review); treat existing workspaces as active exportable sources. Inventory authored AI rules/instructions and `.idx/mcp.json` (`mcpServers`; patch out-of-band with `patch-mcp`), rebinding local stdio paths for the new host while keeping `.idx/dev.nix` environment setup, cloud tokens, and indexes separate.

Official sources: [1](https://firebase.google.com/docs/studio/mcp-servers) · [2](https://firebase.google.com/docs/studio/migrating-project)

## jules

**Google Jules cloud, Tools CLI and API** · Evidence: `documented-subset` · Runtime: `not-run`.

Jules consumes repository instructions (`AGENTS.md` / `README.md`) and cloud environment setup scripts; Tools CLI/API orchestrate cloud jobs rather than local Skill/MCP folders. Migrate authored repo instructions, review setup scripts and required secret names without executing commands or copying VM snapshots/transcripts, and keep scheduled tasks unregistered until approved.

Official sources: [1](https://jules.google/docs/environment/) · [2](https://jules.google/docs/cli/) · [3](https://jules.google/docs/scheduled-tasks/)

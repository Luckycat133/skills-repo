# Google IDEs and cloud development

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## android-studio

**Gemini in Android Studio** · Evidence: `documented-subset` · Runtime: `not-run`.

Separate bundled Gemini in Android Studio from Gemini CLI and generic Code Assist. Inventory `AGENTS.md` files, Agent Skills (`SKILL.md` on current releases; verify Studio build before assuming legacy experimental Skill schemas), saved UI prompts/rules, and MCP/device bindings. Keep emulator/device permissions, signing keys, and IDE indexes out of transfers; verify discovery in a fresh session without running builds or device actions unapproved.

Official sources: [1](https://developer.android.com/studio/gemini/skills) · [2](https://developer.android.com/studio/gemini/agent-files) · [3](https://developer.android.com/studio/gemini/features)

## antigravity

**Antigravity IDE, App and CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

- **Candidate paths & schemas**: Workspace `.agents/` (legacy `.agent/`, `_agents/`, `_agent/`) and global `~/.gemini/config/` share the same layout: Instructions `AGENTS.md` / `GEMINI.md` / `~/.gemini/config/AGENTS.md` (legacy `~/.gemini/AGENTS.md`, `~/.gemini/GEMINI.md`); Rules `.agents/rules/*.md`, `~/.gemini/config/rules/*.md` (requires YAML `trigger: always_on | glob | model_decision | manual` + `description` / `globs`); Skills `.agents/skills/<name>/SKILL.md`, `$ANTIGRAVITY_SKILLS_DIR` or `~/.gemini/config/skills/<name>/SKILL.md` (legacy `~/.gemini/antigravity/skills`, CLI `~/.gemini/antigravity-cli/skills` & `~/.gemini/skills`); Custom agents `.agents/agents/<name>.md` (or `<name>/agent.md`), `~/.gemini/config/agents/`; Plugins `.agents/plugins/<name>/`, `~/.gemini/config/plugins/<name>/` + `config.json` `plugins`; Discovery manifests `{skills,rules,agents,plugins}.json`; Workflows `.agents/workflows/*.md`, `~/.gemini/config/workflows/*.md` (legacy `.agent/workflows`); Hooks `.agents/hooks.json`, `~/.gemini/config/hooks.json`; Helper scripts `~/.gemini/config/scripts/`; Sidecars `~/.gemini/config/sidecars/`; Portable settings `config.json` `userSettings`, `~/.gemini/antigravity-cli/{settings,keybindings}.json`; MCP `.agents/mcp_config.json`, `~/.gemini/config/mcp_config.json` (legacy `~/.gemini/antigravity/mcp_config.json`; `mcpServers` root key, `serverUrl` for Streamable HTTP, `timeoutSeconds`, `enabledTools`/`disabledTools`, no legacy SSE). Built-in profile: `antigravity` (`anti`/`agy`).
- **Cautions & check**: Exclude `~/.gemini/antigravity/{conversations,brain}`, sqlite DBs, `.subagent_sessions/`, `jetski-standalone-oauth-token`, and permission/sandbox grants. Workflow-to-Skill migration applies to Antigravity App 2.12+ on-demand workflows (`disable-model-invocation` preserved), never persistent rules. Keep hooks/sidecars parked until `--activate-hooks` is approved.

Official sources: [1](https://antigravity.google/docs/skills) · [2](https://antigravity.google/docs/customization-discovery) · [3](https://antigravity.google/docs/migration/workflows-to-skills) · [4](https://antigravity.google/changelog)

## firebase-studio

**Firebase Studio / former IDX** · Evidence: `documented-subset` · Runtime: `not-run`.

Shutdown is scheduled for **2027-03-22** (future as of review); treat existing workspaces as active exportable sources. Inventory authored AI rules/instructions and `.idx/mcp.json` (`mcpServers`; patch out-of-band with `patch-mcp`), rebinding local stdio paths for the new host while keeping `.idx/dev.nix` environment setup, cloud tokens, and indexes separate.

Official sources: [1](https://firebase.google.com/docs/studio/mcp-servers) · [2](https://firebase.google.com/docs/studio/migrating-project)

## jules

**Google Jules cloud, Tools CLI and API** · Evidence: `documented-subset` · Runtime: `not-run`.

Jules consumes repository instructions (`AGENTS.md` / `README.md`) and cloud environment setup scripts; Tools CLI/API orchestrate cloud jobs rather than local Skill/MCP folders. Migrate authored repo instructions, review setup scripts and required secret names without executing commands or copying VM snapshots/transcripts, and keep scheduled tasks unregistered until approved.

Official sources: [1](https://jules.google/docs/environment/) · [2](https://jules.google/docs/cli/) · [3](https://jules.google/docs/scheduled-tasks/)

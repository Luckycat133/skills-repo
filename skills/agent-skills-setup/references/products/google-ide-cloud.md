# Google IDEs and cloud development

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## android-studio

**Gemini in Android Studio** · Evidence: `documented-subset` · Runtime: `not-run`.

Separate Android Studio's bundled Gemini from generic Code Assist and Gemini CLI. Current documentation covers AGENTS files, Agent Skills, prompt/rule UI and MCP/device capabilities. Older Studio releases used experimental Skill formats; identify the installed release before using a current `SKILL.md` example.

Inventory project instructions, Skills, saved prompts, UI rules, agent settings and MCP, plus required Android tool dependencies. AGENTS instructions and IDE-managed prompt libraries are different objects. Do not transfer device permissions, credentials, emulator state or indexes.

Check a new session sees the migrated Skill/instructions and the intended project. Validate API/tool bindings without running builds, app installation or device control unless authorized.

Official sources: [1](https://developer.android.com/studio/gemini/skills) · [2](https://developer.android.com/studio/gemini/agent-files) · [3](https://developer.android.com/studio/gemini/features)

## antigravity

**Antigravity IDE, App and CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

Do not merge the three surfaces. Current Skill discovery includes `.agents/skills`; older `.agent/skills` compatibility and explicit includes need precedence checks. Inventory rules, Skills, workflows, agents, hooks, plugins, MCP, project/user settings and review artifacts separately.

The current workflow-to-Skill migration is documented for Antigravity App 2.12+, not automatically for IDE or CLI. A workflow can become an on-demand Skill, but preserve manual invocation and arguments; never convert a persistent rule this way. Where workflow and Skill share a name, inspect the documented precedence before deleting either.

Check the current customization-discovery page against local settings. Different old `.gemini`/`.agent` paths in archived notes are not sufficient evidence for new targets. Imported scripts/hooks remain parked until separately approved.

Official sources: [1](https://antigravity.google/docs/skills) · [2](https://antigravity.google/docs/customization-discovery) · [3](https://antigravity.google/docs/migration/workflows-to-skills) · [4](https://antigravity.google/changelog)

## firebase-studio

**Firebase Studio / former IDX** · Evidence: `documented-subset` · Runtime: `not-run`.

Official migration guidance schedules shutdown for **2027-03-22**; that is still in the future as of this review. Prefer a reviewed export from an existing workspace, not the claim that it is already closed.

Inventory authored rules/AI instructions, workspace configuration and `.idx/mcp.json`. Its MCP map is not absent merely because the workspace is cloud-hosted. Preserve the server definitions and declared transport, but rebind local commands to the new execution environment. Nix/devcontainer/setup files are environment configuration, not AI rules.

Export project files and selected instructions through supported mechanisms, not cloud tokens, sessions or generated indexes. Migration to Antigravity or AI Studio requires inspecting that destination's current context surfaces independently.

Official sources: [1](https://firebase.google.com/docs/studio/mcp-servers) · [2](https://firebase.google.com/docs/studio/migrating-project)

## jules

**Google Jules cloud, Tools CLI and API** · Evidence: `documented-subset` · Runtime: `not-run`.

Jules uses repository instructions and a cloud task environment. Inventory AGENTS/README guidance, selected repository/branch, explicit setup script, environment snapshot metadata, schedules and integrations. Tools CLI/API control a cloud service; they do not establish a local Skill or MCP discovery directory.

Copy selected authored guidance as project instructions. Recreate environment setup only after reviewing executable commands and secrets requirements. Do not copy a VM image, session transcript or cloud credential as context. Keep scheduled tasks disabled/unregistered until authorized.

Check the target job reads the expected repository instructions and can prepare its environment in an explicitly approved test. Merely parsing a setup script does not verify the environment.

Official sources: [1](https://jules.google/docs/environment/) · [2](https://jules.google/docs/cli/) · [3](https://jules.google/docs/scheduled-tasks/)

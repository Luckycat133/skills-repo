# Warp Desktop and Oz

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## warp

**Warp Desktop and Warp Drive** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory Skills and compatibility roots, AGENTS and legacy WARP guidance, global Rules, MCP, Agent Profiles, Warp Drive prompts/workflows/notebooks/environment variables and cloud/team state. These are distinct context types, not one config file.

Use actual Desktop settings to distinguish local files from account/team objects. Rule hierarchy and Skill precedence need confirmation before merging aliases. Environment-variable values, team permissions and provider auth are not portable context; retain names/rebinding steps only.

Rebuild selected Warp Drive objects via supported export/UI where needed. Do not claim a file copy recreated account-side state. Check a new Desktop session sees the intended rules/Skill/profile, and review whether a workflow contains executable commands before enabling it.

Official sources: [1](https://docs.warp.dev/agents/capabilities/skills) · [2](https://docs.warp.dev/agents/capabilities/agent-profiles-permissions/) · [3](https://docs.warp.dev/agents/capabilities)

## warp-oz

**Oz CLI, cloud runtime and SDK/API** · Evidence: `documented-subset` · Runtime: `not-run`.

Oz is not a substitute name for every Warp Desktop setting. Inventory project instructions/Skills, run environment, MCP, agent profiles and supported task/workflow inputs using current Oz docs.

A cloud job's working directory, dependency environment and secret bindings differ from Desktop. Move selected authored context, then map it to the destination runner; do not transfer cloud sessions or credentials. A schedule/job definition requires its own authorization before registration.

Check which files the selected Oz run actually mounts and loads. File parsing alone does not prove an SDK/API/cloud job consumed them.

Official sources: [1](https://docs.warp.dev/) · [2](https://docs.warp.dev/agents/capabilities)

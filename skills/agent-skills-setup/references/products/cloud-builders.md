# Cloud and application builders

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## replit

**Replit Agent** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory Agent Skills, `replit.md` project context, user-selected project knowledge, connected MCP/integrations and environment setup. `replit.md` may contain both authored and agent-updated content: review selected facts, not all historical state.

Cloud workspace files can be portable, but account integrations and runtime secrets are not. `.replit` is environment/run configuration, not automatically an instruction file. Do not infer a new local MCP client schema from cloud UI.

Check the project's native Skill/instruction discovery and account-side integration controls. Recreate selected server definitions and dependency notes without copying secrets, deployments, indexes or chat histories.

Official sources: [1](https://docs.replit.com/replitai/skills) · [2](https://docs.replit.com/features/project-setup/replit-dot-md) · [3](https://docs.replit.com/replitai/agent)

## bolt-new

**Bolt.new / StackBlitz** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory project knowledge/instructions, selected assets/design context, connectors/MCP UI and workspace environment. Do not confuse Bolt.new with unrelated Bolt-branded apps or invent a local JSON `servers` file from an example for another client.

Move reviewed instructions and repository content through the project's supported export/Git/UI flow. Recreate connectors with new authorization. Deployment variables, cloud runtime, database credentials and conversation state are excluded by default.

Check the intended project actually displays the imported knowledge and that its active agent uses it. Record UI-only actions precisely rather than label the entire product unsupported.

Official sources: [1](https://support.bolt.new/building/using-bolt/project-settings) · [2](https://bolt.new/blog/introducing-connectors)

## v0

**v0 projects, Skills and API** · Evidence: `documented-subset` · Runtime: `not-run`.

Current v0 documentation/changelog includes project instructions, Skills/pickers, slash invocation and design-system Skills as well as MCP integrations. Older references mentioning only connectors are incomplete.

Inventory team/user/project instruction scope, design-system resources, Skills and selected integrations. v0 acting as an MCP client and v0 exposing an MCP/API service are different directions. Do not create local IDE paths for hosted UI state.

Transfer reviewed instructions/packages through documented UI/API mechanisms; preserve design assets and references, but not cloud secrets, deployment state or chat history. Check the selected project loads the requested Skill and instruction scope. An API call that changes a cloud project needs the user's scoped authorization.

Official sources: [1](https://v0.app/docs/faqs) · [2](https://v0.app/changelog) · [3](https://v0.app/docs/api/v2/guides/design-systems) · [4](https://v0.app/docs/MCP) · [5](https://v0.app/docs/api/v2/guides/mcp-server)

## lovable

**Lovable workspace/project instructions and Skills** · Evidence: `documented-subset` · Runtime: `not-run`.

The former Knowledge feature is now documented as Instructions. Distinguish workspace and project layers. Current Skills can be imported through supported repository/archive flows and invoked on demand; do not retain the old classification that Lovable only has Knowledge/MCP.

Inventory instructions, Skills with resources, connectors and selected project files. Lovable's MCP service exposed to other agents is separate from its in-chat MCP connections. Preserve instruction scope and Skill invocation; recreate auth per connection.

Check project/workspace UI after import and test a harmless task. Do not upload raw conversation history, environment secrets or an entire workspace database. When the UI changes names, retain the behavioral distinction rather than mapping both layers into one text field.

Official sources: [1](https://docs.lovable.dev/features/knowledge) · [2](https://docs.lovable.dev/features/skills) · [3](https://lovable.dev/mcp)

## monkeycode

**Chaitin MonkeyCode platform** · Evidence: `documented-subset` · Runtime: `not-run`.

Current MonkeyCode is a cloud/self-hosted development platform, not merely security middleware. Inventory project/task configuration, Skills, agent resources, MCP integrations, Specs and Git/workspace bindings through the actual platform.

The platform may launch another coding agent; identify that harness and remote workspace before choosing instruction paths. Recreate selected authored definitions through documented UI/API, not a guessed local MonkeyCode settings file. Server admin configuration, model-provider secrets and task/session databases are excluded.

Check the selected task environment discovers the Skill and instructions, then test the underlying harness separately. A working platform connection does not prove context-format compatibility.

Official sources: [1](https://github.com/chaitin/MonkeyCode/blob/main/frontend/doc.md) · [2](https://monkeycode.docs.baizhi.cloud/node/019ea688-4dc6-78ee-bcec-21a97baf0734) · [3](https://www.monkeycode.docs.baizhi.cloud/landing/monkeycode)

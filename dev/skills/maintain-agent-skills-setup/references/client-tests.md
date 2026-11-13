# Run the real-agent / native-client acceptance queue

This is a manual developer-agent procedure, not a new runtime test platform.
The owner plans to pull this branch and run it with an agent. Use existing tools.

## 1. Establish the environment

Read canonical SKILL.md and its references as the target host would. Record agent
product/model/version, native client/profile/version, OS, local/WSL/SSH/container
execution home and workspace. Record loaded Skill path. No native client available
means blocked-environment, not success. Do not install or sign into products merely
to fill the table without authorization. Public docs verification alone is doc-only.

Create a fresh temporary workspace/home supported by the client. If isolation needs
config override flags, verify those flags in that client's help first. Never point
a synthetic test at real global config. Save a source/target file list and hashes.
No credentials: use synthetic variable names/placeholders, not real secret values.

## 2. Inventory all context categories for the selected profile

For instructions, Skills, prompts, commands, agents, hooks, workflows/specs/schedules,
MCP, authored memory/knowledge, plugins/extensions and settings/policy/trust record:
present / absent / unknown / not-applicable-with-evidence. Include UI/cloud categories.
Record native name, scope, loader, format and permission boundary. Do not silently
omit a requested category because no conversion helper exists.

## 3. Minimum scenarios per available profile

A. **Outgoing:** migrate selected authored context to a second known profile. Compare
body/resource content and loss decisions; keep source unchanged.
B. **Incoming:** use that client as destination. Prove native discovery with a unique
harmless marker. A parser result alone is insufficient.
C. **Negative activation:** use a nonmatching file/task. A scoped rule/optional Skill
must not become unconditional. Check hierarchy and alias shadowing.
D. **Existing target:** keep an unrelated setting/rule/server and test a same-name
conflict beside a unique object. Only the conflict is deferred.
E. **No-action:** request preview only. No target writes, installations, connections,
hook execution or new scheduled jobs are allowed.
F. **Repeat:** run again after a harmless unrelated target edit. Same content is a
no-op; newer unrelated edits survive.
G. **Device move:** normal folder + MIGRATION.md; use different synthetic home and
workspace. Rebind paths/variable names, not old absolute roots. No special archive
protocol, restore script, signing service or session DB is required.

Apply only categories actually present and authorized. For MCP, parse the native
schema and list config safely; starting servers/tool calls/OAuth are separate tests.
For hooks/plugins/workflows, keep executable drafts outside live discovery paths.
Use explicit owner approval for a sandboxed native invocation; otherwise mark
execution pending. UI/cloud changes likewise need scoped authorization.

## 4. Required targeted cases

Run evals/catalog-cases.json plus the original cases. In particular: VS Code harness
routing; Cursor/Claude scope; CodeCompanion MDC widening; Augment user rule behavior;
Zed first-match; Qwen permission spelling; Kiro schema boundary; Kimi root override;
OpenCode V1/V2 ID; Pi/ZCode MCP precedence; settings subobject isolation; package
hooks; cloud knowledge scope; MCP-served Skill origin; legacy/unknown identity.

At least one actual Windows-home case and one WSL/remote-host case are required
before making cross-platform claims. POSIX fixture paths on a Windows runner are
only fixture portability, not real Windows discovery evidence.

## 5. Record evidence and stop conditions

Use result-template.md and a local redacted evidence folder. Copy only synthetic
traces into the repository. Report `pass`, `fail`, `blocked-environment`,
`blocked-documentation`, `not-applicable` and `not-run` separately. Preserve an
existing failure record when adding a new successful rerun.

Stop the affected object's write when product identity, active scope/schema or
permission mapping is unresolved. Continue independent authorized objects. Fix
small documentation/fixtures; never weaken safety or add an engine just for a test.
No release/tag/ClawHub upload is part of these tests.

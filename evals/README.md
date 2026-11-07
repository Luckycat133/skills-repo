# Behavior evaluation, not a migration framework

`cases.json` retains 15 original isolated before-file cases and rubrics.
`catalog-cases.json` adds 21 version/harness/format-specific cases.
`client-matrix.json` is a 90-entry native-client acceptance queue.
These are **not completed model/client runs**. Structural CI is not a behavior score.

Start with the [development Skill](../dev/skills/maintain-agent-skills-setup/SKILL.md)
and its [client procedure](../dev/skills/maintain-agent-skills-setup/references/client-tests.md).
Use [the result template](../dev/skills/maintain-agent-skills-setup/references/result-template.md).
The [catalog ledger](../docs/research/catalog-2026-11-07.json) maps IDs to the exact
source-backed reference; it is documentation bookkeeping, not a runtime registry.

For each case, create a fresh isolated workspace/home with synthetic input files.
Load only the canonical Skill in the host being evaluated. Give the agent the user
prompt, not the expected answer, and capture its edits and redacted tool trace.
Do not install missing clients, connect MCP, execute hooks or touch real user config
without separate authorization. Unavailable clients are blocked-environment.

Compare semantics, matching/nonmatching activation, conflicts, untouched neighbors,
secrets, execution consent and repeat-run behavior. Inspect actual file differences,
not only the agent's final claim. Check the native target loader separately from
parsing a JSON/TOML file. Use actual Windows/WSL paths before cross-platform claims.

When recording a run, expand `row_template` in the matching queue row. Record exact
client version, harness, OS, category inventory, evidence paths and status. Keep
scenarios and the dated documentation snapshot unchanged as historical inputs;
write actual run evidence separately. Pass/fail needs evidence; blocked or N/A needs
a reason. Preserve prior failures when adding a successful rerun.

Do not build a CLI, protocol, database, signing service or test orchestration engine
to run this queue. Use the existing agent and its native file/documentation tools.

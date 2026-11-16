# Run the real-agent / native-client acceptance queue

This is a developer-agent acceptance procedure, not a background test daemon.
Use existing host-agent tools plus `skills/agent-skills-setup/scripts/migrate_context.py`
inside isolated temporary roots.

## 1. Establish the environment

Read canonical `skills/agent-skills-setup/SKILL.md` and only the relevant references as
the target host would. Record host agent model/version, native client/profile/version,
OS, local/WSL/SSH/container execution home, workspace, and loaded Skill path. If the
native client is unavailable, record `blocked-environment`, never `pass`. Do not install
or sign into products or touch real `HOME` without explicit authorization.

Create fresh isolated temporary `--workspace` and `--home` directories. Use synthetic
canary secret values (`sk-ant-CANARY-...`) when testing zero-leakage secret migration —
never real production credentials.

## 2. Inventory all context categories for the selected profile

For `instructions`, `skills`, `prompts`, `commands`, `agents`, `hooks`,
`workflows`, `mcp`, `authored-memory-knowledge`, `plugins-extensions`, and
`settings-policy-trust`, record `present`, `absent`, `unknown`, or
`not-applicable-with-evidence` (for full-context runs and client acceptance rows).

## 3. Minimum scenarios per available profile

A. **Outgoing:** migrate selected authored context (and synthetic canary secrets, plus a
`--redact-secrets` variant) to a second known profile. Verify 0 canary occurrences in
`stdout`/`stderr`/`MIGRATION.md`, `0600` target permissions, and unchanged source.
B. **Incoming:** use that client as destination and prove native discovery with a unique
harmless marker (syntax parsing alone is not native discovery proof).
C. **Negative activation:** test non-matching paths/tasks so scoped rules and manual
`disable-model-invocation: true` Skills never fire unconditionally.
D. **Existing target & conflict:** keep unrelated settings/servers/rules and test a
same-name conflict beside a unique object; verify only the conflict is deferred and a
`0600` backup is created before modifying existing files.
E. **Preview (`--dry-run`):** verify zero target writes and zero backup dirs created.
F. **Repeat (`noop`):** re-run after a harmless unrelated target edit; verify identical
items report `noop` and unrelated edits survive.
G. **Device move (`export-device` / `import-device`):** verify `0700`/`0600` transfer
folder + redacted `MIGRATION.md`, `$HOME`/`$WORKSPACE` rebinding on new roots, and
exclusion of chat history/DBs/grants.

## 4. Required targeted cases & recording

Execute `evals/cases.json` and `evals/catalog-cases.json` (VS Code harness routing,
Cursor unquoted/comma `.mdc` globs, CodeCompanion MDC widening, Augment user rules,
Zed first-match shadowing, Qwen `allowedTools`, Kiro v2/v3, `KIMI_CODE_HOME`, OpenCode
V1/V2 IDs, Pi knob-only MCP overrides, ZCode MCP precedence, Gemini `.gemini/settings.json`
subobject isolation, Git-tracked target secret guard, symlink escape rejection).

Record results with [result-template.md](result-template.md). Keep `pass`, `fail`,
`blocked-environment`, `blocked-documentation`, `not-applicable`, and `not-run` distinct.

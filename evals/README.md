# Behavior evaluation, not a migration framework

`cases.json` contains isolated before-files, expected examples where deterministic,
and a reviewer rubric. These are **not completed model runs**. Do not interpret
structural CI as a score for agent behavior.

For each case, create a fresh temporary workspace/home fixture with the listed
files. Install only the canonical Skill in the host being evaluated. Give the
agent the prompt, not the expected answer, and capture its actual file edits and
redacted tool trace. Confirm no real home/config roots can be accessed by the test.

Compare intended semantics, positive/negative scope examples, conflicts, untouched
neighbors, secrets, execution consent and idempotence. Expected file examples allow
formatting differences but not behavioral differences. Review file changes, not
just the agent's final claim. Record host/model/version, prompt, fixture, actual
outputs, checks and failure reasons in `docs/validation-status.md`.

Run a second time to check idempotence. Do not activate Hooks, launch subprocesses,
connect MCP or install packages unless a dedicated sandbox scenario explicitly
permits it. Real target discovery is a separate evidence level from parsing files.

# Changelog

## Unreleased — agent-first scope reset

- Replace the standalone migration engine with a guidance-first Skill using host
  agent tools; metadata is `0.11.0-dev`, not a published release.
- Remove runtime CLI, ACB/signing orchestration and generated compatibility claims
  from the active package; retain the full former implementation in Git history.
- Add rule/MCP worked conversions, all-context inventory, conflict/scope guidance,
  authored-memory distinctions and plain-folder device transfer.
- Add a repository-only development Skill with access-dependent acceptance work.
- Separate structural/package checks from real agent and real IDE evaluation.

Earlier release history is preserved in
[the historical changelog](docs/history/CHANGELOG-before-agent-first.md).

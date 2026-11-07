# Remaining work after the 2026-11-07 documentation update

## Completed in this branch

Agent-first scope reset remains intact. Product references route all 87 historical
identifiers, add missing clients/profiles, record primary sources and version traps,
and stay documentation-only. Main Skill remains short and loads selected profiles.
Historical reference material is not reactivated as an automatic compatibility map.

## Pending: real behavior, not more architecture

1. Run client-tests.md with the Skill actually loaded. Execute available rows from
   evals/client-matrix.json and all applicable fixture cases. Record unavailable
   native clients as blocked; never claim their tests passed.
2. Resolve discovery-required identities/contracts: iFlyCode, SenseTime Raccoon,
   veCLI/Ark CLI distinction, exact International TRAE build, PearAI submodule and
   Coder Xum version paths. Keep reviewed source content without guessed installs.
3. Confirm document disagreements locally: Amazon Q global MCP, Forge home config,
   Windsurf/Devin transition, Kiro major version, OpenCode major version, active
   VS Code harness, Kimi root overrides, Bob IDE versus Shell MCP.
4. Run Windows/WSL/remote-home and cloud/UI cases with actual supported clients.
5. Add only the native examples a failed case demonstrates are missing. Commands,
   agents, hooks, specs, workflows and authored memory remain in inventory; no
   generic converter/runtime is required to prepare reviewed target definitions.
6. Before publication, recheck changed vendor pages, run official Skill validation,
   package only the allowlist, inspect archive, and separately authorize release /
   license / marketplace operations and download-back verification.

## Important evidence limits

`documented-subset` means the cited primary material supports the described
subset. It does not mean all listed URLs were fetched successfully, every feature
has a file path, all possible IDEs are covered, or a client was exercised. Unknown
fields/types and page-access conflicts stay explicit. The test queue is not a test
result. Structural CI only certifies repository/package/example consistency.

Do not restore ACB, signing, bulk detection, plugin installation, background sync
or a migration CLI to make these rows pass. Improve what the host agent reads,
checks and edits for the real migration request.

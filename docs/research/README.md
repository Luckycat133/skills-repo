# Documentation review — 2026-11-07

The agent-first Skill now has a source-backed, progressively loaded
[product catalog](../../skills/agent-skills-setup/references/products.md).
Its coverage ledger is [catalog-2026-11-07.json](catalog-2026-11-07.json).
All 87 historical identifiers have a route; 90 profile/category records cover them
and additional clients, profiles and aliases. These numbers are coverage, not a
count of runtime-certified IDEs or compatible product pairs.

Primary materials include vendor customization docs, schemas, release notes and
official repositories. Each family section links relevant sources and states its
known formats, scopes, precedence, migration cautions and native checks. The ledger
records 280 unique source URLs; this is not a claim every page was fully accessible
or every client/category has a documented file contract.

New client coverage includes Codebuff/Freebuff, iFlow, Huawei CodeArts Agent, Ona,
Avante, T3 Code and Coder Xum, with identity/version limits. New profiles include
Copilot app/other IDEs, JetBrains Air, Kiro Crew, Qoder Work/Wake, Vibe Work,
Augment Cosmos and gptel-agent. Renames are not counted as new independent IDEs.

Important changes include harness-specific VS Code customization; Windsurf/Devin
redirects; Qwen permission-field differences; Kiro/OpenCode major-version contracts;
Kimi home overrides; native Pi MCP; ZCode precedence; Letta Code AgentFile changes;
and updated cloud/UI Skills. Ambiguous official paths and unavailable complete
contracts remain explicit discovery-required/version-sensitive entries.

No real clients were run here. Follow the repository-only development Skill and
`evals/client-matrix.json` for native discovery, activation, negative scope,
existing-target/conflict, preview, repeat and device-move evidence. Do not promote
a documentation row to tested compatibility just because structural CI is green.

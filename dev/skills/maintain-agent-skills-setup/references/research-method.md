# Research and product update method

Baseline review: 2026-11-07. Public documentation changes independently of installed
software. Review the official customization index/release notes, not just a search
snippet or a product's SKILL.md inside its own development repository.

## Evidence ladder

1. Vendor documentation for the selected version and profile, plus official schema
   or implementation for ambiguous details.
2. Installed client's own help/configuration view and harmless discovery result.
3. Real host-agent migration trace and target behavior (including negative scope).

Record these independently. An indexed official snippet can identify a feature;
it does not establish an entire schema. A failed page fetch, redirect or contradictory
page is a gap to investigate, not a successful verification. Third-party directories
and skill installers may suggest candidates but cannot certify native capabilities.

## Every product update

Record vendor identity, CLI/IDE/cloud/ACP profile, actual version, OS/execution host,
user/project/local/managed scopes, locations/overrides, format fields, precedence,
activation/invocation, imports, executable parts, credentials and verification action.
Enumerate all requested categories using products.md. Mark unknown types explicitly.
Do not call a provider/installer/editor an IDE migration target without a real host.

Use primary URLs beside the statement. Summarize rather than copy vendor text.
Do not automatically update reviewed_at just because a URL returns 200. Check the
relevant fields and a release note. Do not turn documentation dates into tested
version ranges. Never claim shutdown solely from an inactive repository.

## Known decisions requiring local confirmation

- VS Code customization depends on active harness, not merely model.
- Windsurf redirects to Devin documentation: legacy Cascade and Devin Local differ.
- Qwen allowedTools is not generic allowed-tools.
- Kiro CLI 2/3 agent schemas differ; permissions are not portable grants.
- Kimi's current root differs from older ~/.kimi.
- Pi now documents native MCP; older absence claims are stale.
- Letta Code's legacy AgentFile import/export is not a current default workflow.
- Amazon Q and Forge have conflicting official path examples: inspect effective config.
- Ona's current agent overview redirects to Codex; coder/mux redirects to coder/xum.
- Supermaven sunset retains some autocomplete; do not call every feature closed.
- iFlyCode, SenseTime Raccoon and veCLI lack a complete verified file contract here.

## Coverage is finite and explicit

The archived catalog's 87 identifiers all have a route. New candidates and new
profiles are named separately. This does not prove no other IDE exists. For another
product, add its identity/sources and a pending test, without inventing support or
adding background discovery software.

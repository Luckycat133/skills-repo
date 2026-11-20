# Migration report

Request and authorization: <actual intent; preview/apply; approved scope>
Overall result: <complete within scope / partial / preview / no-op>
Source / destination: <product, profile/harness, installed versions or unknown, OS/host>
Loaded Skill: <version; source commit/digest when known>
Evidence dates: <documentation checks and actual client runs, separately>
Report audience: <private local / portable or public; use logical roots for portable>

## Inventory and outcomes

| Requested category | Present / absent / unknown / N-A | Evidence or gap |
| --- | --- | --- |
| <skills/rules/MCP/commands/agents/hooks/memory/etc.> | <state> | <scoped observation> |

| Object ID / source | Destination and scope | Outcome | Semantic loss / reason / next action |
| --- | --- | --- | --- |
| <one logical object; no secrets> | <approved target> | <copied/converted/unchanged/conflict/draft/deferred/excluded/failed> | <precise result> |

Counts: <selected N = copied + converted + unchanged + conflict + draft + deferred + excluded + failed>
Count logical objects once; do not count files or duplicate aliases as additional successes.

## Verification

| Check | pass / fail / not-run / blocked | Tool/evidence and reason |
| --- | --- | --- |
| Syntax | <status> | <selected file, parser/tool, result> |
| Content, scope, imports | <status> | <matching and nonmatching examples> |
| Unrelated target content / source preservation | <status> | <redacted diff or comparison> |
| Native discovery | <status> | <actual client/version/harness or why unavailable> |
| Activation | <status> | <positive and negative trigger observations> |
| Runtime / connection | <status> | <separate authorization, or not run> |
| Repeat review | <status> | <no duplication; concurrent edits preserved> |

## Remaining work

<Variable names to rebind, re-authentication, missing dependencies, unresolved
semantics and concrete decisions. No values, tokens, raw history or private logs.>

## Recovery

<Edits completed; exact private backup paths for local use, or logical references
for portable reports; conditional restore steps; concurrent-change conflicts.
No replacements means no backup needed. No universal atomic rollback claim.>

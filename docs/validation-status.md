# Validation status — agent-first documentation update

Research date: 2026-11-07. Agent-first baseline:
`2a65abed5cd0e80aeca2413dd1d183c01deabf42`.
Candidate metadata remains `0.11.0-dev` (unreleased).

| Level | Status |
| --- | --- |
| Local package/link/contract/catalog checks | PASS in Linux sandbox; 22 unittest checks |
| Example JSON/TOML and scope/content checks | PASS for recorded deterministic fixture expectations |
| Documentation coverage | All 87 historical identifiers routed; 90 profile/category records, 30 family references, 25 additional names/profiles/aliases |
| Primary-source references | 280 unique URLs attached to relevant sections; links are evidence for described subsets, not a complete schema/runtime certification |
| Official Agent Skills validator | Required in CI; not installed in local sandbox |
| Actual host agent runs | NOT RUN; 15 original + 21 additional cases await execution |
| Native IDE discovery/activation | NOT RUN; 90-entry client queue prepared |
| Native Windows, WSL and remote behavior | NOT RUN |
| Marketplace publication/download verification | NOT RUN; not part of this edit |

The documentation snapshot and test scenarios remain historical inputs. Record new
real runs in `evals/client-matrix.json` with installed version, harness, OS, category
results and redacted evidence files. Do not relabel research as a native-client pass.
The queue validation accepts recorded passes/failures only with that evidence;
unavailable environments require a block reason rather than a fabricated success.

See [evaluation](../evals/README.md),
[catalog ledger](research/catalog-2026-11-07.json), and
[developer procedure](../dev/skills/maintain-agent-skills-setup/references/client-tests.md).
A green structural test proves internal consistency, not the behavior of all clients.

# Verification records

The v0.10.0 records cover the published payload at commit
`12d56c84407ff91847b0c9afe1c970f90818a102`, observed on 2026-10-03.
They separate file/fixture checks, native client behavior, platform security
reports, and browser delivery.

| Record | Verified scope | Remaining boundary |
| --- | --- | --- |
| [Windows legacy suites](windows-legacy-v0.10.0.md) | All five formerly excluded suites passed on native Windows Python; 488 path checks matched. | Full validation matrix is tracked separately; no installed IDE is exercised by these fixtures. |
| [Native offline acceptance](native-v0.10.0.md) | Frozen-package migration, Codex discovery/instructions/local MCP/rollback; Claude MCP discovery and VS Code isolated registration. | Model turns, Claude connectivity, VS Code skill activation, unavailable clients, and remote hosts were not tested. |
| [Security report comparison](security-v0.10.0.md) | All 112 platform findings reviewed; exact 120-file payload binding and scanner coverage limits retained. | Raw critical warnings, partial analyzers, binary inspection and dormant legacy coverage remain distinct from the platform's aggregate pass. |
| [Browser delivery](clawhub-ui-v0.10.0.md) | Rendered metadata/card/files/versions/diff/security and a completed download matching all 120 submitted files. | Direct raw reference navigation was blocked by the client; site Files viewing passed. |

Raw reports, local reproduction harnesses, screenshots, native protocol logs,
and synthetic fixture outputs are retained as local verification evidence.
Their digests and assertion scope are recorded in the linked reports. These
records do not upgrade experimental profiles or certify every source/target
pair, installed product, transport, or model session.

The [v0.10.1 security review](security-v0.10.1.md) binds the signing-key
transaction correction to the actual 120-file runtime candidate and records
all 101 local scan findings, preserved warnings and incomplete coverage.
The v0.10.0 native and browser records remain evidence for that earlier payload;
they do not certify native application behavior of v0.10.1.

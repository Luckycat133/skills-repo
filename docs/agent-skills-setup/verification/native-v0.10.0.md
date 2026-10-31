# v0.10.0 native offline acceptance

Verified on 2026-10-03 with native macOS 27.0.1 executables. Codex discovery,
instruction loading, local MCP execution, and rollback passed. Claude project MCP
discovery and VS Code isolated MCP registration passed. No model turn ran.

## Frozen input

The final runs used the published v0.10.0 package for commit
`12d56c84407ff91847b0c9afe1c970f90818a102`, copied into a new temporary project.
All 120 package files matched the prepared published package byte for byte; the
synthetic `native-probe` skill added one file. The current working tree was not
the final test input.

The package tree digest is SHA-256 of UTF-8 JSON mapping relative POSIX filenames
to file SHA-256 values, with sorted keys and compact separators.

| Input | SHA-256 |
| --- | --- |
| Published package tree | `b662e3fdea0b815381cb8086d8fa919c7ecd5ff3b4cbb54172dba654273730d2` |
| `scripts/context-migrator.py` | `15f0dd39de17456c8d755b4041581a9a566186ff2c74e238d0f2e3a7076a7379` |
| `scripts/migration_core.py` | `c443bb182b5d56c4eef9ac12b793ec315800fbce137f1b2dfdaf40da9881bd06` |
| `references/registry-v2.json` | `c222b77f4a9df80bd1906e010dc6e346ada670a22a9b4bebd0d26fb3e6512348` |
| Fixture `CLAUDE.md` | `555c1a41d1dd01bdd199dbd5f462fb3f5e89c2249e214bdc29bc29e52b7cadc6` |
| Fixture `native-probe/SKILL.md` | `8fd1b8f96c69e41982978fbfce57af1ca53e07d87d7308b85a26cea1abb5c112` |

Earlier exploratory runs used a working-tree copy. Its migration scripts and
registry matched the frozen release, but publication overlays changed two
package files. Those artifacts remain exploratory evidence; the reported final
acceptance used the complete frozen published package.

## Results and limits

| Native check | Result | Evidence |
| --- | --- | --- |
| Codex `0.159.0-alpha.12.1`: skill discovery | PASS | `skills/list` with `forceReload` found enabled `agent-skills-setup` and `native-probe`, with no discovery errors. |
| Codex: package preservation and native reads | PASS | All 121 source skill files matched the migrated tree. Native `fs/readFile` returned identical bytes for both skill bodies, the registry, and one packaged asset. |
| Codex: migrated instructions in session context | PASS | `debug prompt-input` contained the fixture instructions marker and both skill names. |
| Codex: local stdio MCP | PASS | The native app server initialized the synthetic server, listed `fixture_echo`, and invoked it with the fixed fixture value. The server journal recorded `initialize`, `tools/list`, and `tools/call`. |
| Codex: rollback and reload | PASS | Rollback removed migrated instructions and skills; another native `skills/list` no longer contained either skill. Original source files were unchanged. |
| Claude Code `2.1.283`: project MCP discovery | PASS | Native `mcp get` and `mcp list` found the explicit fixture server and reported pending project approval. They added zero MCP journal methods. |
| Claude Code: MCP connection and skill activation | NOT_RUN | Pending project approval was preserved. No interactive or model session ran. |
| VS Code `1.131.0`: isolated extension discovery | PASS | Native `--list-extensions` returned an empty list with dedicated user-data and extension directories. |
| VS Code: native MCP registration | PASS | `--add-mcp` persisted the exact fixture command, arguments, and environment in the isolated `User/mcp.json`. Registration added zero MCP journal methods. |
| VS Code: MCP connection and skill activation | NOT_RUN | CLI registration did not start a UI or chat session; no chat extension was installed in the isolated profile. |
| Cursor and Windsurf | NOT_RUN | Native applications were unavailable on this machine. |
| Model execution, turn skill injection, and remote MCP | NOT_RUN | No `turn/start`, inference request, real account, or remote server was used. |

Codex MCP configuration was reconstructed explicitly for this local fixture;
this does not establish automatic migration of the Codex TOML MCP surface. The
app-server calls followed the installed protocol schema and the official
[Codex app-server documentation](https://learn.chatgpt.com/docs/app-server).
`debug prompt-input` validates session context. It does not prove the full skill
body was injected into an inference turn, which remains untested.

## Loss gate and reversibility

The first attempt applied the safe skill item and skipped instructions:
`lossy-skipped: 1`. `AGENTS.md` was absent. The original assertion expecting that
file failed, correctly exposing an unaccepted conversion loss rather than a
migration defect. Its plan, manifest, verification, failure, and successful
rollback evidence were retained.

The reviewed plan's complete loss report contained exactly one field:
`instructions.hierarchy` could not be represented by `agents-md`. The fixed
fixture has one `CLAUDE.md` and no nested hierarchy. After checking that exact
report, the second apply accepted only the reviewed instructions item using
`--accept-loss 1:instructions`. It did not use blanket loss acceptance.
Verification passed before native inspection. Rollback passed afterward and
left the original instructions and both source skill packages unchanged.

The reusable harness repeats the skipped-loss and rollback assertions in each
fresh project before the specifically accepted apply. A modified package was
also rejected by its digest check before any package script executed.

## Isolation

Every migration and native CLI subprocess used a whitelisted environment with
temporary `HOME`, `CODEX_HOME`, `CLAUDE_CONFIG_DIR`, `USERPROFILE`, and `TMPDIR`.
No API key or authentication environment was inherited. Native subprocesses
ran inside `sandbox-exec` with these core rules, where `TEMP_ROOT` is the
canonical path of the harness-created temporary directory:

```scheme
(version 1)
(allow default)
(deny network*)
(deny file-write*)
(allow file-write* (subpath "TEMP_ROOT"))
(allow file-write-data (literal "/dev/null"))
(deny mach-lookup (global-name "com.apple.securityd"))
```

Additional `file-read*` rules denied the real home paths for `.codex`, `.agents`,
`.claude`, `.claude.json`, `.vscode`, `Library/Keychains`, and the Claude,
Code, and Code Insiders application-support directories. The `/dev/null`
exception permits a nonpersistent byte sink required by native launchers and
Git metadata checks. It grants no persistent write location. A subprocess
actually attempted a loopback socket and received an OS permission denial.

Claude discovery used `--bare`, `--setting-sources project`,
`--strict-mcp-config`, and an explicit synthetic MCP file. VS Code used dedicated
`--user-data-dir` and `--extensions-dir`, disabled extensions, and disabled
telemetry. Codex used an isolated unauthenticated provider configuration whose
loopback endpoint was also denied by the OS sandbox. Only the synthetic local
stdio MCP server was connected; it exposes one echo tool and writes only a
method journal in the temporary directory.

Native calls were bounded: app-server RPCs used 25 seconds, prompt rendering
40 seconds, Claude discovery 30 seconds, and VS Code calls 35 seconds. The
reviewed harness terminates its own process groups on timeout and preserves
stdout, stderr, and timeout evidence. No timeout occurred in the final run.

## Reproduction and evidence

The local maintainer harness comprises `check-native-acceptance.py` and the
adjacent `mcp-fixture.py`, retained with the verification evidence rather than
distributed as repository or Skill runtime commands. It requires Python 3.10+, native macOS
`/usr/bin/sandbox-exec`, and explicitly supplied native CLI paths. It creates a
new temporary directory, refuses a package digest mismatch, retains evidence,
and prints only the assertion summary and evidence location.

```bash
python3 check-native-acceptance.py \
    --package-dir "$V0100_PACKAGE_DIR" \
    --codex "$NATIVE_CODEX_CLI" \
    --claude "$NATIVE_CLAUDE_CLI" \
    --vscode "$NATIVE_VSCODE_CLI"
```

Supply the extracted published v0.10.0 skill directory and installed executable
paths. The optional Claude and VS Code arguments may be omitted; those clients
are then explicitly `NOT_RUN`. Do not substitute simulated platform detection
or a working-tree package for frozen release evidence.

| Reviewed harness file | SHA-256 |
| --- | --- |
| `check-native-acceptance.py` | `f0d61841905a4bb243e58516660dc1bbc123a573e57c75468be1f534fe03e22e` |
| `mcp-fixture.py` | `f73135749be1e952bb121fce23d325d1d52eee5396cfcf10cb73680f7bbc5049` |

The final reusable-harness run exited 0 with empty launcher stderr. Its
`native-result.json` records the native versions and boundaries above.
`frozen-inputs.json` records every source file hash; `initial-safeguard.json`
records the default loss rejection; the reviewed plan, accepted manifest, and
verify/rollback outputs record the migration lifecycle. Native RPC methods,
MCP method journal, and per-client result files record actual client behavior.
Full protocol and prompt artifacts contain synthetic fixture data and remain
in local evidence rather than repository documentation.

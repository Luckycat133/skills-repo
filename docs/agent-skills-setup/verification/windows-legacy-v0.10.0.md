# Windows legacy compatibility acceptance

Baseline: v0.10.0 (`12d56c84407ff91847b0c9afe1c970f90818a102`). This record covers the five legacy suites previously excluded from Windows validation. Updated fixtures passed all five on a real Windows runner at commit `31223c949008940840acb9403d07ef5a629939b7` on 2026-10-03; the full PR matrix is recorded separately.

## Supported boundary

The public `smart-ide-migration.sh legacy` interface permits `--print-path` and `--dry-run`. It rejects `--yes`, including when combined with `--dry-run`. Writes use reviewed Registry v2 plans through `plan`, `apply`, `verify`, and `rollback`.

The retained Bash converter is internal. Its test-only authorization exercises compatibility mechanics in temporary fixtures and does not authorize public legacy writes or certify that an installed IDE accepts the resulting configuration. Undocumented product paths, whole-IDE configuration, whole-project configuration, and explicitly manual adapters retain their existing refusal or manual-review behavior.

## Coverage on a real Windows runner

| Suite | Behavior exercised without installed IDEs |
| --- | --- |
| `test-antigravity-migration.sh` | Current and existing legacy Skills paths; unsupported config target; manual rules/project boundaries; public write refusal; retained MCP `url` to `serverUrl` conversion. |
| `test-conflict-strategies.sh` | Invalid strategy leaves target and backups unchanged; rule/prompt backup preserves originals; MCP backup and overwrite preserve their selected-map boundaries. |
| `test-copilot-mapping.sh` | CLI paths and MCP root key; unsupported websocket transport refusal; retained stdio conversion. |
| `test-ide-paths.sh` | Every legacy object mapping for the actual host; unsupported lookup exit status; per-IDE reference consistency; CLI prompt boundary. |
| `test-smart-ide-migration.sh` | Existing product-specific manual/refusal boundaries, Skills discovery, Cline overrides and ambiguity, MCP validation/redaction, and exclusion of private session state. |

Every suite also checks a public Skills dry-run against an existing target. File names, types, permission values, and content hashes must match before and after preview and rejected `--dry-run --yes` execution. The preview must actually discover the fixture Skill. Original internal conversion and failure assertions remain active.

The [shared fixture helper](../../../skills/agent-skills-setup/scripts/test-support/legacy-fixture.sh) confines HOME, USERPROFILE, APPDATA, LOCALAPPDATA, XDG_CONFIG_HOME, and temporary paths to the suite's own directory. It clears inherited Cline path overrides, uses paths accepted by both Git Bash and native Python, and requires `win32`/`nt` Python when running under Windows Git Bash. No `uname` override is used. The helper is maintainer code and is excluded from published runtime packages.

The path-drift suite compares the documented public display format: USERPROFILE-relative paths render as `~/...`; APPDATA resolves within the fixture. Its Python TSV producer emits LF explicitly so Windows text-mode stdout cannot insert a carriage return into the expected path field. Per-IDE references still undergo comparison with the original registry strings.

The first Windows run at `764618b784098cc1297e2afa42e47dd376c5b071` passed the first three suites, then failed one of the 488 path checks: native Python received a backslash-form HOME while Git Bash printed the documented `~/.mcp.json`. The fixture now compares the USERPROFILE-relative display form directly. No runtime path mapping or original assertion was removed.

## Reproduce and record

On `windows-latest`, select `shell: bash` and native Python 3.12, then run from the repository root:

```bash
export PYTHONUTF8=1
export PYTHONDONTWRITEBYTECODE=1
python3 -c 'import os,sys; assert os.name == "nt"; assert sys.platform == "win32"; print(sys.version)'
bash skills/agent-skills-setup/scripts/test-antigravity-migration.sh
bash skills/agent-skills-setup/scripts/test-conflict-strategies.sh
bash skills/agent-skills-setup/scripts/test-copilot-mapping.sh
bash skills/agent-skills-setup/scripts/test-ide-paths.sh
bash skills/agent-skills-setup/scripts/test-smart-ide-migration.sh
```

Record the exact commit, GitHub Actions run URL, native Python version, per-suite exit status, and any failure output. After focused acceptance, run the complete `bash validate-all.sh` matrix with all five suites included on Windows. A local macOS result or lexical Windows path check cannot substitute for that run.

| Evidence | Status |
| --- | --- |
| Unchanged v0.10.0 suites under isolated macOS HOME | Passed all five. |
| Updated isolation and public-boundary checks on macOS | Passed all five focused suites and Bash syntax checks. |
| Updated suites on native Windows CI | All five passed; `MINGW64_NT-10.0-26100`, native Python `win32`/`nt` 3.12.10; [Actions run](https://github.com/Luckycat133/skills-repo/actions/runs/37083839585). |
| Full validation matrix with the five Windows exclusions removed | Pending PR checks. |

Live IDE/UI acceptance, dependency installation, authentication, cloud services, and undocumented adapters remain outside these isolated legacy suites. Their absence is not converted into a passing Windows acceptance claim.

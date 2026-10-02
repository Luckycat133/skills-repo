# Roadmap

The Registry and [compatibility matrix](compatibility-matrix.md) define each
profile's scope and evidence. A passing fixture establishes the tested behavior;
native discovery and execution in a target application remain separate checks.
The repository configures Linux, macOS, and Windows validation in CI.

## Implemented

- Registry v2 resolves product/profile aliases, inheritance, platform paths,
  scopes, support levels, and evidence. No profile claims `full` support.
- `detect`, bulk `snapshot`, and bulk `restore` share detection and precedence.
  Named operations inspect only their selected products. Product-specific files
  can provide installation evidence; shared compatibility files remain opt-in.
- Saved plans bind Registry/adapter versions, source and target state, Git
  provenance, and stable object identities. Apply stages outputs, creates exact
  backups, writes a checksummed manifest, and verifies persisted results.
- Partial safe apply records manual, forbidden, invalid, lossy, and conflicting
  items. Conflicts block the affected target group; strict mode rejects mixed
  plans. Reported instruction/MCP losses require explicit acceptance. Rollback
  checks every target and backup before restoring changes.
- ACB `snapshot`, `bundle-verify`, `restore`, and `doctor` support atomic bundles,
  closed-world checksums, 1:1 object/file bindings, multi-source merging,
  ordinary file permissions, reviewable previews, and cross-process plan replay.
  Named plans bind the manifest digest and stable object URIs; bundles without
  permission metadata remain readable.
- `bundle-keygen`, `bundle-sign`, and `bundle-verify` / `restore --trusted-key`
  use Ed25519. Integrity checks can run without a trusted key; authentication of
  the signer requires a trusted public key obtained independently.
- Skills, instructions, and supported local stdio MCP subsets have automatic
  writers. Remote transports and unsupported configuration formats yield manual
  reconstruction actions. Shared MCP settings preserve unrelated fields; previews
  expose server additions, removals, and changed field names without credentials.
- Plugin packages and reviewed handoff summaries retain separate object/opt-in
  gates through snapshot, migration, and restore. Hooks and agents have no live
  staging writer. Legacy compatibility remains read-only.
- Source scanning, secret redaction, environment-file exclusion, symlink
  rejection, output-path containment, and explicit manual follow-ups remain
  enforced. Import and runtime packaging validate a complete staged tree before
  replacing any destination.
- Offline freshness reports retain stale evidence on failure. Explicitly requested
  demotion validates the proposed registry before replacement; the CI workflow
  preserves reports and requires manual opt-in to propose a downgrade.
- Repository scale testing exercises isolated migration, saved-plan restore,
  contents, rollback, and source preservation. Streaming SHA-256 keeps allocation
  bounded; timings are observations rather than CI performance thresholds.

## Limitations and follow-up evidence

- WSL, Remote-SSH, Dev-Container, Codespaces, VS Code profiles, and extension-host
  declarations require host/guest path and apply/rollback tests before stronger
  cross-platform support claims. They remain experimental.
- Ed25519 signing requires the optional `cryptography` dependency. The skill
  does not download or install it; ordinary snapshot and integrity checks do not
  require it. Cross-device signature tests use ephemeral keys.
- `doctor` reports missing executables, package requirements, re-authentication,
  and rebuild work. It does not install dependencies or prove package availability,
  credentials, transport connectivity, or native application acceptance.
- Compatibility data does not prove every source/target pair works in a native
  application. New support requires fixtures, official source evidence, and
  updates to the generated matrix and profile contracts.
- Maintainer online freshness checks are separate from the offline skill.
  Timestamp and schema validation alone do not establish current external paths.

## Out of scope

Automatic downloads, dependency installation, cloud account changes, credential
or trust-state transfer, raw chat-history migration, and patches to installed
third-party applications are outside this skill. Generated/manual surfaces such
as workflows, automation, cron, personas, and modes remain inventory or rebuild
items unless a reviewed adapter and meaningful regression justify a new writer.

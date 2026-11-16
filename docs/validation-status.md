# Validation status (`0.11.0-dev`, unpublished)

## Verified locally (script, contract, security & official `skills-ref`)

- **Official Agent Skills validator (`skills-ref`) & 44 automated checks**:
  `REQUIRE_SKILLS_REF=1 bash validate-all.sh` passes all 44 contract, catalog, torture,
  canary zero-leak, E2E workflow, and repo-consistency checks plus `skills-ref validate`
  on both `skills/agent-skills-setup` and `dev/skills/maintain-agent-skills-setup`
  (with `PYTHONUTF8=1` verified under non-UTF-8 locales).
- **Canonical Skill & progressive references**: `SKILL.md` < 140 lines; all relative
  links and `#anchors` resolve; all 90 canonical IDs, 87 historical IDs, and 25 new
  product/profile names route in Column 1 of `references/products.md` across 30 family
  documents and 280 primary official URLs.
- **Zero-context-leak out-of-band migration (`scripts/migrate_context.py`)**:
  - Multi-round canary secret tests verify **zero** occurrences of synthetic API keys,
    MCP `env` secrets, Bearer headers, URL userinfo passwords, secret CLI flags, and
    `.env*` values in `stdout`, `stderr`, or `MIGRATION.md` across `inspect`, `migrate`,
    `export-device`, `import-device`, and `patch-mcp` (including `--dry-run`, conflict,
    and parse-error paths).
  - Enforces `0700` directory and `0600` atomic file permissions on secret-bearing
    targets, private backups (`~/.agent-skills-setup-backups/`), and device-transfer
    folders; honors `--redact-secrets` when requested.
  - Protects Git-tracked project files (routes secret-bearing Claude `.mcp.json`
    entries to untracked `~/.claude.json` `projects[workspace].mcpServers`; refuses
    other Git-tracked secret writes with exit code `2` unless authorized).
  - Rejects `..` path traversal, symlinks escaping authorized roots, tampered transfer
    manifests (SHA-256 mismatch), and existing export directories.
  - Parses JSONC (`//`, `/* */`, trailing commas), unquoted/comma/brace Cursor `.mdc`
    globs, surgical Codex TOML `[mcp_servers.<name>]` (`env_vars` vs `env` vs rename
    detection), OpenCode V1/V2, Zed `context_servers`, VS Code `servers`, Gemini
    `httpUrl`, Antigravity/Windsurf `serverUrl`, Pi knob-only MCP overrides, Qwen
    `allowedTools`, manual-only `disable-model-invocation: true`, and idempotent
    Markdown section merges.
- **Packaging (`scripts/package_skill.py`)**: Reproducible `.zip` containing only the
  42 allowlisted files (`0755` on `scripts/migrate_context.py`, `0644` on docs),
  excluding `dev/`, `evals/`, `docs/`, `tests/`, `__pycache__/`, and `.pyc`.

## Not verified here (requires live native IDE / GUI / account environments)

- **Native IDE / GUI runtime loading (`evals/client-matrix.json`)**: `not-run` in this
  headless Linux container. Structural/parser/script tests prove generated file syntax,
  permissions, and zero secret leakage, **not** that a closed-source desktop GUI IDE
  (Cursor GUI, Windsurf Desktop, Xcode 27, Android Studio, JetBrains IDE, Claude
  Desktop, Warp Desktop, TRAE, Qoder, etc.) loaded and activated the object in a live
  UI session.
- **Unverified vendor schemas (`discovery-required`)**: `iflycode`, `raccoon-ai`,
  `vecli`/`ark-cli`, International `trae`, `pearai`, `coder-xum`, and `claude-desktop`
  remain explicitly marked `discovery-required` / `not-run` until inspected on real
  installed builds.
- **Live MCP network handshakes & OAuth re-binding**: Intentionally not executed during
  migration or automated tests.

# Security

The published Skill (`skills/agent-skills-setup/`) ships Markdown guidance, templates,
and one zero-dependency Python 3.11+ stdlib helper (`scripts/migrate_context.py`). It
is not a privilege sandbox; the host agent's OS permissions remain authoritative.

## Secret & Untrusted-Content Boundaries

- **Zero LLM context exposure**: Never read raw `.env*` or credential-bearing MCP/client
  configs into LLM prompt context. `scripts/migrate_context.py` moves secret values
  out-of-band disk-to-disk using `0700` directories and `0600` files (or replaces them
  with placeholders under `--redact-secrets`), protects Git-tracked project files
  against silent secret writes, and prints only key names and `sha256[:8]` prefixes.
- **Inactive untrusted code & strict exclusions**: Imported instructions, Skills, and
  hooks are untrusted data. Hooks stay parked in `.migration-review/` unless
  `--activate-hooks` is explicitly approved. Chat histories, transcripts, SQLite/LevelDB
  databases, caches, OAuth cookies, and approval/trust grants are always excluded.

## Reporting a Vulnerability

Do **not** post API keys, tokens, cookies, `.env` values, raw configuration files,
private paths, or session logs in public GitHub Issues. Use GitHub's private
vulnerability reporting (`/security/policy`) when available, or contact the maintainer
for a private channel before disclosing sensitive details.

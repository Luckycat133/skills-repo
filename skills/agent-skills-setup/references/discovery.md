# Discover the actual context, not a guessed IDE brand

Consulted official documentation on 2026-11-07. Candidate paths are starting points,
not runtime certification: inspect the installed version and actual files before
writing, and delegate secret-bearing files to `scripts/migrate_context.py inspect`.

## Resolve identity and scope

Separate CLI, IDE extension/harness, desktop chat, cloud session, and remote/WSL
extension host. VS Code running a Claude or Codex harness is not necessarily a
Copilot session. Resolve `HOME`, `XDG_CONFIG_HOME`, product overrides (`CODEX_HOME`,
`KIMI_CODE_HOME`, `ANTIGRAVITY_SKILLS_DIR`, `GLAB_CONFIG_DIR`), and `--workspace`
from the actual execution host; never expand a Windows `%APPDATA%` path with a Linux
`HOME`. If the target host is unavailable, prepare reviewed files without claiming
live discovery.

Run `python3 "<SKILL_DIR>/scripts/migrate_context.py" inspect --workspace . --scope all`
for bounded discovery across built-in profiles without reading secret values into LLM
context. A shared `.agents/skills` or `AGENTS.md` does not prove every compatible app
is installed: distinguish configured native roots, shared roots, and absent categories.

## Source-backed product catalog

Use [the product catalog](products.md) to route all canonical profile IDs, all 87
historical identifiers, and newly researched tools/aliases. Load **only** the selected
source and target sections, never all 30 family files at once.

For an "all context" request, account for every category in `products.md`
(`instructions`, `skills`, `prompts`, `commands`, `agents`, `hooks`, `workflows`,
`mcp`, `authored-memory-knowledge`, `plugins-extensions`, `settings-policy-trust`).
`unknown` requires native UI/schema inspection, never a guessed file path.

## Any unlisted IDE or uncertain contract

1. Identify the exact vendor, binary/extension ID, and version. Similar names are not aliases.
2. Consult official customization docs, local JSON/TOML schemas, or `--help`.
3. Record the primary URL or local schema path, retrieval date, storage paths,
   precedence, and supported frontmatter/container keys.
4. Use `scripts/migrate_context.py patch-mcp` for JSON/JSONC/TOML MCP maps (so secrets
   stay out-of-band) and host-agent edit tools for verified Markdown/YAML surfaces.
5. Where contract evidence is missing, park a reviewed draft in `.migration-review/`
   and state the exact missing contract rather than guessing or claiming nonsupport.
   Never include local secret values, usernames, or private repo names in web searches.

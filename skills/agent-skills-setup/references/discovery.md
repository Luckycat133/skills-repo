# Discover the actual context, not a guessed IDE brand

Consulted official documentation on 2026-11-07. These are starting points, not a
compatibility certification. Check the installed version and actual files before
writing. Public docs can change independently of the installed client.

## Resolve identity and scope

Separate CLI, IDE extension/harness, desktop chat, cloud session, and remote
extension host. VS Code running a Claude or Codex harness is not necessarily a
Copilot session. Resolve HOME, XDG, product overrides and workspace from the
host's tools; do not expand a Windows path using a Linux home. If the environment
is unavailable, prepare reviewed target files without claiming installation.

Inspect only relevant paths and schema keys. An installed app, enabled extension,
user-confirmed profile, and existing config are different evidence. A shared
`.agents/skills` or `AGENTS.md` does not mean every compatible app is installed.
For an authorized all-tools request, list detected candidates and distinguish
installed, configured, shared-only, and unknown before choosing targets.

## Source-backed product catalog

Use [the product catalog](products.md) for all historical tool identifiers and
newly researched products/profiles. Load only the selected sections, not the whole
catalog. Each section gives primary sources, known surfaces, compatibility traps,
and what the local agent must verify. Documentation review date is 2026-11-07;
all real-client results remain not-run until evidence is recorded.

For a request covering all context, complete the catalog's category checklist even
when a category has no public file contract. `unknown` needs native settings/schema
inspection; it is not permission to guess a path or drop the category.

## Any other IDE or an uncertain path

1. Identify the vendor and exact product/profile. Similar names are not aliases.
2. Open its official documentation index, installed schema, or vendor repository.
   Search rules/instructions/steering, skills, commands/prompts, agents/modes,
   hooks/workflows, MCP/tools, memory/knowledge, plugins/extensions, and scope.
3. Record the evidence URL or local schema path, retrieval date, version when
   known, storage location, loading behavior, precedence, and supported fields.
4. Inspect the user's actual files. Resolve disagreements instead of choosing a
   convenient path. UI-only storage needs UI/export guidance, not invented files.
5. Apply the relevant conversion reference using existing agent tools. Where
   evidence is insufficient, preserve the reviewed source and describe the exact
   missing contract. Do not label the whole IDE unsupported or invent support.

If public lookup is unavailable or forbidden, say so and use only local evidence.
Never send usernames, private repository names, config values, or file contents
as search terms. Product/version/field names are normally sufficient.

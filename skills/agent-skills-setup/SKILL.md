---
name: agent-skills-setup
description: "Standardized instructions for installing, structuring, and configuring custom skills for Antigravity, Claude Code, OpenAI Codex, VS Code Copilot, Trae, and Trae CN. Use when creating or migrating skills between agents, or setting up global and project-level skill directories."
---

# Agent Skills Setup Guide

This skill provides standardized instructions on how to install, structure, and configure custom skills for various AI agents. It covers directory paths, file requirements, and triggering mechanisms for global and project scopes.

## 0. Source of Truth Rule

Unless the user explicitly requests otherwise, treat Antigravity as the canonical source:

- Antigravity global skills: `~/.gemini/antigravity/skills/`
- Mirror targets: Claude Code, OpenAI Codex, VS Code Copilot, Trae, Trae CN, and OpenClaw
- For directory-based agents, sync whole skill folders and remove extras not present in Antigravity
- For VS Code Copilot, flatten each `SKILL.md` into `~/.copilot-skills/<skill-name>.md`
- For Codex, preserve internal directories such as `.system/`
- For OpenClaw, sync whole skill folders into `~/.openclaw/skills/` for shared skills and into `<agent-workspace>/skills/` for per-agent overrides
- After changes, verify inventory parity and content parity rather than assuming the copy succeeded

## 1. Quick Reference: Skills Paths

| Agent              | Global Path                              | Project Path                  |
| :----------------- | :--------------------------------------- | :---------------------------- |
| **Antigravity**    | `~/.gemini/antigravity/skills/`          | `.agents/skills/`             |
| **Claude Code**    | `~/.claude/skills/`                      | `.claude/skills/`             |
| **OpenAI Codex**   | `~/.codex/skills/`                       | `.agents/skills/`             |
| **OpenClaw**       | `~/.openclaw/skills/` + `~/.openclaw/openclaw.json` | `<agent-workspace>/skills/` |
| **Trae**           | `~/.trae/skills/`                        | `./.trae/skills/`             |
| **Trae CN**        | `~/.trae-cn/skills/`                     | `./.trae/skills/`             |
| **VS Code Copilot**| `~/.copilot-skills/` + settings.json     | `.github/copilot-instructions.md` |

## 2. Universal Skill Structure

Regardless of the agent, every skill should follow this anatomy:

```text
<skill-name>/
├── SKILL.md (Required)
│   ├── YAML frontmatter (name, description)
│   └── Markdown instructions
├── scripts/ (Optional) - Executable automation
├── references/ (Optional) - Detailed docs and schemas
└── assets/ (Optional) - Templates and resources
```

## 3. Agent-Specific Deep Dives

For detailed configuration instructions, structure nuances, and UI requirements per agent, refer to:

- **Antigravity**: See [antigravity.md](references/antigravity.md)
- **Claude Code**: See [claude-code.md](references/claude-code.md)
- **OpenAI Codex**: See [codex.md](references/codex.md) (requires `agents/openai.yaml` for UI features)
- **OpenClaw**: See [openclaw.md](references/openclaw.md) (supports bundled/managed/workspace skills, per-agent workspaces, ClawHub, and installer metadata)
- **Trae / Trae CN**: See [trae.md](references/trae.md) (supports skills CLI and UI import)
- **VS Code Copilot**: See [vscode-copilot.md](references/vscode-copilot.md) (supports multiple configuration levels)
- **Public Distribution**: See [publishing.md](references/publishing.md) for GitHub, skills.sh, and Awesome Copilot release paths

## 4. Setup Workflow

When installing a new skill:

1. **Determine Scope**: Should this be Global (all projects) or Project-level (shared in repo)?
2. **Create Directory**: Navigate to the appropriate path above and create the `<skill-name>` folder.
3. **Draft SKILL.md**: Ensure the `description` is comprehensive, as it is the primary trigger for ALL agents.
4. **Agent-Specific Polish**: 
    - For OpenClaw, decide whether the skill belongs in shared `~/.openclaw/skills/` or an individual agent workspace `skills/` folder, and configure `skills.entries` / `agents.list` as needed
   - For Codex, add the `agents/openai.yaml` for UI visibility
   - For VS Code Copilot, add file reference to `settings.json`
   - For Trae, can use skills CLI or UI import

## 5. Recommended Maintenance Workflow

When updating a shared skill used across agents:

1. Edit the Antigravity copy first.
2. If needed, add or update helper scripts under `scripts/`.
3. Sync all target IDEs from Antigravity.
4. Verify:
    - directory inventories match for OpenClaw managed skills after sync
    - directory inventories match for Claude, Trae, and Trae CN
    - directory inventories match for Codex after excluding `.system/`
    - Copilot markdown files match Antigravity `SKILL.md` files
    - changed skills have matching content after sync
5. Only then report completion.

## 6. Sync Script

Use the bundled script for repeatable global sync operations:

```bash
~/.gemini/antigravity/skills/agent-skills-setup/scripts/sync-global-skills.sh
```

Examples:

```bash
# Sync all supported IDEs from Antigravity
~/.gemini/antigravity/skills/agent-skills-setup/scripts/sync-global-skills.sh

# Preview changes without modifying files
~/.gemini/antigravity/skills/agent-skills-setup/scripts/sync-global-skills.sh --dry-run

# Sync a subset of targets
~/.gemini/antigravity/skills/agent-skills-setup/scripts/sync-global-skills.sh --targets claude,codex,copilot,openclaw,trae,trae-cn
```

Behavior:

- Creates missing target directories
- Removes extra skills from mirror targets so they exactly match Antigravity
- Preserves Codex internal `.system/`
- Mirrors OpenClaw managed skills into `~/.openclaw/skills/`
- Rebuilds Copilot markdown files from Antigravity `SKILL.md`
- Prints a concise verification summary

## 6.1 OpenClaw Automation Helpers

Use the bundled OpenClaw helpers when you need first-class OpenClaw setup rather than a plain file copy:

```bash
# Install OpenClaw if needed, sync skills, install declared dependencies,
# and patch ~/.openclaw/openclaw.json for shared + per-agent skills
bash ~/.gemini/antigravity/skills/agent-skills-setup/scripts/auto-configure-openclaw-skills.sh \
    --scope both \
    --agent work:~/.openclaw/workspace-work \
    --default-agent work

# Update the OpenClaw runtime, registry-managed skills, and mirrored local skills
bash ~/.gemini/antigravity/skills/agent-skills-setup/scripts/update-openclaw-skills.sh
```

The auto-configure helper:

- installs OpenClaw via the official installer when missing
- installs ClawHub when missing
- syncs shared skills into `~/.openclaw/skills/`
- syncs per-agent overrides into each configured workspace `skills/` directory
- installs skill dependencies declared in `metadata.openclaw.install`
- writes `skills.load`, `skills.install`, `skills.entries`, and `agents.list` settings into `~/.openclaw/openclaw.json`
- supports `--skip-doctor` when you need a non-intrusive apply on a machine with an existing gateway service

The update helper:

- runs `openclaw update` for the runtime
- runs `clawhub update --all` for registry-managed workspace skills
- detects and applies local source-of-truth skill changes to shared/per-agent OpenClaw skill directories
- runs `openclaw doctor` after non-dry-run updates
- supports `--skip-doctor` for machine-safe update runs when zero gateway interaction is required

Use the ClawHub release helper when you want an exact publish command and metadata validation for a public OpenClaw release:

```bash
bash ~/.gemini/antigravity/skills/agent-skills-setup/scripts/prepare-clawhub-release.sh \
    --skill-dir ~/code/agent-skills-setup-public/agent-skills-setup \
    --slug agent-skills-setup \
    --name "Agent Skills Setup" \
    --version 1.0.0 \
    --tags latest,setup,openclaw
```

## 7. Migrating Skills Between Agents

### From Antigravity to All Other Agents

```bash
# === To Trae (International) ===
for dir in ~/.gemini/antigravity/skills/*/; do
    skill_name=$(basename "$dir")
    mkdir -p ~/.trae/skills/$skill_name
    cp -r "${dir}"* ~/.trae/skills/$skill_name/
done

# === To Trae CN (China) ===
for dir in ~/.gemini/antigravity/skills/*/; do
    skill_name=$(basename "$dir")
    mkdir -p ~/.trae-cn/skills/$skill_name
    cp -r "${dir}"* ~/.trae-cn/skills/$skill_name/
done

# === To VS Code Copilot ===
mkdir -p ~/.copilot-skills
for dir in ~/.gemini/antigravity/skills/*/; do
    skill_name=$(basename "$dir")
    if [ -f "${dir}SKILL.md" ]; then
        cp "${dir}SKILL.md" ~/.copilot-skills/${skill_name}.md
    fi
done
# Then add to settings.json (see vscode-copilot.md)

# === To Claude Code ===
for dir in ~/.gemini/antigravity/skills/*/; do
    skill_name=$(basename "$dir")
    mkdir -p ~/.claude/skills/$skill_name
    cp -r "${dir}"* ~/.claude/skills/$skill_name/
done

# === To OpenAI Codex ===
for dir in ~/.gemini/antigravity/skills/*/; do
    skill_name=$(basename "$dir")
    mkdir -p ~/.codex/skills/$skill_name
    cp -r "${dir}"* ~/.codex/skills/$skill_name/
done

# === To OpenClaw (shared / managed) ===
for dir in ~/.gemini/antigravity/skills/*/; do
    skill_name=$(basename "$dir")
    mkdir -p ~/.openclaw/skills/$skill_name
    cp -r "${dir}"* ~/.openclaw/skills/$skill_name/
done
```

### From Trae CN to Antigravity

```bash
for dir in ~/.trae-cn/skills/*/; do
    skill_name=$(basename "$dir")
    mkdir -p ~/.gemini/antigravity/skills/$skill_name
    cp -r "${dir}"* ~/.gemini/antigravity/skills/$skill_name/
done
```

## 8. Configuration Priority (All Agents)

| Priority | Level | Description |
|----------|-------|-------------|
| 1 (Highest) | Project | `./.trae/skills/`, `.agents/skills/`, `.github/copilot-instructions.md`, `<agent-workspace>/skills/` |
| 2 | Workspace | `.vscode/settings.json` (VS Code only) |
| 3 | Global/User | `~/.openclaw/skills/`, `~/.trae/skills/`, `~/.gemini/antigravity/skills/`, settings.json |
| 4 (Base) | Bundled | OpenClaw bundled skills and any other agent-managed built-ins |

## 9. Quick Migration Commands

### One-command migration to all agents

```bash
# Create all target directories
mkdir -p ~/.trae/skills ~/.trae-cn/skills ~/.copilot-skills ~/.claude/skills ~/.codex/skills ~/.openclaw/skills

# Copy to all agents
for dir in ~/.gemini/antigravity/skills/*/; do
    skill_name=$(basename "$dir")
    
    # Trae
    mkdir -p ~/.trae/skills/$skill_name && cp -r "${dir}"* ~/.trae/skills/$skill_name/
    
    # Trae CN
    mkdir -p ~/.trae-cn/skills/$skill_name && cp -r "${dir}"* ~/.trae-cn/skills/$skill_name/
    
    # VS Code Copilot (flat structure)
    [ -f "${dir}SKILL.md" ] && cp "${dir}SKILL.md" ~/.copilot-skills/${skill_name}.md
    
    # Claude Code
    mkdir -p ~/.claude/skills/$skill_name && cp -r "${dir}"* ~/.claude/skills/$skill_name/
    
    # OpenAI Codex
    mkdir -p ~/.codex/skills/$skill_name && cp -r "${dir}"* ~/.codex/skills/$skill_name/

    # OpenClaw managed skills
    mkdir -p ~/.openclaw/skills/$skill_name && cp -r "${dir}"* ~/.openclaw/skills/$skill_name/
done

echo "Migration complete! Don't forget to update VS Code settings.json"
```

## 10. Operational Notes

- Prefer `rsync -a --delete` over ad hoc copy loops when exact mirror behavior is required.
- Avoid destructive cleanup commands when a mirror sync can express the same intent more safely.
- If Trae international is not installed yet, creating `~/.trae/skills/` is sufficient for pre-seeding the directory.
- If a target contains system-managed content, add an explicit preserve rule before syncing.
- For OpenClaw multi-agent setups, remember that shared skills live in `~/.openclaw/skills/` while per-agent overrides live under each agent workspace `skills/` directory.
- OpenClaw skill env injection from `skills.entries.*.env` only applies to host runs; sandboxed agents need matching `agents.defaults.sandbox.docker.env` or `agents.list[].sandbox.docker.env` when a skill must execute inside the sandbox.

## 11. Public Release Workflow

If the goal is to publish a skill so more people can find and install it:

1. Keep the Antigravity copy as the authoring source.
2. Export the target skill into a public GitHub repository skeleton.
3. Add a repository README with install commands and compatibility notes.
4. Publish the repository publicly on GitHub.
5. Optionally increase discovery by:
     - listing or sharing it via `skills.sh`
     - contributing it to `github/awesome-copilot`
     - posting examples and screenshots in the repo README and release notes

Use the bundled export helper:

```bash
bash ~/.gemini/antigravity/skills/agent-skills-setup/scripts/export-public-skill.sh \
    --skill agent-skills-setup \
    --output ~/tmp/agent-skills-setup-public \
    --repo your-github-name/agent-skills-setup
```

The export helper copies the selected skill into a publishable repository layout and generates a starter `README.md`.

## 12. Publishability Criteria

Before publishing a skill publicly, verify that it:

- solves a specific problem rather than repeating generic model behavior
- does not depend on private local paths without documenting replacements
- includes clear install instructions for at least one agent ecosystem
- explains what the skill does, when to use it, and any safety boundaries
- avoids bundling sensitive credentials, internal URLs, or proprietary assets

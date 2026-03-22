---
name: agent-skills-setup
description: "Standardized instructions for installing, structuring, and configuring custom skills for Antigravity, Claude Code, OpenAI Codex, VS Code Copilot, Trae, and Trae CN. Use when creating or migrating skills between agents, or setting up global and project-level skill directories."
---

# Agent Skills Setup Guide

This skill provides standardized instructions on how to install, structure, and configure custom skills for various AI agents. It covers directory paths, file requirements, and triggering mechanisms for global and project scopes.

## 0. Source of Truth Rule

Unless the user explicitly requests otherwise, treat Antigravity as the canonical source:

- Antigravity global skills: `~/.gemini/antigravity/skills/`
- Mirror targets: Claude Code, OpenAI Codex, VS Code Copilot, Trae, and Trae CN
- For directory-based agents, sync whole skill folders and remove extras not present in Antigravity
- For VS Code Copilot, flatten each `SKILL.md` into `~/.copilot-skills/<skill-name>.md`
- For Codex, preserve internal directories such as `.system/`
- After changes, verify inventory parity and content parity rather than assuming the copy succeeded

## 1. Quick Reference: Skills Paths

| Agent              | Global Path                              | Project Path                  |
| :----------------- | :--------------------------------------- | :---------------------------- |
| **Antigravity**    | `~/.gemini/antigravity/skills/`          | `.agents/skills/`             |
| **Claude Code**    | `~/.claude/skills/`                      | `.claude/skills/`             |
| **OpenAI Codex**   | `~/.codex/skills/`                       | `.agents/skills/`             |
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
- **Trae / Trae CN**: See [trae.md](references/trae.md) (supports skills CLI and UI import)
- **VS Code Copilot**: See [vscode-copilot.md](references/vscode-copilot.md) (supports multiple configuration levels)
- **Public Distribution**: See [publishing.md](references/publishing.md) for GitHub, skills.sh, and Awesome Copilot release paths

## 4. Setup Workflow

When installing a new skill:

1. **Determine Scope**: Should this be Global (all projects) or Project-level (shared in repo)?
2. **Create Directory**: Navigate to the appropriate path above and create the `<skill-name>` folder.
3. **Draft SKILL.md**: Ensure the `description` is comprehensive, as it is the primary trigger for ALL agents.
4. **Agent-Specific Polish**: 
   - For Codex, add the `agents/openai.yaml` for UI visibility
   - For VS Code Copilot, add file reference to `settings.json`
   - For Trae, can use skills CLI or UI import

## 5. Recommended Maintenance Workflow

When updating a shared skill used across agents:

1. Edit the Antigravity copy first.
2. If needed, add or update helper scripts under `scripts/`.
3. Sync all target IDEs from Antigravity.
4. Verify:
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
~/.gemini/antigravity/skills/agent-skills-setup/scripts/sync-global-skills.sh --targets claude,codex,copilot,trae,trae-cn
```

Behavior:

- Creates missing target directories
- Removes extra skills from mirror targets so they exactly match Antigravity
- Preserves Codex internal `.system/`
- Rebuilds Copilot markdown files from Antigravity `SKILL.md`
- Prints a concise verification summary

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
| 1 (Highest) | Project | `./.trae/skills/`, `.agents/skills/`, `.github/copilot-instructions.md` |
| 2 | Workspace | `.vscode/settings.json` (VS Code only) |
| 3 (Base) | Global/User | `~/.trae/skills/`, `~/.gemini/antigravity/skills/`, settings.json |

## 9. Quick Migration Commands

### One-command migration to all agents

```bash
# Create all target directories
mkdir -p ~/.trae/skills ~/.trae-cn/skills ~/.copilot-skills ~/.claude/skills ~/.codex/skills

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
done

echo "Migration complete! Don't forget to update VS Code settings.json"
```

## 10. Operational Notes

- Prefer `rsync -a --delete` over ad hoc copy loops when exact mirror behavior is required.
- Avoid destructive cleanup commands when a mirror sync can express the same intent more safely.
- If Trae international is not installed yet, creating `~/.trae/skills/` is sufficient for pre-seeding the directory.
- If a target contains system-managed content, add an explicit preserve rule before syncing.

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

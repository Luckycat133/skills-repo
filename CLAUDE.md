# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Validation & Sync
- **Full repository validation**: `bash validate-all.sh` (runs bash syntax check, `scripts/validate_skills.py`, and root mirror sync check)
- **Check root `SKILL.md` mirror status**: `bash scripts/sync-root-mirror.sh --check`
- **Regenerate root `SKILL.md` mirror**: `bash scripts/sync-root-mirror.sh`

### Testing Suites
- **Validate IDE config paths against registry**: `bash skills/agent-skills-setup/scripts/verify-ide-config.sh`
- **Test IDE path schema drift**: `bash skills/agent-skills-setup/scripts/test-ide-paths.sh`
- **Migration & sync engine integration tests**: `bash skills/agent-skills-setup/scripts/test-migration.sh`
- **Full Smart IDE Migration tests**: `bash skills/agent-skills-setup/scripts/test-smart-ide-migration.sh`
- **Run single IDE mapping test**: `bash skills/agent-skills-setup/scripts/test-<ide>-mapping.sh` (e.g., `bash skills/agent-skills-setup/scripts/test-claude-code-mapping.sh`, `bash skills/agent-skills-setup/scripts/test-cursor-mapping.sh`)
- **Test MCP secret redaction**: `bash skills/agent-skills-setup/scripts/test-mcp-secret-redaction.sh`

### Installation & Operations
- **Install skills to default target (`~/.agents/skills`)**: `bash install.sh`
- **Install specific skill / custom target**: `bash install.sh --skill <name> --target <dir> [--force]`
- **Sync to Codex environment**: `bash sync-to-codex.sh`
- **Sync to OpenClaw environment**: `bash sync-to-openclaw.sh`
- **Import external skill**: `bash scripts/import-agent-skill.sh <source-dir> <skill-name>`

## Architecture

This repository is the canonical source of truth for authoring, testing, and distributing reusable AI Assistant Capabilities (skills) across 40 IDEs and AI agent environments (Copilot, Cursor, Windsurf, JetBrains, Claude Code, Claude Desktop, Codex, OpenClaw, Trae, Trae CN, Antigravity, Kimi AI, Amazon Q, Gemini CLI, Zed, VS Code, Goose CLI, OpenCode, Continue, Roo Code, Cline, Kilo Code, Kiro, Augment Code, Baidu Comate, Tencent CodeBuddy, ZCode, Void Editor, Aider, Tabnine, Replit, Blackbox, Neovim, Emacs, Cody, Supermaven, Codeium, PearAI, Pieces).

### Canonical Source & Mirror Pipeline
- **Canonical Skill Location**: `skills/agent-skills-setup/` contains the maintained `SKILL.md`, `references/`, `scripts/`, and `assets/`.
- **Root Mirror**: The top-level `SKILL.md` is a generated mirror required by platforms like Smithery.ai. Never edit root `SKILL.md` directly; edit `skills/agent-skills-setup/SKILL.md` and run `bash scripts/sync-root-mirror.sh`.

### Cross-IDE Migration & Synchronization Engine
- `skills/agent-skills-setup/scripts/smart-ide-migration.sh`: Core engine orchestrating migration across IDE ecosystems. Handles 5 asset categories: capabilities/skills, prompts, configurations, rules, and workflows.
- `skills/agent-skills-setup/references/ide-registry.md` & `references/ide-paths.json`: Define canonical path specifications and feature support matrix for all targeted IDEs.
- `sync-global-skills.sh`: Handles cross-agent global skill folder synchronization.
- `auto-configure-openclaw-skills.sh`: Automates OpenClaw configuration and capability binding.

### Validation & Security Rules
- `scripts/validate_skills.py`: Enforces skill structure, YAML frontmatter syntax, internal relative link integrity, and scans files for hardcoded secrets or absolute private system paths.

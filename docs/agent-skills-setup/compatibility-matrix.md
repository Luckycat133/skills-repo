# Compatibility & Migration Matrix

This document provides a comprehensive overview of AI coding tools, IDEs, and profiles supported by **Agent Context Migrator** (Registry v2).

---

## 🎯 Top Supported AI Coding Tools

| Tool / IDE | Profile Selector | Skills | Rules / Instructions | Local stdio MCP | Migration Policy |
|---|---|:---:|:---:|:---:|---|
| **Cursor** | `cursor/ide` | ✅ | ✅ (`.cursorrules`, `.cursor/rules`) | ✅ (`~/.cursor/mcp.json`) | `bidirectional-reviewed` |
| **Claude Code** | `claude/code-cli` | ✅ | ✅ (`CLAUDE.md`) | ✅ (`~/.claude.json`) | `bidirectional-reviewed` |
| **OpenAI Codex** | `codex/cli` | ✅ | ✅ (`AGENTS.md`) | ✅ (`~/.agents/mcp.json`) | `bidirectional-reviewed` |
| **Cline** | `cline/ide` | ✅ | ✅ (`.clinerules`) | ✅ (`cline_mcp_settings.json`) | `bidirectional-reviewed` |
| **Windsurf** | `windsurf/ide` | ✅ | ✅ (`.windsurfrules`) | ✅ (`mcp_config.json`) | `bidirectional-reviewed` |
| **GitHub Copilot** | `copilot/vscode` | ✅ | ✅ (`.github/copilot-instructions.md`) | ✅ (`copilot-mcp.json`) | `bidirectional-reviewed` |
| **Gemini CLI** | `gemini-cli/cli` | ✅ | ✅ (`GEMINI.md`) | ✅ (`settings.json:mcpServers`) | `bidirectional-reviewed` |
| **Continue.dev** | `continue/cli` | ✅ | ✅ (`.prompts`, rules) | ✅ (`config.json`) | `bidirectional-reviewed` |
| **Zed Editor** | `zed/ide` | ✅ | ✅ (Rules) | ✅ (`settings.json`) | `bidirectional-reviewed` |
| **TRAE** | `trae/ide` | ✅ | ✅ (`.traerules`) | ✅ (`mcp.json`) | `bidirectional-reviewed` |
| **Qoder** | `qoder/ide` | ✅ | ✅ (`.qoderrules`) | ✅ (`qoder_mcp.json`) | `bidirectional-reviewed` |
| **Augment Code** | `augment-code/cli-ide` | ✅ | ✅ (`.augmentrules`) | ✅ (`settings.json:mcpServers`) | `bidirectional-reviewed` |
| **OpenCode** | `opencode/cli` | ✅ | ✅ (Rules) | ✅ (`mcp.servers`) | `bidirectional-reviewed` |
| **OpenHands** | `openhands/cli` | ✅ | ✅ (Rules) | ✅ (`openhands-mcp.json`) | `bidirectional-reviewed` |
| **Devin** | `devin/terminal` | ✅ | ✅ (Instructions) | ✅ (`mcp.json`) | `bidirectional-reviewed` |
| **ForgeCode** | `forge/cli` | ✅ | ✅ (Rules) | ✅ (`mcp.json`) | `bidirectional-reviewed` |

---

## 🧭 Common Migration Workflows

### 1. Cursor to Claude Code
```bash
# Migrate Skills, Rules (.cursorrules -> CLAUDE.md), and stdio MCP
bash scripts/smart-ide-migration.sh migrate \
  --source cursor/ide \
  --target claude/code-cli \
  --workspace . \
  --objects all-portable \
  --yes
```

### 2. Cursor to OpenAI Codex
```bash
# Migrate Skills and Rules (.cursorrules -> AGENTS.md)
bash scripts/smart-ide-migration.sh migrate \
  --source cursor/ide \
  --target codex/cli \
  --workspace . \
  --objects all-portable \
  --yes
```

### 3. Cline to Windsurf
```bash
# Migrate Skills, Rules (.clinerules -> .windsurfrules), and MCP
bash scripts/smart-ide-migration.sh migrate \
  --source cline/ide \
  --target windsurf/ide \
  --workspace . \
  --objects all-portable \
  --yes
```

### 4. Computer Switching (Multi-IDE Backup & Restore)
```bash
# On Old Computer: Snapshot all installed tools into a portable bundle
python3 skills/agent-skills-setup/scripts/context-migrator.py snapshot \
  --all-installed \
  --output ~/my-dev-setup.acb

# On New Computer: Restore the bundle to newly installed target IDEs
python3 skills/agent-skills-setup/scripts/context-migrator.py restore \
  ~/my-dev-setup.acb \
  --all-installed \
  --yes
```

---

## 🛡️ Migration Policy Taxonomy

- **`bidirectional-reviewed`**: Full two-way automatic conversion supported with pre-apply review, secret redaction, and rollback.
- **`manual-template`**: Generates concrete format templates for user review; does not overwrite live tool configurations automatically.
- **`official-api-or-rebuild-checklist`**: For cloud-managed and UI-only platforms (e.g. Claude Desktop app connectors, GitHub.com Copilot UI). Emits safe step-by-step checklist without writing unverified files.
- **`source-only`**: Legacy or read-only tools that can be captured as sources but not targeted for writes.

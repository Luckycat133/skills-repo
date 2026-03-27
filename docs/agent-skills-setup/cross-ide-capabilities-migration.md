# Cross-IDE AI Assistant Capabilities Migration Guide

This guide expands migration scope from skills-only to a complete AI Assistant Capabilities model:

- Capabilities (formerly skills)
- Prompts
- Configurations
- Rules
- Workflows
- Related automation surfaces: agents and hooks

中文说明：本指南把迁移范围从仅 skills 扩展到完整 AI Assistant Capabilities，包括能力模块、提示词、配置、规则、工作流，以及相关的 agents/hooks 自动化面。

## 1. Terminology and Compatibility

Preferred term:

- AI Assistant Capabilities

Compatibility term:

- Capabilities (formerly skills)

Why this naming strategy works:

- It keeps public language professional and cross-platform.
- It avoids breaking existing path conventions and marketplace slugs that still use skill naming.

## 2. Mainstream IDE Coverage

This implementation now covers these mainstream AI IDE ecosystems:

1. VS Code + GitHub Copilot
2. Cursor
3. Windsurf
4. JetBrains (AI capability staging profile)
5. Claude Code
6. OpenAI Codex
7. OpenClaw
8. Trae
9. Trae CN

## 3. Migration Objects and Platform Mapping

| Object | Copilot | Cursor | Windsurf | JetBrains | Claude | Codex | OpenClaw | Trae | Trae CN |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Capabilities | .github/skills | .cursor/skills | .windsurf/skills | .idea/ai-capabilities/skills | .claude/skills | .agents/skills | skills (workspace), ~/.openclaw/skills | .trae/skills | .trae-cn/skills |
| Prompts | .github/prompts | .cursor/prompts | .windsurf/prompts | .idea/ai-capabilities/prompts | .claude/prompts | .codex/prompts | openclaw/prompts | .trae/prompts | .trae-cn/prompts |
| Configurations | .vscode/copilot-config | .cursor/config | .windsurf/config | .idea/ai-capabilities/config | .claude/config + settings | .codex/config | openclaw/config + openclaw.json | .trae/config | .trae-cn/config |
| Rules | .github/instructions | .cursor/rules | .windsurf/rules | .idea/ai-capabilities/rules | .claude/rules + CLAUDE.md | .codex/rules + AGENTS.md | openclaw/rules + config policy | .trae/rules | .trae-cn/rules |
| Workflows | .github/workflows/ai | .cursor/workflows | .windsurf/workflows | .idea/ai-capabilities/workflows | .claude/workflows | .codex/workflows | openclaw/workflows | .trae/workflows | .trae-cn/workflows |
| Hooks | .github/hooks | .cursor/hooks | .windsurf/hooks | .idea/ai-capabilities/hooks | .claude/hooks | .codex/hooks | openclaw/hooks | .trae/hooks | .trae-cn/hooks |

Note:

- Some prompt/config/rules/workflow locations are platform-native, while others are team conventions for portability.
- Use the validation section to separate hard requirements from convention-level assets.

## 4. Preconditions

Before migration:

1. Ensure source capability pack is complete and versioned.
2. Ensure target IDE versions support required customization types.
3. Install required tooling:
   - bash
   - rsync
   - jq (recommended for JSON validation)
4. Ensure destination workspace is writable.
5. Decide conflict strategy:
   - skip
   - overwrite
   - backup (recommended)

## 5. Safe Migration Mode (No-Break Default)

To avoid configuration breakage, migration uses a safe default:

1. `--write-mode staging` (default): writes to `.migration-targets/<platform>/...`
2. `--write-mode direct`: writes to live workspace paths
3. Missing selected objects fail the run by default (fail-fast correctness gate)

Recommended production flow:

1. Run migration in `staging` mode.
2. Run strict validation.
3. Diff and review.
4. Promote selected files into live paths.

If you intentionally migrate only a subset and want soft behavior, use:

```bash
--allow-missing-objects
```

## 6. Automated Migration (Implemented)

Two scripts are provided:

1. scripts/migrate-ai-capabilities.sh
2. scripts/validate-capability-migration.sh

### 6.1 Migrate command

```bash
bash skills/agent-skills-setup/scripts/migrate-ai-capabilities.sh \
  --source ./capability-pack \
  --platforms copilot,cursor,windsurf,jetbrains,claude,codex,openclaw,trae,trae-cn \
  --workspace-root ./migration-out \
  --strategy backup \
  --write-mode staging
```

Dry-run example:

```bash
bash skills/agent-skills-setup/scripts/migrate-ai-capabilities.sh \
  --source ./capability-pack \
  --platforms codex,openclaw \
  --objects capabilities,configurations,rules \
  --dry-run
```

Direct-write example (only after staging review):

```bash
bash skills/agent-skills-setup/scripts/migrate-ai-capabilities.sh \
  --source ./capability-pack \
  --platforms copilot,claude,codex \
  --workspace-root . \
  --strategy backup \
  --write-mode direct
```

### 6.2 Validate command

```bash
bash skills/agent-skills-setup/scripts/validate-capability-migration.sh \
  --root ./migration-out
```

Strict validation:

```bash
bash skills/agent-skills-setup/scripts/validate-capability-migration.sh \
  --root ./migration-out \
  --strict
```

## 7. Migration Procedures by Object Type

### 7.1 Capabilities

Steps:

1. Copy capability folders.
2. Verify frontmatter in SKILL.md (name, description).
3. Verify scripts and references are included.

Potential issues:

- Missing SKILL.md
- Broken relative links inside capability docs

Fix:

- Rebuild frontmatter.
- Normalize relative paths to capability root.

Verification:

- SKILL.md checks pass in validation script.

### 7.2 Prompts

Steps:

1. Copy *.prompt.md or prompt markdown files.
2. Keep frontmatter when used by VS Code prompt files.
3. Map prompt naming to slash-command friendly format.

Potential issues:

- Prompt files without description/argument hints
- Prompt tools incompatible with target IDE tool names

Fix:

- Add/normalize frontmatter.
- Replace platform-specific tool references.

Verification:

- Prompt files discoverable in target IDE prompt UI.

### 7.3 Configurations

Steps:

1. Stage config files into platform config directories.
2. Keep machine-local secrets out of shared config.
3. Apply patch strategy instead of direct overwrite for live configs.

Potential issues:

- Invalid JSON/JSON5/TOML
- Environment-specific absolute paths

Fix:

- Parse with validators before applying.
- Parameterize paths and secrets via env variables.

Verification:

- Config parse succeeds.
- IDE runtime starts without config errors.

### 7.4 Rules

Steps:

1. Migrate instruction/rule files to platform rule locations.
2. Keep rule scopes explicit (glob/path-based).
3. For Codex .rules, validate prefix_rule behavior.

Potential issues:

- Conflicting rules between user and project scopes
- Overly broad deny rules blocking normal workflows

Fix:

- Tighten glob/path matchers.
- Add rule-level test examples and decision rationales.

Verification:

- Rule files non-empty and parse-safe.
- Sample commands hit intended policy decisions.

### 7.5 Workflows

Steps:

1. Migrate workflow markdown/spec files.
2. Keep frontmatter complete (name, description).
3. Align workflow outputs with target automation surface.

Potential issues:

- Missing metadata causing workflow discovery failure
- Workflow assumes unavailable tools/models

Fix:

- Add fallback models and tool checks.
- Declare prerequisites near workflow headers.

Verification:

- Workflow loads and executes in target environment.

## 8. Quality Standard and Real Validation

Required quality gates:

1. Official-source-backed mapping for every supported platform.
2. Script-level dry-run and apply-mode validation.
3. At least three end-to-end migration paths tested.
4. Documentation includes prerequisites, execution, risk, fix, verification.
5. No secrets or private local paths in publishable content.
6. Staging migration output passes strict validation before any direct-write rollout.

Recommended E2E matrix:

1. Codex -> Copilot
2. Claude Code -> OpenClaw
3. Copilot -> Codex

## 9. Publishing and Distribution Requirements

## 9.1 GitHub canonical source

Checklist:

1. Include migration guide and scripts.
2. Include changelog entries.
3. Include usage examples.
4. Include maintenance ownership notes.

## 9.2 ClawHub

Use release helper and inspect visibility after security scan.

## 9.3 skills.sh and awesome-copilot

Prepare submission package with:

1. concise capability description
2. install instructions
3. validation evidence
4. maintenance owner and update cadence

## 10. Maintenance Guide

After publication:

1. Keep compatibility naming stable.
2. Version migration scripts independently when behavior changes.
3. Re-run validation after platform updates.
4. Track deprecations of config fields and migration paths.
5. Keep source-of-truth mapping tables updated with official docs.

## 11. Implementation Status in This Repo

Implemented now:

- migrate-ai-capabilities.sh
- validate-capability-migration.sh
- this cross-IDE migration guide

Next recommended rollout:

1. Add a sample capability-pack fixture for CI testing.
2. Add matrix smoke tests in release checklist.
3. Add publication templates for skills.sh and awesome-copilot submissions.

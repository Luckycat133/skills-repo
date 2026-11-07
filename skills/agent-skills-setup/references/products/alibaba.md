# Qwen Code, Qoder and Lingma

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## qwen-code

**Qwen Code CLI and its IDE/desktop integrations** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory QWEN.md/memory, scoped rules, Skills, TOML/custom commands, subagents, hooks, extensions/plugins, MCP, output styles and policies. Skills can come from `.qwen/skills`, `~/.qwen/skills`, shared `.agents` roots, explicit directories or extensions. Native Qwen roots have precedence over shared roots; extra directories configured in settings retain their documented scope.

Qwen's documented Skill field is **`allowedTools`**; a generic `allowed-tools` field can be ignored. Do not claim permission preservation after a textual copy. Hook types and lifecycle contracts include command/HTTP/function/prompt variants; exporting a Skill with a hook can export executable behavior. Auto-Skill/generated archived Skills are not automatically user-authored.

Agent Plugins/Qoder plugin compatibility is component-specific: retain namespace, command/agent/Skill identity and MCP settings, but inspect each target field. Shared `settings.json` is exported only by selected subobject. Check actual Skill loader and tool policy, not frontmatter parsing alone.

Official sources: [1](https://qwenlm.github.io/qwen-code-docs/en/users/features/skills/) · [2](https://qwenlm.github.io/qwen-code-docs/en/users/features/rules/) · [3](https://qwenlm.github.io/qwen-code-docs/en/users/features/hooks/) · [4](https://qwenlm.github.io/qwen-code-docs/en/)

## qoder

**Qoder International IDE, CLI, JetBrains, Work, cloud and Wake** · Evidence: `documented-subset` · Runtime: `not-run`.

Identify the exact product in the Qoder family before interpreting paths. CLI settings use user `~/.qoder/settings.json`, project `.qoder/settings.json` and local `.qoder/settings.local.json`; this does not establish Work/Wake/cloud UI storage.

Inventory rules, Skills, commands, custom agents/Experts, hooks, MCP, plugins and memory/Quest artifacts. Current plugins can bundle rules, Skills, agents, commands, hooks and MCP. Preserve component namespaces and selected scopes. Quest/spec outputs and autonomous task state are not persistent instructions by default.

For CLI, patch only selected settings subobjects; do not carry local grants into a shared project file. For IDE/Work/cloud, use the product's native customization view to resolve storage and import behavior. Check the chosen profile loads the new rule/Skill and that no compatibility copy shadows it.

Official sources: [1](https://docs.qoder.com/product-series/what-is-qoder) · [2](https://docs.qoder.com/cli/config-scope) · [3](https://docs.qoder.com/extensions/plugins) · [4](https://docs.qoder.com/qoder/custom-agents)

## qoder-cn

**Qoder CN / Tongyi Lingma** · Evidence: `version-sensitive` · Runtime: `not-run`.

The brand rename does not imply all directories changed. Current CN IDE documentation still specifies `.lingma/skills` and `~/.lingma/skills`; compatibility with `.agents/skills` is version-dependent. Do not replace these with International CLI paths.

Inventory CN IDE versus CN CLI separately: Skills/rules/MCP/plugins, custom agents, prompts, memory and task artifacts. Work/cloud profiles also require their own settings evidence. This review does not establish a single CN CLI/global path; use its active configuration/help and version rather than infer it from `qoder` or `lingma`.

Migrate selected authored definitions into the destination's actual native format. Preserve the original path/provenance in the transfer note, and detect duplicate names across old/new/shared roots. Native discovery on the chosen CN build is a required pending test.

Official sources: [1](https://docs.qoder.cn/user-guide/skills) · [2](https://docs.qoder.cn/user-guide/what-is-qoder-cn) · [3](https://help.aliyun.com/zh/lingma/qoder-cn-update-log)

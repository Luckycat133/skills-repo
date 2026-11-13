# Chinese coding agents: versioned native surfaces

Documentation review: 2026-11-07. **Client/runtime checks: not run.**
Read only the relevant profile below. Paths are discovery candidates, not permission
to scan or overwrite them. Apply the [catalog contract](../products.md) and record
the installed version, OS, active harness and path overrides before changing files.

## comate

**Baidu Comate IDE plugins and standalone IDE** · Evidence: `documented-subset` · Runtime: `not-run`.

Current Baidu docs/release notes describe Skills, Rules, Memory, custom agents/subagents, MCP, Spec/Mission and command/context features. Do not reduce Comate to Skills+MCP or classify every Memory item as user-authored.

Select standalone IDE versus VS Code/JetBrains plugin and verify their installed releases. Project Skills/rules and `.comateignore` are not an authorization to copy the full application directory. Exact user/profile MCP/rule storage must be resolved through native settings when the public page does not specify it.

Translate rules by activation and scope; preserve authored Specs as task documents, not always-on policy. Check Skill/rule discovery and negative scope examples. Keep generated Memory, indexes, credentials and task history out of the default transfer.

Official sources: [1](https://cloud.baidu.com/doc/COMATE/s/qm7yrpa11) · [2](https://cloud.baidu.com/doc/COMATE/s/Qlup6nu65) · [3](https://cloud.baidu.com/doc/COMATE/s/Nmpe5edyb)

## kimi-code

**Kimi Code current CLI and IDE/ACP use** · Evidence: `version-sensitive` · Runtime: `not-run`.

Current data-location docs use `~/.kimi-code`, overridden by `KIMI_CODE_HOME`; older `~/.kimi` belongs to earlier builds. Current files include `config.toml`, `tui.toml`, `AGENTS.md`, `mcp.json`, Skills and plugin records; project MCP can use `.kimi-code/mcp.json`. Shared `~/.agents/skills` is not relocated by KIMI_CODE_HOME.

Inventory Skills and explicit extra directories, AGENTS, MCP, plugins/commands, agents and hooks supported by the actual build. Do not copy sessions or provider/auth config. For ACP, the agent's actual remote/local execution home is authoritative.

Check paths with the installed version and override environment. Preserve native MCP transports and rebind auth. A generic skill installer still using `~/.kimi` is weaker evidence than the vendor's current data-location contract.

Official sources: [1](https://moonshotai.github.io/kimi-code/en/configuration/data-locations.html) · [2](https://moonshotai.github.io/kimi-code/en/customization/skills) · [3](https://moonshotai.github.io/kimi-code/en/customization/mcp) · [4](https://moonshotai.github.io/kimi-code/en/guides/ides)

## zcode

**Z.ai ZCode** · Evidence: `documented-subset` · Runtime: `not-run`.

Inventory Skills, rules/AGENTS, commands, agents, hooks, plugins, MCP, wiki/memory and automations separately. Current user Skills include `~/.zcode/skills`; plugin Skills have their own flat discovery constraints and are not automatically supplied to every subagent. Check the documented body-size limit before transferring a very large Skill.

MCP precedence is important: native `.zcode` configuration can suppress shared `.agents/mcp.json` at the scope level, not simply merge each server name. Inspect the active native configuration before adding a shared file.

Current plugin documentation uses root `plugin.json`; older `.zcode-plugin` layouts need version matching. Move only supported components and preserve namespace/activation. Check active server enumeration and Skill visibility in the intended main agent/subagent; parsing both files does not establish which wins.

Official sources: [1](https://zcode.z.ai/en/docs/skill) · [2](https://zcode.z.ai/en/docs/mcp-services) · [3](https://zcode.z.ai/en/docs/plugin)

## minimax-code

**MiniMax Code CLI and separately identified desktop/cloud products** · Evidence: `documented-subset` · Runtime: `not-run`.

The official MiniMax-AI/minimax-code project now documents a local coding CLI; do not keep the old blanket classification of MiniMax Code as cloud/UI-only. Inspect its version and profile-specific home (`~/.minimax` or a named profile root), workspace instructions, Skills, MCP and reviewed memory.

CLI auth/provider configuration is not portable context. Desktop/cloud offerings with similar names must be separately identified before using CLI paths. Check official README/configuration and the actual client's discovery output, then prepare selected files and dependency/re-auth notes. Do not assume all terminal-agent commands, hooks or plugins exist merely because the CLI supports Skills.

Official sources: [1](https://github.com/MiniMax-AI/minimax-code)

## mmx-cli

**MiniMax multimedia/service CLI** · Evidence: `provider-or-installer` · Runtime: `not-run`.

`MiniMax-AI/cli` is a service/media tool and may install Skills for other agent clients. It is not evidence of a second coding-agent home or native instructions/MCP client contract.

Inventory only user-selected tool definitions, published Skill packages or command recipes. Treat API host/region/key configuration as service setup; keep credential values out. Route installed Skills to their actual consuming agent profile. Verify the package with that host, not by the existence of an mmx configuration file.

Official sources: [1](https://github.com/MiniMax-AI/cli)

## codely

**Tuanjie Codely IDE and Codely CLI** · Evidence: `documented-subset` · Runtime: `not-run`.

Use Tuanjie's official Codely documentation, not unrelated CodelyTV training material. Current CLI customization covers `.codely-cli/skills`, user Skills, CODELY.md/rules, commands, subagents, MCP and settings with user/project precedence.

Inventory engine-specific context such as Unity Insight/Codely Context separately from authored instructions. CLI and IDE use different invocation/context conventions; consult the migration guide rather than assume every `@` reference transfers unchanged. MCP merging is documented, but imported permissions and session data are not portable.

Check the actual Tuanjie build and native customization view. Inspect all referenced resources and command parameters; preserve project engine context as selected documentation, not an entire editor cache or scene database.

Official sources: [1](https://codely-docs.tuanjie.cn/guides/customization/) · [2](https://codely-docs.tuanjie.cn/guides/migration/) · [3](https://codely-docs.tuanjie.cn/features-introduction/MCP-guide/)

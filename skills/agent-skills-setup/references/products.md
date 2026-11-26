# Product and context reference index

Review date: **2026-11-07**. **Real-client tests: `not-run` (not run).** This catalog routes
all 90 canonical profile IDs, all 87 historical identifiers, and 25 additional names/aliases
to **90 standalone per-product reference files** (`references/products/<id>.md`). Do **not**
load every product file: locate only the requested source and target below and read those
two files (`products/<source>.md` and `products/<target>.md`).

## Evidence contract

- `documented-subset`: current primary vendor docs establish the described subset.
- `version-sensitive`: major versions, redirects, or official path disagreements require
  matching the installed version/harness before writing.
- `discovery-required`: vendor identity is known, but complete local file contracts are
  unverified; inspect the installed UI/schema rather than guessing paths.
- `legacy-source`: archived or sunset upstream; extract reviewed source content only.
- `host-only` / `provider-or-installer`: editor host, memory provider, or installer;
  route to the actual consuming agent plugin/harness.

**None means runtime-verified.** Candidate paths in `products/*.md` are bounded lookup
locations, not permission to scan unrelated directories or overwrite files blindly. Use
`scripts/migrate_context.py` (`migrate` for built-in profiles, `patch-mcp` for any
JSON/JSONC/TOML MCP map) so secrets move out-of-band (`0600`) without entering LLM context.

## Inventory completeness (for full-context requests)

Record `present`, `absent`, `unknown`, or `not applicable with evidence` across:
`instructions`, `skills`, `prompts`, `commands`, `agents`, `hooks`, `workflows`, `mcp`,
`authored-memory-knowledge`, `plugins-extensions`, and `settings-policy-trust`. Record
origin, scope (`user`/`project`/`local`/`managed`/`cloud`), activation, precedence, and
destination. Exclude chat histories, databases, caches, OAuth tokens, and trust grants.

## Routing

| Canonical ID & aliases | Read this profile | Evidence |
| --- | --- | --- |
| `claude-code`, `claude` | [Claude Code CLI, IDE integration, Desktop Code](products/claude-code.md) | documented-subset |
| `claude-desktop` | [Claude Desktop Chat, web Projects and Cowork](products/claude-desktop.md) | discovery-required |
| `codex` | [Codex CLI, local IDE integration and app](products/codex.md) | documented-subset |
| `openai-plugin`, `chatgpt-plugins` | [OpenAI/ChatGPT plugin packages and cloud workspace context](products/openai-plugin.md) | documented-subset |
| `cursor` | [Cursor IDE, CLI and cloud agents](products/cursor.md) | documented-subset |
| `vscode` | [VS Code: Copilot, Local, Claude and Codex harnesses](products/vscode.md) | documented-subset |
| `copilot-cli`, `copilot`, `copilot-app` | [GitHub Copilot CLI and Copilot app](products/copilot-cli.md) | documented-subset |
| `copilot-other-hosts`, `visual-studio`, `copilot-jetbrains`, `copilot-eclipse`, `copilot-xcode`, `copilot-cloud` | [Visual Studio, JetBrains, Eclipse, Xcode and GitHub cloud coding agent](products/copilot-other-hosts.md) | documented-subset |
| `gemini-cli` | [Gemini CLI and its ACP/IDE integration](products/gemini-cli.md) | documented-subset |
| `gemini-code-assist` | [Gemini Code Assist VS Code, JetBrains and enterprise](products/gemini-code-assist.md) | documented-subset |
| `android-studio` | [Gemini in Android Studio](products/android-studio.md) | documented-subset |
| `antigravity` | [Antigravity IDE, App and CLI](products/antigravity.md) | documented-subset |
| `firebase-studio` | [Firebase Studio / former IDX](products/firebase-studio.md) | documented-subset |
| `jules` | [Google Jules cloud, Tools CLI and API](products/jules.md) | documented-subset |
| `cline` | [Cline IDE, CLI and SDK](products/cline.md) | documented-subset |
| `kilocode` | [Kilo IDE and CLI](products/kilocode.md) | documented-subset |
| `roo-code` | [Roo Code archived upstream; installed forks remain version-specific](products/roo-code.md) | legacy-source |
| `windsurf`, `codeium` | [Windsurf / legacy Cascade and Devin Desktop transition](products/windsurf.md) | version-sensitive |
| `devin` | [Devin CLI, Desktop Local and Cloud](products/devin.md) | documented-subset |
| `continue` | [Continue IDE extension and cn CLI](products/continue.md) | documented-subset |
| `zed` | [Zed native agent versus external ACP agent](products/zed.md) | documented-subset |
| `junie`, `jetbrains` | [Junie IDE and CLI](products/junie.md) | documented-subset |
| `jetbrains-ai`, `jetbrains-air` | [JetBrains AI Assistant, external ACP agents and Air](products/jetbrains-ai.md) | documented-subset |
| `xcode` | [Xcode Coding Intelligence and external-agent bridge](products/xcode.md) | documented-subset |
| `kiro`, `kiro-crew` | [Kiro IDE, CLI, web/mobile and Crew](products/kiro.md) | version-sensitive |
| `amazon-q` | [Amazon Q Developer IDE and legacy/current CLI profiles](products/amazon-q.md) | version-sensitive |
| `qwen-code` | [Qwen Code CLI and its IDE/desktop integrations](products/qwen-code.md) | documented-subset |
| `qoder`, `qoder-work`, `qoder-wake` | [Qoder International IDE, CLI, JetBrains, Work, cloud and Wake](products/qoder.md) | documented-subset |
| `qoder-cn`, `tongyi-lingma` | [Qoder CN / Tongyi Lingma](products/qoder-cn.md) | version-sensitive |
| `codebuddy`, `tencent-codebuddy` | [CodeBuddy Code CLI](products/codebuddy.md) | documented-subset |
| `codebuddy-ide`, `tencent-codebuddy-ide` | [CodeBuddy IDE and IDE plugins](products/codebuddy-ide.md) | documented-subset |
| `workbuddy` | [WorkBuddy desktop/workspace](products/workbuddy.md) | documented-subset |
| `trae-cn` | [TRAE China IDE](products/trae-cn.md) | documented-subset |
| `trae`, `trae-agent` | [TRAE International IDE and TRAE Agent CLI](products/trae.md) | discovery-required |
| `trae-work` | [TRAE Work](products/trae-work.md) | documented-subset |
| `comate`, `baidu-comate`, `baidu-comate-ide` | [Baidu Comate IDE plugins and standalone IDE](products/comate.md) | documented-subset |
| `kimi-code`, `kimiai` | [Kimi Code current CLI and IDE/ACP use](products/kimi-code.md) | version-sensitive |
| `zcode` | [Z.ai ZCode](products/zcode.md) | documented-subset |
| `minimax-code` | [MiniMax Code CLI and separately identified desktop/cloud products](products/minimax-code.md) | documented-subset |
| `mmx-cli` | [MiniMax multimedia/service CLI](products/mmx-cli.md) | provider-or-installer |
| `codely` | [Tuanjie Codely IDE and Codely CLI](products/codely.md) | documented-subset |
| `iflycode` | [iFlyCode / iFlytek coding assistant](products/iflycode.md) | discovery-required |
| `raccoon-ai` | [SenseTime coding Raccoon, not unrelated Raccoon products](products/raccoon-ai.md) | discovery-required |
| `vecli`, `ark-cli` | [Volcengine veCLI; distinguish Ark CLI and service CLIs](products/vecli.md) | discovery-required |
| `mistral-vibe`, `vibe-work` | [Mistral Vibe Code and Vibe Work](products/mistral-vibe.md) | documented-subset |
| `forge` | [ForgeCode, not another Forge product](products/forge.md) | version-sensitive |
| `aider` | [Aider](products/aider.md) | documented-subset |
| `pi` | [Pi coding agent](products/pi.md) | version-sensitive |
| `crush` | [Charm Crush](products/crush.md) | documented-subset |
| `goose`, `goose-cli` | [Goose CLI and Desktop](products/goose.md) | documented-subset |
| `factory-droid` | [Factory Droid CLI, desktop and cloud](products/factory-droid.md) | documented-subset |
| `augment-code`, `augment-cosmos` | [Auggie CLI, Augment IDE and Cosmos](products/augment-code.md) | documented-subset |
| `amp`, `sourcegraph-amp` | [Amp CLI/editor/cloud surfaces](products/amp.md) | documented-subset |
| `openhands` | [OpenHands local CLI, SDK, hosted app and agent canvas](products/openhands.md) | documented-subset |
| `opencode` | [OpenCode V1 and V2](products/opencode.md) | version-sensitive |
| `warp` | [Warp Desktop and Warp Drive](products/warp.md) | documented-subset |
| `warp-oz` | [Oz CLI, cloud runtime and SDK/API](products/warp-oz.md) | documented-subset |
| `openclaw` | [OpenClaw Gateway, workspace agents and node hosts](products/openclaw.md) | documented-subset |
| `hermes` | [Nous Research Hermes Agent](products/hermes.md) | documented-subset |
| `letta-code` | [Letta Code CLI/desktop and hosted agent](products/letta-code.md) | version-sensitive |
| `letta` | [Letta platform/API agents](products/letta.md) | documented-subset |
| `rovodev` | [Atlassian Rovo Dev CLI, IDE and cloud](products/rovodev.md) | documented-subset |
| `ibm-bob` | [IBM Bob IDE and Bob Shell](products/ibm-bob.md) | version-sensitive |
| `gitlab-duo` | [GitLab Duo IDE, CLI, web and agent flows](products/gitlab-duo.md) | documented-subset |
| `tabnine` | [Tabnine IDE/CLI and enterprise context](products/tabnine.md) | version-sensitive |
| `qodo` | [Qodo code review, IDE/Command and toolbox integrations](products/qodo.md) | version-sensitive |
| `cody` | [Sourcegraph Cody, not Amp](products/cody.md) | documented-subset |
| `zencoder` | [Zencoder IDE agents and CLI integrations](products/zencoder.md) | documented-subset |
| `zenflow` | [Zenflow Code, Work and remote hosts](products/zenflow.md) | documented-subset |
| `replit` | [Replit Agent](products/replit.md) | documented-subset |
| `bolt-new` | [Bolt.new / StackBlitz](products/bolt-new.md) | documented-subset |
| `v0` | [v0 projects, Skills and API](products/v0.md) | documented-subset |
| `lovable` | [Lovable workspace/project instructions and Skills](products/lovable.md) | documented-subset |
| `monkeycode` | [Chaitin MonkeyCode platform](products/monkeycode.md) | documented-subset |
| `blackbox` | [Blackbox CLI and agent platform](products/blackbox.md) | documented-subset |
| `pieces` | [PiecesOS and Pieces MCP/Memory provider](products/pieces.md) | provider-or-installer |
| `editor-hosts`, `emacs`, `neovim`, `helix` | [Emacs, Neovim and Helix editor](products/editor-hosts.md) | host-only |
| `codecompanion-nvim` | [CodeCompanion.nvim](products/codecompanion-nvim.md) | documented-subset |
| `mcphub-nvim` | [MCPHub.nvim](products/mcphub-nvim.md) | documented-subset |
| `gptel`, `gptel-mcp-el`, `gptel-agent` | [gptel, mcp.el and gptel-agent](products/gptel.md) | documented-subset |
| `avante`, `avante-nvim` | [Avante.nvim](products/avante.md) | documented-subset |
| `void-editor` | [Void editor archived upstream](products/void-editor.md) | legacy-source |
| `supermaven` | [Supermaven sunset service](products/supermaven.md) | legacy-source |
| `pearai` | [PearAI VS Code/Continue-derived editor](products/pearai.md) | discovery-required |
| `codebuff`, `freebuff` | [Codebuff / Freebuff CLI and SDK](products/codebuff.md) | documented-subset |
| `iflow` | [iFlow CLI](products/iflow.md) | version-sensitive |
| `codearts`, `codearts-agent` | [Huawei CodeArts Agent IDE and console](products/codearts.md) | documented-subset |
| `ona`, `gitpod` | [Ona / former Gitpod and its agent harnesses](products/ona.md) | version-sensitive |
| `t3-code` | [T3 Code desktop/web and providers](products/t3-code.md) | documented-subset |
| `coder-xum`, `coder-mux` | [Coder Xum / former coder/mux](products/coder-xum.md) | version-sensitive |

## Newly found products and cross-cutting standards

Codebuff/Freebuff, iFlow, CodeArts Agent, Ona, Avante, T3 Code, Coder Xum, Copilot app/other
IDEs, JetBrains Air, Kiro Crew, Qoder Work/Wake, Vibe Work, Augment Cosmos, and gptel-agent
are documented with explicit limits; unlisted tools use [discovery.md](discovery.md).

Standards: [Agent Skills specification](https://agentskills.io/specification),
[Agent Skills authoring best practices](https://agentskills.io/skill-creation/best-practices),
[MCP documentation](https://modelcontextprotocol.io/docs/getting-started/intro), and
[MCP Skills extension](https://skills.extensions.modelcontextprotocol.io/) (remote origin;
never install remote MCP Skills into local trusted directories silently).

# Product and context reference index

Review date: **2026-11-07**. **Real-client tests: `not-run` (not run).** This catalog routes
all 90 canonical profile IDs, all 87 historical identifiers, and 25 additional names/aliases
across 30 on-demand family documents. Do **not** load every family file: locate the requested
source and target below and read only those `#anchor` sections.

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
| `claude-code`, `claude` | [Claude Code CLI, IDE integration, Desktop Code](products/anthropic.md#claude-code) | documented-subset |
| `claude-desktop` | [Claude Desktop Chat, web Projects and Cowork](products/anthropic.md#claude-desktop) | discovery-required |
| `codex` | [Codex CLI, local IDE integration and app](products/openai.md#codex) | documented-subset |
| `openai-plugin`, `chatgpt-plugins` | [OpenAI/ChatGPT plugin packages and cloud workspace context](products/openai.md#openai-plugin) | documented-subset |
| `cursor` | [Cursor IDE, CLI and cloud agents](products/cursor.md#cursor) | documented-subset |
| `vscode` | [VS Code: Copilot, Local, Claude and Codex harnesses](products/copilot.md#vscode) | documented-subset |
| `copilot-cli`, `copilot`, `copilot-app` | [GitHub Copilot CLI and Copilot app](products/copilot.md#copilot-cli) | documented-subset |
| `copilot-other-hosts`, `visual-studio`, `copilot-jetbrains`, `copilot-eclipse`, `copilot-xcode`, `copilot-cloud` | [Visual Studio, JetBrains, Eclipse, Xcode and GitHub cloud coding agent](products/copilot.md#copilot-other-hosts) | documented-subset |
| `gemini-cli` | [Gemini CLI and its ACP/IDE integration](products/google-cli-assist.md#gemini-cli) | documented-subset |
| `gemini-code-assist` | [Gemini Code Assist VS Code, JetBrains and enterprise](products/google-cli-assist.md#gemini-code-assist) | documented-subset |
| `android-studio` | [Gemini in Android Studio](products/google-ide-cloud.md#android-studio) | documented-subset |
| `antigravity` | [Antigravity IDE, App and CLI](products/google-ide-cloud.md#antigravity) | documented-subset |
| `firebase-studio` | [Firebase Studio / former IDX](products/google-ide-cloud.md#firebase-studio) | documented-subset |
| `jules` | [Google Jules cloud, Tools CLI and API](products/google-ide-cloud.md#jules) | documented-subset |
| `cline` | [Cline IDE, CLI and SDK](products/cline-kilo-roo.md#cline) | documented-subset |
| `kilocode` | [Kilo IDE and CLI](products/cline-kilo-roo.md#kilocode) | documented-subset |
| `roo-code` | [Roo Code archived upstream; installed forks remain version-specific](products/cline-kilo-roo.md#roo-code) | legacy-source |
| `windsurf`, `codeium` | [Windsurf / legacy Cascade and Devin Desktop transition](products/devin-windsurf.md#windsurf) | version-sensitive |
| `devin` | [Devin CLI, Desktop Local and Cloud](products/devin-windsurf.md#devin) | documented-subset |
| `continue` | [Continue IDE extension and cn CLI](products/continue-zed.md#continue) | documented-subset |
| `zed` | [Zed native agent versus external ACP agent](products/continue-zed.md#zed) | documented-subset |
| `junie`, `jetbrains` | [Junie IDE and CLI](products/jetbrains-xcode.md#junie) | documented-subset |
| `jetbrains-ai`, `jetbrains-air` | [JetBrains AI Assistant, external ACP agents and Air](products/jetbrains-xcode.md#jetbrains-ai) | documented-subset |
| `xcode` | [Xcode Coding Intelligence and external-agent bridge](products/jetbrains-xcode.md#xcode) | documented-subset |
| `kiro`, `kiro-crew` | [Kiro IDE, CLI, web/mobile and Crew](products/aws.md#kiro) | version-sensitive |
| `amazon-q` | [Amazon Q Developer IDE and legacy/current CLI profiles](products/aws.md#amazon-q) | version-sensitive |
| `qwen-code` | [Qwen Code CLI and its IDE/desktop integrations](products/alibaba.md#qwen-code) | documented-subset |
| `qoder`, `qoder-work`, `qoder-wake` | [Qoder International IDE, CLI, JetBrains, Work, cloud and Wake](products/alibaba.md#qoder) | documented-subset |
| `qoder-cn`, `tongyi-lingma` | [Qoder CN / Tongyi Lingma](products/alibaba.md#qoder-cn) | version-sensitive |
| `codebuddy`, `tencent-codebuddy` | [CodeBuddy Code CLI](products/tencent.md#codebuddy) | documented-subset |
| `codebuddy-ide`, `tencent-codebuddy-ide` | [CodeBuddy IDE and IDE plugins](products/tencent.md#codebuddy-ide) | documented-subset |
| `workbuddy` | [WorkBuddy desktop/workspace](products/tencent.md#workbuddy) | documented-subset |
| `trae-cn` | [TRAE China IDE](products/trae.md#trae-cn) | documented-subset |
| `trae`, `trae-agent` | [TRAE International IDE and TRAE Agent CLI](products/trae.md#trae) | discovery-required |
| `trae-work` | [TRAE Work](products/trae.md#trae-work) | documented-subset |
| `comate`, `baidu-comate`, `baidu-comate-ide` | [Baidu Comate IDE plugins and standalone IDE](products/china-coding.md#comate) | documented-subset |
| `kimi-code`, `kimiai` | [Kimi Code current CLI and IDE/ACP use](products/china-coding.md#kimi-code) | version-sensitive |
| `zcode` | [Z.ai ZCode](products/china-coding.md#zcode) | documented-subset |
| `minimax-code` | [MiniMax Code CLI and separately identified desktop/cloud products](products/china-coding.md#minimax-code) | documented-subset |
| `mmx-cli` | [MiniMax multimedia/service CLI](products/china-coding.md#mmx-cli) | provider-or-installer |
| `codely` | [Tuanjie Codely IDE and Codely CLI](products/china-coding.md#codely) | documented-subset |
| `iflycode` | [iFlyCode / iFlytek coding assistant](products/china-discovery.md#iflycode) | discovery-required |
| `raccoon-ai` | [SenseTime coding Raccoon, not unrelated Raccoon products](products/china-discovery.md#raccoon-ai) | discovery-required |
| `vecli`, `ark-cli` | [Volcengine veCLI; distinguish Ark CLI and service CLIs](products/china-discovery.md#vecli) | discovery-required |
| `mistral-vibe`, `vibe-work` | [Mistral Vibe Code and Vibe Work](products/terminal-agents.md#mistral-vibe) | documented-subset |
| `forge` | [ForgeCode, not another Forge product](products/terminal-agents.md#forge) | version-sensitive |
| `aider` | [Aider](products/terminal-agents.md#aider) | documented-subset |
| `pi` | [Pi coding agent](products/terminal-agents.md#pi) | version-sensitive |
| `crush` | [Charm Crush](products/terminal-agents.md#crush) | documented-subset |
| `goose`, `goose-cli` | [Goose CLI and Desktop](products/terminal-agents.md#goose) | documented-subset |
| `factory-droid` | [Factory Droid CLI, desktop and cloud](products/factory-augment.md#factory-droid) | documented-subset |
| `augment-code`, `augment-cosmos` | [Auggie CLI, Augment IDE and Cosmos](products/factory-augment.md#augment-code) | documented-subset |
| `amp`, `sourcegraph-amp` | [Amp CLI/editor/cloud surfaces](products/amp-openhands.md#amp) | documented-subset |
| `openhands` | [OpenHands local CLI, SDK, hosted app and agent canvas](products/amp-openhands.md#openhands) | documented-subset |
| `opencode` | [OpenCode V1 and V2](products/opencode.md#opencode) | version-sensitive |
| `warp` | [Warp Desktop and Warp Drive](products/warp.md#warp) | documented-subset |
| `warp-oz` | [Oz CLI, cloud runtime and SDK/API](products/warp.md#warp-oz) | documented-subset |
| `openclaw` | [OpenClaw Gateway, workspace agents and node hosts](products/openclaw-hermes.md#openclaw) | documented-subset |
| `hermes` | [Nous Research Hermes Agent](products/openclaw-hermes.md#hermes) | documented-subset |
| `letta-code` | [Letta Code CLI/desktop and hosted agent](products/letta.md#letta-code) | version-sensitive |
| `letta` | [Letta platform/API agents](products/letta.md#letta) | documented-subset |
| `rovodev` | [Atlassian Rovo Dev CLI, IDE and cloud](products/enterprise.md#rovodev) | documented-subset |
| `ibm-bob` | [IBM Bob IDE and Bob Shell](products/enterprise.md#ibm-bob) | version-sensitive |
| `gitlab-duo` | [GitLab Duo IDE, CLI, web and agent flows](products/enterprise.md#gitlab-duo) | documented-subset |
| `tabnine` | [Tabnine IDE/CLI and enterprise context](products/enterprise.md#tabnine) | version-sensitive |
| `qodo` | [Qodo code review, IDE/Command and toolbox integrations](products/enterprise.md#qodo) | version-sensitive |
| `cody` | [Sourcegraph Cody, not Amp](products/enterprise.md#cody) | documented-subset |
| `zencoder` | [Zencoder IDE agents and CLI integrations](products/zencoder.md#zencoder) | documented-subset |
| `zenflow` | [Zenflow Code, Work and remote hosts](products/zencoder.md#zenflow) | documented-subset |
| `replit` | [Replit Agent](products/cloud-builders.md#replit) | documented-subset |
| `bolt-new` | [Bolt.new / StackBlitz](products/cloud-builders.md#bolt-new) | documented-subset |
| `v0` | [v0 projects, Skills and API](products/cloud-builders.md#v0) | documented-subset |
| `lovable` | [Lovable workspace/project instructions and Skills](products/cloud-builders.md#lovable) | documented-subset |
| `monkeycode` | [Chaitin MonkeyCode platform](products/cloud-builders.md#monkeycode) | documented-subset |
| `blackbox` | [Blackbox CLI and agent platform](products/blackbox-pieces.md#blackbox) | documented-subset |
| `pieces` | [PiecesOS and Pieces MCP/Memory provider](products/blackbox-pieces.md#pieces) | provider-or-installer |
| `editor-hosts`, `emacs`, `neovim`, `helix` | [Emacs, Neovim and Helix editor](products/editor-plugins.md#editor-hosts) | host-only |
| `codecompanion-nvim` | [CodeCompanion.nvim](products/editor-plugins.md#codecompanion-nvim) | documented-subset |
| `mcphub-nvim` | [MCPHub.nvim](products/editor-plugins.md#mcphub-nvim) | documented-subset |
| `gptel`, `gptel-mcp-el`, `gptel-agent` | [gptel, mcp.el and gptel-agent](products/editor-plugins.md#gptel) | documented-subset |
| `avante`, `avante-nvim` | [Avante.nvim](products/editor-plugins.md#avante) | documented-subset |
| `void-editor` | [Void editor archived upstream](products/legacy.md#void-editor) | legacy-source |
| `supermaven` | [Supermaven sunset service](products/legacy.md#supermaven) | legacy-source |
| `pearai` | [PearAI VS Code/Continue-derived editor](products/legacy.md#pearai) | discovery-required |
| `codebuff`, `freebuff` | [Codebuff / Freebuff CLI and SDK](products/new-clients.md#codebuff) | documented-subset |
| `iflow` | [iFlow CLI](products/new-clients.md#iflow) | version-sensitive |
| `codearts`, `codearts-agent` | [Huawei CodeArts Agent IDE and console](products/new-clients.md#codearts) | documented-subset |
| `ona`, `gitpod` | [Ona / former Gitpod and its agent harnesses](products/new-clients.md#ona) | version-sensitive |
| `t3-code` | [T3 Code desktop/web and providers](products/new-clients.md#t3-code) | documented-subset |
| `coder-xum`, `coder-mux` | [Coder Xum / former coder/mux](products/new-clients.md#coder-xum) | version-sensitive |

## Newly found products and cross-cutting standards

Codebuff/Freebuff, iFlow, CodeArts Agent, Ona, Avante, T3 Code, Coder Xum, Copilot app/other
IDEs, JetBrains Air, Kiro Crew, Qoder Work/Wake, Vibe Work, Augment Cosmos, and gptel-agent
are documented with explicit limits; unlisted tools use [discovery.md](discovery.md).

Standards: [Agent Skills specification](https://agentskills.io/specification),
[Agent Skills authoring best practices](https://agentskills.io/skill-creation/best-practices),
[MCP documentation](https://modelcontextprotocol.io/docs/getting-started/intro), and
[MCP Skills extension](https://skills.extensions.modelcontextprotocol.io/) (remote origin;
never install remote MCP Skills into local trusted directories silently).

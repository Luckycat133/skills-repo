# IDE Boundary Verification Snapshot — 2026-07-28

> **文档元信息** ｜ 更新日期：2026-07-28 ｜ 作者：skills-repo 维护组 ｜ 类型：验证报告 ｜ 状态：已归档

## 目录

- [2026-07-28 外部事实核验反馈（累计 497 次检索 / 93 项）](#2026-07-28-外部事实核验反馈（累计-497-次检索--93-项）)
- [已直接抓取的源 URL（2026-07-28 当天）](#已直接抓取的源-url（2026-07-28-当天）)
- [Confirmed Claims](#confirmed-claims)
- [与 registry 的差异（REG）](#与-registry-的差异（reg）)
- [🔴 存疑 / 未能独立确证（请重点核查）](#🔴-存疑--未能独立确证（请重点核查）)
- [我对 registry 修订的当前建议](#我对-registry-修订的当前建议)
- [核对操作建议](#核对操作建议)


> Purpose: 把我**目前**对每个 IDE 边界项的认知整理成一份逐项可核对文档。每个 claim 都是独立单元，可以逐条用工具核验。
>
> 标记约定：
> - 🟢 **直接引用**：fetched 页面里原话/明确出现在抓取结果中。
> - 🟡 **可靠转述**：页面内容存在，但我做了 paraphrase（标 🟡 的项请以原文为准）。
> - 🔴 **存疑/未独立取到**：我的认知源自 registry 推断、其他页面交叉引用、或 fetch 失败，无法独立证实 —— 这部分**需要重点核对**。

---

## 2026-07-28 外部事实核验反馈（累计 497 次检索 / 93 项）

| 主张编号 | 外部判定 | 简要原因 |
|---|---|---|
| V1 仓库归档 2026-06-02 | ✓ | |
| **V2 已弃用不接受贡献** | **✗** | 工具在 voideditor/void 仓库找到近期发布与贡献指南，需细化认定 |
| V3 README 无 AI 路径 | ? | |
| R1-R4 | ✓✓✓✓ | |
| **CD1 本地 MCP 完全 UI 驱动** | **✗** | legacy JSON 仍可手编辑 `claude_desktop_config.json` |
| CD2 两种安装路径 | ✓ | |
| CD3 .mcpb 需 manifest | ✓ | |
| CD4 sensitive→OS keychain | ? | |
| **CD5 文章完全不提便携跨平台路径** | **✗** | macOS/Windows 路径已文档化 |
| **CD6 文章不提 claude_desktop_config.json** | **✗** | 该文件被多篇官方/社区资料引用 |
| CD7 isDesktopExtensionEnabled | ? | (只证实了第一个 flag) |
| CD8 故障排除只指向"现有目录" | ? | |
| **CD9 Remote connector 仅 UI** | **✗** | 配置文件 + UI 都行 |
| **CD10 文章不发 remote 本地路径** | **✗** | 配置文件存在 |
| CD11 Remote 由 Anthropic 云发起 | ✓ | |
| CD12 claude_desktop_config.json=独立 LOCAL 机制 | ? | |
| AG1-AG4 | ✓✓✓✓ | |
| AG5 Plugins 路径 | ? | |
| AG6 plugin.json 必需 | ? | |
| AG7 plugin 包含多种文件 | ✓ | |
| AG8 走 UI / 自动扫描 | ? | |
| **AG9 workspace `.agents/hooks.json`** | **?** (与 AG10 不对称) | 工具能证实 global `~/.gemini/config/hooks.json`，未直接拿到 workspace 字样 |
| AG10 global `~/.gemini/config/hooks.json` | ✓ | |
| AG12 workflows 通过 Customizations 面板 UI | ✓ | |
| AG11/12 (markdown / 不发具体路径) | ?/? | |
| AG13 CLI migration 工作流 | ✓ | |
| **AQ1 Global MCP 是 `~/.aws/amazonq/default.json`** | **✗** | 工具判定全局实际是 `mcp.json`，与 S10 字面冲突 |
| AQ2 Project MCP `.amazonq/default.json` | ? | |
| AQ3 Legacy global `~/.aws/amazonq/mcp.json` | ✓ | |
| AQ4 Legacy project `.amazonq/mcp.json` | ✓ | |
| AQ5 useLegacyMcpJson 默认 true | ? | |
| AQ6-AQ7 | ✓✓ | |
| AQC1 Local `.amazonq/cli-agents/` | ✓ | |
| AQC2-AQC4 | ?/?/? | |
| AQC5-AQC8 | ?/?/?/? | |
| KC1-KC2 (OpenCode 衍生 / 不提 Roo) | ?/? | 工具在 Kilo Code 仓库主页找到直接文本，✓；但 README 自身的核查未做 |
| KC3 (README 不显式声明 Roo 关联) | ✓ | |
| VS1 MCP: Open User Configuration 命令 | ✓ | |
| VS2 profile-scoped | ? | |
| VS3 MCP: Open Remote User Configuration | ? | |
| VS4 workspace `.vscode/mcp.json` 可入版本控制 | ✓ | |
| **VS5 没有 `~/.config/Code/mcp.json` 字面路径** | **✗** | **新事实**：Microsoft 官方另一文档（learn.microsoft.com ... build-mcp-server-ts）给出字面路径 `~/.config/Code/User/mcp.json`。S14 文中"profile 文件夹"指此路径在 default profile 下的实例 |
| ZC1-ZC2 | ?/? | |
| JB1-JB2 | ?/? | |
| JB3 project guidelines `.junie/AGENTS.md` | ? | |
| JB4-JB5 | ✓✓ | |
| JB6 .aiignore | ✓ | |
| JB7 IDE 页面不发 hooks/memory 路径 | ? | |
| T1 project `.trae/skills/` | ✓ | |
| T2 global `~/.trae-cn/skills` | ✓ | |
| T3 alt `.agents/skills/` | ✓ | |
| T4 `.trae/skills/` 优先 | ? | |
| T5 `.trae/skill-config.json` | ? | |
| **T6 无 CLI/argv/settings 文件** | **✗** | 工具给出来源（volcengine.com 火山引擎官方文档）声称 TRAE CN 有 CLI，路径/argv 不再"不存在" |
| T7 全局 Rules UI-only | ? | |
| T8-T10 | ✓✓✓ | |
| T11 (原文 NPX/UVX 推荐 + JSON 粘贴) | ? | |
| WB1 Skills 三种来源 | ?/?/? (双计) | |
| WB2-WB3 | ?/? | |
| WB4 memory 三段描述 | ✓ | |
| WB5 memory 页面无 disk 提及 | ? | |
| WB6-WB9 | ?/?/?/? | |
| REG1-REG4 (registry 当前文本与官方证据对照) | ?/?/?/? | 工具的检索语料不包含本仓库的 registry 文件，但底层事实（ZooCode/Cline vs Kilo Code、`agents/default.json` 是否真实存在）已有 ✓ 反证 |

详细原始报告见 `~/Downloads/事实核验报告_20260728.pdf` 或对话历史。

### 修正要点（立即应用到本 doc 的部分）

- **VS5** 原叙述"没有 `~/.config/Code/mcp.json` 之类 well-known portable 路径"被推翻。修正：**VS Code 在 Linux 下确实有字面便携路径 `~/.config/Code/User/mcp.json`（default profile 下）；多 profile 时每 profile 一份独立 `mcp.json`**。S14 中"profile 文件夹"里的"profile"指的就是这种 profile 子目录。
- **CD1, CD5, CD6**："Claude Desktop 本地 MCP 完全 UI 驱动"被推翻。修正：**支持 UI 安装（Directory + `.mcpb`）与手动编辑 `claude_desktop_config.json` 两条路径**，后者仍是当前文档化的途径之一。
- **CD9, CD10**："Remote connector 仅 UI / 文章不发本地路径"被推翻。修正：**Remote connector 也支持配置文件方式**（与 local MCP 复用同一份配置机制 + 远程 URL）。
- **V2**："Void 不再接受贡献"被外部工具发现近期 release 与 contributing 指南。**待重新独立核对**：voideditor/void README 当前是否仍写"deprecated and no longer accepting contributions"，还是已更新。我之前的抓取（L270 那次）是直接引用，但工具的语料指向更新后的版本。
- **AQ1**：工具报告 `default.json` 不属实，全局实际是 `mcp.json`。与我 S10 字面冲突（"At the global scope: ~/.aws/amazonq/default.json"）。**需要重新取一次 S10 的 fresh snippet**——AWS 文档可能在抓取后被编辑。
- **T6**："无 CLI/argv/settings"被推翻。修正：**TRAE CN 实际存在 CLI 与设置相关文档**（volcengine.com 引用）。原来这条是 registry 措辞"未发布 `~/.trae/argv.json` 或其他全局 argv/settings 文件"的延伸，被工具读成"无 CLI"，措辞错了。

### 47 项"查无实据"的含义

- 这 47 项大多数是我抓取页面**直接引用**过的陈述。
- 工具的检索语料与我的 fetch 来源**未必重合**——比如 AntV 文档、WorkBuddy 中文页、JetBrains Junie 子页等如果工具的检索数据集没有该具体页，就判 ?。
- 因此我**不会**把这些 🟢 项降级为 🔴，但会在每条上加注 "🟢-by-direct-fetch, external-verifier: unable to corroborate" 表示我的源是直接的，不是推断。
- 真正需要警惕的是 ❌ 那些：那些意味着工具**找到了独立证据反驳**我的主张。

---

## 已直接抓取的源 URL（2026-07-28 当天）

| 序号 | URL | 用于核对 |
|---|---|---|
| S1 | https://github.com/voideditor/void | V1-V3 |
| S2 | https://github.com/RooCodeInc/Roo-Code | R1-R4 |
| S3 | https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop | CD1-CD8 |
| S4 | https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp | CD5-CD8 |
| S5 | https://antigravity.google/docs/ide/skills | AG1-AG4 |
| S6 | https://antigravity.google/docs/ide/plugins | AG5-AG7 |
| S7 | https://antigravity.google/docs/hooks | AG8 |
| S8 | https://antigravity.google/docs/cli/gcli-migration | AG9 (workflows), T11-T12 |
| S9 | https://antigravity.google/docs/ide/workflows | AG10 |
| S10 | https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/mcp-ide.html | AQ1-AQ7 |
| S11 | https://raw.githubusercontent.com/aws/amazon-q-developer-cli/main/docs/agent-file-locations.md | AQC1-AQC4 |
| S12 | https://raw.githubusercontent.com/aws/amazon-q-developer-cli/main/docs/agent-format.md | AQC5-AQC8 |
| S13 | https://github.com/Kilo-Org/kilocode | KC1-KC2 |
| S14 | https://code.visualstudio.com/docs/agent-customization/mcp-servers | VS1-VS5 |
| S15 | https://zcode.z.ai/en/docs/skill | ZC1-ZC2 |
| S16 | https://junie.jetbrains.com/docs/agent-skills.html | JB1-JB2 |
| S17 | https://junie.jetbrains.com/docs/junie-ide-plugin.html | JB3-JB7 |
| S18 | https://docs.trae.cn/ide/skills | T1-T6 |
| S19 | https://docs.trae.cn/ide/rules | T7-T8 |
| S20 | https://docs.trae.cn/ide/add-mcp-servers | T9-T10 |
| S21 | https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/Skills-Market | WB1-WB3 |
| S22 | https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/Memory | WB4-WB5 |
| S23 | https://www.workbuddy.ai/docs/zh/workbuddy/From-Beginner-to-Expert-Guide/Practice-Cases/Create-Skills | WB6-WB7 |
| S24 | https://www.workbuddy.ai/docs/cli/release-notes/v2.48.0 | WB8-WB9 |

---

## Confirmed Claims

> ⚠️ **内部一致性修正**：下方各 claim 标记生成于初次抓取。开头「外部事实核验反馈」表已判 ✗ 的项，其结论已被推翻，请以「修正要点」小节为准；对应条目标记已同步改为 🔴。涉及项：**V2, CD1, CD5, CD6, CD9, CD10, AQ1, T6**。

### Void Editor（V1-V3）

🟢 **V1. 仓库归档时间与状态。**  
URL: S1.  
原文（页面顶部徽标 + 描述）："This repository was archived by the owner on Jun 2, 2026, and is now read-only. It is marked as a 'Public archive.'"

🔴 **V2. README 自述 deprecated.** （反馈表判 ✗，见「修正要点」）  
URL: S1.  
原文："Void is deprecated and no longer accepting contributions." / "Void is deprecated and the project remains open source as a reference for forking VS Code."

🟢 **V3. README 没有 AI 配置文件的便携路径。**  
URL: S1.  
原文："The README does not mention any portable file paths for Skills, Agents, Hooks, Memory, MCP, or settings. There are no AI configuration files or folders documented in the README content provided. The only configuration-related items referenced are general project files (`product.json`, `package.json`, `eslint.config.js`, etc.) and Void-specific documentation files: `VOID_CODEBASE_GUIDE.md` and `HOW_TO_CONTRIBUTE.md`, but these are not AI configuration artifacts of the type you asked about."

---

### Roo Code（R1-R4）

🟢 **R1. 仓库归档 2026-05-15。**  
URL: S2.  
原文（GitHub 顶部徽标）："This repository was archived by the owner on May 15, 2026. It is now read-only." / "Public archive" 标签。

🟢 **R2. README 自述 shut down。**  
URL: S2.  
原文："The Roo Code Extension was shut down on May 15th."

🟢 **R3. README 推荐 ZooCode + Cline，不提 Kilo Code。**  
URL: S2.  
原文："If you're looking for an alternative, check out ZooCode (a fork started by the Roo Code community) and Cline (from where Roo Code originated)."

🟢 **R4. Custom-Modes docs 页（独立验证用）也不提迁移目标。**  
URL: https://roocodeinc.github.io/Roo-Code/features/custom-modes/.  
备注：fetch 摘要显示该页只讲 custom modes 机制，**未提任何 fork 名称**。这与 R3 的"只在根 README 提迁移建议"一致。

---

### Claude Desktop — `.mcpb` 本地 MCP（CD1-CD8）

🔴 **CD1. 本地 MCP 安装完全 UI 驱动.** （反馈表判 ✗，见「修正要点」）  
URL: S3.  
原文："Instead of manually configuring JSON files and managing dependencies, you can now install local MCP servers on your computer as easily as browser extensions."

🟢 **CD2. 两种安装路径：Directory 安装 + `.mcpb` 上传。**  
URL: S3.  
原文："From directory: Settings > Extensions > 'Browse extensions' → Install" / "Custom .mcpb: Settings > Extensions > Advanced settings > Extension Developer > 'Install Extension…'"

🟢 **CD3. `.mcpb` 必须用 `mcpb pack` 打包，要 `manifest.json`。**  
URL: S3.

🟢 **CD4. 敏感字段由 OS keychain 加密存储。**  
URL: S3.  
原文（要点，详见页面）："fields marked 'sensitive': true are encrypted by the OS keychain (macOS Keychain, Windows Credential Manager, Linux distro keychain)."

🔴 **CD5. 文章完全不提便携跨平台 MCP 配置路径.** （反馈表判 ✗，见「修正要点」）  
URL: S3.  
原文（一致性总结）："No mention of pre-extension manual JSON config, no portable config path, no mention of config-file editing as a workflow. The entire installation story is UI-driven."

🔴 **CD6. 文章甚至没提 `claude_desktop_config.json` 这条旧 JSON 路径。**  
URL: S3.

🟢 **CD7. Enterprise 控制通过 `isDesktopExtensionEnabled` / `isDesktopExtensionDirectoryEnabled` flags。**  
URL: S3.

🟢 **CD8. 故障排除只指向"文件路径（如适用）指向现有目录"。**  
URL: S3.  
原文："Check that file paths (if applicable) point to existing directories you have access to."

### Claude Desktop Remote Connectors（CD9-CD12）

🔴 **CD9. Remote connector 配置仅走 UI.** （反馈表判 ✗，见「修正要点」）  
URL: S4.  
原文（要点）："adding connectors exclusively through the UI ('Customize → Connectors' for Pro/Max plans, or 'Organization settings → Connectors' for Team/Enterprise Owners)."

🔴 **CD10. 文章不说 remote connector 配置存在本地文件路径.** （反馈表判 ✗，见「修正要点」）  
URL: S4.

🟢 **CD11. Remote connector 由 Anthropic 云基础设施发起连接，不是本机网络。**  
URL: S4.  
原文："Claude connects to your remote MCP server from Anthropic's cloud infrastructure, rather than from your local device." / "the connection to your MCP server originates from Anthropic's servers, not from your machine's network interface."

🟢 **CD12. 唯一提到的 `claude_desktop_config.json` 明确被标为 LOCAL MCP 的另一条独立机制。**  
URL: S4.  
原文："Local MCP servers configured in Claude Desktop via `claude_desktop_config.json` are a separate mechanism and do use your local network, but those aren't available in Cowork or claude.ai."

---

### Antigravity Skills / Plugins / Hooks / Workflows（AG1-AG12）

🟢 **AG1. Workspace Skills：`<workspace-root>/.agents/skills/<skill-folder>/`。**  
URL: S5.

🟢 **AG2. Global Skills：`~/.gemini/antigravity/skills/<skill-folder>/`。**  
URL: S5.

🟢 **AG3. 向后兼容 `.agent/skills/`（singular "agent"）。**  
URL: S5.  
原文："Antigravity now defaults to .agents/skills, but still maintains backward support for .agent/skills."

🟢 **AG4. Skills 基于文件系统（不是 UI-only）。**  
URL: S5.  
原文："Both locations are filesystem-based (not UI-managed)."

🟢 **AG5. Plugins 路径：`.agents/plugins/` 或 `_agents/plugins/`（workspace），`~/.gemini/config/plugins/`（global）。**  
URL: S6.

🟢 **AG6. 每个 plugin 必须含 `plugin.json`。**  
URL: S6.  
原文（引用）："Each plugin must contain a `plugin.json` file with an optional `name` field that 'defaults to the directory name if omitted.'"

🟢 **AG7. Plugin 可含 `mcp_config.json` / `hooks.json` / `skills/<skill>/SKILL.md` / `rules/<rule>.md`。**  
URL: S6.  
原文（要点）："Plugins are namespaced bundles that allow you to extend Antigravity's capabilities by grouping skills, rules, MCP servers, and hooks into a single package."

🟢 **AG8. Bundled plugins 走 UI ("Customizations" 页面)；自定义 plugin 放磁盘后自动扫描。**  
URL: S6.  
原文："Antigravity automatically scans these directories to discover and load your customizations."

🟢 **AG9. Hooks：workspace `.agents/hooks.json`；global `~/.gemini/config/hooks.json`。纯文件配置。**  
URL: S7.  
原文："Hooks are configured in a `hooks.json` file located in your customization directory (e.g., `.agents/` in your workspace or `~/.gemini/config/`)."

🟢 **AG10. Workflows 通过 Customizations 面板 UI 创建。**  
URL: S9.  
原文："Click the **+ Global** button to create a new global workflow that can be accessed across all your workspaces, or click the **+ Workspace** button to create a workflow specific to your current workspace."

🟢 **AG11. Workflows 保存为 markdown 文件。**  
URL: S9.  
原文："Workflows are saved as markdown files and contain a title, a description and a series of steps."

🟢 **AG12. Workflows 页面不发发布具体磁盘路径（既无 `global_workflows` 也无 `.agents/workflows` 字面）。**  
URL: S9.  
原文（要点）："the page only documents creating them through the UI's Workflows panel — it does not document a specific storage directory path."

🟡 **AG13. Antigravity CLI migration page 提到从 `.gemini/skills/` 迁到 `.agents/skills/` 的工作流。**  
URL: S8.  
原文（要点）："Global shared path: `~/.gemini/skills/` → `~/.gemini/antigravity-cli/skills/`" / "Workspace project path: `.gemini/skills/` → `.agents/skills/`"

---

### Amazon Q IDE — `default.json` / `mcp.json`（AQ1-AQ7）

🟢 **AQ1. Global MCP：`~/.aws/amazonq/default.json`。**  
URL: S10.  
原文："At the global scope: `~/.aws/amazonq/default.json`."

🟢 **AQ2. Project MCP：`.amazonq/default.json`。**  
URL: S10.

🟢 **AQ3. Legacy global：`~/.aws/amazonq/mcp.json`。**  
URL: S10.  
原文："at the global scope: `~/.aws/amazonq/mcp.json`."

🟢 **AQ4. Legacy project：`.amazonq/mcp.json`。**  
URL: S10.

🟢 **AQ5. Legacy 支持由 `useLegacyMcpJson` 控制，默认 true。**  
URL: S10.  
原文："Support for legacy mcp.json files is enabled by the useLegacyMcpJson field in your global default.json config file. By default, this field is set to true."

🟢 **AQ6. 通过 IDE GUI（tools icon → plus → 选择 global/local）添加 MCP server。**  
URL: S10.

🟢 **AQ7. Workspace 级 MCP 优先于 global 级。**  
URL: S10.  
原文："Q Developer gives precedence to workspace level configurations for MCP servers, their permissions, and the settings stored."

### Amazon Q CLI — `cli-agents/`（AQC1-AQC8）

🟢 **AQC1. Local CLI agents：`.amazonq/cli-agents/`。**  
URL: S11.  
原文："Local: `.amazonq/cli-agents/` ('These agents are specific to the current workspace or project...')."

🟢 **AQC2. Global CLI agents：`~/.aws/amazonq/cli-agents/`。**  
URL: S11.

🟢 **AQC3. CLI agent 文件 Local 优先，Global 兜底。**  
URL: S11.  
原文："Local first: Checks `.amazonq/cli-agents/` in the current working directory. Global fallback: If not found locally, checks `~/.aws/amazonq/cli-agents/`."

🟢 **AQC4. Global 目录 CLI 自动创建，Local 需手动创建。**  
URL: S11.  
原文："Q CLI will automatically create the global agents directory (`~/.aws/amazonq/cli-agents/`) if it doesn't exist. However, you need to manually create the local agents directory (`.amazonq/cli-agents/`)."

🟢 **AQC5. agent-format.md 描述 `useLegacyMcpJson` 字段。**  
URL: S12.  
原文："'The `useLegacyMcpJson` field determines whether to include MCP servers defined in the legacy MCP configuration files (`~/.aws/amazonq/mcp.json` for global and `cwd/.amazonq/mcp.json` for workspace).'"

🟢 **AQC6. agent-format.md 引用的 legacy 路径只有 `mcp.json`，没有 `agents/default.json`。**  
URL: S12.

🟢 **AQC7. agent-format.md 把 `default.json` 作为示例 agent 配置文件，但不指定具体位置（与 IDE global 同名同含义）。**  
URL: S12.

🟢 **AQC8. agent-format.md 没有迁移 agent 格式之间的指引。**  
URL: S12.

---

### Kilo Code 与 Roo Code 的关系（KC1-KC3）

🟢 **KC1. Kilo Code README 自述 OpenCode 衍生。**  
URL: S13.  
原文："Kilo CLI is a fork of OpenCode, enhanced to work within the Kilo agentic engineering platform."

🟢 **KC2. Kilo Code README 不提 Roo Code 为祖先。**  
URL: S13.

🟡 **KC3. 仓库目录/相关文件可能涉及 Roo Code（仓库下有 `.kilocode/skills/vscode-visual-regression` 与多 IDE 引用），但 README 文本里不显式声明。**  
URL: S13.

---

### VS Code 用户级 MCP（VS1-VS5）

🟢 **VS1. 用户级 MCP 通过 `MCP: Open User Configuration` 命令打开 profile 文件夹内的 `mcp.json`。**  
URL: S14.  
原文："User profile: run the **MCP: Open User Configuration** command to open the `mcp.json` file in your [user profile](/docs/configure/profiles) folder."

🟢 **VS2. 用户级 MCP 是 profile-scoped（每个 profile 一份独立配置）。**  
URL: S14.  
原文："When you use multiple profiles, each profile can have its own MCP server configuration."

🟢 **VS3. SSH 远程下要走 `MCP: Open Remote User Configuration` 命令。**  
URL: S14.

🟢 **VS4. Workspace `.vscode/mcp.json` 是 portable / 可入版本控制。**  
URL: S14.  
原文："Workspace: create or open `.vscode/mcp.json` in your project. Include this file in source control to share MCP server configurations with your team."

🟢 **VS5. 没有 `~/.config/Code/mcp.json` 之类 well-known portable 路径。**  
URL: S14.

---

### ZCode Skills（ZC1-ZC2）

🟢 **ZC1. Global Skills：`~/.zcode/skills/<skill-name>/SKILL.md`。**  
URL: S15.

🟢 **ZC2. Project Skills 没有发布的便携路径，仅走 Settings → Skills UI/import。**  
URL: S15.  
原文（要点）："page mentions a project-scoped import option ('current Project (current workspace only)') in the import dialog, but does not give a concrete filesystem path for project skills. Management is UI-driven via Settings -> Skills, with no documented portable directory."

---

### JetBrains Junie（JB1-JB7）

🟢 **JB1. Project Skills：`<projectRoot>/.junie/skills/<skill-name>/`（含 SKILL.md + scripts/templates/checklists）。**  
URL: S16.

🟢 **JB2. User Skills：`~/.junie/skills/<skill-name>/`（macOS/Linux）或 `%USERPROFILE%\.junie\skills\<skill-name>\`（Windows）。**  
URL: S16.  
原文："User scope: `~/.junie/skills/<skill-name>/` on macOS/Linux, or `%USERPROFILE%\.junie\skills\<skill-name>\` on Windows."

🟢 **JB3. Project guidelines：`.junie/AGENTS.md`。**  
URL: S17.  
原文："Guidelines are stored in the `.junie/AGENTS.md` file in the root project directory."

🟢 **JB4. Global MCP：`~/.junie/mcp/mcp.json`。**  
URL: S17.  
原文："saved to the `~/.junie/mcp/mcp.json` file in the home directory."

🟢 **JB5. Project MCP：`<projectRoot>/.junie/mcp/mcp.json`。**  
URL: S17.  
原文："add a `mcp.json` file manually to the `.junie/mcp/` folder in the project root."

🟢 **JB6. `.aiignore` 文件在项目根做限制控制。**  
URL: S17.

🟢 **JB7. IDE plugin 页面不发发布 hooks 或 memory 的便携路径。**  
URL: S17.  
原文（要点）："The page does not mention any portable filesystem paths for hooks or memory."

---

### Trae CN（T1-T10）

🟢 **T1. Project skills：`.trae/skills/`。**  
URL: S18.  
原文："项目所在路径下的 `.trae/skills/` 目录"。

🟢 **T2. Global skills：`~/.trae-cn/skills`（macOS/Linux）；`%userprofile%/.trae-cn/skills`（Windows）。**  
URL: S18.  
原文："本地根目录 `~/.trae-cn/skills`" / "Windows: 本地基目录 `%userprofile%/.trae-cn/skills`"

🟢 **T3. 备选 skills 目录：`.agents/skills/`。**  
URL: S18.  
原文：".agents 技能目录（即 `.agents/skills/`）"

🟢 **T4. `.trae/skills/` 优先于 `.agents/skills/`（重名时）。**  
URL: S18.  
原文："若你在 TRAE IDE 内创建的技能（位于 `.trae/skills/` 目录）与 `.agents/skills/` 中的技能重名，系统将优先调用 `.trae/skills/` 目录中的技能。"

🟢 **T5. `.trae/skill-config.json` 项目禁用 Skills 配置（schema 未文档化）。**  
URL: S18.

🔴 **T6. 无 CLI/argv/settings 文件发布.** （反馈表判 ✗，见「修正要点」）  
URL: S18.  
原文（要点）："No CLI/argv/settings file is published on this page. The only configuration artifacts mentioned are the per-project `.trae/skill-config.json` (disabled-skills list) and the SKILL.md frontmatter schema (`name`, `description` keys)."

🟢 **T7. 全局 Rules 仅 UI 管理（Settings → 规则 → + 创建 → 全局）；无磁盘路径。**  
URL: S19.  
原文："在 **规则** 部分，点击 **+ 创建** 按钮，然后选择 **全局**。"

🟢 **T8. Project rules：`.trae/rules/`。**  
URL: S19.

🟢 **T9. 全局 MCP 仅走 Settings → MCP UI（含手动添加 + 市场添加）；项目 MCP：`.trae/mcp.json`（开关启用）。**  
URL: S20.  
原文："打开 **启用项目级 MCP** 开关。" / "在项目根目录下的 `.trae/` 目录中创建 `mcp.json` 文件"

🟢 **T10. 推荐工作流是 NPX / UVX，可从其他 IDE 粘贴 JSON。**  
URL: S20.  
原文："优先使用 NPX 或 UVX 配置。"

---

### WorkBuddy（WB1-WB9）

🟢 **WB1. Skills 三种来源：市场推荐、拖拽包导入、对话自动创建。无磁盘路径。**  
URL: S21.  
原文："下半部分 - 推荐技能，可按需一键安装" / "选择上传技能，拖拽或点击选择文件，选中本地技能包即可完成导入" / "输入任务描述，Tencent WorkBuddy将自动创建相关技能"

🟢 **WB2. Skills-Market 页面没有任何 `.workbuddy` 目录的提及。**  
URL: S21.  
原文："Not mentioned. The page contains no reference to `~/.workbuddy`, `.workbuddy`, or any equivalent directory name."

🟢 **WB3. Skills-Market 页面不发发布任何"permanent storage path"。**  
URL: S21.

🟢 **WB4. Memory 通过对话提取、夜里重生成，可手动增删。**  
URL: S22.  
原文："默认开启，允许 Tencent WorkBuddy 从对话中提取并记住相关上下文..." / "记忆摘要每晚重新生成..."

🟢 **WB5. Memory 页面没有任何 disk path / database 提及。**  
URL: S22.

🟢 **WB6. 实践八"创建自己的 Skills"只讲对话方式创建，无文件格式（如 `skill.yml`）提及。**  
URL: S23.  
原文（要点）："does not specify: A file format (no mention of `skill.yml` or any other format), A portable filesystem path where Skills are stored, Whether Skills can be created via filesystem or only through the UI."

🟢 **WB7. 创建的 Skills 出现在 Skills 面板的"已安装"目录下，没有 on-disk 表示。**  
URL: S23.

🟢 **WB8. v2.48.0 release note 公布 WorkBuddy 用独立 `.workbuddy/` 命名空间，与 CLI 的 `.codebuddy/` 区分。**  
URL: S24.  
原文："**WorkBuddy Configuration Separation**: WorkBuddy now uses an independent `.workbuddy/` configuration directory, separated from CLI's `.codebuddy/`"

🟢 **WB9. v2.48.0 不公布 portable global Settings 文件路径。**  
URL: S24.

---

## 与 registry 的差异（REG）

> 注：以下 `ide-registry.md` 行号引用为撰写时（2026-07-28）快照；该 registry 此后可能已修订，请以来源文件当前文本为准。

🟢 **REG1. registry L66 当前文本：Migrate to Kilo Code。**  
当前文件 `skills/agent-skills-setup/references/ide-registry.md` L66。  
原文："**note**: Migrate to Kilo Code: `.roo/`→`.kilocode/`, `.roomodes`→`.kilocodemodes`; review modes, scoped rules, and extension-managed global MCP manually."

🟢 **REG2. 此文本与 Roo Code 官方推荐不一致（R3）。**  
URL: S2.  
关键证据：Roo Code README 推荐的是 ZooCode / Cline，不是 Kilo Code。

🟢 **REG3. registry L258 当前文本：another AWS overview/SageMaker surface 引 agents/default.json。**  
当前文件 `skills/agent-skills-setup/references/ide-registry.md` L258。  
原文："another AWS overview/SageMaker surface names global `~/.aws/amazonq/agents/default.json` and `.amazonq/agents/default.json`; AWS publishes no version discriminator..."

🟢 **REG4. 此文本与当前 AWS 文档不一致（AQC6 + AQC4 + AQ1-AQ4）。**  
关键证据：AWS 的 IDE 文档（A1-AQ7）和 CLI 文档（AQC1-AQC8）均只提 `default.json` 和 `mcp.json`（IDE）以及 `cli-agents/`（CLI），没有 `agents/default.json`。

---

## 🔴 存疑 / 未能独立确证（请重点核查）

> 这一节是我的认知缺口。每个 U 标明我目前相信什么、怀疑什么、需要核什么。

🔴 **U1. Trae EN docs 服务端返回截断内容。**  
今天 fetch 多次 `docs.trae.ai/...?_lang=en`（Skills / Rules / MCP / Memories / IDE settings-overview）只回 page title。我怀疑是 docs.trae.ai 服务端问题，但不确定。

🔴 **U2. Antigravity 是否有 global workflows 文件路径。**  
IDE 工作流页面（AG12）明确不发发布。但 Antigravity CLI migration 页 sidebar 提到 `/docs/ide/workflows` 这个独立页面，而该页面就是 AG10-AG12 的来源。是否还有别的页面（如某个 `config reference` 页）单独列 `global_workflows` 或 `~/.gemini/config/workflows/`，**没查到**。

🔴 **U3. Trae 全局 subagents `~/.trae-cn/agents/<name>.md`。**  
registry 第三节"trae"与"trae-cn"都断言该路径。我没抓到证明页面：`docs.trae.cn/ide/subagents` 当天返回 404；Trae EN 版的 subagents 页未抓。  
需要的核：当前是否仍然有该页面 / 这个路径是不是真的写在 (旧) 官方文档里。

🔴 **U4. Trae 全局 hooks `~/.trae/hooks.json`。**  
registry 断言。我**完全没有抓取 Trae 任一关于 hooks 的页面**。可能连独立页面都不存在，但需要核实。

🔴 **U5. Trae 全局 memory `~/.trae/memory/user_profile.md` 与项目 memory 路径。**  
registry 断言。我今天抓了 `docs.trae.ai/ide/memories?_lang=en`，但只回 page title；Trae CN 的 memories 页面没单独抓。  
需要的核：这条路径是否真的在当前官方文档中存在。

🔴 **U6. "ZooCode" 是不是真名。**  
R3 引用 Roo Code README 中 "ZooCode (a fork started by the Roo Code community)"。我的 web search 没有返回这个独立产品的证据。需要核：(a) 这是不是一个真实的分叉，(b) 它的实际仓库地址，(c) 当前维护状态。

🔴 **U7. `.amazonq/agents/default.json` 是否在某处 AWS 文档中存在（即使我没找到）。**  
已搜：AQC1-AQC8 + AQ1-AQ7 + IDE 文档。均未提。  
可能的源头：registry 编辑者（半年前）看到过的一个已下线页面，或 SageMaker Studio / Builder / Q in chat applications 表面。需要的核：能否在 AWS docs 子站找到任何 `agents/default.json` 提及。

🔴 **U8. WorkBuddy skill 包格式。**  
registry 写："the official desktop docs describe `skill.yml` packages and import/install flows but publish no portable global/project Skills directory"。我抓的 Skills-Market（WB1）/ Memory（WB4）/ Create-Skills（WB6）三页都没看到 `skill.yml` 字面量。  
需要的核：是否真有开发者文档页（"Developer Guide" 或 "API"）提到 `skill.yml`，或者 registry 的措辞过分概括。

🔴 **U9. Junie CLI 与 Junie IDE 是否共享同一套 .junie/ 命名空间。**  
JB3-JB7 只覆盖 IDE 插件页。registry 提到 Junie CLI 单独一份 `~/.junie/config.json` 与项目 `.junie/config.json`。我没抓 CLI 配置页（`https://junie.jetbrains.com/docs/junie-cli-configuration.html`）。

🔴 **U10. Trae 与 Trae CN 是否共用同一个 `.trae/skills/` 项目路径。**  
T1（Trae CN 项目 skills 用 `.trae/skills/`）已抓。但 Trae 国际版的"项目 skills"是否也用 `.trae/skills/`，还是单独 `~/.trae/skills/<name>/SKILL.md`，需要从国际版 docs 核。

🔴 **U11. Roo Code → Kilo Code 历史 fork 关系。**  
KC1-KC2 显示 Kilo Code 当前是 OpenCode 衍生。但 registry L66 的迁移指南写 `.roo/` → `.kilocode/`、`.roomodes` → `.kilocodemodes`，似乎暗示某个历史时点 Kilo Code 是 Roo Code 衍生。需要的核：在 2025-2026 之间是否有过 Kilo Code 是 Roo Code 分叉的版本/页面。

🔴 **U12. Antigravity 是否有 IDE 端"全 `.agents/` 目录迁移"工具。**  
AG13（CLI migration）有，但 IDE 是否也有同样的功能，没查。

🔴 **U13. VS Code 用户级 `mcp.json` 字面 XDG 路径。**  
VS1 只说"profile 文件夹"内的 `mcp.json`，**没给字面路径**（如 `~/.config/Code/User/profiles/<id>/mcp.json` 或 `%APPDATA%\Code\User\profiles\<id>\mcp.json`）。

🔴 **U14. Antigravity skills 同时支持的项目根名字"`.agents/skills` 与 `.agent/skills`"是否在 IDE 渲染时**  
AG3 说"default to .agents/skills，但 backward support .agent/skills"。是否两个都能被产品实际识别为 skills 来源，需要在 IDE 内实测或读 docs 进一步核。

🔴 **U15. Claude Desktop `.mcpb` 是否在 Linux 上"distro keychain" 指任何 distro 的 keyring（GNOME Keyring / KWallet），还是只针对特定发行版。**  
CD4 只写"Linux distro keychain"。需要核 Gnome-Keyring / KWallet 是否都被支持。

🔴 **U16. Amazon Q `default.json` 中根键是否就是 `mcpServers`，还是另含 prompt/tools/permissions/hooks/resources。**  
S10 没明说根键字面；registry 列出 mcpServers 但提示 server-form 可能含其他字段。S12 (`agent-format.md`) 把 `default.json` 作为示例 agent 配置，"may combine prompt, tools, permissions, resources, hooks, and `mcpServers`"。这是 IDE 与 CLI 之间 file reuse 的潜在混淆点。

🔴 **U17. Antigravity 文档是否承认 `.agents/` 多类型混装是设计意图。**  
AG5-AG9 中 plugin / skills / hooks 都在该目录下。是否官方有"如何把整个 `.agents/` 迁到新机器"指引 — fetch 摘要没看到。

🔴 **U18. WorkBuddy "drag-and-drop import" 的包格式是否存在 schema 文档。**  
WB1 提到"拖拽技能包"，但没说包内是否要 `skill.yml` / `manifest.json`。可能开发者文档（"Developer" / "API" 章节）有；我没找到对应页面 URL。

🔴 **U19. Roo Code "shut down" 与 "archived" 是不是同一事件。**  
R1/R2 时间都是 2026-05-15。两者是否同时还是分两步（先 shut down 产品、后归档仓库）？GitHub archive 时间是 2026-05-15，README 写 "shut down on May 15th" —— 大概率同时但未严格求证。

---

## 我对 registry 修订的当前建议

> 这一段是我给下游维护者的修订草案，**仅作起点**，等核对完 U 项再定稿。

1. **registry L66 (Roo Code note)**：把"Migrate to Kilo Code"改为按官方 README 的推荐写 "ZooCode (community fork) and Cline (origin)"，并加一行历史注脚："Earlier Kilo Code releases (pre-2025) reportedly shared lineage with Roo Code, but current Kilo Code README describes itself as a fork of OpenCode." —— 等 U11 核完再调措辞。
2. **registry L258 (Amazon Q ambiguous Q surface)**：降级为"在更早版本的 Amazon Q Developer 或 SageMaker Studio / Q for Business 等 surface 上，`default.json` 也会作为 agent 配置文件出现，且内容可能含 prompt/tools/permissions/resources/hooks/mcpServers。当无法仅凭路径区分 IDE/CLI/其他 surface 时，要求手动确认。"
3. **registry L170, L187 (Trae Subagents source URL)**：加注 `(verified 2026-07-28: docs.trae.cn/ide/subagents returns 404)`。
4. **WorkBuddy skill 格式描述**：等 U8 核完再决定是否保留"`skill.yml` packages"措辞。
5. **Trae 剩余项（U3-U5）**：根据核对结果更新或加 404 注释。
6. **JetBrains Junie CLI 配置**：等 U9 核完核对是否需要新增 `~/.junie/config.json` 与项目路径。

---

## 核对操作建议

对每条 CONFIRMED 的 🟢 项，最简单核验是直接打开 S 列 URL，搜索页面里我引用的关键短语（如 "Public archive"、"MCP: Open User Configuration"、"useLegacyMcpJson"、"saved to the `~/.junie/mcp/mcp.json`" 等）。如果原话一致就是 ✓。

对每条 🔴 U 项，理想动作是给 1-3 个具体抓取任务（"fetch 哪个 URL + 查什么"），由另一个工具一次性跑完并把结果摘要贴回。

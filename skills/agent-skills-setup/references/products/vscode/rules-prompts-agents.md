# VS Code & Copilot CLI: Instructions, Prompts, Agents & Skills

Parent: [vscode.md](../vscode.md)

## Harness Separation

VS Code supports Copilot/Local, Claude, and Codex harnesses. Always verify the active harness before writing files; Claude and Codex harnesses use `.claude/` and `.codex/`/`AGENTS.md`.

## Copilot / Local Workspace & User Paths

| Surface | Workspace Path | Global Path (`copilot-cli` / User) | Schema Notes |
| --- | --- | --- | --- |
| Always-on doc | `.github/copilot-instructions.md` and `AGENTS.md` | `~/.copilot/copilot-instructions.md` | Plain Markdown |
| File-scoped rules | `.github/instructions/*.instructions.md` | — | YAML **`applyTo: "glob"`** |
| Reusable prompts | `.github/prompts/*.prompt.md` | — | `.prompt.md` suffix required for VS Code chat prompts |
| Custom agents | `.github/agents/*.agent.md` | `~/.copilot/agents/*.agent.md` | `.agent.md` suffix; specialized persona + tools |
| Agent Skills | `.github/skills/<name>/SKILL.md` and `.agents/skills/<name>/SKILL.md` | `~/.copilot/skills/<name>/SKILL.md` | Standard `SKILL.md` spec |

Official sources: [custom instructions](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference) · [customization](https://code.visualstudio.com/docs/agents/concepts/customization) · [GitHub Copilot cheat sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)

# OpenClaw Skills Configuration

OpenClaw has the richest skills model in this repository: it supports bundled skills, shared user-managed skills, per-agent workspace skills, ClawHub registry distribution, metadata-driven dependency installers, per-run env injection, and hot reload.

This guide maps those official capabilities into a reproducible setup and maintenance workflow.

## 1. Official Paths and Load Order

OpenClaw loads skills from four sources.

| Layer | Path | Scope | Precedence |
|---|---|---|---|
| Workspace skills | `<agent-workspace>/skills/` | One agent only | Highest |
| Managed skills | `~/.openclaw/skills/` | Shared on one machine | Medium |
| Bundled skills | Built into OpenClaw | Runtime-wide | Lower |
| Extra dirs | `skills.load.extraDirs` | Shared packs | Lowest |

Resolution order for duplicate skill names:

`<agent-workspace>/skills` → `~/.openclaw/skills` → bundled skills → `skills.load.extraDirs`

Important filesystem locations from the official docs:

- Config file: `~/.openclaw/openclaw.json`
- Global env fallback: `~/.openclaw/.env`
- Shared skills: `~/.openclaw/skills`
- Default workspace: `~/.openclaw/workspace`
- Agent sessions: `~/.openclaw/agents/<agentId>/sessions/`
- Multi-instance overrides: `OPENCLAW_CONFIG_PATH`, `OPENCLAW_STATE_DIR`

## 2. Global Configuration

All OpenClaw skill settings live under the `skills` key in `~/.openclaw/openclaw.json`.

### 2.1 Core fields

| Field | Purpose | Official behavior |
|---|---|---|
| `skills.allowBundled` | Allowlist bundled skills | Does not affect managed or workspace skills |
| `skills.load.extraDirs` | Extra scan roots | Lowest precedence |
| `skills.load.watch` | Skill watcher switch | Default `true` |
| `skills.load.watchDebounceMs` | Watch debounce | Default `250` |
| `skills.install.preferBrew` | Prefer Homebrew | Default `true` |
| `skills.install.nodeManager` | Node package backend | `npm`, `pnpm`, `yarn`, `bun` |
| `skills.entries.<skill>.enabled` | Enable or disable one skill | `false` disables it even if present |
| `skills.entries.<skill>.env` | Per-skill env injection | Added only if absent from process env |
| `skills.entries.<skill>.apiKey` | SecretRef or convenience key | Useful with `metadata.openclaw.primaryEnv` |
| `skills.entries.<skill>.config` | Free-form config bag | Skill-defined settings |

### 2.2 Example

```json5
// ~/.openclaw/openclaw.json
{
  agents: {
    defaults: {
      workspace: "~/.openclaw/workspace",
    },
  },
  skills: {
    allowBundled: ["peekaboo", "gifgrep"],
    load: {
      extraDirs: [
        "~/.gemini/config/skills",
        "~/Projects/internal-openclaw-skill-pack/skills",
      ],
      watch: true,
      watchDebounceMs: 250,
    },
    install: {
      preferBrew: true,
      nodeManager: "npm",
    },
    entries: {
      "agent-skills-setup": {
        enabled: true,
        env: {
          OPENCLAW_SKILLS_SOURCE: "~/.gemini/config/skills",
        },
        config: {
          preferredScope: "managed",
        },
      },
    },
  },
}
```

### 2.3 Environment resolution

OpenClaw reads missing env vars from these sources:

1. Parent process environment
2. `.env` in the current working directory
3. `~/.openclaw/.env`
4. `skills.entries.<skill>.env` in `openclaw.json`

Important caveat: `skills.entries.*.env` and `skills.entries.*.apiKey` only affect host runs. They do not automatically populate Docker sandbox env.

## 3. Per-Agent Configuration, Isolation, and Inheritance

OpenClaw isolates agents through workspaces. Each workspace can carry its own `skills/` directory.

### 3.1 Default workspace and explicit agents

```json5
{
  agents: {
    defaults: {
      workspace: "~/.openclaw/workspace",
    },
    list: [
      {
        id: "home",
        default: true,
        workspace: "~/.openclaw/workspace-home",
      },
      {
        id: "work",
        workspace: "~/.openclaw/workspace-work",
      },
    ],
  },
}
```

Each workspace can then override shared skills through its own directory.

- `~/.openclaw/workspace-home/skills/`
- `~/.openclaw/workspace-work/skills/`

### 3.2 Scope isolation rules

| Scope | Isolation | Shared? | Typical use |
|---|---|---|---|
| `<agent-workspace>/skills/` | Per agent | No | Persona or team overrides |
| `~/.openclaw/skills/` | Machine-wide | Yes | Shared personal pack |
| `skills.load.extraDirs` | Machine-wide | Yes | Mirrored read-only packs |
| Bundled skills | Runtime-wide | Yes | Baseline built-ins |

### 3.3 Priority and inheritance

OpenClaw skill precedence is path-based:

1. Workspace skill wins.
2. Shared managed skill is next.
3. Bundled skill is fallback.
4. `skills.load.extraDirs` are lowest.

Config inheritance is different:

- `agents.defaults.*` provides base agent settings.
- `agents.list[]` overrides only the matching agent.
- `skills.entries.*` is global to the gateway process.

If you need full isolation of config, skills, sessions, and credentials, split by `OPENCLAW_CONFIG_PATH` and `OPENCLAW_STATE_DIR`.

```bash
OPENCLAW_CONFIG_PATH=~/.openclaw/work.json \
OPENCLAW_STATE_DIR=~/.openclaw-work \
openclaw gateway --port 19001
```

### 3.4 Sandboxed agents

When a skill must run inside Docker sandboxed agents, mirror env into sandbox settings as well.

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main",
        backend: "docker",
        docker: {
          env: {
            LANG: "C.UTF-8",
            GEMINI_API_KEY: "${GEMINI_API_KEY}",
          },
          setupCommand: "apt-get update && apt-get install -y git curl jq",
        },
      },
    },
  },
}
```

## 4. Skill Metadata and Installers

OpenClaw extends skill metadata under `metadata.openclaw`.

### 4.1 Example metadata

```yaml
---
name: gifgrep
description: Search GIF providers with CLI/TUI, download results, and extract stills/sheets.
homepage: https://gifgrep.com
metadata: {"openclaw":{"emoji":"🧲","requires":{"bins":["gifgrep"]},"install":[{"id":"brew","kind":"brew","formula":"steipete/tap/gifgrep","bins":["gifgrep"],"label":"Install gifgrep (brew)"}]}}
---
```

### 4.2 Official installer kinds

| Kind | Fields |
|---|---|
| `brew` | `formula`, `bins`, `label`, `os` |
| `node` | `package`, `bins`, `label`, `os` |
| `go` | `module`, `bins`, `label`, `os` |
| `uv` | `package`, `bins`, `label`, `os` |
| `download` | `url`, `sha256`, `archive`, `extract`, `stripComponents`, `targetDir`, `bins`, `label`, `os` |

Notes:

- OpenClaw prefers `brew` when available, otherwise `node` if multiple installers exist.
- `download` installers default to `~/.openclaw/tools/<skillKey>` if `targetDir` is omitted.
- Set `sha256` to the expected 64-character SHA-256 digest. The helper verifies it before extracting or writing to `targetDir`; legacy specs without it emit a warning.
- `skills.install.nodeManager` affects skill dependency installs, not the OpenClaw runtime itself.

## 5. Automatic Setup Workflow

This repository includes a dedicated helper:

```bash
bash ../scripts/auto-configure-openclaw-skills.sh \
  --yes \
  --scope both \
  --agent home:~/.openclaw/workspace-home \
  --agent work:~/.openclaw/workspace-work \
  --default-agent home \
  --node-manager npm \
  --env agent-skills-setup:OPENCLAW_SKILLS_SOURCE=~/.gemini/config/skills
```

What it does:

1. Install OpenClaw if `openclaw` is missing.
2. Install ClawHub if `clawhub` is missing.
3. Sync selected skills into `~/.openclaw/skills/` and workspace `skills/` directories.
4. Parse `metadata.openclaw.install` and install declared dependencies.
5. Patch `~/.openclaw/openclaw.json` with `skills.*` and `agents.*` settings.
6. Run `openclaw doctor` after a real apply.

## 6. Updates and Lifecycle

OpenClaw has two first-class update surfaces plus local mirrors.

### 6.1 Runtime updates

```bash
openclaw update
openclaw update --channel beta
openclaw update --tag main
openclaw update --dry-run
```

### 6.2 ClawHub updates

```bash
clawhub update --all
```

ClawHub stores install state in `.clawhub/lock.json` and compares local content hashes against published versions.

### 6.3 Local mirror updates

```bash
bash ../scripts/update-openclaw-skills.sh
```

This helper combines:

1. `openclaw update`
2. `clawhub update --all`
3. `rsync` refresh for `~/.openclaw/skills/` and workspace `skills/`

## 7. OpenClaw vs Other IDE Skills

| Capability | OpenClaw | Claude/Codex/Trae/Copilot |
|---|---|---|
| Bundled skills | Yes | Usually no |
| Shared managed skills | Yes | Sometimes, but less structured |
| Per-agent workspaces | Yes | Usually project or global only |
| Load-time gating | Yes | Rare |
| Metadata-driven installers | Yes | Rare |
| Per-run env injection | Yes | Usually external only |
| Registry updates | Yes, via ClawHub | Usually ad hoc Git repos |
| Watcher and hot reload | Yes | Rare |

Practical implication:

OpenClaw is not just another folder for `SKILL.md`; it is a managed skill runtime.

## 8. Cross-IDE Integration Strategy

Recommended model:

1. Keep Antigravity as the single source of truth.
2. Run `sync-global-skills.sh --targets claude,codex,copilot,openclaw,trae,trae-cn` for global mirrors.
3. Use `auto-configure-openclaw-skills.sh` when OpenClaw-specific dependency installs or per-agent routing are required.
4. Use `update-openclaw-skills.sh` for maintenance.

## 9. Validation Plan

### 9.1 Automated smoke test

```bash
bash ../scripts/test-openclaw-support.sh
```

This covers managed sync, workspace sync, config patching, dependency install flow, and update refresh behavior.

### 9.2 Real-machine test guidance

Use isolated state roots when testing on a machine that already has OpenClaw installed.

```bash
OPENCLAW_STATE_DIR=/tmp/openclaw-test-state \
OPENCLAW_CONFIG_PATH=/tmp/openclaw-test-state/openclaw.json \
AGENT_SKILLS_OPENCLAW_DIR=/tmp/openclaw-test-state/skills \
bash ../scripts/auto-configure-openclaw-skills.sh --dry-run
```

The script refuses global installs, config writes, and replacement syncs unless `--yes` is supplied. Review `--dry-run` output first; existing skill directories and config files receive timestamped `.bak.*` copies before replacement.

Important note: even with isolated config paths, `openclaw doctor` may still observe or interact with machine-global gateway state such as a running local service or LaunchAgent. Use dry runs first when non-interference matters.

### 9.3 Release guardrails

1. `bash -n` passes for every new script.
2. `test-openclaw-support.sh` passes locally.
3. `sync-global-skills.sh --dry-run --targets openclaw` shows only expected changes.
4. `auto-configure-openclaw-skills.sh --dry-run` prints the expected plan.
5. Real-machine verification is documented with any observed gateway-side effects.

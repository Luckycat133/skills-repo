# Publishing Skills Publicly

This guide covers realistic ways to publish a custom skill so other people can discover and install it.

## 1. Short Answer

Yes, you can publish this type of skill publicly.

The most practical distribution path is:

1. Put the skill in a public GitHub repository.
2. Structure it as a normal skill folder with `SKILL.md` and optional `scripts/`, `references/`, and `assets/`.
3. Add a README that explains compatibility and installation.
4. Share the repository directly, or make it discoverable through ecosystems like `skills.sh` and `awesome-copilot`.

## 2. Best Public Distribution Channels

### A. Public GitHub Repository

This is the lowest-friction option and should be your default.

Why it matters:

- works as the canonical public source
- easy to link from docs, social posts, and other registries
- compatible with manual installs across multiple agent ecosystems
- versioning, issues, releases, and README all come for free

Recommended repository contents:

```text
<repo-root>/
├── README.md
├── LICENSE
└── <skill-name>/
    ├── SKILL.md
    ├── scripts/
    ├── references/
    └── assets/
```

### B. skills.sh

`skills.sh` is the strongest public discovery channel for multi-agent skills today.

What the research confirms:

- it supports Antigravity, Claude Code, Codex, GitHub Copilot, Trae, and many other agents
- the `skills` CLI installs skills from public repositories
- the leaderboard surfaces popular installs using anonymous CLI telemetry

Practical implication:

- if your public GitHub repo is compatible with the `skills` CLI, it gains discoverability beyond direct links

Example install command shown by the docs:

```bash
npx skills add owner/repo
```

Notes:

- repository naming and layout should stay simple
- write the README so users understand which agents are supported and whether the repo contains one skill or a collection
- if the repo is installable with the CLI, it has a path to organic discovery through the skills ecosystem

### C. Awesome GitHub Copilot

`github/awesome-copilot` is a high-visibility public collection for skills, agents, instructions, plugins, and workflows.

What the contribution guide confirms:

- it accepts community skill contributions
- skills live under the repository's `skills/` directory
- contributors should run validation and build steps before submission
- pull requests should target the `staged` branch, not `main`

Why this matters:

- strong visibility for Copilot users
- public review and curation
- good credibility signal if accepted

Constraints:

- the skill must be specific, high-signal, and safe
- generic or low-value skills may be rejected
- content is licensed under MIT when contributed there

## 3. Recommended Release Strategy

For this skill, the most defensible release sequence is:

1. Publish a standalone GitHub repository first.
2. Make sure the README clearly explains the multi-agent support story.
3. Verify the repository is installable and understandable without your local machine context.
4. Submit or adapt it for public directories like `skills.sh` and `awesome-copilot`.

That order is better than starting with a directory submission because:

- you retain a canonical home for issues and updates
- you can point all registries back to the same source
- you can iterate on docs before asking for public review

## 4. What To Clean Before Publishing

Before making the skill public:

- replace private usernames, local absolute paths, or machine-specific assumptions
- remove internal-only notes that depend on your personal environment
- document any scripts that assume `bash`, `rsync`, or a specific OS
- make sure bundled assets do not contain private or proprietary material
- explain any platform-specific limitations clearly

## 5. Public README Requirements

A publishable skill README should cover:

- what problem the skill solves
- which agents it supports
- install methods
- example prompts or use cases
- maintenance model and source of truth
- safety or scope boundaries

The bundled export helper creates a starter README, but you should still revise it before publishing.

## 6. Suggested GitHub Topics

Helpful topics for discoverability:

- `agent-skills`
- `ai-agents`
- `antigravity`
- `claude-code`
- `github-copilot`
- `codex`
- `trae`
- `prompt-engineering`

## 7. Awesome Copilot Submission Notes

If you submit there, align with their contribution rules:

- keep the skill focused and specific
- avoid duplicating generic model behavior
- validate the skill before opening the PR
- target the `staged` branch
- expect the repository maintainers to review for quality and safety

## 8. Operational Recommendation

Treat public publishing as a separate release lane from your private mirrored installs:

- private lane: Antigravity source plus sync into your local IDEs
- public lane: exported copy plus public README and release metadata

That separation reduces the chance of leaking local assumptions into the public version.
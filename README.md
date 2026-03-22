# Skills Repository

Reusable AI agent skills, with a local-first authoring workflow and a path to public release.

## Structure

```text
skills-repo/
├── README.md
├── docs/
│   └── agent-skills-setup/
├── scripts/
└── skills/
    └── agent-skills-setup/
```

## Conventions

- `skills/` stores publishable skill folders.
- `docs/` stores development notes, release plans, and maintenance checklists.
- Antigravity remains the authoring source of truth unless explicitly changed.
- Import changes into this repository before preparing a public release.

## Current Skill

- `agent-skills-setup`: multi-agent skill installation, synchronization, and publishing workflow.

## Development Workflow

1. Edit the source skill in Antigravity.
2. Import or sync the updated skill into this repository.
3. Refine release docs under `docs/`.
4. Publish the repository when the skill and metadata are ready.

## Importing Skills

Use the bundled import script:

```bash
bash scripts/import-agent-skill.sh \
    ~/.gemini/antigravity/skills/agent-skills-setup \
    agent-skills-setup
```

## Open Source Metadata

- License: MIT
- Contributions: see `CONTRIBUTING.md`
- Security reporting: see `SECURITY.md`
- Community expectations: see `CODE_OF_CONDUCT.md`

## Publishing

This repository is designed to support both:

- private local development
- public release through GitHub and ecosystems such as `skills.sh`

Before publishing, review the files under `docs/agent-skills-setup/` and make sure the repository does not contain private environment assumptions.
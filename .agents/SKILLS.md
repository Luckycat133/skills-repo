# Project Skill routing

- [agent-skills-setup](skills/agent-skills-setup/SKILL.md): cross-IDE context migration and device transfer. This relative link resolves to the canonical publishable Skill in `skills/agent-skills-setup/`.
- Repository maintenance follows `AGENTS.md` and `CLAUDE.md`; there is no separate maintained `agent-skills-setup-maintenance` Skill.

Claude discovery uses `.claude/skills/agent-skills-setup` through the same canonical alias. No Skill bodies are duplicated.

On 2026-10-18 three pre-existing broken Claude links (`agent-skills-setup-maintenance`, `github-actions`, `managing-python-dependencies`) were removed from active discovery because their former `.agents/skills` sources do not exist in this repository. The original links are retained locally under `.claude/skill-link-archive/20261018/`; this archive is not active discovery or a dependency. Use the available generic GitHub and dependency workflows when needed; install project Skills only after checking an actual task gap and a maintained source.

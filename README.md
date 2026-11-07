# Agent Skills Setup

A Skill that teaches your existing coding agent to move context between tools.
It is **not a separate migration application**. The agent inspects your files,
translates the actual formats, makes a scoped diff, and verifies what changed.

[中文](README.zh-CN.md) · [日本語](README.ja-JP.md) · [Español](README.es.md)

## Use it

Install only `skills/agent-skills-setup/` through your client's documented Skill
installer or copy it to that client's confirmed Skill directory. Do not install
the repository root or the development Skill. There is no required Bash, Python,
cryptography package, background service, or migration CLI in the user package.

Then ask your agent:

> Move this project's Cursor rules and Skills to Claude Code, preserving file scope.

> Move these MCP definitions to Codex; preserve my existing settings and don't copy keys.

> I'm changing computers. Put my selected tools' context in an ordinary reviewable folder.

> Restore this folder into the tools on my new computer; explain any behavior that cannot survive.

## What the Skill contributes

It teaches discovery by product/profile/version; rules and trigger conversion;
Skills/resources; MCP JSON/JSONC/TOML/YAML and auth differences; prompts/commands;
agent and hook definitions; authored memory; conflict handling; and evidence-based
verification. Unknown formats are researched for the selected task, not guessed.
Executable drafts stay outside live loading paths until separately approved.

There is no claim that all IDEs, versions or formats are tested. The examples are
source-backed guidance; actual target behavior must be checked. Documentation
lookup may use public vendor pages without sending local configuration.

## This development branch

The agent-first reset is **unreleased** (`0.11.0-dev`). Published 0.10.x versions
still contain the retired engine; they have not been changed by this branch.
See [the reset](docs/agent-first-reset.md) and
[validation status](docs/validation-status.md). Old code and backups are not erased
from Git history or users' devices. Historical profile notes remain maintainer-only.

## Contribute

Run `bash validate-all.sh`. This checks packaging, links and example fixtures;
it does not substitute for running a real agent. See
[behavior evaluation](evals/README.md) and [development Skill](dev/skills/maintain-agent-skills-setup/SKILL.md).
Please submit one reproducible migration case rather than an unverified product count.

[Security](SECURITY.md) · [Contributing](CONTRIBUTING.md) · [Support](SUPPORT.md)

If this saves setup time, a repository star or voluntary sponsorship helps.
No star, payment or external account is required to use it.

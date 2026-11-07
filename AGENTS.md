# Repository instructions

This repository maintains a Skill that helps an existing agent migrate context.
It is not a standalone migration application. Read
[the development Skill](dev/skills/maintain-agent-skills-setup/SKILL.md) before changing it.

The publishable directory is `skills/agent-skills-setup/`. It contains only concise
instructions, on-demand references, and templates. Do not add a runtime CLI,
transaction engine, ACB protocol, key service, auto-installer, telemetry, or bulk
self-copy. Existing host-agent tools do the editing. A tiny helper requires a
repeated, measured need and a focused test; do not create one speculatively.

Keep every requested context type in the inventory. Unknown formats require
source verification, not fabricated paths or a blanket unsupported label.
Preserve scope, activation, restrictions, user-authored memory and unrelated files.
Never equate a listed product with full support.

Validation: `bash validate-all.sh` (or the Python commands inside it).
Maintainer tooling and behavior evals live outside the published Skill. Structural
checks do not prove real agent/IDE behavior. Record unrun checks honestly.

Make focused commits on a branch; preserve main protection. Do not publish a
release, upload a marketplace package, change account settings or request payment
unless separately authorized. Do not reintroduce the retired engine to fix a test.

# Agent-first scope reset — 2026-11-07

The owner explicitly requested that this project return to being a Skill that
helps an agent migrate context, rather than an independently growing migration
application. This change is a product-scope correction, not another engine patch.

## Kept and strengthened

A concise canonical Skill, on-demand format guidance, worked rule/MCP examples,
all-context inventory, authored-memory handling, conflict isolation, plain-folder
device transfer, source verification, and honest content/discovery/runtime checks.

## Removed from the active tree and package

The bundled Python/Bash migration engine, legacy wrapper, ACB implementation,
signing/key CLI, automatic detection/orchestration, generated pair matrix, runtime
registries, engine-specific evals, and old publishing automation. The old test
suite is retired with the removed engine; new tests cover the new artifact. They
do not claim that the old engine's behavior is still supported or certified.

Repository-only scripts now validate/stage the Skill; they cannot migrate a user's
configuration and are not distributed. No new runtime dependency was introduced.

## Historical material is retained

The full previous tree is immutable Git history at
[`880c5f58d310f5964963c88e685e0530a60e1757`](https://github.com/Luckycat133/skills-repo/tree/880c5f58d310f5964963c88e685e0530a60e1757).
Its profile notes and registry snapshot are also kept under `docs/history/` for
manual re-verification, never as active instructions or automatic support evidence.
The earlier changelog is retained there. No existing user backup is touched.

## Not claimed

No marketplace release has been made. No real IDE/agent behavioral evaluation is
inferred from structural CI. No claim of complete IDE coverage remains. The
remaining work and its acceptance evidence live in the repository's development
Skill. Existing published releases remain unchanged until an approved replacement.

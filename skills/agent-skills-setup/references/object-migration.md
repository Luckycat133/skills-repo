# File-backed object migration

Read with [migration-safety.md](migration-safety.md) for file-backed objects and
inert reconstruction material. Automatic MCP migration also follows
[MCP migration](mcp-migration.md).

| Object | Handling |
| --- | --- |
| Skills | Preflight all source text, then copy credential-free named directories as units. |
| Rules / Instructions | Parse and emit the selected product's native frontmatter; never flatten conditional activation into an unconditional file. |
| Prompts / Commands | Produce reviewed native-format reconstruction actions; no automatic writer. Snapshot's `--include-review-materials` preserves eligible standalone text as inert source material. Check Gemini TOML and UI/enterprise libraries only when selected. |
| Workflows / Cron / Automation | Record reconstruction actions and required target engine features; eligible standalone workflow text can be saved for review. No automatic writer or activation, and no automatic cron/account-side export. |
| Config / project | No whole-config or opaque-tree writer. Snapshot can preserve allowlisted scalar preferences and selected Codex provider/profile fields as inert review JSON for the agent's native field-level merge. |
| Agents / Droids / Modes / Personas | Report native permission, event, and command schemas to rebuild; eligible standalone agent text can be saved for review. `draft-disabled` is a plan status, not proof that a file was generated. |
| Hooks | Review lifecycle event mapping and command permissions; eligible standalone text can be saved for review, but embedded/shared hook configurations remain manual. Automatic migration writes no hook script to a live product surface. |
| Plugins / Extensions | With `--objects plugins --include-plugins`, copy compatible registry-declared packages as units after preflight; no installation or execution. Other packages produce manual rebuild actions. |
| Handoff | With `--objects handoff --include-session`, serialize only reviewed summary, branch, selected relative file list, and explicit patch; reject private runtime state. |
| Sessions / Chat logs | Strictly non-transferable; runtime conversation logs and state are excluded from migration (handoff uses strict whitelist serialization). |
| Memory / Context | Do not copy or inspect private/generated state outside scope (e.g. `~/.cline/data` generated memory); the user may select reviewed context to rewrite as rules. |
| Bundles (ACB) | Package reviewed objects into secret-redacted offline `.acb` directories; use [bundle-workflow.md](bundle-workflow.md) for allowlists, subobject isolation, signatures, and replayable restore plans. |

Treat living or generated files, including Replit `replit.md`, as manual conversation state rather than overwrite targets. When no compatible target format is documented, describe reconstruction instead of an unvalidated copy. There is no generic embedded-config exception: a sub-object is automatic only when Registry v2 names a reviewed source and target adapter for the exact profile/version.

With `snapshot --include-review-materials`, `objects/review/` holds scanned,
non-secret text, allowlisted preferences and supported MCP/provider definitions from the selected profiles
and scopes. It is bound to bundle checksums but excluded from automatic restore
sources. Unhandled shared configuration, sensitive names, remaining literal credentials, unsafe
links, binaries, unreadable content, and collection-limit exclusions require
manual recovery; safe siblings may still be captured. Inspect the per-file
outcomes in `recovery.json`, not just the presence of a review directory.

The initial preference allowlist contains Codex `model`, `model_provider`,
`model_reasoning_effort`, and `personality`; Claude Code `model`; and Gemini CLI
`model.name`, on their registered surfaces. Missing, non-scalar, or rejected
values are reported. Other settings and editor preferences still require
separate inventory; the Codex provider allowlist below adds selected endpoint
and profile reconstruction material. A preference value
does not include the model, provider credentials, or its runtime. TOML review
needs Python's `tomllib`; unavailable parsers are reported rather than installed.

Codex provider review reads only registered TOML preference surfaces. It retains
the selected `model_provider` ID and allowlisted `model_providers` fields:
`name`, `base_url`, `wire_api`, `env_key`, `requires_openai_auth`,
`request_max_retries`, `stream_max_retries`, `stream_idle_timeout_ms`,
`http_headers` and `env_http_headers`. Named `profiles` retain only `model`,
`model_provider`, `model_reasoning_effort` and `personality`. Environment bindings
contain variable names; literal headers use placeholders, URL userinfo and all
query values are removed with safe parameter names recorded for rebuild.
Unknown fields retain only safe field names, never their values. A remaining
credential finding excludes that provider/profile entry while safe siblings
can be preserved. Projects, permissions, sandbox/approval/trust state, execution
settings and unrelated shared-config siblings are not copied. Use the target
Codex version's schema for a reviewed field-level merge; this does not install
a model, authenticate a provider or prove that its endpoint works.

MCP review supports JSON/JSONC `mcpServers`, `servers` and `mcp` containers plus
Codex TOML `mcp_servers`. It captures sanitized per-server definitions, required
credential names and omitted-field details. Shared settings siblings are not
included. Literal environment/header values become placeholders and URL query
values are removed; explicit environment references retain their variable names.
Supported command/URL, arguments, environment/header bindings and
selected tool, timeout or enablement fields are reconstruction data; omitted
unknown values and rejected servers remain explicit work. Source command,
argument and `cwd` paths need destination mapping. JSON/JSONC review works
without `tomllib`; Codex TOML review records a missing-parser outcome when it is
unavailable. This reader does not expand automatic MCP formats/transports or
connect to a local/remote server. The agent must recreate the native definition,
bind local credentials and verify native discovery and an actual tool request.

On the destination, the AI agent adapts the captured text and selected fields to
the installed product's schema, remap paths, establish local trust, and verify
native discovery before explicitly enabling executable actions. Retain task
status and evidence outside the immutable ACB directory. Use the
[bundle workflow](bundle-workflow.md) for the full source/destination checklist.

For Skill copies, preserve upstream `SKILL.md`, references, scripts, and assets
as one package; exclude environment files and reject credential findings or
unsafe links before copying. Do not optimize or rewrite a migrated skill's
instructions as part of migration unless the user separately requests that edit.
When using ACB for scripts, check the recorded `files[].mode` and the restored
executable bits as described in [bundle-workflow.md](bundle-workflow.md);
content hashes alone do not prove permission preservation. No copied script is
executed or activated by migration.
For explicitly reviewed linked sources, use `prepare-skill-source.py` as
described in the [bundle workflow](bundle-workflow.md). Its new staging tree
materializes packages only from the selected source and allowed linked roots;
environment-file omissions and rejected packages remain in the report. Snapshot
that staged source through the corresponding registered product surface. This
keeps live sources unchanged and does not install or activate the staged Skills.
For instructions, preserve scoped activation and hierarchy. Review dropped
frontmatter and same-name changes before accepting any loss.

The reviewed instruction adapters use native fields for Augment (`type`), Cline/Claude (`paths`), Cursor and Continue (`alwaysApply`/`globs`), Kiro (`inclusion`/`fileMatchPattern`), Copilot (`applyTo`), Trae/Qoder (`alwaysApply`), and Windsurf (`trigger`). Unknown frontmatter is reported as loss. A conversion becomes manual when the target cannot preserve `always`, glob, model-decided, or manual activation semantics.

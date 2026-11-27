# qoder

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**Qoder International IDE, CLI, JetBrains, Work, cloud and Wake** · Evidence: `documented-subset` · Runtime: `not-run`.

Separate CLI (`~/.qoder/settings.json`, `.qoder/settings.json`, `.qoder/settings.local.json`, `.qoder/skills`, `.qoder/rules`, `.qoder/commands`, `.qoder/agents`, `hooks` & `mcpServers` in `settings.json`; built-in profile: `qoder`) from IDE, Work, Wake, and cloud UI storage. Patch only selected `mcpServers` subobjects, keep hooks parked unless `--activate-hooks`, keep local grants out of shared `.qoder/settings.json`, preserve plugin component namespaces, and exclude Quest/autonomous task artifacts from persistent rules.

Official sources: [1](https://docs.qoder.com/product-series/what-is-qoder) · [2](https://docs.qoder.com/cli/config-scope) · [3](https://docs.qoder.com/extensions/plugins) · [4](https://docs.qoder.com/qoder/custom-agents)

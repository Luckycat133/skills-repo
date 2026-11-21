# Identity and documentation gaps: do not invent native paths

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

## iflycode

**iFlyCode / iFlytek coding assistant** · Evidence: `discovery-required` · Runtime: `not-run`.

Public docs confirm the IDE plugin and `iflytek/iFly-Skills` repository (a Skill collection, not proof of an iFlyCode local autoload directory; Spark Agent Platform MCP is a separate cloud product). Inspect the installed plugin's settings/export UI before writing, park reviewed drafts in `.migration-review/`, and never invent `iflycode_mcp.json`.

Official sources: [1](https://iflycode.xfyun.cn/) · [2](https://github.com/iflytek/iFly-Skills) · [3](https://support.huaweicloud.com/iflycode-aislt/iflycode_05.html)

## raccoon-ai

**SenseTime coding Raccoon, not unrelated Raccoon products** · Evidence: `discovery-required` · Runtime: `not-run`.

Confirm SenseTime's coding assistant plugin/IDE build (do not use unrelated Raccoon agents or assume unverified rename paths). Inventory exposed UI instructions, prompts, memory, agents, and Skills/MCP controls; prepare reviewed Markdown drafts + a UI reconstruction checklist rather than fabricated disk paths, and exclude app state directories.

Official sources: [1](https://www.sensetime.com/cn/product-detail?categoryId=51134384) · [2](https://www.sensetime.com/cn/news/sensetime-raccoon-ai-coding-market-20260915-1816)

## vecli

**Volcengine veCLI; distinguish Ark CLI and service CLIs** · Evidence: `discovery-required` · Runtime: `not-run`.

Distinguish Volcengine's `veCLI` terminal agent from Ark CLI / Coding Plan provider-setup helpers. Confirm exact package, `--help`, and active config schema locally before writing; never invent `.vecli/` rules or MCP files, and exclude Ark API keys/session logs unless explicitly migrating `.env` credentials out-of-band.

Official sources: [1](https://developer.volcengine.com/resource/7564595926895951923) · [2](https://docs.volcengine.com/docs/ark/coding-plan-personal-get-started)

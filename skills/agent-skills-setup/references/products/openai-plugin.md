# openai-plugin

Review: 2026-11-07 · Client checks: not run · Contract: [products.md](../products.md).

**OpenAI/ChatGPT plugin packages and cloud workspace context** · Evidence: `documented-subset` · Runtime: `not-run`.

Current plugin packages use a root `plugin.json`, optional MCP configuration, Skills, and namespaced OpenAI extensions; do not conflate with older `.codex-plugin/` layouts or third-party plugin manifests. Preserve package identity when the target supports `plugin.json`; otherwise extract only user-selected portable Skills/instructions into reviewed drafts without copying cloud workspace connections, policies, or session state. Validate with the target's current plugin validator/import UI.

Official sources: [1](https://developers.openai.com/plugins/build/plugins) · [2](https://learn.chatgpt.com/docs/build-skills)

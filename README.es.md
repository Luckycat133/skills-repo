# Agent Skills Setup

[English](README.md) · [中文](README.zh-CN.md) · [日本語](README.ja-JP.md)

`agent-skills-setup` es un [Agent Skill](https://agentskills.io/specification) portátil
para agentes de programación existentes. Permite migrar, convertir o transferir reglas,
Agent Skills, servidores MCP, comandos, agentes personalizados, hooks, memoria escrita
por el usuario y claves API / `.env` entre IDE, CLI y ordenadores **sin exponer valores
secretos en el contexto del modelo (LLM)**.

## Diseño sin fugas en el contexto

- **Agent-First + script estándar sin dependencias**: Incluye `SKILL.md`, referencias
  bajo demanda (`references/`), plantillas (`assets/`) y un único script en librería
  estándar de Python 3.11+ (`skills/agent-skills-setup/scripts/migrate_context.py`).
  Sin paquetes propietarios `.acb`, servicio de firmas ni demonios en segundo plano.
- **Transferencia fuera de banda (`0700`/`0600`)**: Copia credenciales MCP y `.env*`
  disco a disco en modo `0600` (con respaldos privados `0600`), protege archivos
  rastreados por Git y solo imprime nombres de variables y prefijos `sha256[:8]` en
  `stdout` / `MIGRATION.md`. Usa `--redact-secrets` si prefieres marcadores de entorno.
- **Catálogo progresivo de 90 perfiles**: 15 perfiles integrados más 75+ herramientas
  enrutadas mediante `references/products.md` y `patch-mcp` (revisión: 2026-11-07;
  cobertura documental, no certificación de ejecución en todos los IDE).

Instala únicamente `skills/agent-skills-setup/` en el directorio de Skills de tu
cliente. Consulta el estado actual (`0.11.0-rc.1`, aún sin publicar) en
[docs/validation-status.md](docs/validation-status.md).

[Contribuir](CONTRIBUTING.md) · [Seguridad](SECURITY.md) · [Licencia (MIT)](LICENSE)

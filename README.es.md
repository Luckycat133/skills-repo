# Repositorio de Skills

> Estado: Desarrollo Activo · Fuente Canónica de Skills

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/openclaw.md)

> 🌐 Languages: [English](README.md) · [中文](README.zh-CN.md) · [日本語](README.ja-JP.md) · **Español**

Capacidades de Asistente de IA (anteriormente skills) con un flujo de trabajo de autoría centrado en lo local y un camino práctico hacia la publicación pública.

## Instalación

Instala la skill `agent-skills-setup` en tu entorno de agente:

**ClawHub (nativo de OpenClaw)**

```bash
openclaw skills install @luckycat133/agent-skills-setup
```

**skills.sh (multiagente, Vercel)**

```bash
npx skills add Luckycat133/skills-repo
```

Repositorio fuente: [Luckycat133/skills-repo](https://github.com/Luckycat133/skills-repo)

## Tabla de Contenidos

- [Resumen Rápido](#resumen-rápido)
- [Instalación](#instalación)
- [Estructura](#estructura)
- [Convenciones](#convenciones)
- [Módulo de Capacidad Actual](#módulo-de-capacidad-actual)
- [Flujo de Desarrollo](#flujo-de-desarrollo)
- [Importar Skills](#importar-skills)
- [Metadatos de Código Abierto](#metadatos-de-código-abierto)
- [Publicación](#publicación)

## Resumen Rápido

| Idioma | Resumen |
| --- | --- |
| Español | Mantén un Skill público dedicado a migración y limita la automatización de OpenClaw y publicación al repositorio. |

## Estructura

```text
skills-repo/
├── README.md
├── docs/
│   └── agent-skills-setup/
├── scripts/
└── skills/
    └── agent-skills-setup/
```

## Convenciones

- `skills/` almacena carpetas de skills publicables.
- `docs/` almacena notas de desarrollo, planes de lanzamiento, notas de validación y listas de verificación de mantenimiento.
- GitHub `main` es la fuente canónica de verdad; no edites las copias instaladas.
- Las skills específicas de producto permanecen en su repositorio de producto canónico.

## Módulo de Capacidad Actual

- `agent-skills-setup`: migración con consentimiento de contexto seleccionado entre IDE y agentes nombrados.

El alcance de migración entre IDE ahora incluye capacidades, prompts, configuraciones, reglas y flujos de trabajo.

Los ecosistemas de IDE principales cubiertos ahora incluyen 40 IDEs y agentes (Copilot, Cursor, Windsurf, JetBrains, Claude Code, Claude Desktop, Codex, OpenClaw, Trae, Trae CN, Antigravity, Kimi AI, Amazon Q, Gemini CLI, Zed, VS Code, Goose CLI, OpenCode, Continue, Roo Code, Cline, Kilo Code, Kiro, Augment Code, Baidu Comate, Tencent CodeBuddy, ZCode, Void Editor, Aider, Tabnine, Replit, Blackbox, Neovim, Emacs, Cody, Supermaven, Codeium, PearAI, Pieces, WorkBuddy).

## Flujo de Desarrollo

1. Edita la skill en `skills/` en una rama de GitHub.
2. Ejecuta `bash validate-all.sh`.
3. Para cambios en `agent-skills-setup`, ejecuta también la suite de verificación enfocada:
   - `bash skills/agent-skills-setup/scripts/verify-ide-config.sh` — verifica que las rutas de IDE resueltas coincidan con `references/ide-registry.md` (235 comprobaciones).
   - `bash skills/agent-skills-setup/scripts/test-ide-paths.sh` — prueba de deriva entre `references/ide-paths.json` y el script (450 comprobaciones).
   - `bash skills/agent-skills-setup/scripts/test-migration.sh` — pruebas del motor de migración (50 comprobaciones, HOME temporal aislado).
   - `bash skills/agent-skills-setup/scripts/test-security-audit-boundary.sh` — verifica que la automatización del repositorio no entre en el Skill publicable.
4. Fusiona solo después de que el flujo de validación pase.
5. Instala la versión fusionada en un entorno de agente:

```bash
bash install.sh
bash sync-to-codex.sh
bash sync-to-openclaw.sh
```

Los objetivos existentes nunca se sobrescriben silenciosamente. Pasa `--force` solo cuando quieras que el instalador mueva la copia actual a una copia de seguridad con marca de tiempo y la reemplace.

## Importar Skills

El ayudante de importación heredado sirve solo para traer una skill externa a una rama de revisión. El contenido importado no es canónico hasta la validación y la fusión.

Usa el script de importación incluido:

```bash
bash scripts/import-agent-skill.sh \
    ~/.gemini/config/skills/agent-skills-setup \
    agent-skills-setup
```

## Metadatos de Código Abierto

- Licencia: MIT
- Contribuciones: consulta `CONTRIBUTING.md`
- Reporte de seguridad: consulta `SECURITY.md`
- Expectativas de la comunidad: consulta `CODE_OF_CONDUCT.md`

## Publicación

Este repositorio está diseñado para admitir tanto el desarrollo local privado como la distribución pública.

Canales de distribución actuales:

- Repositorio de GitHub como fuente pública canónica.
- ClawHub para publicación nativa de OpenClaw y actualizaciones versionadas.
- `skills.sh` para descubrimiento multiagente.
- la lista comunitaria awesome-copilot, para visibilidad curada de Copilot (seguimiento como canal de distribución independiente).

Antes de publicar, ejecuta `bash validate-all.sh`, revisa `THIRD_PARTY_NOTICES.md` y confirma que el repositorio no contiene rutas privadas, secretos locales ni supuestos específicos de la máquina.

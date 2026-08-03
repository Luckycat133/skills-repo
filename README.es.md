# Repositorio de Skills

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/ides/openclaw.md)

> Languages: [English](README.md) · [中文](README.zh-CN.md) · [日本語](README.ja-JP.md) · **Español**

Skills reutilizables de asistentes de IA, creadas localmente y publicadas desde GitHub.

## Instalación

```bash
# OpenClaw
openclaw skills install @luckycat133/agent-skills-setup

# skills.sh
npx skills add Luckycat133/skills-repo
```

## Estructura

```text
skills-repo/
├── docs/                         # documentación de mantenimiento vigente
├── scripts/                      # herramientas del repositorio
└── skills/agent-skills-setup/    # Skill publicable canónico
    ├── SKILL.md
    ├── references/
    └── scripts/
```

## `agent-skills-setup`

Migra, con consentimiento explícito, contexto seleccionado entre IDE y agentes compatibles: skills, reglas, prompts y objetos MCP documentados. La configuración completa del IDE y los árboles opacos del proyecto requieren revisión manual. Consulta los 44 identificadores compatibles con el script y las superficies manuales en el [registro de IDE](skills/agent-skills-setup/references/ide-registry.md).

La versión 0.7.1 solo declara lectura y escritura de archivos locales y shell; no usa la red. Las escrituras aún requieren una ejecución `--yes` aprobada. Se rechazan los destinos MCP que sean enlaces simbólicos y la limpieza se limita al destino exacto o a la raíz verificada de una copia de Skill.

## Desarrollo

1. Edita `skills/agent-skills-setup/`; no edites el `SKILL.md` raíz generado.
2. Ejecuta `bash validate-all.sh`.
3. Tras cambiar el Skill canónico, ejecuta `bash scripts/sync-root-mirror.sh`.
4. Fusiona después de validar e instala con `bash install.sh` o el script de sync correspondiente.

Los destinos existentes se conservan salvo que `--force` solicite explícitamente una copia de seguridad con marca de tiempo y el reemplazo. Revisa skills externas en una rama con `bash scripts/import-agent-skill.sh <source-dir> <skill-name>`.

## Publicación

GitHub es la fuente canónica; ClawHub, `skills.sh` y Awesome Copilot son canales de distribución. Antes de publicar, ejecuta todas las pruebas y el análisis de seguridad, sube y verifica el commit de GitHub y exige un dry run correcto de ClawHub. Consulta la [lista de publicación](docs/agent-skills-setup/release-checklist.md).

## Proyecto

- [Contribuir](CONTRIBUTING.md)
- [Seguridad](SECURITY.md)
- [Código de conducta](CODE_OF_CONDUCT.md)
- [Licencia](LICENSE)

# Repositorio de Skills

[![GitHub Repo](https://img.shields.io/badge/GitHub-Luckycat133%2Fskills--repo-181717?logo=github)](https://github.com/Luckycat133/skills-repo)
[![License](https://img.shields.io/badge/License-MIT-b7285.svg)](LICENSE)
[![OpenClaw Ready](https://img.shields.io/badge/OpenClaw-Ready-1f7a8c)](skills/agent-skills-setup/references/ides/openclaw.md)

> Languages: [English](README.md) · [中文](README.zh-CN.md) · [日本語](README.ja-JP.md) · **Español**

Skills reutilizables de asistentes de IA, creadas localmente y publicadas desde GitHub.

## Uso

Instala `agent-skills-setup` mediante el gestor de Skills del agente actual o ClawHub. El repositorio no proporciona un instalador entre agentes; la instalación solo pone las referencias y el script de migración a disposición de ese agente.
La instalación no selecciona un IDE. `--source`, `--target`, `--objects` y `--workspace` pertenecen al comando de migración que el agente ejecuta después.

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

Migra contexto con alcance definido entre IDE y agentes compatibles: skills, reglas, prompts y objetos MCP documentados. La configuración completa del IDE y los árboles opacos del proyecto requieren revisión manual. Consulta los 44 identificadores compatibles con el script y las superficies manuales en el [registro de IDE](skills/agent-skills-setup/references/ide-registry.md).

El paquete de ejecución contiene referencias y un único comando de migración. No instala IDE ni runtimes, no crea enlaces simbólicos o bloqueos de registro y no se copia en los directorios de otros agentes. Las migraciones globales seleccionan Skills por defecto; los objetos de proyecto usan un workspace explícito.

## Desarrollo

1. Edita `skills/agent-skills-setup/`; no edites el `SKILL.md` raíz generado.
2. Ejecuta `bash validate-all.sh`.
3. Tras cambiar el Skill canónico, ejecuta `bash scripts/sync-root-mirror.sh`.
4. Fusiona después de validar.

Revisa skills externas en una rama con `bash scripts/import-agent-skill.sh <source-dir> <skill-name>`.

## Publicación

GitHub es la fuente canónica; ClawHub y Awesome Copilot son canales de distribución. Antes de publicar, ejecuta todas las pruebas y el análisis de seguridad, sube y verifica el commit de GitHub y exige un dry run correcto de ClawHub. Consulta la [lista de publicación](docs/agent-skills-setup/release-checklist.md).

## Proyecto

- [Contribuir](CONTRIBUTING.md)
- [Seguridad](SECURITY.md)
- [Código de conducta](CODE_OF_CONDUCT.md)
- [Licencia](LICENSE)

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

Migra contexto con alcance definido entre perfiles de producto. Registry v2 registra ciclo de vida, versión, fuente, alcance, almacenamiento y política por superficie; las entradas legacy, cloud, provider, host-editor y alias no son destinos de escritura ordinarios. Consulta el [registro de IDE](skills/agent-skills-setup/references/ide-registry.md).

El paquete de ejecución contiene referencias y un único comando de migración. No instala IDE ni runtimes, no crea enlaces simbólicos o bloqueos de registro y no se copia en los directorios de otros agentes. Las migraciones globales seleccionan Skills por defecto; los objetos de proyecto usan un workspace explícito.
Antes de copiar un directorio de Skill se analiza todo el texto de origen. Una credencial literal probable o un enlace fuera del Skill hace que se omita sin modificar el origen ni el destino existente.
El frontmatter canónico usa solo campos estándar de Agent Skills. La CLI por perfiles ofrece `detect`, `inventory`, `plan`, `apply`, `verify` y `rollback`; las instrucciones pasan por un IR tipado con informe de pérdida, y la aplicación crea respaldos exactos y un manifiesto verificable.

## Desarrollo

1. Edita `skills/agent-skills-setup/`; no edites el puntero generado del repositorio raíz.
2. Ejecuta `bash validate-all.sh`.
3. Tras cambiar el Skill canónico, ejecuta `bash scripts/sync-root-mirror.sh` para actualizar el puntero raíz.
4. Fusiona después de validar.

Revisa skills externas en una rama con `bash scripts/import-agent-skill.sh <source-dir> <skill-name>`.

## Publicación

GitHub es la fuente canónica; ClawHub y Awesome Copilot son canales de distribución. El repositorio sigue bajo MIT; el bundle generado para ClawHub usa MIT-0 por separado, elimina licencias incompatibles y declara Bash/Python. La publicación exige reconocer explícitamente la autorización de los contribuidores. Consulta la [lista de publicación](docs/agent-skills-setup/release-checklist.md).

## Proyecto

- [Contribuir](CONTRIBUTING.md)
- [Seguridad](SECURITY.md)
- [Código de conducta](CODE_OF_CONDUCT.md)
- [Licencia](LICENSE)

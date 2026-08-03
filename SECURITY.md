# Security Policy

Do not open a public issue for a potential vulnerability. Report it privately to the maintainer with the affected file/workflow, impact, reproduction, and any known mitigation.

Preferred channel: a private [GitHub Security Advisory](https://docs.github.com/en/code-security/security-advisories). Do not disclose details until a fix is released.

Reports covering repository scripts, install/sync workflows, or published assets are in scope.

Published migration code is expected to declare only the local capabilities it
uses, preserve dry-run and explicit-write gates, reject indirect MCP targets,
and constrain cleanup to verified target paths. Releases must pass the complete
test suite, a skill security scan, and a registry dry run before publication.

# Security

The published Skill contains instructions and templates, not a runtime sandbox.
The host agent's permissions remain authoritative. Inspect imported content as
untrusted data. No scanner or document promises zero secret leakage.

Do not post credentials, tokens, cookies, raw configuration, private paths or
session logs in public issues. Review and redact examples manually. Use GitHub's
private vulnerability reporting when available; otherwise ask the maintainer for
a private channel before disclosing sensitive details.

The Skill must not auto-execute hooks/scripts, transfer OAuth/trust state, broaden
permissions, or follow paths outside the approved scope. Package and fixture tests
are not a substitute for actual host validation.

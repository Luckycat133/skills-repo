#!/usr/bin/env bash
# common.sh - Unified, agent-readable output for agent-skills-setup scripts.
#
# Output contract (plain ASCII so it parses cleanly in CI, non-UTF-8 terminals,
# and by LLM agents):
#   * Diagnostics use a fixed "[LEVEL] message" prefix on stderr:
#       [INFO]  informational
#       [WARN]  recoverable / needs attention
#       [ERROR] fatal / abort
#   * Result lines use a fixed ASCII status token on stdout:
#       [OK]    success / copied
#       [WARN]  manual / partial
#       [FAIL]  failed / error
#       [-]    skipped / absent / none
#   * Colors/markup are gated behind a TTY; default output is plain text.
#   * Optional JSON mode: set MIGRATE_JSON=1 (or pass --json) to emit a
#     machine-readable summary on stdout instead of the human report.

# TTY / color capability (colors stay OFF by default for agent logs).
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  MIGRATE_TTY=1
else
  MIGRATE_TTY=0
fi

log_info()  { printf '[INFO] %s\n'  "$*" >&2; }
log_warn()  { printf '[WARN] %s\n'  "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }
log_debug() { [[ -n "${DEBUG:-}" ]] && printf '[DEBUG] %s\n' "$*" >&2; }

# Map a semantic migration status to a short, stable ASCII token.
status_token() {
  case "$1" in
    success|copied|ok)   printf 'OK'   ;;
    manual|partial|warn) printf 'WARN' ;;
    failed|error)        printf 'FAIL' ;;
    skipped|absent|none) printf '-'   ;;
    *)                   printf '?'   ;;
  esac
}

# Escape a string for safe embedding inside a JSON string value.
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  # Collapse literal newlines/tabs into JSON escapes.
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

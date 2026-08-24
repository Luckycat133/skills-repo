#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_PATH="${SCRIPT_DIR}/../references/registry-v2.json"

WS="$(mktemp -d /tmp/handoff-refusal-ws.XXXXXX)"
trap 'rm -rf "$WS"' EXIT

# Establish a git workspace on a real, named branch (not detached HEAD).
git -C "$WS" init -q
git -C "$WS" config user.email "test@example.com"
git -C "$WS" config user.name "ACB Test"
git -C "$WS" checkout -q -b "release/0.8.21"
printf 'seed\n' > "$WS/seed.txt"
git -C "$WS" add -A
git -C "$WS" commit -qm "seed"

# Handoff source contains a private field that must never reach any target.
mkdir -p "$WS/.agent"
printf '{"summary": "Reviewed handoff snapshot", "raw": "machine-specific-path-should-be-stripped"}\n' \
    > "$WS/.agent/handoff.json"

cd "$SCRIPT_DIR"

python3 - "$REGISTRY_PATH" "$WS" <<'PYEOF'
import sys
from pathlib import Path

registry_path = Path(sys.argv[1])
workspace = Path(sys.argv[2])
sys.path.insert(0, str(registry_path.parent.parent / "scripts"))

from migration_core import (  # noqa: E402
    AUTO_WRITABLE_OBJECT_TYPES,
    ItemStatus,
    PlanItem,
    SurfacePath,
    apply_plan,
)


def make_surface(resolved: Path, boundary: Path) -> SurfacePath:
    return SurfacePath(
        product="cline",
        profile="ide",
        object_type="handoff",
        scope="user",
        storage="home",
        path=".agent/handoff.json",
        resolved_path=resolved,
        boundary=boundary,
        source_format="json",
        policy="manual-rebuild",
        location_role="source",
        canonical_path=".agent/handoff.json",
        precedence=0,
    )


source = make_surface(workspace / ".agent" / "handoff.json", workspace)
dest = workspace / ".cursor" / "handoff" / "session.json"
item = PlanItem(
    object_type="handoff",
    status=ItemStatus.READY.value,
    reason="replayed-plan handoff fixture",
    source=source,
    target=make_surface(dest, workspace),
)

# Audit SDI-2 (0.8.32): session-derived artifacts have NO write path.
# There is no opt-in flag anymore — even a replayed plan that marks a
# handoff item eligible must fail closed without writing anything.
assert "handoff" not in AUTO_WRITABLE_OBJECT_TYPES
try:
    apply_plan([item], workspace, workspace / "manifest.json")
except ValueError as exc:
    assert "no automatic writer" in str(exc), exc
    print(f"OK apply refuses handoff unconditionally: {exc}")
else:
    raise AssertionError("apply_plan wrote a handoff/session artifact")
assert not dest.exists(), "session artifact reached the target tree"

print("OK handoff write path is structurally absent")
PYEOF

echo "Handoff refusal test passed"

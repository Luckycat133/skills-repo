#!/usr/bin/env bash
# ==============================================================================
# test-acb-all-installed.sh: E2E tests for --all-installed multi-IDE snapshot,
# multi-target restore, 1:1 manifest binding, and atomic staging.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(mktemp -d /tmp/acb-all-inst-XXXXXX)"
HOME_SRC="$WORKSPACE/home_src"
WS_SRC="$WORKSPACE/ws_src"
HOME_DST="$WORKSPACE/home_dst"
WS_DST="$WORKSPACE/ws_dst"

mkdir -p "$HOME_SRC" "$WS_SRC" "$HOME_DST" "$WS_DST"
trap 'rm -rf "$WORKSPACE"' EXIT

MIGRATOR="python3 $SCRIPT_DIR/context-migrator.py"
REGISTRY="$SCRIPT_DIR/../references/registry-v2.json"

echo "=== Test 1: Setup multiple simulated source IDEs on Device A ==="
# 1. Cline (user skills + user mcp)
mkdir -p "$HOME_SRC/.cline/skills/cline-helper" "$HOME_SRC/.cline/data/settings"
cat <<'EOF' > "$HOME_SRC/.cline/skills/cline-helper/SKILL.md"
---
name: cline-helper
description: Cline helper skill
---
# Cline Helper
EOF

cat <<'EOF' > "$HOME_SRC/.cline/data/settings/cline_mcp_settings.json"
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
    }
  }
}
EOF

# 2. Cursor (user skills + project rules)
mkdir -p "$HOME_SRC/.cursor/skills/cursor-helper" "$WS_SRC/.cursor/rules"
cat <<'EOF' > "$HOME_SRC/.cursor/skills/cursor-helper/SKILL.md"
---
name: cursor-helper
description: Cursor helper skill
---
# Cursor Helper
EOF

cat <<'EOF' > "$WS_SRC/.cursor/rules/lint.mdc"
---
description: lint rule
globs: ["*.py"]
---
Always lint Python code.
EOF

# 3. Claude Code (user skills + project mcp)
mkdir -p "$HOME_SRC/.claude/skills/claude-helper"
cat <<'EOF' > "$HOME_SRC/.claude/skills/claude-helper/SKILL.md"
---
name: claude-helper
description: Claude Code helper skill
---
# Claude Helper
EOF

cat <<'EOF' > "$WS_SRC/.mcp.json"
{
  "mcpServers": {
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git"]
    }
  }
}
EOF

echo "OK source fixtures initialized"

echo "=== Test 2: snapshot --all-installed ==="
BUNDLE="$WORKSPACE/multi-device.acb"
SNAPSHOT_OUT="$(HOME="$HOME_SRC" $MIGRATOR snapshot \
  --registry "$REGISTRY" \
  --workspace "$WS_SRC" \
  --output "$BUNDLE" \
  --all-installed \
  --scope user,project \
  --json)"

echo "$SNAPSHOT_OUT" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data.get("ok") is True, data
assert data.get("objects_captured", 0) >= 3, f"Expected at least 3 captured objects, got: {data}"
print("OK snapshot --all-installed captured objects:", data["objects_captured"])
'

# Verify manifest and closed-world 1:1 file bindings
python3 -c "
import json
from pathlib import Path
bundle = Path('$BUNDLE')
manifest = json.loads((bundle / 'manifest.json').read_text())
objects = manifest.get('objects', [])
assert len(objects) >= 3, f'Expected >= 3 manifest objects, got {len(objects)}'

products = {obj.get('product') for obj in objects}
assert 'cline' in products, f'cline missing from manifest products: {products}'
assert 'cursor' in products, f'cursor missing from manifest products: {products}'
assert 'claude' in products, f'claude missing from manifest products: {products}'

for obj in objects:
    files = obj.get('files', [])
    assert len(files) >= 1, f'Object {obj} missing files array'
    for f in files:
        disk_file = bundle / f['path']
        assert disk_file.is_file(), f'Declared file missing: {disk_file}'

print('OK manifest 1:1 file binding verified across products:', sorted(products))
"

echo "=== Test 3: bundle-verify on multi-product bundle ==="
VERIFY_OUT="$($MIGRATOR bundle-verify "$BUNDLE" --json)"
echo "$VERIFY_OUT" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data.get("ok") is True, data
assert data.get("errors") == [], data
print("OK bundle-verify clean for multi-product bundle")
'

echo "=== Test 4: doctor requirements inspection ==="
DOCTOR_OUT="$($MIGRATOR doctor "$BUNDLE" --json)"
echo "$DOCTOR_OUT" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data.get("ok") is True, data
reqs = json.loads(open("'"$BUNDLE"'/requirements.json").read())
executables = reqs.get("executables", [])
packages = reqs.get("packages", [])

# Verify IDE names are not mistaken for executables
assert "cursor" not in executables, f"cursor should not be in executables: {executables}"
assert "cline" not in executables, f"cline should not be in executables: {executables}"

# Verify real command runners and packages are present
pkg_names = [p.get("name") for p in packages]
assert any("@modelcontextprotocol/server-filesystem" in p for p in pkg_names), f"Missing filesystem package: {packages}"
assert any("mcp-server-git" in p for p in pkg_names), f"Missing git package: {packages}"
print("OK doctor requirements accurately parsed command runners and packages:", pkg_names)
'

echo "=== Test 5: restore --all-installed onto Device B ==="
# Setup Device B with simulated installed IDEs: Windsurf and Forge
mkdir -p "$HOME_DST/.codeium/windsurf/skills" "$HOME_DST/forge/skills" "$WS_DST/.cursor/rules"

RESTORE_OUT="$(HOME="$HOME_DST" $MIGRATOR restore \
  "$BUNDLE" \
  --registry "$REGISTRY" \
  --workspace "$WS_DST" \
  --all-installed \
  --scope user,project \
  --apply-safe \
  --yes \
  --json)"

echo "$RESTORE_OUT" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data.get("ok") is True, data
summary = data.get("summary", {})
assert summary.get("applied", 0) >= 1, f"Expected applied >= 1, got {summary}"
print("OK restore --all-installed applied summary:", summary)
'

echo "=== Test 6: Verify restored files on Device B ==="
# Check skills landed in destination IDEs
find "$HOME_DST" -type f | sort
python3 -c "
from pathlib import Path
home_dst = Path('$HOME_DST')
ws_dst = Path('$WS_DST')

# Check skill restoration
found_skills = list(home_dst.rglob('SKILL.md'))
assert len(found_skills) >= 1, f'No skills restored under {home_dst}'
print('OK restored skills found on Device B:', [str(s.relative_to(home_dst)) for s in found_skills])
"

echo "=== Test 7: Atomic bundle creation rollback on failure ==="
# Create a valid pre-existing bundle
EXISTING_BUNDLE="$WORKSPACE/existing.acb"
HOME="$HOME_SRC" $MIGRATOR snapshot \
  --registry "$REGISTRY" \
  --workspace "$WS_SRC" \
  --source cline/ide \
  --output "$EXISTING_BUNDLE" \
  --json >/dev/null

PRE_MTIME=$(stat -f %m "$EXISTING_BUNDLE/manifest.json" 2>/dev/null || stat -c %Y "$EXISTING_BUNDLE/manifest.json")

# Attempt writing a bundle with an injected secret to the same output path
python3 -c "
import sys
from pathlib import Path
sys.path.insert(0, '$SCRIPT_DIR')
from acb.bundle import write_bundle, ACBManifest, ACBSecretLeak, make_bundle_id

manifest = ACBManifest(
    schema_version=1,
    bundle_id=make_bundle_id(),
    created_at='2026-08-20T00:00:00Z',
    source_platform={'system': 'darwin'},
    inventory_summary={},
    objects=[{'product': 'cline', 'surface': 'skills', 'files': []}],
)

# Object containing private key leak
leak_objects = {'skills/cline/ide/user/key.pem': b'-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0...'}
try:
    write_bundle(
        bundle_root=Path('$EXISTING_BUNDLE'),
        manifest=manifest,
        inventory_rows=[],
        compatibility={},
        requirements={},
        secrets_required=[],
        reauth=[],
        rebuild=[],
        objects_dir_files=leak_objects,
    )
    raise SystemExit('FAIL: write_bundle did not reject secret')
except ACBSecretLeak:
    print('OK write_bundle rejected secret during atomic staging')
"

# Verify pre-existing bundle was NOT corrupted or wiped
assert_exists() {
    [[ -f "$EXISTING_BUNDLE/manifest.json" ]] || { echo "FAIL: existing manifest.json was destroyed"; exit 1; }
    [[ -f "$EXISTING_BUNDLE/checksums.json" ]] || { echo "FAIL: existing checksums.json was destroyed"; exit 1; }
}
assert_exists
echo "OK atomic staging safely preserved pre-existing bundle on write failure"

echo
echo "All all-installed multi-IDE E2E tests PASSED!"

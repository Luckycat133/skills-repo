#!/usr/bin/env python3
"""Maintainer-only packaging; never reads or modifies user IDE configuration."""
from __future__ import annotations
import argparse
import hashlib
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "agent-skills-setup"
# Explicit reviewable allowlist; no filesystem-glob admission into the package.
# 220 KB permits the requested on-demand vendor catalog, not a runtime platform.
MAX_PACKAGE_BYTES = 220_000
ALLOWED = frozenset({
    'LICENSE',
    'SKILL.md',
    'references/device-transfer.md',
    'references/discovery.md',
    'references/instructions.md',
    'references/mcp.md',
    'references/other-context.md',
    'references/products/alibaba.md',
    'references/products/amp-openhands.md',
    'references/products/anthropic.md',
    'references/products/aws.md',
    'references/products/blackbox-pieces.md',
    'references/products/china-coding.md',
    'references/products/china-discovery.md',
    'references/products/cline-kilo-roo.md',
    'references/products/cloud-builders.md',
    'references/products/continue-zed.md',
    'references/products/copilot.md',
    'references/products/cursor.md',
    'references/products/devin-windsurf.md',
    'references/products/editor-plugins.md',
    'references/products/enterprise.md',
    'references/products/factory-augment.md',
    'references/products/google-cli-assist.md',
    'references/products/google-ide-cloud.md',
    'references/products/jetbrains-xcode.md',
    'references/products/legacy.md',
    'references/products/letta.md',
    'references/products/new-clients.md',
    'references/products/openai.md',
    'references/products/openclaw-hermes.md',
    'references/products/opencode.md',
    'references/products/tencent.md',
    'references/products/terminal-agents.md',
    'references/products/trae.md',
    'references/products/warp.md',
    'references/products/zencoder.md',
    'references/products.md',
    'references/verification.md',
    'assets/device-readme.md',
    'assets/migration-report.md',
})

def package_files(skill: Path = SKILL) -> list[Path]:
    if skill.is_symlink() or not skill.is_dir():
        raise ValueError("Skill root must be an ordinary directory")
    files = []
    for path in sorted(skill.rglob("*")):
        if path.is_symlink():
            raise ValueError(f"symlink is not allowed: {path}")
        if path.is_dir():
            continue
        if not path.is_file():
            raise ValueError(f"non-regular package entry: {path}")
        rel = path.relative_to(skill).as_posix()
        if rel not in ALLOWED:
            raise ValueError(f"unexpected package file: {rel}")
        files.append(path)
    actual = {p.relative_to(skill).as_posix() for p in files}
    if actual != ALLOWED:
        raise ValueError(f"missing package files: {sorted(ALLOWED - actual)}")
    if sum(p.stat().st_size for p in files) > MAX_PACKAGE_BYTES:
        raise ValueError("Package exceeds documentation budget; review scope before raising it")
    return files

def build(output: Path, skill: Path = SKILL) -> str:
    files = package_files(skill)
    output = output.absolute()
    if output == skill.resolve() or skill.resolve() in output.resolve().parents:
        raise ValueError("Output must be outside the Skill source")
    if output.exists() or output.is_symlink():
        raise ValueError("Refusing to replace an existing output; choose a new path")
    if not output.parent.is_dir():
        raise ValueError("Output parent must already exist")
    created = False
    try:
        stream = output.open("xb")
        created = True
        with stream, zipfile.ZipFile(stream, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for path in files:
                info = zipfile.ZipInfo("agent-skills-setup/" + path.relative_to(skill).as_posix())
                info.date_time = (2026, 11, 7, 0, 0, 0)
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o100644 << 16
                archive.writestr(info, path.read_bytes())
    except Exception:
        if created and output.is_file():
            output.unlink()
        raise
    return hashlib.sha256(output.read_bytes()).hexdigest()

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    try:
        digest = build(args.output)
    except (OSError, ValueError, zipfile.BadZipFile) as exc:
        parser.exit(1, f"ERROR: {exc}\n")
    print(f"{digest}  {args.output}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

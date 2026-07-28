#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
compute_manifest.py - Generate a dataset manifest (version control +
integrity verification).

What it does:
  - Walk the data files under train_data / validation_data / test_data,
    computing each file's SHA-256, size, and modification time;
  - Write the result to .manifests/manifest_<version>_<timestamp>.json;
  - This manifest is the core of dataset version control: instead of
    committing large files to Git, commit the lightweight manifest and use
    its checksums to confirm a given version's data is untampered and
    reproducible.

Usage:
    python compute_manifest.py --version v1.0.0
    # Verify the current data matches a manifest:
    python compute_manifest.py --verify .manifests/manifest_v1.0.0_xxx.json
"""
import argparse
import hashlib
import json
import os
import sys
from datetime import datetime

DEFAULT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIRS = ("train_data", "validation_data", "test_data")
# Skip placeholder and metadata-irrelevant files
IGNORE_NAMES = {".gitkeep", ".DS_Store"}


def sha256_of(path, chunk=1 << 20):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(chunk), b""):
            h.update(block)
    return h.hexdigest()


def scan(root):
    entries = {}
    for d in DATA_DIRS:
        base = os.path.join(root, d)
        for dirpath, _, filenames in os.walk(base):
            for name in sorted(filenames):
                if name in IGNORE_NAMES:
                    continue
                full = os.path.join(dirpath, name)
                rel = os.path.relpath(full, root)
                st = os.stat(full)
                entries[rel] = {
                    "sha256": sha256_of(full),
                    "bytes": st.st_size,
                    "mtime": datetime.fromtimestamp(st.st_mtime).isoformat(timespec="seconds"),
                }
    return entries


def build_manifest(root, version):
    entries = scan(root)
    return {
        "version": version,
        "created_at": datetime.now().isoformat(timespec="seconds"),
        "file_count": len(entries),
        "total_bytes": sum(e["bytes"] for e in entries.values()),
        "files": entries,
    }


def verify(root, manifest_path):
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)
    current = scan(root)
    old = manifest["files"]
    changed, added, removed = [], [], []
    for rel, info in old.items():
        if rel not in current:
            removed.append(rel)
        elif current[rel]["sha256"] != info["sha256"]:
            changed.append(rel)
    for rel in current:
        if rel not in old:
            added.append(rel)
    print(f"[VERIFY] against manifest {os.path.basename(manifest_path)} (version={manifest.get('version')})")
    for tag, lst in (("changed", changed), ("added", added), ("removed", removed)):
        for rel in lst:
            print(f"  [{tag.upper():<7}] {rel}")
    if not (changed or added or removed):
        print("  [OK] data matches the manifest exactly; no changes.")
        return 0
    print(f"  Changes: {len(changed)} modified / {len(added)} added / {len(removed)} removed")
    return 3


def main():
    p = argparse.ArgumentParser(description="Generate/verify a dataset manifest")
    p.add_argument("--version", help="semantic version, e.g. v1.0.0 (generation mode)")
    p.add_argument("--verify", help="verification mode: path to a manifest json")
    p.add_argument("--root", default=DEFAULT_ROOT)
    args = p.parse_args()

    if args.verify:
        sys.exit(verify(args.root, args.verify))

    if not args.version:
        sys.exit("[ERROR] generation mode requires --version, e.g. --version v1.0.0")

    manifest = build_manifest(args.root, args.version)
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    out_dir = os.path.join(args.root, ".manifests")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, f"manifest_{args.version}_{ts}.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    try:
        os.chmod(out, 0o640)
    except OSError:
        pass
    print(f"[OK] manifest generated: {out}")
    print(f"     file_count={manifest['file_count']}  total_bytes={manifest['total_bytes']} bytes")
    print("     Commit this manifest to Git and record the version in DATA_VERSION.md.")


if __name__ == "__main__":
    main()

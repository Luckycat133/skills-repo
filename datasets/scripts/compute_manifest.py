#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
compute_manifest.py — 生成数据集清单（版本控制 + 完整性校验）

功能:
  - 遍历 train_data / validation_data / test_data 下的数据文件，
    计算每个文件的 SHA-256、大小、修改时间；
  - 输出到 .manifests/manifest_<version>_<timestamp>.json；
  - 该清单是数据版本控制的核心：不把大文件塞进 Git，而是提交轻量清单，
    通过校验和确认"某版本的数据"未被篡改、可复现。

用法:
    python compute_manifest.py --version v1.0.0
    # 验证当前数据是否与某清单一致：
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
# 忽略占位与元数据无关文件
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
    print(f"[VERIFY] 基于清单 {os.path.basename(manifest_path)} (version={manifest.get('version')})")
    for tag, lst in (("changed", changed), ("added", added), ("removed", removed)):
        for rel in lst:
            print(f"  [{tag.upper():<7}] {rel}")
    if not (changed or added or removed):
        print("  [OK] 数据与清单完全一致，未发生变更。")
        return 0
    print(f"  变更: {len(changed)} 修改 / {len(added)} 新增 / {len(removed)} 删除")
    return 3


def main():
    p = argparse.ArgumentParser(description="生成/校验数据集清单")
    p.add_argument("--version", help="语义化版本号，如 v1.0.0（生成模式）")
    p.add_argument("--verify", help="校验模式：给定清单 json 路径")
    p.add_argument("--root", default=DEFAULT_ROOT)
    args = p.parse_args()

    if args.verify:
        sys.exit(verify(args.root, args.verify))

    if not args.version:
        sys.exit("[ERROR] 生成模式需 --version，如 --version v1.0.0")

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
    print(f"[OK] 清单已生成: {out}")
    print(f"     文件数={manifest['file_count']}  总大小={manifest['total_bytes']} bytes")
    print("     请将该清单提交至 Git，并在 DATA_VERSION.md 记录本次版本。")


if __name__ == "__main__":
    main()

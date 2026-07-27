#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
split_dataset.py — 分层随机划分：train / validation / test

设计目标：零第三方依赖（仅标准库），结果可复现（固定随机种子），
默认采用分层抽样（stratified sampling）保证各集合标签分布一致。

划分语义（重要）:
    1) 先从全量数据中按 test_ratio 留出 [测试集]（占总量，建议 20%-30%）。
    2) 再从剩余"训练数据池"中按 val_ratio 留出 [验证集]
       （val_ratio 是相对"剩余池"的比例，即占训练数据的比例，建议 15%-20%）。
    3) 剩余即为 [训练集]。

用法示例:
    python split_dataset.py \\
        --input datasets/train_data/raw/full_dataset.csv \\
        --label-col label --test-ratio 0.25 --val-ratio 0.18 --seed 42
"""
import argparse
import csv
import os
import random
import sys
from collections import defaultdict

# 默认输出到 datasets/<split>/processed/ 下
DEFAULT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def read_csv(path):
    with open(path, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames is None:
            sys.exit(f"[ERROR] 输入文件为空或无表头: {path}")
        return list(reader), reader.fieldnames


def write_csv(path, rows, fieldnames):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    # 数据文件权限 640
    try:
        os.chmod(path, 0o640)
    except OSError:
        pass


def stratified_split(rows, label_col, test_ratio, val_ratio, seed):
    """返回 (train_rows, val_rows, test_rows)。按 label 分层，逐层切分后合并。"""
    rng = random.Random(seed)
    by_label = defaultdict(list)
    for r in rows:
        by_label[r.get(label_col, "__NA__")].append(r)

    train, val, test = [], [], []
    for label, items in sorted(by_label.items(), key=lambda kv: str(kv[0])):
        items = items[:]
        rng.shuffle(items)
        n = len(items)
        n_test = int(round(n * test_ratio))
        remaining = n - n_test
        n_val = int(round(remaining * val_ratio))
        # 边界保护：每层至少各留 1 条（样本足够时）
        if n >= 3:
            n_test = min(max(n_test, 1), n - 2)
            n_val = min(max(n_val, 1), n - n_test - 1)
        test.extend(items[:n_test])
        val.extend(items[n_test:n_test + n_val])
        train.extend(items[n_test + n_val:])

    # 合并后再整体打乱，避免按标签聚块
    rng.shuffle(train)
    rng.shuffle(val)
    rng.shuffle(test)
    return train, val, test


def main():
    p = argparse.ArgumentParser(description="分层随机划分 train/validation/test")
    p.add_argument("--input", required=True, help="输入 CSV（全量带标签数据）")
    p.add_argument("--label-col", required=True, help="标签列名（用于分层）")
    p.add_argument("--test-ratio", type=float, default=0.25,
                   help="测试集占总量比例，建议 0.20-0.30（默认 0.25）")
    p.add_argument("--val-ratio", type=float, default=0.18,
                   help="验证集占'剩余训练池'比例，建议 0.15-0.20（默认 0.18）")
    p.add_argument("--seed", type=int, default=42, help="随机种子（默认 42）")
    p.add_argument("--root", default=DEFAULT_ROOT, help="datasets 根目录")
    args = p.parse_args()

    for r, name in [(args.test_ratio, "test-ratio"), (args.val_ratio, "val-ratio")]:
        if not 0.0 < r < 1.0:
            sys.exit(f"[ERROR] {name} 必须在 (0,1) 之间，当前 {r}")

    rows, fieldnames = read_csv(args.input)
    if args.label_col not in fieldnames:
        sys.exit(f"[ERROR] 标签列 '{args.label_col}' 不在表头: {fieldnames}")

    train, val, test = stratified_split(
        rows, args.label_col, args.test_ratio, args.val_ratio, args.seed)

    outputs = {
        "train_data": (train, f"train_seed{args.seed}.csv"),
        "validation_data": (val, f"validation_seed{args.seed}.csv"),
        "test_data": (test, f"test_seed{args.seed}.csv"),
    }
    total = len(rows)
    print(f"[INFO] 输入总样本: {total}  (seed={args.seed}, "
          f"test_ratio={args.test_ratio}, val_ratio={args.val_ratio})")
    for split, (data, fname) in outputs.items():
        out = os.path.join(args.root, split, "processed", fname)
        write_csv(out, data, fieldnames)
        pct = (len(data) / total * 100) if total else 0
        print(f"[OK]  {split:<16} {len(data):>7} 条 ({pct:5.1f}%) -> {out}")

    print("[DONE] 划分完成。下一步：python scripts/verify_distribution.py "
          f"--label-col {args.label_col} --seed {args.seed}")


if __name__ == "__main__":
    main()

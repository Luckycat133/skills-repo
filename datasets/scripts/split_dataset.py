#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
split_dataset.py - Stratified random split: train / validation / test.

Design goals: zero third-party dependencies (standard library only),
reproducible results (fixed random seed), and stratified sampling so each
split keeps the same label distribution.

Split semantics (important):
  1) Hold out the [test set] from the full data by test_ratio
     (share of the total; recommended 20%-30%).
  2) Hold out the [validation set] from the remaining "training pool"
     by val_ratio (share of the *remaining pool*, i.e. of the training
     data; recommended 15%-20%).
  3) Whatever remains is the [training set].

Usage example:
    python split_dataset.py \
        --input datasets/train_data/raw/full_dataset.csv \
        --label-col label --test-ratio 0.25 --val-ratio 0.18 --seed 42
"""
import argparse
import csv
import os
import random
import sys
from collections import defaultdict

# Default output under datasets/<split>/processed/
DEFAULT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def read_csv(path):
    with open(path, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames is None:
            sys.exit(f"[ERROR] input file is empty or has no header: {path}")
        return list(reader), reader.fieldnames


def write_csv(path, rows, fieldnames):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    # Data file mode 640
    try:
        os.chmod(path, 0o640)
    except OSError:
        pass


def stratified_split(rows, label_col, test_ratio, val_ratio, seed):
    """Return (train_rows, val_rows, test_rows). Split per label, then merge."""
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
        # Boundary guard: keep at least 1 sample per split when enough exist
        if n >= 3:
            n_test = min(max(n_test, 1), n - 2)
            n_val = min(max(n_val, 1), n - n_test - 1)
        test.extend(items[:n_test])
        val.extend(items[n_test:n_test + n_val])
        train.extend(items[n_test + n_val:])

    # Shuffle each split again after merging to avoid label-clustered blocks
    rng.shuffle(train)
    rng.shuffle(val)
    rng.shuffle(test)
    return train, val, test


def main():
    p = argparse.ArgumentParser(description="Stratified random split train/validation/test")
    p.add_argument("--input", required=True, help="input CSV (full labeled data)")
    p.add_argument("--label-col", required=True, help="label column name (for stratification)")
    p.add_argument("--test-ratio", type=float, default=0.25,
                   help="test set share of total; recommended 0.20-0.30 (default 0.25)")
    p.add_argument("--val-ratio", type=float, default=0.18,
                   help="validation share of 'remaining training pool'; recommended 0.15-0.20 (default 0.18)")
    p.add_argument("--seed", type=int, default=42, help="random seed (default 42)")
    p.add_argument("--root", default=DEFAULT_ROOT, help="datasets root directory")
    args = p.parse_args()

    for r, name in [(args.test_ratio, "test-ratio"), (args.val_ratio, "val-ratio")]:
        if not 0.0 < r < 1.0:
            sys.exit(f"[ERROR] {name} must be between (0,1), got {r}")

    rows, fieldnames = read_csv(args.input)
    if args.label_col not in fieldnames:
        sys.exit(f"[ERROR] label column '{args.label_col}' not in header: {fieldnames}")

    train, val, test = stratified_split(
        rows, args.label_col, args.test_ratio, args.val_ratio, args.seed)

    outputs = {
        "train_data": (train, f"train_seed{args.seed}.csv"),
        "validation_data": (val, f"validation_seed{args.seed}.csv"),
        "test_data": (test, f"test_seed{args.seed}.csv"),
    }
    total = len(rows)
    print(f"[INFO] total input samples: {total}  (seed={args.seed}, "
          f"test_ratio={args.test_ratio}, val_ratio={args.val_ratio})")
    for split, (data, fname) in outputs.items():
        out = os.path.join(args.root, split, "processed", fname)
        write_csv(out, data, fieldnames)
        pct = (len(data) / total * 100) if total else 0
        print(f"[OK]  {split:<16} {len(data):>7} rows ({pct:5.1f}%) -> {out}")
    print("[DONE] split complete. Next step: python scripts/verify_distribution.py "
          f"--label-col {args.label_col} --seed {args.seed}")


if __name__ == "__main__":
    main()

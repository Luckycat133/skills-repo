#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verify_distribution.py - Verify label-distribution consistency across the
train / validation / test splits.

Metrics:
  1) Per-class proportion table for each split;
  2) Max absolute proportion deviation of validation/test vs train;
  3) PSI (Population Stability Index), measuring distribution drift:
        PSI < 0.10  stable distribution (good consistency)
        0.10-0.25  mild drift (worth watching)
        > 0.25     significant drift (split likely problematic)

Zero third-party dependencies; standard library only.
"""
import argparse
import csv
import math
import os
import sys
from collections import Counter

DEFAULT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def load_labels(path, label_col):
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        if label_col not in (reader.fieldnames or []):
            sys.exit(f"[ERROR] label column '{label_col}' not found in {path}")
        return [row[label_col] for row in reader]


def proportions(labels, classes):
    n = len(labels) or 1
    c = Counter(labels)
    return {k: c.get(k, 0) / n for k in classes}


def psi(expected, actual, classes, eps=1e-6):
    total = 0.0
    for k in classes:
        e = max(expected.get(k, 0.0), eps)
        a = max(actual.get(k, 0.0), eps)
        total += (a - e) * math.log(a / e)
    return total


def main():
    p = argparse.ArgumentParser(
        description="Verify label-distribution consistency across dataset splits")
    p.add_argument("--label-col", required=True)
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--root", default=DEFAULT_ROOT)
    p.add_argument("--psi-threshold", type=float, default=0.10)
    args = p.parse_args()

    files = {
        "train": os.path.join(args.root, "train_data", "processed",
                              f"train_seed{args.seed}.csv"),
        "validation": os.path.join(args.root, "validation_data", "processed",
                                   f"validation_seed{args.seed}.csv"),
        "test": os.path.join(args.root, "test_data", "processed",
                             f"test_seed{args.seed}.csv"),
    }

    data = {}
    for split, path in files.items():
        labels = load_labels(path, args.label_col)
        if labels is None:
            sys.exit(f"[ERROR] cannot find {split} file: {path}\n"
                     "        run split_dataset.py first")
        data[split] = labels

    classes = sorted(set().union(*[set(v) for v in data.values()]), key=str)
    props = {s: proportions(labels, classes) for s, labels in data.items()}

    # Print the proportion table
    print(f"{'label':<16}" + "".join(f"{s:>12}" for s in files))
    print("-" * (16 + 12 * len(files)))
    for k in classes:
        print(f"{str(k):<16}" + "".join(f"{props[s][k]*100:>11.2f}%" for s in files))
    print("-" * (16 + 12 * len(files)))
    print(f"{'N (count)':<16}" + "".join(f"{len(data[s]):>12}" for s in files))

    # Compare against train
    print("\n[Distribution consistency vs train]")
    ok = True
    for split in ("validation", "test"):
        max_dev = max(abs(props[split][k] - props["train"][k]) for k in classes)
        val_psi = psi(props["train"], props[split], classes)
        status = "OK" if val_psi < args.psi_threshold else "WARN"
        if val_psi >= args.psi_threshold:
            ok = False
        print(f"  {split:<11} max prop deviation={max_dev*100:5.2f}%  "
              f"PSI={val_psi:.4f}  [{status}]")

    print("\n[Conclusion] " + ("Distribution consistency is good; safe to use."
          if ok else
          "Distribution drift detected; check the data source or re-run the stratified split."))
    sys.exit(0 if ok else 2)


if __name__ == "__main__":
    main()

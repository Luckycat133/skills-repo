#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verify_distribution.py — 校验 train/validation/test 三集合的标签分布一致性

指标:
  1) 各集合的每类占比表；
  2) 与训练集相比，验证集/测试集的最大占比偏差（max abs deviation）；
  3) PSI（Population Stability Index），衡量分布漂移：
        PSI < 0.10  分布稳定（一致性良好）
        0.10-0.25   轻微漂移（需关注）
        > 0.25      显著漂移（划分可能有问题）

零第三方依赖，仅标准库。
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
            sys.exit(f"[ERROR] 标签列 '{label_col}' 不在 {path}")
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
    p = argparse.ArgumentParser(description="校验各数据集标签分布一致性")
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
            sys.exit(f"[ERROR] 找不到 {split} 文件: {path}\n"
                     "        请先运行 split_dataset.py")
        data[split] = labels

    classes = sorted(set().union(*[set(v) for v in data.values()]), key=str)
    props = {s: proportions(labels, classes) for s, labels in data.items()}

    # 打印占比表
    print(f"{'label':<16}" + "".join(f"{s:>12}" for s in files))
    print("-" * (16 + 12 * len(files)))
    for k in classes:
        print(f"{str(k):<16}" + "".join(f"{props[s][k]*100:>11.2f}%" for s in files))
    print("-" * (16 + 12 * len(files)))
    print(f"{'N (count)':<16}" + "".join(f"{len(data[s]):>12}" for s in files))

    # 与 train 对比
    print("\n[分布一致性 vs train]")
    ok = True
    for split in ("validation", "test"):
        max_dev = max(abs(props[split][k] - props["train"][k]) for k in classes)
        val_psi = psi(props["train"], props[split], classes)
        status = "OK" if val_psi < args.psi_threshold else "WARN"
        if val_psi >= args.psi_threshold:
            ok = False
        print(f"  {split:<11} 最大占比偏差={max_dev*100:5.2f}%  "
              f"PSI={val_psi:.4f}  [{status}]")

    print("\n[结论] " + ("分布一致性良好，可放心使用。" if ok else
          "存在分布漂移，建议检查数据来源或重新分层划分。"))
    sys.exit(0 if ok else 2)


if __name__ == "__main__":
    main()

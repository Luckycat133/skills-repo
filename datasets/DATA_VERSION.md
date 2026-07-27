# DATA_VERSION.md — 数据版本控制与更新历史

本文件记录数据集的版本演进。采用**语义化版本（SemVer）** `vMAJOR.MINOR.PATCH`：

- **MAJOR**：不兼容变更（schema 变化、标签定义变化、划分口径变化）。
- **MINOR**：向后兼容的新增（新增样本、新增特征列）。
- **PATCH**：修复类变更（修正错误标签、去重、清洗）。

## 版本控制机制

数据文件通常较大且不适合直接进 Git。本目录采用**清单（manifest）+ 校验和**方式做版本控制：

1. 每次数据定版后运行 `python scripts/compute_manifest.py --version vX.Y.Z`，
   在 `.manifests/` 生成含每个文件 **SHA-256** 的清单快照。
2. 将该清单 JSON 与本文件一并提交 Git（清单很小），真实数据由外部存储/DVC/LFS 托管。
3. 任何人可用 `python scripts/compute_manifest.py --verify <清单路径>` 校验本地数据
   是否与某版本完全一致（防篡改、可复现）。

> 如需更强能力，可接入 [DVC](https://dvc.org/) 或 Git LFS；本机制为零依赖的轻量替代。

---

## 更新历史（Changelog）

### v1.0.0 — 2026-07-24
- 初始化标准化数据集目录结构（train/validation/test + raw/processed/metadata）。
- 建立划分脚本、分布校验脚本与清单机制。
- 划分口径：test=25%（占总量），validation=18%（占剩余训练池），seed=42，分层抽样。

<!--
新版本按如下模板追加（置于最上方，倒序排列）：

### vX.Y.Z — YYYY-MM-DD
- 变更类型（MAJOR/MINOR/PATCH）：...
- 变更内容：...
- 影响范围：train / validation / test
- 对应清单：.manifests/manifest_vX.Y.Z_<timestamp>.json
- 划分参数：test_ratio=.. val_ratio=.. seed=..
-->

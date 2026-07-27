# Datasets — 标准化数据集目录

本目录遵循机器学习工程通用规范，用于**清晰、可维护、可复现**地组织训练集、验证集与测试集。
核心原则：**职责分离、命名统一、版本可追溯、划分可复现、权限最小化**。

---

## 1. 完整目录结构

```
datasets/
├── README.md                     # 本文件：目录结构总说明（先读我）
├── DATA_USAGE_GUIDE.md           # 数据使用规范指南（团队必读）
├── DATA_VERSION.md               # 数据版本控制 / 更新历史（Changelog）
│
├── config/                       # 路径与划分参数配置
│   ├── data_paths.example.yaml   # 路径配置示例（YAML）
│   └── data_paths.example.json   # 路径配置示例（JSON）
│
├── scripts/                      # 可复现的数据处理脚本（零第三方依赖）
│   ├── split_dataset.py          # 分层随机划分：train / validation / test
│   ├── verify_distribution.py    # 划分后各集合分布一致性校验
│   └── compute_manifest.py       # 生成 SHA-256 清单，用于版本追踪与完整性校验
│
├── train_data/                   # 训练集（模型拟合用）
│   ├── README.md
│   ├── raw/                      # 原始、未处理数据（只读，不可修改）
│   ├── processed/                # 清洗/特征工程后的数据
│   └── metadata/                 # 特征字典、schema、标签映射等
│
├── validation_data/              # 验证集（调参 / 早停 / 模型选择用）
│   ├── README.md
│   ├── raw/
│   ├── processed/
│   └── metadata/
│
├── test_data/                    # 测试集（最终评估用，训练全程不可接触）
│   ├── README.md
│   ├── raw/
│   ├── processed/
│   └── metadata/
│
└── .manifests/                   # 各版本数据清单快照（由 compute_manifest.py 生成）
```

> 每个数据集目录下的 `raw/processed/metadata` 三层结构是行业惯例：
> - **raw**：原始输入，视为不可变（immutable）源，任何处理都不在此写入。
> - **processed**：经过清洗、编码、特征工程后的可直接喂给模型的数据。
> - **metadata**：特征含义、数据字典、schema、标签编码表、统计摘要等。

---

## 2. 命名规范（统一强制）

| 项目 | 规范 | 示例 |
|------|------|------|
| 顶层数据集目录 | 小写 + 下划线，语义明确 | `train_data` / `validation_data` / `test_data` |
| 数据文件 | `<数据集>_<版本>_<切片>.<扩展名>` | `test_v1.2.0.csv` |
| 版本号 | 语义化版本 SemVer | `v1.0.0`（详见 DATA_VERSION.md） |
| 随机种子 | 固定并记录在配置与文件名 | `seed42` |
| 目录/文件 | 全小写、避免空格与中文、用下划线 | `feature_dictionary.md` |

---

## 3. 三大数据集职责边界

| 数据集 | 用途 | 是否参与训练 | 使用频率 |
|--------|------|--------------|----------|
| **train_data** | 模型参数拟合 | 是 | 每个 epoch |
| **validation_data** | 超参调优、早停、模型选择 | 否（仅评估） | 每轮/多次 |
| **test_data** | 最终、无偏性能评估 | 否（严格隔离） | **仅一次**（发布前） |

> 铁律：**测试集在模型开发全过程中不得以任何形式泄漏**（不参与调参、不做特征选择、不反复评估）。反复看测试集会造成过拟合泄漏，评估结果失真。

---

## 4. 快速开始

```bash
# 1) 将原始带标签数据放入 train_data/raw/（例如 full_dataset.csv）
# 2) 执行分层随机划分（默认 test=25%，validation≈18%）
python datasets/scripts/split_dataset.py \
  --input datasets/train_data/raw/full_dataset.csv \
  --label-col label \
  --test-ratio 0.25 \
  --val-ratio 0.18 \
  --seed 42

# 3) 校验三个集合的标签分布是否一致
python datasets/scripts/verify_distribution.py --label-col label

# 4) 生成数据清单（校验和 + 版本快照）
python datasets/scripts/compute_manifest.py --version v1.0.0
```

详细划分策略、比例建议与分布一致性措施见 **DATA_USAGE_GUIDE.md**。

---

## 5. 安全与权限

- 目录权限 `750`（`drwxr-x---`）：仅属主可写，同组可读，其他用户无权限。
- 数据文件建议权限 `640`（`-rw-r-----`）。
- 敏感/隐私数据**不入库 Git**；`raw/` 与 `processed/` 下的真实数据应通过 `.gitignore` 排除，仅保留 `.gitkeep` 与 metadata。
- 版本追踪与完整性依靠 `.manifests/` 下的 SHA-256 清单，而非直接把大文件提交到仓库。

---

## 6. 交付物索引

| 交付物 | 文件 |
|--------|------|
| 完整文件夹结构说明 | 本文件 `README.md` |
| 数据存放路径配置示例 | `config/data_paths.example.{yaml,json}` |
| 数据使用规范指南 | `DATA_USAGE_GUIDE.md` |
| 数据版本控制/更新历史 | `DATA_VERSION.md` |
| 划分/校验/清单脚本 | `scripts/*.py` |
| 各集合数据说明 | `{train,validation,test}_data/README.md` |

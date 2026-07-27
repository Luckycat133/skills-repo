# DATA_USAGE_GUIDE — 数据使用规范指南

面向使用本数据集目录的所有工程师。目标：**可复现、无泄漏、分布一致、安全合规**。

---

## 1. 数据集划分：比例建议

| 数据集 | 推荐比例 | 计算基准 | 作用 |
|--------|----------|----------|------|
| **测试集 test** | **20% – 30%** | 占**全部独立数据总量** | 最终无偏评估 |
| **验证集 validation** | **15% – 20%** | 占**剩余训练数据池**（扣除测试集后） | 调参 / 早停 / 模型选择 |
| **训练集 train** | 剩余部分（约 50%–65%） | — | 参数拟合 |

> 经验法则：
> - 数据量**小（< 1 万）**：可用 60/20/20，或改用 **K 折交叉验证** 替代固定验证集。
> - 数据量**大（> 10 万）**：验证/测试各取一个足够大的绝对样本量即可（如各 1–2 万），无需死守百分比。
> - 存在**时间序列/分布漂移**：测试集应取**最新时间段**（按时间切分），而非随机抽样。

本目录默认：`test_ratio=0.25`、`val_ratio=0.18`（占剩余池）、`seed=42`。

---

## 2. 划分的具体实施步骤

```bash
# 步骤 1：放置原始全量带标签数据
cp your_full_dataset.csv datasets/train_data/raw/full_dataset.csv

# 步骤 2：执行分层随机划分（可复现）
python datasets/scripts/split_dataset.py \
  --input datasets/train_data/raw/full_dataset.csv \
  --label-col label \
  --test-ratio 0.25 \
  --val-ratio 0.18 \
  --seed 42

# 步骤 3：校验三集合的标签分布一致性（PSI < 0.10 视为一致）
python datasets/scripts/verify_distribution.py --label-col label --seed 42

# 步骤 4：定版并生成校验清单
python datasets/scripts/compute_manifest.py --version v1.0.0
#   随后在 DATA_VERSION.md 记录本次版本，并提交清单到 Git
```

---

## 3. 随机划分方法与可复现性

- **固定随机种子**：所有划分使用同一 `seed`（默认 42），任何人重跑得到完全相同的切分。
- **分层抽样（stratified）**：按标签列分组后在每组内部按比例抽样，保证 train/val/test 的
  类别占比与总体一致 —— 尤其对**类别不平衡**数据至关重要。
- **打乱顺序**：切分后整体 shuffle，避免样本按标签聚块影响 batch 采样。

---

## 4. 确保数据分布一致性的措施

1. **分层抽样**：从源头保证各类别比例一致（本目录脚本默认启用）。
2. **一致性量化校验**：`verify_distribution.py` 输出每类占比 + 最大偏差 + **PSI**：
   - `PSI < 0.10` 稳定 ✅ ；`0.10–0.25` 轻微漂移 ⚠️ ；`> 0.25` 显著漂移 ❌。
3. **连续特征分布**（可选）：对关键数值特征额外比较均值/分位数，或做 KS 检验。
4. **时间/来源一致性**：确认三集合无跨期泄漏；测试集与训练集不重叠、不同源要显式说明。

---

## 5. 防数据泄漏铁律（Data Leakage）

- **预处理只在训练集上 fit**（标准化、编码、缺失值填充的统计量），再 transform 到 val/test。
- **去重要在划分前**完成，避免同一样本同时落入 train 与 test。
- **特征选择 / 调参只用 validation**，绝不看 test。
- **test 只在最终评估读取一次**；反复用 test 迭代 = 变相过拟合泄漏。

---

## 6. 安全与合规

- 目录权限 `750`、数据文件 `640`（仅属主可写、同组可读）。
- 真实数据**不提交 Git**（见 `.gitignore`），仅提交 metadata 与清单。
- 含 PII / 敏感信息的数据需脱敏或加密存储，遵循所在组织的数据合规要求。
- `raw/` 视为**不可变源**，任何清洗结果写入 `processed/`。

---

## 7. 目录使用速查

| 我想… | 去哪里 |
|-------|--------|
| 放原始数据 | `train_data/raw/` |
| 看特征含义 | `<split>/metadata/feature_dictionary.md` |
| 改路径/比例配置 | `config/data_paths.example.{yaml,json}` |
| 划分数据 | `scripts/split_dataset.py` |
| 校验分布 | `scripts/verify_distribution.py` |
| 定版/校验完整性 | `scripts/compute_manifest.py` |
| 查版本历史 | `DATA_VERSION.md` |

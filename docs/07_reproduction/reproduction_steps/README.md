# 复现步骤说明

这份文档只保留当前有效的复现路线，不再混入开发过程中的旧待办、旧结论和重复运行记录。

## 1. 当前项目做到哪里

当前项目已经完成第一轮 30 步建设：

```text
raw_code
  保留为只读原始代码和 baseline

src
  已有 independent decoding
  已有 independent evaluation
  已有 independent NSGA-II search
  已有 metrics
  已有 visualization

scripts
  已有 independent small / medium / formal
  已有 metrics / visualization
  已有 baseline small comparison
  已有 multiseed summary

tests
  已有 smoke / invalid / integration / raw compare / dry-run

docs
  已有复现步骤、实验说明和新项目迁移手册
```

## 2. 三十步当前状态

| 阶段 | 步骤 | 当前结果 |
|---|---:|---|
| 原始代码认识与运行骨架 | 1-10 | 数据、评价、small、medium、配置和入口已整理 |
| 实验工程化与模板 | 11-20 | outputs、日志、指标、图表和工程模板已建立 |
| independent 核心实现 | 21-23 | decoding、evaluation、NSGA-II search 已独立实现 |
| 对照和实验入口 | 24-25 | raw 对照通过，independent 实验入口已建立 |
| 结果闭环和迁移 | 26-30 | formal、结果分析、baseline、多 seed、迁移演练已完成首轮 |

这里的“完成首轮”表示入口、测试和第一轮运行已经完成，不表示所有论文级大规模实验都已完成。

## 3. Independent 主线

### 第 21 步：Independent decoding

[打开说明](21_independent_decoding.md)

```text
不调用 raw sorting.m
单条染色体可独立解码
population 可独立解码
```

### 第 22 步：Independent evaluation

[打开说明](22_independent_evaluation.md)

```text
不调用 raw fitness.m
可独立计算 makespan 和 energy
```

### 第 23 步：Independent NSGA-II

[打开说明](23_independent_nsga2_search.md)

```text
不调用 raw NSGA2.m
搜索流程使用自己的 encoding / decoding / evaluation
```

### 第 24 步：Raw 对照验收

[打开说明](24_independent_raw_compare.md)

```text
decoding 有 raw 对照
evaluation 有 raw 对照
search small 有 raw 对照
```

### 第 25 步：Independent 实验入口

[打开说明](25_independent_experiment_entries.md)

```text
small 可运行
medium 可运行
formal 有受保护入口
```

## 4. 第 26-30 步结果闭环

| 步骤 | 说明 | 状态 |
|---|---|---|
| 26 | [Independent formal 真正运行](26_independent_formal_run.md) | 已真实运行 |
| 27 | [Metrics / visualization 接 outputs](27_independent_result_analysis.md) | 已接通并生成结果 |
| 28 | [Baseline small 对比](28_baseline_comparison_small.md) | 已完成单 seed small 对比 |
| 29 | [Independent 多 seed 汇总](29_independent_multiseed_summary.md) | 已完成 small 五 seed |
| 30 | [新项目迁移演练](30_new_project_migration_rehearsal.md) | 模板和字段测试已完成 |

## 5. 已验证结果

### Independent formal

```text
dataset: Mk01
seed: 42
pop: 30
max_gen: 10
runTime: 7.625127
paretoSolutionCount: 4
bestMakespan: 111.853333
bestTotalEnergy: 1669.020000
usedRawSearch: 0
usedRawDecoding: 0
usedRawEvaluation: 0
```

### 结果分析

```text
spacing: 2.549194
Pareto 图: 已生成
收敛曲线: 已生成
HV / IGD / C-metric: 缺少 reference 或 baseline，当前为 NaN
```

### Baseline small

| 结果 | Raw NSGA-II | Independent NSGA-II |
|---|---:|---:|
| Pareto 解数量 | 3 | 1 |
| 最优 makespan | 155.886667 | 138.456667 |
| 最优 totalEnergy | 1890.048000 | 1936.654667 |

### Independent small 五 seed

```text
seedList: [42 43 44 45 46]
bestMakespan mean/std: 137.010000 / 3.095851
bestTotalEnergy mean/std: 1909.781867 / 18.655365
runTime mean/std: 0.809344 / 0.253770
paretoSolutionCountMean: 2.400000
```

## 6. 我现在应该怎么运行

### 快速检查配置

```matlab
run('tests/test_independent_experiment_configs.m')
run('tests/test_independent_formal_preflight.m')
```

### 跑 small

```matlab
run('scripts/run_independent_small_nsga2.m')
```

### 跑 medium

```matlab
run('scripts/run_independent_medium_nsga2.m')
```

### 跑 formal

先检查：

```matlab
run('tests/test_independent_formal_preflight.m')
```

明确确认后运行：

```matlab
RUN_INDEPENDENT_FORMAL_CONFIRMED = true;
run('scripts/run_independent_formal_nsga2.m')
```

### 分析 formal 结果

```matlab
run('scripts/run_independent_metrics.m')
run('scripts/run_independent_visualization.m')
```

### 跑 baseline small

```matlab
run('scripts/run_baseline_comparison_small.m')
```

### 跑 independent 多 seed

```matlab
run('scripts/run_independent_multiseed_summary.m')
```

## 7. 遇到新项目怎么套

按以下顺序：

```text
config / data dry-run
-> encoding
-> decoding
-> evaluation
-> independent small
-> metrics / visualization
-> independent medium
-> formal preflight
-> independent formal
-> baseline / multiseed
```

详细说明：

- [新项目套用与复现入口顺序](10_reproduction_entry_layers.md)
- [新项目迁移手册](../../08_engineering/new_project_migration_guide.md)
- [新项目迁移演练](../../08_engineering/new_project_migration_rehearsal.md)

## 8. 当前尚未完成的论文级工作

```text
formal 多 seed
formal 多算法 baseline 对比
完整 reference point / reference front 设计
完整 HV / IGD / C-metric 论文结果
消融实验
真实新选题从数据到论文结果的完整迁移
```

## 9. 阅读原则

```text
README.md
  看项目总体状态

本文件
  看当前复现顺序

第 21-30 步独立页面
  看每一步的入口、结果和边界

```

# baseline 对比 small 验收

## 1. 本阶段目标

第 28 步用于跑通最小 baseline 对比闭环：

```text
baseline = raw NSGA-II
variant = independent NSGA-II
```

本阶段只跑 small，不跑 medium / formal baseline 对比。

## 2. 配置入口

```text
configs/baseline_comparison_config.m
```

当前配置：

```text
baselineName: raw_nsga2
variantName: independent_nsga2
datasetName: Mk01
seed: 42
pop: 10
max_gen: 2
outputBaseDir: outputs/baseline_comparison_small
```

## 3. 运行入口

```text
scripts/run_baseline_comparison_small.m
```

MATLAB 命令：

```matlab
run('scripts/run_baseline_comparison_small.m')
```

脚本会依次运行：

```text
raw NSGA-II baseline
independent NSGA-II variant
```

并把两个结果保存到同一个 run 目录。

## 4. 测试入口

```matlab
run('tests/test_baseline_comparison_config.m')
run('tests/test_baseline_comparison_small.m')
```

`test_baseline_comparison_config.m` 只检查配置，不运行算法。

`test_baseline_comparison_small.m` 会运行 small 对比，并检查：

```text
baseline obj_matrix 非空
variant obj_matrix 非空
二者 objective column 数一致
seed 一致
pop / max_gen 一致
variant 标记为 independent
raw_code 状态未变化
```

## 5. 输出目录

每次运行输出到：

```text
outputs/baseline_comparison_small/<timestamp>/
```

目录包含：

```text
result.mat
summary.txt
run_info.txt
```

`outputs/` 不提交 Git。

## 6. 当前阶段没有完成什么

当前阶段不是论文正式对比实验，还没有做：

```text
medium baseline comparison
formal baseline comparison
multi-seed comparison
HV / IGD / Spacing / C-metric 对比表
图表对比
```

这些属于后续第 29 步和更完整的论文实验阶段。

## 7. 完成标准

第 28 步完成后，应满足：

```text
raw baseline small 可跑
independent variant small 可跑
两者 obj_matrix 可比
统一 seed / pop / max_gen
输出目录独立
raw_code 只读未修改
outputs 不进 Git
```


# 第 29 步：多 seed 统计汇总

## 目标

把 independent 搜索从一次随机运行提升为可以重复多次并汇总统计结果的实验入口。

## 入口

```text
配置：configs/independent_multiseed_config.m
脚本：scripts/run_independent_multiseed_summary.m
配置测试：tests/test_independent_multiseed_config.m
dry-run 测试：tests/test_independent_multiseed_summary_dryrun.m
```

MATLAB 命令：

```matlab
run('scripts/run_independent_multiseed_summary.m')
```

## 已完成结果

已验收输出：

```text
outputs/independent_multiseed/20260529_142234/
seedList：[42 43 44 45 46]
seedCount：5
pop：10
max_gen：2
```

统计摘要：

| 指标 | mean | std | best | worst |
|---|---:|---:|---:|---:|
| bestMakespan | 137.010000 | 3.095851 | 132.363333 | 140.770000 |
| bestTotalEnergy | 1909.781867 | 18.655365 | 1890.132000 | 1936.654667 |
| runTime | 0.809344 | 0.253770 | - | - |

```text
paretoSolutionCountMean：2.400000
```

每个 seed 都有独立目录和结果，总目录包含：

```text
aggregate_summary.txt
aggregate_result.mat
```

## 完成结论

```text
5 个 seed 已真实运行
每个 seed 的结果独立保存
mean / std / best / worst 可生成
outputs 未提交 Git
```

本步骤使用 small 参数，不是 formal 多 seed 论文统计。

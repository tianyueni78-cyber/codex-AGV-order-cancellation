# independent 多 seed 统计汇总说明

## 1. 本阶段目标

第 29 步把 independent 结果从“单次运行”推进到“多 seed 统计汇总”。当前仍使用 small 参数，避免一开始就跑正式大规模多 seed。

```text
seedList = [42, 43, 44, 45, 46]
pop <= 10
max_gen <= 2
```

## 2. 配置入口

```text
configs/independent_multiseed_config.m
```

当前配置：

```text
runType: independent_multiseed_small
seedList: [42, 43, 44, 45, 46]
pop: 10
max_gen: 2
outputBaseDir: outputs/independent_multiseed
```

## 3. 运行入口

```text
scripts/run_independent_multiseed_summary.m
```

MATLAB 命令：

```matlab
run('scripts/run_independent_multiseed_summary.m')
```

脚本会遍历 seedList。每个 seed 都运行一次 independent NSGA-II，并单独保存结果。

## 4. 输出结构

总输出目录：

```text
outputs/independent_multiseed/<timestamp>/
```

每个 seed 子目录：

```text
seed_42/result.mat
seed_42/summary.txt
seed_42/run_info.txt
```

总目录包含：

```text
aggregate_summary.txt
aggregate_result.mat
```

## 5. aggregate summary 字段

当前汇总：

```text
bestMakespanMean
bestMakespanStd
bestMakespanBest
bestMakespanWorst
bestTotalEnergyMean
bestTotalEnergyStd
bestTotalEnergyBest
bestTotalEnergyWorst
runTimeMean
runTimeStd
paretoSolutionCountMean
```

## 6. 测试入口

```matlab
run('tests/test_independent_multiseed_config.m')
run('tests/test_independent_multiseed_summary_dryrun.m')
```

`test_independent_multiseed_config.m` 检查 seedList、small 参数和输出目录。

`test_independent_multiseed_summary_dryrun.m` 静态检查脚本结构，不运行算法。

## 7. 当前阶段没有完成什么

当前阶段不是 formal 多 seed，也不是 baseline 多 seed 对比，还没有生成论文最终统计表。

后续如果要进入论文级统计，应再增加：

```text
baseline / variant 多 seed 对比
metrics 多 seed 汇总
boxplot 或表格输出
formal 参数下多 seed
```

## 8. 完成标准

第 29 步完成后，应满足：

```text
多 seed 可运行
每个 seed 结果独立保存
aggregate summary 可生成
mean / std / best / worst 可读
raw_code 未修改
outputs 不进 Git
```


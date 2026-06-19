# formal 实验运行前检查

## formal 是什么

formal 是正式实验入口，用来在参数、seed、输出和记录规则都确认之后运行完整复现实验。

当前阶段不是正式运行 formal。

当前阶段只是 formal 运行前检查，用来确认入口是否安全、配置是否完整、输出是否可追溯。

## small / medium / formal 的区别

```text
small
  用途：快速 smoke test
  运行成本：低
  常规验收时可以运行

medium
  用途：中等规模验收
  运行成本：中
  用来从 smoke 过渡到 formal

formal
  用途：正式实验
  运行成本：高
  本阶段只检查，不运行
```

## 当前入口

formal 运行脚本：

```text
scripts/run_formal_nsga2.m
```

formal 配置：

```text
configs/formal_nsga2_config.m
```

dry-run 测试：

```text
tests/test_formal_nsga2_config.m
tests/test_formal_entry_static.m
tests/test_experiment_entry_configs.m
```

## 当前 formal 参数

当前 formal config 继承 medium config，然后覆盖 formal 相关字段：

```text
runType = formal
experimentName = formal_nsga2_Mk01
datasetName = Mk01
outputBaseDir = outputs/formal_nsga2
algorithmName = NSGA-II
pop = 30
max_gen = 10
```

seed 字段：

```text
seed = 42
seedList = 42
currentSeed = 42
```

算法参数来自 config：

```text
p_cross
p_mutation
pop
max_gen
```

能耗参数来自 config：

```text
AGVEG_MAX
eChargeSpeed
```

## 输出目录规则

formal 正式运行时应写入：

```text
outputs/formal_nsga2/<timestamp>/
```

`run_formal_nsga2.m` 使用 timestamp 目录，并在重名时追加 suffix，避免覆盖旧 outputs。

预期输出文件：

```text
formal_nsga2_result.mat
summary.txt
run_info.txt
```

## summary.txt 应记录什么

`summary.txt` 用来快速查看一次 formal 运行结果，应包含：

```text
experimentName
datasetName
seed
pop
max_gen
p_cross
p_mutation
runTime
paretoSolutionCount
bestMakespan
bestTotalEnergy
outputDir
```

## run_info.txt 应记录什么

`run_info.txt` 用来复现实验，应包含：

```text
runType
experimentName
description
datasetName
datasetSource
datasetNote
fjsp
machineExcel
agvExcel
algorithmDir
outputDir
algorithmName
seed
seedList
pop
max_gen
p_cross
p_mutation
AGVEG_MAX
eChargeSpeed
```

## 如何 dry-run 检查

本阶段只运行配置和静态检查：

```matlab
run('tests/test_formal_nsga2_config.m')
run('tests/test_experiment_entry_configs.m')
run('tests/test_formal_entry_static.m')
```

这些测试不会运行 NSGA-II，不会生成 formal outputs。

## 本阶段为什么不运行 formal

formal 是正式实验入口，运行成本更高，也会生成正式 outputs。

在正式运行前，必须先确认：

```text
配置字段完整
seed 可追溯
输出目录正确
run log 规则明确
不会写 raw_code
不会覆盖旧 outputs
```

所以当前阶段只做 preflight，不启动：

```matlab
run('scripts/run_formal_nsga2.m')
```

## 真正运行 formal 前 checklist

运行 formal 前检查：

```text
git status 干净
raw_code 无变化
outputs 不会被 stage
formal config 参数已确认
currentSeed 已确认
seedList 已确认
outputBaseDir = outputs/formal_nsga2
磁盘空间足够
明确本次运行是否要保留 outputs
```

运行后检查：

```text
outputs/formal_nsga2/<timestamp>/ 存在
formal_nsga2_result.mat 存在
summary.txt 存在
run_info.txt 存在
obj_matrix 非空
raw_code 无变化
outputs 不进 Git
没有 logs/tmp/cache/data.mat
```

## 当前没有完成什么

当前阶段没有运行 formal。

当前阶段没有验证论文最终结果。

当前阶段没有生成正式指标表或论文图。

这些内容应在 formal 正式运行任务中单独完成。

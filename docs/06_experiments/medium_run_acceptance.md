# medium 实验 dry-run / 小规模验收

## medium 是做什么的

medium 是 small smoke test 和 formal 正式实验之间的中间档位。

它的用途是确认：

```text
入口能跑
参数可追溯
输出目录正确
结果结构非空
不会污染 raw_code
```

medium 不是正式实验，也不用于验证论文最终结果。

## 和 small / formal 的区别

```text
small
  用途：快速 smoke test
  参数：pop = 10, max_gen = 2
  运行成本：低

medium
  用途：中等规模验收
  参数：pop = 20, max_gen = 5
  运行成本：中

formal
  用途：正式实验
  参数：formal config 控制
  运行成本：高
```

## 当前入口

运行入口：

```text
scripts/run_medium_nsga2.m
```

配置入口：

```text
configs/medium_nsga2_config.m
```

dry-run 配置测试：

```text
tests/test_medium_nsga2_config.m
```

## 当前参数

当前 medium config 继承 small config，然后覆盖：

```text
outputBaseDir = outputs/medium_nsga2
pop = 20
max_gen = 5
```

seed 继承自 small config：

```text
seed = 42
```

交叉和变异概率也来自 config：

```text
p_cross
p_mutation
```

## 如何 dry-run 检查

dry-run 只检查配置，不运行算法，不生成 outputs：

```matlab
run('tests/test_medium_nsga2_config.m')
run('tests/test_experiment_entry_configs.m')
```

通过代表：

```text
medium config 存在
medium 参数大于 small
seed 可追溯
输出路径在 outputs/medium_nsga2
数据路径和 algorithmDir 存在
```

## 如何实际运行 medium

如果要做小规模 medium 运行验收，在 MATLAB 中运行：

```matlab
run('scripts/run_medium_nsga2.m')
```

该入口会生成：

```text
outputs/medium_nsga2/<timestamp>/
```

目录中应包含：

```text
medium_nsga2_result.mat
summary.txt
run_info.txt
```

## summary.txt 怎么看

`summary.txt` 应包含：

```text
runType
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

如果 `paretoSolutionCount` 大于 0，并且 `bestMakespan`、`bestTotalEnergy` 可读，说明 medium 小规模运行至少产生了可检查结果。

## 当前没有完成什么

当前阶段不是 formal 正式实验。

当前阶段不验证论文最终指标。

当前阶段不修改 raw_code。

当前阶段不提交 outputs。

## 污染检查

运行前后都要确认：

```text
raw_code 无变化
outputs 不进 Git
没有 logs/tmp/cache/data.mat
```

如果实际运行 medium，`outputs/medium_nsga2/<timestamp>/` 是预期 ignored 输出，不应 stage。

## 后续怎么走

medium 通过后，才能进入 formal 运行前检查。

formal 应另开任务，不要和 medium 验收混在同一轮里直接跑。

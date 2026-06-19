# independent formal 运行记录

## 1. 本次运行目的

本次运行用于完成第 26 步：真正运行 `independent formal`，确认 independent 链路不仅能跑 small / medium，也能在 formal 档位完成一次可追溯运行。

当前阶段不是 baseline 对比，不计算完整论文指标，也不生成论文图表。

## 2. 运行入口

配置入口：

```text
configs/independent_formal_config.m
```

脚本入口：

```text
scripts/run_independent_formal_nsga2.m
```

MATLAB 命令：

```matlab
RUN_INDEPENDENT_FORMAL_CONFIRMED = true;
run('scripts/run_independent_formal_nsga2.m')
```

## 3. 参数

```text
runType: independent_formal
experimentName: independent_formal_nsga2
datasetName: Mk01
seedList: [42 43 44 45 46]
currentSeed: 42
pop: 30
max_gen: 10
p_cross: 0.8
p_mutation: 0.2
```

第一次记录的输出目录：

```text
outputs/independent_formal_nsga2/20260529_140231
```

之后又完成一次相同配置的确认运行：

```text
outputs/independent_formal_nsga2/20260529_143851
runTime: 7.625127
paretoSolutionCount: 4
bestMakespan: 111.853333
bestTotalEnergy: 1669.020000
```

当前汇报优先使用 `20260529_143851` 这次最新确认结果。

## 4. 输出文件

本次输出目录包含：

```text
result.mat
summary.txt
run_info.txt
```

`result.mat` 已检查：

```text
NSGA2_Result.obj_matrix 非空
obj_matrix 行数 = 4
obj_matrix 列数 = 2
curve.min / curve.avg 存在
curve 代数 = 10
runInfo.isIndependent = true
runInfo.usedRawSearch = false
runInfo.usedRawDecoding = false
runInfo.usedRawEvaluation = false
```

## 5. summary 摘要

```text
runTime: 7.554301
paretoSolutionCount: 4
bestMakespan: 111.853333
bestTotalEnergy: 1669.020000
```

## 6. 污染检查

```text
raw_code 未修改
outputs 未进入 Git
logs 不存在
tmp 不存在
cache 不存在
根目录 data.mat 不存在
```

## 7. 当前结论

第 26 步完成后，项目状态从：

```text
independent small / medium 可跑，formal 只有 preflight
```

推进为：

```text
independent small / medium / formal 均有真实运行能力
formal 结果可追溯
formal result.mat 可作为后续 metrics / visualization 的输入
```

下一步建议进入第 27 步：

```text
independent metrics / visualization 接 outputs
```

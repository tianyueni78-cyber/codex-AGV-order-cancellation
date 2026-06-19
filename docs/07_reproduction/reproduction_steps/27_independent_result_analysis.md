# 第 27 步：independent metrics / visualization 接 outputs

## 目标

让 independent formal 的 `result.mat` 可以直接进入指标层和图表层，形成结果分析闭环。

## 入口

```text
指标脚本：scripts/run_independent_metrics.m
图表脚本：scripts/run_independent_visualization.m
指标测试：tests/test_independent_metrics_from_output.m
图表测试：tests/test_independent_visualization_from_output.m
```

MATLAB 命令：

```matlab
run('scripts/run_independent_metrics.m')
run('scripts/run_independent_visualization.m')
```

## 已完成结果

已对以下 formal 输出完成分析：

```text
outputs/independent_formal_nsga2/20260529_140231/
```

生成：

```text
metrics/summary.txt
metrics/metrics_result.mat
figures/pareto.png
figures/convergence.png
```

已得到：

```text
solutionCount：4
objectiveCount：2
spacing：2.549194
```

当前 HV、IGD、C-metric 为 `NaN`，原因不是入口失败，而是本次没有提供：

```text
referencePoint
referenceFront
baselineObjMatrix
```

## 完成结论

```text
formal result 可以被 metrics 读取
Pareto 图可以生成
收敛曲线可以生成
分析产物写入原 run 目录
outputs 不提交 Git
```

本步骤完成的是分析管线接通，不等于论文级指标参数已经全部确定。

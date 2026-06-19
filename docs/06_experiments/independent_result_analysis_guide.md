# independent 结果分析入口说明

## 1. 本阶段目标

第 27 步把第 26 步生成的 independent formal 输出接到指标层和图表层，形成第一版结果分析闭环：

```text
outputs/independent_formal_nsga2/<timestamp>/result.mat
-> obj_matrix / curve
-> metrics/summary.txt
-> figures/pareto.png
-> figures/convergence.png
```

当前阶段不是 baseline 对比，也不是多 seed 统计。

## 2. 输入要求

输入来自 independent formal 运行目录：

```text
outputs/independent_formal_nsga2/<timestamp>/result.mat
```

`result.mat` 至少需要包含：

```text
NSGA2_Result.obj_matrix
NSGA2_Result.curve
```

## 3. metrics 入口

脚本：

```text
scripts/run_independent_metrics.m
```

MATLAB 命令：

```matlab
run('scripts/run_independent_metrics.m')
```

输出：

```text
outputs/independent_formal_nsga2/<timestamp>/metrics/summary.txt
outputs/independent_formal_nsga2/<timestamp>/metrics/metrics_result.mat
```

当前 `compute_metric_summary` 会计算：

```text
solutionCount
objectiveCount
spacing
hv
igd
cMetric
warnings
```

如果缺少 `referencePoint`、`referenceFront` 或 `baselineObjMatrix`，对应的 HV / IGD / C-metric 先返回 `NaN`，并写入 warnings。

## 4. visualization 入口

脚本：

```text
scripts/run_independent_visualization.m
```

MATLAB 命令：

```matlab
run('scripts/run_independent_visualization.m')
```

输出：

```text
outputs/independent_formal_nsga2/<timestamp>/figures/pareto.png
outputs/independent_formal_nsga2/<timestamp>/figures/convergence.png
```

图表来源：

```text
Pareto 图使用 NSGA2_Result.obj_matrix
收敛曲线使用 NSGA2_Result.curve.min / curve.avg
```

## 5. 测试入口

```matlab
run('tests/test_independent_metrics_from_output.m')
run('tests/test_independent_visualization_from_output.m')
```

测试使用已有 independent formal output，不运行 formal 算法。

## 6. 污染与提交规则

```text
raw_code 不修改
outputs 不提交 Git
metrics/ 和 figures/ 是本地运行产物
提交代码、测试和文档，不提交图片或 mat 输出
```

## 7. 当前完成后能达到什么

第 27 步完成后，项目具备：

```text
independent formal result 可被指标层读取
independent formal result 可被图表层读取
metrics summary 可生成
Pareto 图可生成
convergence 曲线可生成
```

下一步可以进入：

```text
28. baseline 对比实验跑通
29. 多 seed 统计汇总
```


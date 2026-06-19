# metrics 指标层说明

## 这一层是做什么的

metrics 指标层负责把算法输出的目标矩阵单独拿出来计算论文实验指标。

当前阶段只处理已经得到的目标值，例如：

```text
objMatrix = [
    makespan, totalEnergy
    makespan, totalEnergy
    ...
]
```

它不负责运行 NSGA-II，不负责读取正式实验结果，也不负责生成论文表格。

## 当前入口

代码入口：

```text
src/metrics/compute_hv.m
src/metrics/compute_igd.m
src/metrics/compute_spacing.m
src/metrics/compute_c_metric.m
src/metrics/compute_metric_summary.m
```

测试入口：

```text
tests/test_metrics_toy_cases.m
tests/test_metrics_compare_raw.m
```

## 指标含义

`HV` 衡量非支配解集相对参考点覆盖的目标空间体积。当前实现支持二维最小化目标的精确计算。

`IGD` 衡量算法结果到参考 Pareto front 的平均距离，数值越小通常越好。

`Spacing` 衡量解集分布的均匀程度，当前公式和 raw `Spacing.m` 保持一致，使用 cityblock 最近邻距离的标准差。

`C-metric` 衡量一个解集支配另一个解集的比例，当前公式和 raw `c_compute_A_B.m` 保持一致。

## 输入格式

指标函数接收 objective matrix：

```text
行 = 一个解
列 = 一个目标
```

例如：

```matlab
objMatrix = [
    138.45, 1936.65
    140.10, 1900.20
];
```

## referencePoint 和 referenceFront

`compute_hv` 需要 `referencePoint`：

```matlab
hv = compute_hv(objMatrix, [maxMakespan, maxEnergy]);
```

`compute_igd` 需要 `referenceFront`：

```matlab
igd = compute_igd(objMatrix, referenceFront);
```

如果使用：

```matlab
summary = compute_metric_summary(objMatrix, options);
```

可以通过 `options.referencePoint`、`options.referenceFront`、`options.baselineObjMatrix` 传入这些对照数据。

## 如何运行测试

在 MATLAB 中运行：

```matlab
run('tests/test_metrics_toy_cases.m')
run('tests/test_metrics_compare_raw.m')
```

`test_metrics_toy_cases.m` 使用手工小矩阵，不依赖 raw 代码，不运行算法。

`test_metrics_compare_raw.m` 只做指标函数对照，不修改 raw 代码。其中 IGD、C-metric 和 raw 函数做数值一致性检查；Spacing 如果当前 MATLAB 有 `pdist2`，就和 raw `Spacing.m` 对照，如果没有对应工具箱，就记录跳过 raw 对照；HV 使用当前层的二维精确实现，不和 raw 的 Monte Carlo 近似做严格数值比较。

## 当前没有完成什么

当前阶段不是正式实验。

当前阶段不是生成论文指标表。

当前阶段不读取 `outputs/formal_nsga2/`。

当前阶段没有实现高维 HV 的精确计算。

## 后续怎么接正式实验

正式实验跑完以后，只需要从结果文件中取出目标矩阵：

```text
objMatrix
```

然后调用：

```matlab
summary = compute_metric_summary(objMatrix, options);
```

如果要比较多个算法，需要给 `options.baselineObjMatrix` 或单独调用：

```matlab
cValue = compute_c_metric(objMatrixA, objMatrixB);
```

这样 metrics 层就可以服务新项目：只要新项目能输出目标矩阵，就可以复用这一层计算指标。

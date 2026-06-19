# 评价层拆分计划

## 1. 目的

这份文档记录 raw wrapper 验收之后的第一轮评价层拆分。

目标是把目标值计算逻辑拆成更容易理解、可单独测试的小函数，同时保留当前 raw `fitness.m` wrapper 作为基准答案。

当前阶段不是替换 raw `fitness.m`。

## 2. raw fitness.m 当前做了什么

当前 raw 入口是：

```text
raw_code/NSGA-II/fitness.m
```

它的职责包括：

```text
初始化 machineTable
初始化 AGVTable
调用 sorting
计算 makespan
计算机器能耗
计算 AGV 能耗
构建 FUNC = {[makespan, totalEnergy]}
```

raw 链路是：

```text
chrom
-> sorting(...)
-> machineTable / AGVTable / jobCompleteUnLoad / agvEGRecord / agvChargeNum
-> makespan 和 energy 目标值
```

## 3. 各输出字段从哪里来

`machineTable`

```text
在 fitness.m 中初始化，由 sorting.m 填充。
后续用于统计机器工作时长和空闲时长。
```

`AGVTable`

```text
在 fitness.m 中初始化，由 sorting.m 填充。
它用于检查调度过程，但 raw AGV 能耗实际来自 agvEGRecord。
```

`makespan`

```text
makespan = max(jobCompleteUnLoad)
```

`machineEnergy`

```text
遍历每个有限的 machineTable 时间块：
job == 0  -> 计入空闲时长
job ~= 0  -> 计入工作时长

machineEnergy = workRates' * workDurations + freeRates' * idleDurations
```

`agvEnergy`

```text
遍历每辆 AGV 的电量记录：
只累计相邻电量之间的正向下降值。
如果电量上升，认为是充电或恢复，不计入消耗。
```

`FUNC`

```text
FUNC = {[makespan, machineEnergy + agvEnergy]}
```

## 4. 新增组件入口

本阶段拆出的评价层小函数是：

```text
src/evaluation/compute_makespan_from_schedule.m
src/evaluation/compute_machine_energy.m
src/evaluation/compute_agv_energy.m
src/evaluation/build_objectives.m
```

职责如下：

```text
compute_makespan_from_schedule
    读取 schedule.jobCompleteUnLoad，返回 max(jobCompleteUnLoad)。

compute_machine_energy
    读取 machineTable 和 machineEnergy 能耗率，返回机器总能耗。

compute_agv_energy
    读取 agvEGRecord，返回 AGV 电量下降累计值。

build_objectives
    合并 makespan、机器能耗和 AGV 能耗，构建目标字段。
```

这些小函数不调用：

```text
fitness.m
sorting.m
NSGA2.m
```

## 5. 测试入口

手工小样本组件测试：

```matlab
run('tests/test_evaluation_components.m')
```

raw wrapper 对照测试：

```matlab
run('tests/test_evaluation_components_compare_raw.m')
```

已有 wrapper 测试：

```matlab
run('tests/test_evaluate_chromosome.m')
run('tests/test_evaluation_invalid_cases.m')
```

## 6. 测试通过代表什么

如果评价层组件测试通过，说明：

```text
makespan 可以作为小函数单独计算
机器能耗可以作为小函数单独计算
AGV 能耗可以作为小函数单独计算
objectives 可以作为小函数单独构建
machineEnergy / agvEnergy / totalEnergy 与 evaluate_chromosome 输出一致
```

raw 对照测试故意使用 `evaluate_chromosome` 作为当前基准。

这样可以保证拆分出来的小函数仍然和 raw `fitness.m` 行为对齐。

## 7. 当前阶段没有完成什么

当前阶段没有完成：

```text
替换 raw fitness.m
替换 raw sorting.m
运行完整 NSGA-II
验证 medium/formal 实验
实现独立 search
实现 metrics 或 plots
```

当前阶段只负责把 objective calculations 拆成可测试的小函数。

## 8. 后续路线

如果要完全脱离 raw `fitness.m`，后续按小任务继续：

```text
1. 保留 evaluate_chromosome 作为 raw baseline。
2. 使用 decoding 层输出的 schedule 作为新评价函数输入。
3. 后续每新增一个独立 evaluation 入口，都加 raw 对照测试。
4. 只有所有组件对照通过后，才考虑替换 raw fitness wrapper。
```

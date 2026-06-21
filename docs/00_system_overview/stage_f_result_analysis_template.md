# 阶段 F Step F9：小规模实验结果分析模板

本文档定义阶段 F 小规模实验结果的分析口径。当前模板不能替代真实结论；只有在 Step F8 已运行并生成多随机种子输出后，才能把本文档中的待填项替换为实际分析。

## 1. 输入文件

Step F9 必须基于以下输出文件分析：

```text
outputs/order_cancellation_small_experiment/<timestamp>/scenario_results.csv
outputs/order_cancellation_small_experiment/<timestamp>/seed_results.csv
outputs/order_cancellation_small_experiment/<timestamp>/selected_strategy_counts.csv
outputs/order_cancellation_small_experiment/<timestamp>/summary.json
outputs/order_cancellation_small_experiment/<timestamp>/experiment_notes.md
```

如果缺少 `scenario_results.csv` 或 `seed_results.csv`，不能形成阶段 F 小规模结论。

## 2. 分析原则

Step F9 必须遵守：

1. 只基于多随机种子汇总结果下结论。
2. 同时报告原始指标和综合指标 `Y`。
3. 不声称全局最优。
4. 不把单个 smoke 结果当作研究结论。
5. 不把阶段 F 小规模实验外推为大规模实验结论。
6. 若存在不可行候选，必须说明不可行原因来自哪类约束检查。

## 3. 必须分析的问题

### 3.1 哪些场景更倾向选择局部修复

需要查看：

```text
scenario_results.csv:
selected_local_repair_count
selected_complete_rescheduling_count

selected_strategy_counts.csv:
selected_strategy
count
```

待填写：

```text
在 early_cancel / middle_cancel / late_cancel 中，
局部修复被选择次数最多的场景是：待填。
可能原因：待填。
```

### 3.2 哪些场景更倾向选择完全重调度

需要查看：

```text
scenario_results.csv:
selected_complete_rescheduling_count
complete_Cmax_delta_mean
complete_energy_delta_mean
complete_Y_mean
```

待填写：

```text
完全重调度被选择次数最多的场景是：待填。
它是否同时带来 Cmax 或能耗改善：待填。
```

### 3.3 完全重调度是否稳定降低 Cmax

需要比较：

```text
local_Cmax_delta_mean
complete_Cmax_delta_mean
```

判断口径：

1. 若 `complete_Cmax_delta_mean < local_Cmax_delta_mean`，说明完全重调度在该场景平均更有利于缩短最大完工时间。
2. 若只在一个 seed 上改善，不能称为稳定。
3. 若不同 seed 方向不一致，应记录为不稳定。

待填写：

```text
完全重调度稳定降低 Cmax 的场景：待填。
不稳定或未降低 Cmax 的场景：待填。
```

### 3.4 完全重调度是否带来更大 SD 或 TD

需要比较：

```text
local_SD_mean
complete_SD_mean
local_TD_mean
complete_TD_mean
```

判断口径：

1. 若 `complete_SD_mean > local_SD_mean`，说明完全重调度带来更大机器工序扰动。
2. 若 `complete_TD_mean > local_TD_mean`，说明完全重调度带来更大 AGV 运输扰动。
3. 若扰动增大但 `Y` 更小，应说明这是效率收益和扰动之间的权衡。

待填写：

```text
完全重调度带来更大 SD 的场景：待填。
完全重调度带来更大 TD 的场景：待填。
扰动与效率之间的权衡：待填。
```

### 3.5 能耗变化是否稳定

需要比较：

```text
local_energy_delta_mean
complete_energy_delta_mean
```

判断口径：

1. `energy_delta < 0` 表示相对原正常计划能耗降低。
2. `complete_energy_delta_mean < local_energy_delta_mean` 表示完全重调度平均能耗更低。
3. 能耗结论必须结合当前简化 AGV 能耗口径说明。

待填写：

```text
能耗更稳定降低的策略：待填。
需要注意的能耗口径限制：待填。
```

### 3.6 不可行案例来自哪类约束

需要查看：

```text
seed_results.csv:
local_machine_check_isFeasible
local_agv_check_isFeasible
local_job_sequence_check_isFeasible
complete_machine_check_isFeasible
complete_agv_check_isFeasible
complete_job_sequence_check_isFeasible
complete_frozen_check_isFeasible
complete_cancelled_exclusion_check_isFeasible
local_error_count
complete_error_count
```

判断口径：

1. 若所有检查均为 `1`，说明本次小规模实验没有约束不可行案例。
2. 若某类检查为 `0`，需要统计它出现在哪些场景和 seed。
3. 不能只写“不可行”，必须写清楚是机器冲突、AGV 冲突、工序顺序、冻结一致性还是取消任务回流。

待填写：

```text
不可行案例数量：待填。
主要不可行约束类型：待填。
对应场景和 seed：待填。
```

## 4. 结论模板

真实结论应按以下格式填写：

```text
基于 <timestamp> 的阶段 F 小规模实验，
本次共运行 <run_count> 个场景-seed 组合，
覆盖 early_cancel、middle_cancel、late_cancel 三类取消场景。

策略选择方面：
<填写局部修复和完全重调度被选择次数。>

Cmax 方面：
<填写完全重调度是否稳定降低 Cmax。>

扰动方面：
<填写 SD/TD 是否增加，以及是否形成效率-扰动权衡。>

能耗方面：
<填写 energy_delta 的方向和稳定性。>

可行性方面：
<填写约束检查结果和不可行原因。>

结论边界：
该结论仅适用于本次小规模实验配置，
不代表全局最优，
不代表大规模实例结论，
不包含机器故障、新订单插入、连续取消或强化学习。
```

## 5. Step F9 完成条件

Step F9 只有在以下条件满足时才算完成：

1. 已有 Step F8 生成的 `<timestamp>` 输出目录。
2. 已读取 `scenario_results.csv`。
3. 已读取 `seed_results.csv`。
4. 已读取 `selected_strategy_counts.csv`。
5. 结论同时报告原始指标和 `Y`。
6. 结论说明局限。
7. 没有声称全局最优。

## 6. 当前状态

当前本文档只是分析模板。由于尚未确认并运行 Step F8，当前不能填写真实实验结论。

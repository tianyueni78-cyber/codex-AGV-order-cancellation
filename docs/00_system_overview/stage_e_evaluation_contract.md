# 阶段 E 评价与策略选择输入契约

本文档定义阶段 E 的输入契约、前置条件、候选来源、评价输出结构和禁止行为。Step E1 只确认评价层接收什么，Step E2 只定义评价结果格式；二者都不实现指标计算，不选择最终策略，不写 `outputs/`。

## 1. 阶段 E 目标

阶段 E 的目标是：

```text
比较局部修复和完全重调度。
```

阶段 E 后续完整验收标准为：

1. 能计算 `Cmax_delta`、`SD`、`TD`、能耗和 `Y`。
2. 最终选择 `Y` 更小的候选方案。
3. 结果写入 `outputs/`。

Step E1 和 Step E2 只确认契约和输出结构，不实现上述评价指标。

## 2. 输入契约

阶段 E 评价层只接收两个已经生成的候选方案：

```matlab
problem
machineData
agvData
baselineSchedule
localRepairCandidate
completeReschedulingCandidate
cancel
config
```

字段含义：

| 输入 | 含义 |
|---|---|
| `problem` | 原正常调度问题数据，用于工序、工件和机器基础信息 |
| `machineData` | 原机器数据，用于后续能耗或运输相关评价 |
| `agvData` | 原 AGV 数据，用于后续 AGV 能耗或运输相关评价 |
| `baselineSchedule` | 订单取消前的原正常调度计划，作为扰动和变化量评价基线 |
| `localRepairCandidate` | 阶段 C 生成的局部修复候选 |
| `completeReschedulingCandidate` | 阶段 D 生成的完全重调度候选 |
| `cancel` | 当前订单取消事件 |
| `config` | 阶段 E 的评价权重、归一化参数和输出参数 |

## 3. 候选来源要求

`localRepairCandidate` 必须来自阶段 C：

```matlab
build_local_repair_candidate(...)
```

并且至少包含：

```matlab
localRepairCandidate.machineTable
localRepairCandidate.AGVTable
localRepairCandidate.isFeasible
localRepairCandidate.report
```

`completeReschedulingCandidate` 必须来自阶段 D：

```matlab
build_complete_rescheduling_candidate(...)
```

并且至少包含：

```matlab
completeReschedulingCandidate.machineTable
completeReschedulingCandidate.AGVTable
completeReschedulingCandidate.isFeasible
completeReschedulingCandidate.report
```

## 4. 前置可行性要求

两个候选进入阶段 E 前，必须已经完成各自阶段的可行性检查。

局部修复候选应通过：

```matlab
localRepairCandidate.isFeasible == true
```

并且其 `report` 中应包含阶段 C 检查结果：

```matlab
machineConflictCheck
agvConflictCheck
jobSequenceCheck
```

完全重调度候选应通过：

```matlab
completeReschedulingCandidate.isFeasible == true
```

并且其 `report` 中应包含阶段 D 检查结果：

```matlab
completeFeasibilityCheck.machineConflictCheck
completeFeasibilityCheck.agvConflictCheck
completeFeasibilityCheck.jobSequenceCheck
completeFeasibilityCheck.frozenConsistencyCheck
completeFeasibilityCheck.cancelledTaskExclusionCheck
```

如果某个候选不可行，阶段 E 后续策略选择可以记录其不可选原因，但 Step E1 不实现该逻辑。

## 5. baselineSchedule 要求

`baselineSchedule` 是订单取消前已经生成的正常调度计划。

必须包含：

```matlab
baselineSchedule.machineTable
baselineSchedule.AGVTable
```

阶段 E 后续评价中：

1. `Cmax_delta` 应相对于 `baselineSchedule` 计算。
2. `SD` 应相对于 `baselineSchedule.machineTable` 计算。
3. `TD` 应相对于 `baselineSchedule.AGVTable` 计算。
4. 能耗变化应相对于 `baselineSchedule` 计算。

Step E1 只确认基线输入字段，Step E3 进一步确认基线指标来源。二者都不计算这些指标。

## 6. 基线指标来源

Step E3 明确：阶段 E 的变化量指标统一相对于订单取消前的原正常调度计划 `baselineSchedule` 计算。

基线来源：

```text
baseline = baselineSchedule
```

也就是说：

1. `baseline Cmax` 从 `baselineSchedule.machineTable` 计算。
2. `baseline energy` 从 `baselineSchedule` 计算。
3. `localRepair Cmax` 从 `localRepairCandidate.machineTable` 计算。
4. `localRepair energy` 从 `localRepairCandidate` 计算。
5. `completeRescheduling Cmax` 从 `completeReschedulingCandidate.machineTable` 计算。
6. `completeRescheduling energy` 从 `completeReschedulingCandidate` 计算。

变化量口径：

```matlab
localRepair.metrics.Cmax_delta = ...
    localRepair.metrics.Cmax - baselineMetrics.Cmax

completeRescheduling.metrics.Cmax_delta = ...
    completeRescheduling.metrics.Cmax - baselineMetrics.Cmax

localRepair.metrics.energy_delta = ...
    localRepair.metrics.energy - baselineMetrics.energy

completeRescheduling.metrics.energy_delta = ...
    completeRescheduling.metrics.energy - baselineMetrics.energy
```

阶段 E 不允许把局部修复候选作为完全重调度候选的基线，也不允许把完全重调度候选作为局部修复候选的基线。

禁止混用：

1. 不混用不同数据集的 `baselineSchedule` 和候选。
2. 不混用不同取消事件的 `baselineSchedule` 和候选。
3. 不混用不同随机种子的 `baselineSchedule` 和候选。
4. 不混用不同正常调度初始解的 `baselineSchedule` 和候选。

后续若进入阶段 F 多随机种子实验，每个种子必须在自己的基线下分别计算指标，再做汇总统计。不能先跨种子混合计划再计算单个 `Cmax_delta` 或 `energy_delta`。

Step E3 只确认指标来源和比较口径，不实现 `Cmax`、能耗或变化量计算。

## 7. config 要求

阶段 E 的 `config` 后续至少应承载：

```matlab
config.weights
config.normalization
config.output
```

其中：

1. `config.weights` 用于 `Y` 的指标权重。
2. `config.normalization` 用于各指标归一化口径。
3. `config.output` 用于控制是否写入 `outputs/` 以及输出目录。

Step E1 和 Step E2 不新增具体权重，也不写死任何权重值。

## 8. 评价输出结构

Step E2 统一阶段 E 的评价结果格式。建议顶层输出为：

```matlab
evaluation.localRepair
evaluation.completeRescheduling
evaluation.selectedStrategy
evaluation.report
```

字段含义：

| 字段 | 含义 |
|---|---|
| `evaluation.localRepair` | 局部修复候选的评价结果 |
| `evaluation.completeRescheduling` | 完全重调度候选的评价结果 |
| `evaluation.selectedStrategy` | 最终选择的策略名称和选择原因 |
| `evaluation.report` | 阶段 E 的整体错误、警告、不可评价原因和运行摘要 |

## 9. 单个候选评价结构

`evaluation.localRepair` 和 `evaluation.completeRescheduling` 使用同一套结构：

```matlab
candidateEvaluation.strategyName
candidateEvaluation.metrics.Cmax
candidateEvaluation.metrics.Cmax_delta
candidateEvaluation.metrics.SD
candidateEvaluation.metrics.TD
candidateEvaluation.metrics.energy
candidateEvaluation.metrics.energy_delta
candidateEvaluation.metrics.Y
candidateEvaluation.metrics.isFeasible
candidateEvaluation.report
```

字段含义：

| 字段 | 含义 |
|---|---|
| `strategyName` | 候选策略名称，例如 `local_repair` 或 `complete_rescheduling` |
| `metrics.Cmax` | 候选计划最大完工时间 |
| `metrics.Cmax_delta` | 候选 `Cmax` 相对 `baselineSchedule` 的变化量 |
| `metrics.SD` | 机器工序调度扰动指标 |
| `metrics.TD` | AGV 运输任务扰动指标 |
| `metrics.energy` | 候选计划能耗 |
| `metrics.energy_delta` | 候选能耗相对 `baselineSchedule` 的变化量 |
| `metrics.Y` | 综合评价值，后续 Step E8 定义计算方式 |
| `metrics.isFeasible` | 候选是否可参与评价和策略选择 |
| `report` | 当前候选的评价错误、警告和不可评价原因 |

Step E2 只定义这些字段，不计算字段值。

## 10. 不可评价原因记录

每个候选都应能记录不可评价原因。建议结构：

```matlab
candidateEvaluation.report.errors
candidateEvaluation.report.warnings
candidateEvaluation.report.rejectedReasons
candidateEvaluation.report.metricStatus
```

约定：

1. `errors` 记录导致该候选无法评价的错误。
2. `warnings` 记录不阻断评价的提示。
3. `rejectedReasons` 记录该候选不可参与策略选择的原因。
4. `metricStatus` 记录每个指标是否成功计算。

常见不可评价原因包括：

1. 候选本身 `isFeasible == false`。
2. 候选缺少 `machineTable`。
3. 候选缺少 `AGVTable`。
4. `baselineSchedule` 缺少对应任务，无法计算扰动。
5. 能耗评价所需数据缺失。
6. `Y` 所需权重或归一化参数缺失。

Step E2 只定义记录位置，不实现不可评价判断。

## 11. 最终选择结构

`evaluation.selectedStrategy` 用于记录阶段 E 最终选择结果。建议结构：

```matlab
evaluation.selectedStrategy.name
evaluation.selectedStrategy.reason
evaluation.selectedStrategy.selectedY
evaluation.selectedStrategy.comparedStrategies
evaluation.selectedStrategy.isSelected
```

字段含义：

| 字段 | 含义 |
|---|---|
| `name` | 最终选择的策略名称，例如 `local_repair` 或 `complete_rescheduling` |
| `reason` | 选择原因，例如 `smaller_Y`、`only_feasible_candidate` 或 `tie_break_local_repair` |
| `selectedY` | 被选中候选的 `Y` 值 |
| `comparedStrategies` | 本次参与比较的策略名称列表 |
| `isSelected` | 是否成功选出策略 |

如果两个候选都不可评价，`evaluation.selectedStrategy.isSelected` 应为 `false`，`name` 可为空，原因写入 `reason` 和 `evaluation.report.errors`。

Step E2 只定义该结构，不执行最终选择。

## 12. 阶段 E 禁止行为

Step E1 和 Step E2 禁止：

1. 修改 `localRepairCandidate`。
2. 修改 `completeReschedulingCandidate`。
3. 重新解码。
4. 重新搜索。
5. 调用 NSGA-II。
6. 重新生成局部修复候选。
7. 重新生成完全重调度候选。
8. 计算 `Cmax_delta`、`SD`、`TD`、能耗或 `Y`。
9. 选择最终策略。
10. 写入 `outputs/`。
11. 运行 MATLAB。
12. 修改 `raw_code/`。

Step E4 只允许实现 `Cmax` 和 `Cmax_delta` 计算，不允许提前实现 `SD`、`TD`、能耗、`Y` 或策略选择。

Step E5 只允许实现机器工序调度扰动 `SD`，不允许提前实现 `TD`、能耗、`Y` 或策略选择。

Step E6 只允许实现 AGV 运输扰动 `TD`，不允许提前实现能耗、`Y` 或策略选择。

Step E7 只允许实现能耗和 `energy_delta` 计算，不允许提前实现 `Y` 或策略选择。

Step E8 只允许定义综合评价 `Y` 的公式、权重来源和归一化口径，不允许提前实现最终策略选择。

Step E9 只允许实现单个候选评价函数，不允许比较局部修复和完全重调度，也不允许选择最终策略。

Step E10 只允许比较两个已经评价好的候选并选择策略，不允许重新计算指标、重新生成候选或写入 `outputs/`。

Step E11 只允许新增小样例 smoke 输出脚本。该脚本会写入 `outputs/`，因此运行前需要用户确认或由用户主动运行。

Step E12 只允许新增不写 `outputs/` 的最小 pipeline 测试，不允许启动正式实验或 NSGA-II。

Step E13 只允许在 `data_sample/Mk01.fjs` 上运行样例数据策略选择 smoke。该 smoke 会写入 `outputs/`，运行前需要用户确认或由用户主动运行。

## 13. Step E1 验收标准

Step E1 完成条件：

1. 明确阶段 E 输入包括 `problem`、`machineData`、`agvData`、`baselineSchedule`、`localRepairCandidate`、`completeReschedulingCandidate`、`cancel` 和 `config`。
2. 明确局部修复候选来自阶段 C。
3. 明确完全重调度候选来自阶段 D。
4. 明确两个候选都必须先通过可行性检查。
5. 明确阶段 E 不再修改候选计划。
6. 明确阶段 E 不重新解码、不重新搜索。
7. README 已挂载本文档入口。

## 14. Step E2 验收标准

Step E2 完成条件：

1. 明确 `evaluation.localRepair` 用于记录局部修复候选评价结果。
2. 明确 `evaluation.completeRescheduling` 用于记录完全重调度候选评价结果。
3. 明确每个候选都包含 `Cmax`、`Cmax_delta`、`SD`、`TD`、`energy`、`energy_delta`、`Y` 和 `isFeasible` 字段。
4. 明确每个候选都能通过 `report.rejectedReasons` 记录不可评价原因。
5. 明确 `evaluation.selectedStrategy` 能记录最终选择的策略名称。
6. 明确 Step E2 不计算指标、不选择策略、不写 `outputs/`。

## 15. Step E3 验收标准

Step E3 完成条件：

1. 文档说明 `baselineSchedule` 是取消前正常调度计划。
2. 文档说明 `baseline Cmax` 从原计划计算。
3. 文档说明 `baseline energy` 从原计划计算。
4. 文档说明候选 `Cmax` 从各自候选计划计算。
5. 文档说明候选 `energy` 从各自候选计划计算。
6. 明确不把局部修复当作完全重调度的基线。
7. 明确不把完全重调度当作局部修复的基线。
8. 明确不混用不同样例、取消事件、随机种子或正常调度初始解。
9. 明确 Step E3 不实现指标计算。

## 16. Step E4：Cmax 和 Cmax_delta 计算

Step E4 实现候选最大完工时间变化计算。

新增函数：

```text
src/cancellation/evaluate_candidate_cmax.m
```

新增测试：

```text
tests/test_order_cancellation_evaluation_cmax.m
```

输入：

```matlab
baselineSchedule
candidateSchedule
```

输出：

```matlab
metrics.baseline_Cmax
metrics.Cmax
metrics.Cmax_delta
metrics.isFeasible
report
```

计算口径：

```matlab
Cmax = max(all real machine operation end times)
Cmax_delta = candidate_Cmax - baseline_Cmax
```

真实机器工序定义：

```matlab
machineTable block with job > 0
```

空闲块定义：

```matlab
machineTable block with job <= 0
```

空闲块不参与 `Cmax` 计算，即使空闲块 `end` 为 `inf` 或较大数值，也不能改变 `Cmax`。

Step E4 不计算：

1. `SD`。
2. `TD`。
3. 能耗。
4. `Y`。
5. 最终策略选择。

## 17. Step E4 验收标准

Step E4 完成条件：

1. 能计算 `baseline Cmax`。
2. 能计算候选 `Cmax`。
3. 能计算 `Cmax_delta`。
4. 空闲块不参与计算。
5. 缺少 `machineTable` 时能记录错误。
6. 真实工序 `end < start` 时能拒绝计算。
7. 不实现能耗、`SD`、`TD`、`Y` 或策略选择。

## 18. Step E5：调度扰动指标 SD

Step E5 实现机器工序调度扰动指标。

新增函数：

```text
src/cancellation/evaluate_candidate_sd.m
```

新增测试：

```text
tests/test_order_cancellation_evaluation_sd.m
```

输入：

```matlab
baselineSchedule
candidateSchedule
cancel
```

输出：

```matlab
metrics.SD
metrics.isFeasible
report
```

第一版计算口径：

```matlab
SD = sum(abs(candidate_start - baseline_start))
```

统计范围：

1. 只统计 `job > 0` 的真实机器工序。
2. 排除 `job == cancel.job_id` 的取消订单工序。
3. 忽略 `job <= 0` 的空闲块。
4. 使用 `(job_id, operation_id)` 匹配 baseline 与 candidate 中的同一工序。

含义：

1. 被取消订单未完成工序不参与 `SD`。
2. 被取消订单已完成工序第一版也不参与 `SD`，因为 `SD` 用于衡量未取消订单计划扰动。
3. 已完成冻结任务若属于未取消订单且开始时间不变，对 `SD` 的贡献为 `0`。
4. 未取消订单剩余工序若开始时间变化，按变化绝对值计入 `SD`。

异常情况：

1. baseline 中存在的未取消订单工序，在 candidate 中缺失时，拒绝计算。
2. candidate 中出现 baseline 没有的未取消订单工序时，拒绝计算。
3. 同一计划中同一个 `(job_id, operation_id)` 重复出现时，拒绝计算。
4. 真实工序 `end < start` 时，拒绝计算。

Step E5 不计算：

1. `TD`。
2. 能耗。
3. `Y`。
4. 最终策略选择。

## 19. Step E5 验收标准

Step E5 完成条件：

1. 能计算未取消订单工序开始时间变化绝对值之和。
2. 被取消订单未完成工序不参与 `SD`。
3. 已完成冻结任务若开始时间不变，对 `SD` 贡献为 `0`。
4. 未取消订单剩余工序若时间变化，计入 `SD`。
5. 缺失未取消订单工序能报错。
6. 多余未取消订单工序能报错。
7. 空闲块不参与计算。
8. 不实现 `TD`、能耗、`Y` 或策略选择。

## 20. Step E6：运输扰动指标 TD

Step E6 实现 AGV 运输任务扰动指标。

新增函数：

```text
src/cancellation/evaluate_candidate_td.m
```

新增测试：

```text
tests/test_order_cancellation_evaluation_td.m
```

输入：

```matlab
baselineSchedule
candidateSchedule
cancel
```

输出：

```matlab
metrics.TD
metrics.isFeasible
report
```

第一版计算口径：

```matlab
TD = sum(abs(candidate_transport_start - baseline_transport_start))
```

统计范围：

1. 只统计 `job > 0 && opera > 0` 的真实 AGV 工序运输任务。
2. 排除 `job == cancel.job_id` 的取消订单运输任务。
3. 忽略 `job <= 0` 的空闲或充电块。
4. 忽略 `opera <= 0` 的辅助 AGV 块，例如 `opera = -1` 的非工序运输记录。
5. 使用 `(job_id, operation_id)` 匹配 baseline 与 candidate 中的同一运输任务。

含义：

1. 被取消订单未完成运输任务不参与 `TD`。
2. 被取消订单已完成 AGV 历史运输允许保留，但不计入 `TD`。
3. 已完成 AGV 冻结任务若属于未取消订单且开始时间不变，对 `TD` 的贡献为 `0`。
4. 未取消订单 AGV 任务若开始时间变化，按变化绝对值计入 `TD`。
5. 候选中如果出现取消订单未完成真实 AGV 工序运输回流，直接拒绝评价。

异常情况：

1. baseline 中存在的未取消订单 AGV 任务，在 candidate 中缺失时，拒绝计算。
2. candidate 中出现 baseline 没有的未取消订单 AGV 任务时，拒绝计算。
3. candidate 中出现取消订单未完成真实 AGV 工序运输回流时，拒绝计算。
4. 同一计划中同一个 `(job_id, operation_id)` AGV 任务重复出现时，拒绝计算。
5. 真实 AGV 任务 `end < start` 时，拒绝计算。

Step E6 不计算：

1. 能耗。
2. `Y`。
3. 最终策略选择。

## 21. Step E6 验收标准

Step E6 完成条件：

1. 能计算未取消订单 AGV 任务开始时间变化绝对值之和。
2. 被取消订单未完成运输任务不参与 `TD`。
3. 被取消订单已完成 AGV 历史运输允许保留。
4. `opera <= 0` 的辅助 AGV 块不参与计算。
5. 已完成 AGV 冻结任务若开始时间不变，对 `TD` 贡献为 `0`。
6. 未取消订单 AGV 任务若时间变化，计入 `TD`。
7. 缺失未取消订单 AGV 任务能报错。
8. 取消订单未完成真实 AGV 工序运输回流能报错。
9. 多余未取消订单 AGV 任务能报错。
10. 空闲或充电块不参与计算。
11. 不实现能耗、`Y` 或策略选择。

## 22. Step E7：能耗计算

Step E7 实现 baseline 和候选计划的能耗计算。

新增函数：

```text
src/cancellation/evaluate_candidate_energy.m
```

新增测试：

```text
tests/test_order_cancellation_evaluation_energy.m
```

输入：

```matlab
baselineSchedule
candidateSchedule
machineData
agvData
```

输出：

```matlab
metrics.baseline_energy
metrics.energy
metrics.energy_delta
metrics.baseline_machine_energy
metrics.machine_energy
metrics.baseline_agv_energy
metrics.agv_energy
metrics.baseline_agv_energy_source
metrics.agv_energy_source
metrics.isFeasible
report
```

机器能耗口径：

```matlab
compute_machine_energy(schedule.machineTable, machineData.machineEnergy)
```

说明：机器能耗优先复用原 `src/evaluation/compute_machine_energy.m`，保持与原评价层一致。

AGV 能耗口径：

1. 若 schedule 中存在 `agvEGRecord`，则复用：

```matlab
compute_agv_energy(schedule.agvEGRecord)
```

2. 若 schedule 中没有 `agvEGRecord`，第一版使用简化 AGVTable 时长估计：

```matlab
AGV energy = sum(real_transport_duration * first(AGVEnergy.load))
           + sum(idle_or_charging_duration * first(AGVEnergy.free))
```

其中：

1. `job > 0` 视为真实运输任务，使用 `AGVEnergy.load` 的第一个能耗率。
2. `job <= 0` 视为空闲或充电块，使用 `AGVEnergy.free` 的第一个能耗率。
3. `end == inf` 的尾部块不参与能耗计算。

简化原因：

阶段 C/D 候选主要保留 `machineTable` 和 `AGVTable`，不一定保留完整 `agvEGRecord`。因此 Step E7 第一版在无法复用 `compute_agv_energy` 时，采用明确记录来源的简化估计，并在输出中写入：

```matlab
metrics.agv_energy_source = 'AGVTable_simplified'
```

如果成功复用 `agvEGRecord`，则写入：

```matlab
metrics.agv_energy_source = 'agvEGRecord'
```

变化量口径：

```matlab
energy_delta = candidate_energy - baseline_energy
```

Step E7 不计算：

1. `Y`。
2. 最终策略选择。
3. 正式实验输出。

## 23. Step E7 验收标准

Step E7 完成条件：

1. 优先复用原项目已有机器能耗函数 `compute_machine_energy`。
2. 有 `agvEGRecord` 时复用原项目 AGV 能耗函数 `compute_agv_energy`。
3. 无 `agvEGRecord` 时文档说明简化 AGVTable 能耗口径。
4. 能计算 baseline energy。
5. 能计算候选 energy。
6. 能计算 `energy_delta`。
7. 能记录 AGV 能耗来源。
8. 不实现 `Y` 或策略选择。

## 24. Step E8：综合评价 Y

Step E8 定义综合评价 `Y`，用于把多个指标合成一个可比较分数。

第一版公式：

```matlab
Y = w1 * normalize(Cmax_delta)
  + w2 * normalize(SD)
  + w3 * normalize(TD)
  + w4 * normalize(energy_delta)
```

其中：

```matlab
w1 = config.weights.Cmax_delta
w2 = config.weights.SD
w3 = config.weights.TD
w4 = config.weights.energy_delta
```

权重要求：

1. 权重必须来自 `config.weights`。
2. 算法实现中不得写死权重。
3. 四个权重字段必须同时存在。
4. 权重应为非负数。
5. 第一版建议权重和为 `1`，若后续允许不等于 `1`，必须在 report 中记录实际权重和。

`Y` 的方向：

```text
Y 越小越好。
```

原因：

1. `Cmax_delta` 越小，最大完工时间恶化越少。
2. `SD` 越小，机器工序计划扰动越少。
3. `TD` 越小，AGV 运输计划扰动越少。
4. `energy_delta` 越小，能耗增加越少。

## 25. 指标归一化口径

两个候选必须使用同一套归一化口径。第一版建议使用两候选共同 min-max 归一化。

对任一指标 `x`：

```matlab
normalized_x = (x - min(x_local, x_complete)) ...
             / (max(x_local, x_complete) - min(x_local, x_complete))
```

其中：

1. `x_local` 来自局部修复候选。
2. `x_complete` 来自完全重调度候选。
3. 两个候选使用同一个 `min` 和同一个 `max`。

若分母为 `0`，即两个候选该指标完全相同：

```matlab
normalized_x = 0
```

含义：该指标无法区分两个候选，因此不增加任一候选的 `Y` 惩罚。

第一版归一化指标包括：

```matlab
Cmax_delta
SD
TD
energy_delta
```

注意：

1. 不允许局部修复使用一套归一化参数，完全重调度使用另一套归一化参数。
2. 不允许跨不同样例、不同取消事件或不同随机种子混合计算 min-max。
3. 若某个候选不可评价，则不能用它的缺失指标参与 min-max。

## 26. Step E8 验收标准

Step E8 完成条件：

1. 文档定义 `Y` 的组成指标。
2. 文档说明 `Y` 越小越好。
3. 文档说明权重来自 `config.weights`，不写死在算法里。
4. 文档列出 `config.weights.Cmax_delta`。
5. 文档列出 `config.weights.SD`。
6. 文档列出 `config.weights.TD`。
7. 文档列出 `config.weights.energy_delta`。
8. 文档说明两候选使用同一套归一化口径。
9. 文档说明第一版 min-max 归一化方式。
10. 文档说明分母为 `0` 时归一化值为 `0`。
11. 不实现最终策略选择。

## 27. Step E9：单个候选评价函数

Step E9 实现单个订单取消候选方案的完整指标评价。

新增函数：

```text
src/cancellation/evaluate_order_cancellation_candidate.m
```

新增测试：

```text
tests/test_order_cancellation_candidate_evaluation.m
```

输入：

```matlab
baselineSchedule
candidate
cancel
machineData
agvData
config
strategyName
```

输出：

```matlab
evaluation.strategyName
evaluation.metrics.Cmax
evaluation.metrics.Cmax_delta
evaluation.metrics.SD
evaluation.metrics.TD
evaluation.metrics.energy
evaluation.metrics.energy_delta
evaluation.metrics.Y
evaluation.metrics.isFeasible
evaluation.report
```

组合调用：

```matlab
evaluate_candidate_cmax(...)
evaluate_candidate_sd(...)
evaluate_candidate_td(...)
evaluate_candidate_energy(...)
```

`Y` 计算要求：

1. 使用 `config.weights` 中的权重。
2. 使用 `config.normalization` 中的归一化上下界。
3. 不在函数内写死权重。
4. 不在函数内临时生成只属于单个候选的归一化口径。

不可行候选处理：

```matlab
candidate.isFeasible == false
```

或缺少 `candidate.isFeasible` 时，候选不参与评价，输出：

```matlab
evaluation.metrics.isFeasible = false
evaluation.report.rejectedReasons includes candidate_infeasible
```

Step E9 不负责：

1. 比较两个候选。
2. 选择局部修复或完全重调度。
3. 写入 `outputs/`。
4. 启动正式实验。

## 28. Step E9 验收标准

Step E9 完成条件：

1. 可评价局部修复候选。
2. 可评价完全重调度候选。
3. 能输出 `Cmax_delta`。
4. 能输出 `SD`。
5. 能输出 `TD`。
6. 能输出能耗和 `energy_delta`。
7. 能输出 `Y`。
8. 不可行候选不参与最终选择，且记录拒绝原因。
9. 不实现最终策略选择。

## 29. Step E10：策略选择函数

Step E10 实现订单取消策略选择函数。

新增函数：

```text
src/cancellation/select_order_cancellation_strategy.m
```

新增测试：

```text
tests/test_order_cancellation_strategy_selection.m
```

输入：

```matlab
localRepairEvaluation
completeReschedulingEvaluation
```

输出：

```matlab
selection.name
selection.reason
selection.selectedY
selection.comparedStrategies
selection.isSelected
selection.report
```

选择规则：

1. 两个候选都可行：选择 `Y` 更小者，`reason = 'smaller_Y'`。
2. 只有局部修复可行：选择局部修复，`reason = 'only_feasible_candidate'`。
3. 只有完全重调度可行：选择完全重调度，`reason = 'only_feasible_candidate'`。
4. 两个候选都不可行：拒绝选择，`reason = 'no_feasible_candidate'`。
5. 两个候选 `Y` 相同：第一版选择局部修复，`reason = 'tie_break_local_repair'`。

平局选择局部修复的原因：

1. 删除式局部修复扰动更保守。
2. 不重新搜索，不引入额外重排。
3. 第一版更容易解释和验证。

Step E10 不负责：

1. 计算 `Cmax_delta`、`SD`、`TD`、能耗或 `Y`。
2. 重新生成局部修复候选。
3. 重新生成完全重调度候选。
4. 写入 `outputs/`。
5. 启动正式实验。

## 30. Step E10 验收标准

Step E10 完成条件：

1. 能选择局部修复。
2. 能选择完全重调度。
3. 能处理一个候选不可行。
4. 能处理两个候选都不可行。
5. 能处理 `Y` 相同的平局情况。
6. 能记录选择原因。
7. 不重新计算指标。
8. 不写 `outputs/`。

## 31. Step E11：结果写入 outputs

Step E11 新增策略选择 smoke 脚本，并把评价与选择结果写入 `outputs/`。

新增脚本：

```text
scripts/run_order_cancellation_strategy_selection_smoke.m
```

运行入口：

```matlab
run('scripts/run_order_cancellation_strategy_selection_smoke.m')
```

输出目录：

```text
outputs/order_cancellation_strategy_selection/<timestamp>/
```

输出文件：

```text
summary.json
metrics.csv
selected_strategy.txt
```

`summary.json` 包含：

1. 取消事件。
2. `config.weights`。
3. `config.normalization`。
4. 局部修复候选评价结果。
5. 完全重调度候选评价结果。
6. 最终选择结果。
7. scope 标记，说明不是正式实验、不是多随机种子、没有启动 NSGA-II。

`metrics.csv` 包含两个候选的指标：

```text
strategy
isFeasible
Cmax
Cmax_delta
SD
TD
energy
energy_delta
Y
```

`selected_strategy.txt` 包含：

```text
isSelected
name
reason
selectedY
```

Step E11 运行前要求：

1. 因为会写入 `outputs/`，运行 MATLAB 前需要确认。
2. 不覆盖已有 timestamp 目录。
3. 不启动正式多随机种子实验。
4. 不调用 NSGA-II。
5. 不形成正式研究结论。

## 32. Step E11 验收标准

Step E11 完成条件：

1. smoke 脚本入口存在。
2. 输出目录为 `outputs/order_cancellation_strategy_selection/<timestamp>/`。
3. 输出包含 `summary.json`。
4. 输出包含 `metrics.csv`。
5. 输出包含 `selected_strategy.txt`。
6. 输出包含两个候选指标。
7. 输出包含最终选择策略。
8. 输出包含 `config.weights`。
9. 不启动正式多随机种子实验。

## 33. Step E12：阶段 E smoke 测试

Step E12 用最小构造数据验证评价和选择逻辑。

新增测试：

```text
tests/test_order_cancellation_evaluation_pipeline.m
```

运行入口：

```matlab
run('tests/test_order_cancellation_evaluation_pipeline.m')
```

测试范围：

1. 构造最小 baseline schedule。
2. 构造一个局部修复候选。
3. 构造一个完全重调度候选。
4. 调用 `evaluate_order_cancellation_candidate` 计算两个候选指标。
5. 调用 `select_order_cancellation_strategy` 选择策略。

测试内容：

1. 局部修复 `Y` 更小时，局部修复被选中。
2. 完全重调度 `Y` 更小时，完全重调度被选中。
3. 不可行候选被排除。
4. `Cmax_delta`、`SD`、`TD`、`energy` 和 `Y` 都能计算。

Step E12 禁止：

1. 写入 `outputs/`。
2. 调用 NSGA-II。
3. 启动正式实验。
4. 读取大型数据集。
5. 形成正式研究结论。

## 34. Step E12 验收标准

Step E12 完成条件：

1. pipeline 测试入口存在。
2. 测试只用最小构造数据。
3. 局部修复 `Y` 更小时能被选中。
4. 完全重调度 `Y` 更小时能被选中。
5. 不可行候选能被排除。
6. `Cmax_delta`、`SD`、`TD`、`energy` 和 `Y` 都能计算。
7. 不写 `outputs/`。
8. 不跑 NSGA-II。
9. 不跑正式实验。

## 35. Step E13：样例数据策略选择 smoke

Step E13 在 `data_sample/Mk01.fjs` 上串联阶段 B、C、D、E。

脚本入口：

```text
scripts/run_order_cancellation_strategy_selection_smoke.m
```

运行入口：

```matlab
run('scripts/run_order_cancellation_strategy_selection_smoke.m')
```

执行流程：

1. 读取 `data_sample/Mk01.fjs`。
2. 创建 `cancel`。
3. 调用阶段 B：`extract_cancellation_state` 提取取消时刻状态。
4. 调用阶段 C：`build_local_repair_candidate` 构造局部修复候选。
5. 调用阶段 D：`build_complete_rescheduling_candidate` 构造完全重调度候选。
6. 调用阶段 E：`evaluate_order_cancellation_candidate` 分别评价两个候选。
7. 调用阶段 E：`select_order_cancellation_strategy` 选择 `Y` 更小的方案。
8. 写入 `outputs/order_cancellation_strategy_selection/<timestamp>/`。

输出文件：

```text
summary.json
metrics.csv
selected_strategy.txt
```

控制台输出至少包含：

```text
local_repair.Cmax_delta
local_repair.SD
local_repair.TD
local_repair.energy
local_repair.Y
complete_rescheduling.Cmax_delta
complete_rescheduling.SD
complete_rescheduling.TD
complete_rescheduling.energy
complete_rescheduling.Y
selected.name
selected.reason
```

归一化说明：

1. 脚本先用宽范围归一化配置做一次预评价，得到两个候选的原始指标。
2. 若两个候选均可评价，则使用两个候选共同 min-max 生成最终 `config.normalization`。
3. 最终评价和选择使用同一套 `config.weights` 和 `config.normalization`。

Step E13 不包含：

1. 不做多随机种子。
2. 不启动正式实验。
3. 不调用 NSGA-II 正式搜索。
4. 不形成正式研究结论。

## 36. Step E13 验收标准

Step E13 完成条件：

1. 能创建 `cancel`。
2. 能提取取消状态。
3. 能构造局部修复候选。
4. 能构造完全重调度候选。
5. 能分别评价两个候选。
6. 能选择 `Y` 更小的方案。
7. 能打印两个候选的 `Cmax_delta`、`SD`、`TD`、`energy` 和 `Y`。
8. 能打印最终选择方案。
9. 能写入 `outputs/`。
10. 不做多随机种子。
11. 不形成正式研究结论。

## 37. 后续步骤

Step E14 应整理阶段 E 工作记录文档，例如：

```text
docs/00_system_overview/stage_e_work_record.md
```

Step E14 应把测试入口、smoke 输出结果和阶段 F 入口写清楚。

# 阶段 D 工作记录：完全重调度候选方案

本文档记录阶段 D 的目标、输入契约、冻结规则、任务排除规则、复用 independent 解码层的方式、新增文件、测试入口、当前验证结果和完成标志。阶段 D 第一版只生成完全重调度候选，不负责与局部修复候选比较，不计算评价权重 `Y`。

## 1. 阶段目标

阶段 D 的目标是：

```text
复用 independent 解码和搜索层，对剩余未完成工序重新调度。
```

阶段 D 当前实现范围进一步收窄为：

```text
基于调用方给定的 chrom，复用 independent 解码入口生成一个完全重调度候选。
```

说明：

1. 已复用 independent 解码入口。
2. 尚未启动 independent 搜索循环。
3. 不做局部修复与完全重调度的策略比较。
4. 不计算 `Cmax_delta`、`SD`、`TD`、能耗差值或 `Y`。

## 2. 输入契约

阶段 D 完全重调度候选输入：

```matlab
problem
machineData
agvData
schedule.machineTable
schedule.AGVTable
state
cancel
chrom
config
```

其中：

1. `state` 来自阶段 B 的 `extract_cancellation_state`。
2. `schedule.machineTable` 和 `schedule.AGVTable` 来自原正常调度计划。
3. `chrom` 由调用方提供，阶段 D 第一版不生成种群。
4. `config` 提供 independent 解码需要的能量和初始表参数。

支持策略：

```text
cancel_unstarted_operations_only
```

拒绝条件：

1. `cancel` 非法。
2. `state.cancel` 与 `cancel` 不一致。
3. 存在正在加工的取消相关机器工序。
4. 存在正在运输的取消相关 AGV 任务。
5. 剩余任务集合不可行。
6. independent 解码失败。
7. 合并后完整候选未通过可行性检查。

## 3. 冻结规则

冻结任务来自阶段 B 状态：

```matlab
state.completed_operations
state.completed_agv_tasks
```

冻结规则：

```text
operation.end_time <= cancel.cancel_time
agv_task.end_time <= cancel.cancel_time
```

阶段 D 要求：

1. 冻结机器工序的机器编号、开始时间和结束时间保持不变。
2. 冻结 AGV 任务的 AGV 编号、开始时间和结束时间保持不变。
3. 冻结任务不进入 remaining problem。
4. 正在加工或正在运输任务第一版不冻结，直接作为 unsupported 拒绝。

## 4. 任务排除规则

完全重调度任务来自：

```matlab
state.remaining_unfinished_operations
```

必须排除：

```matlab
state.cancelled_unfinished_operations
state.cancelled_unfinished_agv_tasks
cancel.job_id 的未完成任务
```

保留说明：

1. 被取消订单已经完成的机器工序可以作为冻结历史保留。
2. 被取消订单已经完成的 AGV 任务可以作为冻结历史保留。
3. 被取消订单未完成工序不得进入 `remainingSet.operations`。
4. 被取消订单未完成工序记录在 `excluded_operations`。

## 5. independent 解码复用说明

阶段 D 第一版复用：

```matlab
src/decoding/decode_chromosome_independent.m
```

复用方式：

1. `build_rescheduling_problem` 构造只包含剩余未完成工序的 temporary problem。
2. `decode_complete_rescheduling_candidate` 调用 `decode_chromosome_independent`。
3. 解码结果通过 `operation_map` 从 temporary job/operation 映射回原 job/operation。
4. `merge_frozen_and_rescheduled_schedule` 将冻结前缀和重调度后缀合并。
5. `check_complete_rescheduling_candidate` 复用阶段 C 可行性检查函数验证完整候选。

当前没有做：

1. 不启动 `run_independent_nsga2`。
2. 不生成 population。
3. 不做多随机种子实验。
4. 不写 `outputs/`。
5. 不计算阶段 E 的评价指标。

## 6. 新增文件清单

阶段 D 文档：

```text
docs/00_system_overview/stage_d_complete_rescheduling_contract.md
docs/00_system_overview/stage_d_work_record.md
```

阶段 D 源码：

```text
src/cancellation/extract_frozen_schedule_prefix.m
src/cancellation/build_remaining_operation_set.m
src/cancellation/build_rescheduling_problem.m
src/cancellation/build_rescheduling_constraints.m
src/cancellation/decode_complete_rescheduling_candidate.m
src/cancellation/merge_frozen_and_rescheduled_schedule.m
src/cancellation/check_complete_rescheduling_candidate.m
src/cancellation/build_complete_rescheduling_candidate.m
```

阶段 D 测试：

```text
tests/test_order_cancellation_frozen_prefix.m
tests/test_order_cancellation_remaining_set.m
tests/test_order_cancellation_rescheduling_problem.m
tests/test_order_cancellation_rescheduling_constraints.m
tests/test_order_cancellation_rescheduling_decode.m
tests/test_order_cancellation_schedule_merge.m
tests/test_order_cancellation_complete_rescheduling_feasibility.m
tests/test_order_cancellation_complete_rescheduling_candidate.m
tests/test_order_cancellation_complete_rescheduling.m
```

阶段 D smoke 脚本：

```text
scripts/run_order_cancellation_complete_rescheduling_smoke.m
```

## 7. 测试与 smoke 入口

单步测试入口：

```matlab
run('tests/test_order_cancellation_frozen_prefix.m')
run('tests/test_order_cancellation_remaining_set.m')
run('tests/test_order_cancellation_rescheduling_problem.m')
run('tests/test_order_cancellation_rescheduling_constraints.m')
run('tests/test_order_cancellation_rescheduling_decode.m')
run('tests/test_order_cancellation_schedule_merge.m')
run('tests/test_order_cancellation_complete_rescheduling_feasibility.m')
run('tests/test_order_cancellation_complete_rescheduling_candidate.m')
run('tests/test_order_cancellation_complete_rescheduling.m')
```

样例数据 smoke 入口：

```matlab
run('scripts/run_order_cancellation_complete_rescheduling_smoke.m')
```

## 8. 当前 smoke 输出结果

用户已运行并反馈以下测试通过：

```text
test_order_cancellation_rescheduling_problem passed
test_order_cancellation_rescheduling_constraints passed
test_order_cancellation_rescheduling_decode passed
test_order_cancellation_schedule_merge passed
```

用户后续已运行 D12 样例数据 smoke，并反馈以下输出：

```text
order cancellation complete rescheduling smoke
dataset: data_sample/Mk01.fjs
cancel.job_id: 2
cancel.cancel_time: 10.000000
cancel.policy: cancel_unstarted_operations_only
completed_operations: 3
completed_agv_tasks: 3
cancelled_unfinished_operations: 1
cancelled_unfinished_agv_tasks: 1
remaining_unfinished_operations: 2
unsupported_operations: 0
unsupported_agv_tasks: 0
frozen_operations: 3
frozen_agv_tasks: 3
excluded_operations: 1
rescheduled_operations: 2
candidate.isFeasible: 1
machineConflictCheck.isFeasible: 1
agvConflictCheck.isFeasible: 1
jobSequenceCheck.isFeasible: 1
frozenConsistencyCheck.isFeasible: 1
cancelledTaskExclusionCheck.isFeasible: 1
error_count: 0
rejected_reason_count: 0
```

上述结果含义：

1. `completed_operations: 3` 和 `completed_agv_tasks: 3` 表示取消时刻前已经完成的机器工序和 AGV 运输任务数量。
2. `cancelled_unfinished_operations: 1` 和 `cancelled_unfinished_agv_tasks: 1` 表示被取消订单中尚未完成、需要排除的机器工序和 AGV 运输任务数量。
3. `remaining_unfinished_operations: 2` 表示未取消订单中仍需进入完全重调度的剩余工序数量。
4. `unsupported_operations: 0` 和 `unsupported_agv_tasks: 0` 表示样例中没有正在加工或正在运输的取消相关任务，因此阶段 D 第一版可以继续处理。
5. `frozen_operations: 3` 和 `frozen_agv_tasks: 3` 表示冻结前缀已经提取，历史任务保持原计划不变。
6. `excluded_operations: 1` 表示被取消订单的未完成工序已从重调度任务集中排除。
7. `rescheduled_operations: 2` 表示剩余未完成工序已经通过 independent 解码入口形成重调度后缀。
8. `candidate.isFeasible: 1` 表示合并冻结前缀与重调度后缀后的完全重调度候选整体可行。
9. 六个检查项均为 `1`，表示机器时间冲突、AGV 时间冲突、工件工序顺序、冻结一致性和取消任务排除都通过。
10. `error_count: 0` 和 `rejected_reason_count: 0` 表示本次 smoke 没有记录错误，也没有触发拒绝原因。

因此，D12 smoke 说明：在 `data_sample/Mk01.fjs` 的最小样例上，阶段 D 已经能把已完成任务冻结、把取消订单未完成任务排除，并对剩余未完成任务生成一个可行的 FJSP-AGV 完全重调度候选。

边界说明：该结果只证明阶段 D 候选生成链路在样例 smoke 上闭环，不代表已经完成局部修复与完全重调度的优劣比较，也不代表已经形成正式实验结论。

## 9. 阶段 D 完成标志

阶段 D 完成标志：

```text
冻结任务保持不变；
被取消订单的未完成任务被排除；
剩余未完成任务能够通过 independent 解码入口生成一个可行的 FJSP-AGV 完全重调度候选计划。
```

当前状态：

1. D3-D12 文件已经建立。
2. D5-D8 用户反馈测试通过。
3. D12 样例数据 smoke 用户反馈通过，`candidate.isFeasible: 1`，`error_count: 0`。
4. 阶段 D 候选仍只是候选，不代表最终策略。

## 10. 阶段 E 入口说明

阶段 E 才负责比较局部修复候选和完全重调度候选。

阶段 E 可接入内容：

1. 阶段 C 的局部修复候选。
2. 阶段 D 的完全重调度候选。
3. 最大完工时间变化。
4. 能耗变化。
5. 调度扰动指标。
6. 最终综合评价 `Y`。

阶段 D 不负责：

1. 不计算 `Y`。
2. 不选择局部修复或完全重调度谁更优。
3. 不写正式实验结果。
4. 不形成研究结论。

## 11. 阶段 D 静态验收

Step D14 静态验收结果：

1. `build_complete_rescheduling_candidate.m` 已存在。
2. `extract_frozen_schedule_prefix.m` 已存在。
3. `build_remaining_operation_set.m` 已存在。
4. `build_rescheduling_problem.m` 已存在。
5. `merge_frozen_and_rescheduled_schedule.m` 已存在。
6. 完全重调度测试已存在。
7. 样例数据 smoke 脚本已存在。
8. README 已挂阶段 D 契约和阶段 D 工作记录入口。
9. `raw_code/` 无修改。
10. 阶段 D 新增源码、测试和 smoke 脚本中没有阶段 E 的 `Y` 选择逻辑。
11. 阶段 D 新增源码、测试和 smoke 脚本中没有局部修复和完全重调度比较逻辑。
12. 阶段 D 新增源码、测试和 smoke 脚本中没有正式实验入口。
13. `git diff --check` 通过。

本次静态验收没有运行 MATLAB，没有生成 `outputs/`。

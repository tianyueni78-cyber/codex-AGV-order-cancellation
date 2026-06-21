# 阶段 D 完全重调度输入与输出契约

> 本文档已不再作为阶段 D 的主要阅读入口。阶段 D 的输入输出、冻结规则、任务排除、解码复用、测试入口和 smoke 结果已整合到 [阶段 D 工作记录](stage_d_work_record.md)。本文档仅保留为历史过程记录。

本文档定义阶段 D 完全重调度候选方案的输入、输出、任务来源、排除规则、拒绝条件和禁止行为。Step D1 和 Step D2 只确认契约，不实现完全重调度算法。

## 1. 阶段 D 目标

阶段 D 的目标是：

```text
复用 independent 解码和搜索层，对剩余未完成工序重新调度。
```

阶段 D 第一版完全重调度的基本思想：

1. 冻结取消时刻以前已经完成的机器工序和 AGV 运输任务。
2. 排除被取消订单的未完成机器工序和相关 AGV 运输任务。
3. 只对未取消订单的剩余未完成工序重新调度。
4. 后续实现优先复用 independent 编码、解码、AGV 调度和搜索层。
5. 完全重调度只生成候选方案，不在阶段 D 比较局部修复与完全重调度。

## 2. 输入契约

阶段 D 完全重调度候选只接收阶段 B 的状态结果和原正常调度计划。

必须输入：

```matlab
problem
machineData
agvData
schedule.machineTable
schedule.AGVTable
state
cancel
config
```

其中：

1. `problem` 来自原正常调度数据读取链路。
2. `machineData` 来自原机器数据读取链路。
3. `agvData` 来自原 AGV 数据读取链路。
4. `schedule.machineTable` 来自原正常调度结果。
5. `schedule.AGVTable` 来自原正常调度结果。
6. `state` 必须由 `extract_cancellation_state(problem, schedule, cancel)` 生成。
7. `cancel` 必须由 `create_order_cancellation_event` 创建，并通过 `validate_order_cancellation_event` 校验。
8. `config` 用于后续复用 independent 解码或搜索层的参数。

阶段 D 不直接重新提取状态。若输入的 `state` 与 `schedule` 或 `cancel` 不一致，后续实现应拒绝生成完全重调度候选，并在 `candidate.report` 中说明原因。

## 3. 冻结任务来源

冻结任务来自阶段 B 状态提取结果：

```matlab
state.completed_operations
state.completed_agv_tasks
```

冻结规则：

1. `state.completed_operations` 中的机器工序视为已执行历史。
2. `state.completed_agv_tasks` 中的 AGV 运输任务视为已执行历史。
3. 冻结任务的 `start_time`、`end_time`、机器编号和 AGV 编号必须保持不变。
4. 冻结任务不能进入重新调度任务集合。
5. 后续完全重调度结果必须与冻结任务合并为完整候选计划。

## 4. 重调度任务来源

重调度任务来自阶段 B 状态提取结果：

```matlab
state.remaining_unfinished_operations
```

含义：

1. 这些工序属于未取消订单。
2. 这些工序在 `cancel_time` 时刻尚未完成。
3. 这些工序是阶段 D 完全重调度的主要任务集合。
4. 后续实现应基于这些工序构造 temporary rescheduling problem。

阶段 D 第一版不从原始 `problem` 中自行猜测剩余任务，而是以阶段 B 的状态提取结果为准。

## 5. 必须排除的任务

以下任务不得进入完全重调度任务集合：

```matlab
state.cancelled_unfinished_operations
state.cancelled_unfinished_agv_tasks
```

排除规则：

1. 被取消订单的未完成机器工序不进入重调度任务集。
2. 被取消订单尚未执行的 AGV 运输任务不进入重调度任务集。
3. 被取消订单已完成的历史任务可以保留在冻结前缀中。
4. 被取消订单正在加工或正在运输的任务第一版不处理，触发 unsupported 拒绝。

## 6. 支持的取消策略

阶段 D 第一版只支持：

```text
cancel_unstarted_operations_only
```

若 `cancel.policy` 不是该值，完全重调度候选必须拒绝生成。

## 7. 必须拒绝进入完全重调度的情况

以下任一条件成立时，阶段 D 第一版必须拒绝进入完全重调度：

```matlab
state.has_unsupported_operations == true
```

含义：被取消订单存在正在加工的机器工序。第一版不处理中断加工。

```matlab
state.has_unsupported_agv_tasks == true
```

含义：被取消订单存在正在运输的 AGV 任务。第一版不处理中断运输。

其他必须拒绝的情况：

1. `cancel.policy` 不是 `cancel_unstarted_operations_only`。
2. 缺少 `problem`。
3. 缺少 `machineData`。
4. 缺少 `agvData`。
5. 缺少 `schedule.machineTable`。
6. 缺少 `schedule.AGVTable`。
7. 缺少 `state.completed_operations`。
8. 缺少 `state.completed_agv_tasks`。
9. 缺少 `state.remaining_unfinished_operations`。
10. 缺少 `state.cancelled_unfinished_operations`。
11. `state.cancel.job_id` 与 `cancel.job_id` 不一致。
12. `state.cancel.cancel_time` 与 `cancel.cancel_time` 不一致。

## 8. 阶段 D 禁止行为

Step D1、Step D2 以及阶段 D 第一版完全重调度禁止：

1. 修改 `raw_code/`。
2. 修改阶段 C 的局部修复候选逻辑。
3. 把局部修复和完全重调度做最终比较。
4. 新增评价权重 `Y` 的策略选择逻辑。
5. 生成正式实验输出。
6. 在未确认前运行 MATLAB。
7. 绕过阶段 B 的 `state`，直接从原始数据中猜测取消状态。

## 9. 完全重调度候选输出结构

Step D2 定义完全重调度候选方案的输出结构。后续冻结任务提取、剩余任务集合构造、independent 解码或搜索、冻结计划合并和可行性检查都应写入同一个 `candidate`。

```matlab
candidate.machineTable
candidate.AGVTable
candidate.frozen_operations
candidate.frozen_agv_tasks
candidate.rescheduled_operations
candidate.excluded_operations
candidate.isFeasible
candidate.report
```

字段含义：

| 字段 | 含义 |
|---|---|
| `candidate.machineTable` | 冻结任务与完全重调度后剩余机器工序合并形成的机器表候选 |
| `candidate.AGVTable` | 冻结任务与完全重调度后剩余 AGV 任务合并形成的 AGV 表候选 |
| `candidate.frozen_operations` | 来自 `state.completed_operations` 的冻结机器工序 |
| `candidate.frozen_agv_tasks` | 来自 `state.completed_agv_tasks` 的冻结 AGV 运输任务 |
| `candidate.rescheduled_operations` | 已进入完全重调度并成功生成计划的剩余未完成机器工序 |
| `candidate.excluded_operations` | 因订单取消而被排除的未完成机器工序 |
| `candidate.isFeasible` | 当前完全重调度候选是否通过阶段 D 可行性检查 |
| `candidate.report` | 候选生成过程、拒绝原因、检查结果和不可行原因 |

## 10. 冻结任务记录约定

`candidate.frozen_operations` 必须能记录哪些机器工序被冻结。每条记录至少包含：

```matlab
job_id
operation_id
machine_id
start_time
end_time
status
source
```

`candidate.frozen_agv_tasks` 必须能记录哪些 AGV 运输任务被冻结。每条记录至少包含：

```matlab
job_id
operation_id
agv_id
start_time
end_time
from_machine
to_machine
status
source
```

约定：

1. 冻结记录只来自阶段 B 的 completed 状态。
2. 冻结记录的时间和资源分配必须与原正常调度计划一致。
3. 冻结记录不能被 independent 解码或搜索修改。

## 11. 重调度任务记录约定

`candidate.rescheduled_operations` 必须能记录哪些剩余未完成机器工序进入了完全重调度。每条记录至少包含：

```matlab
job_id
operation_id
machine_id
start_time
end_time
status
source
```

约定：

1. 重调度记录只来自 `state.remaining_unfinished_operations`。
2. 重调度记录不得包含 `cancel.job_id` 的未完成工序。
3. 重调度记录的开始时间不得早于 `cancel.cancel_time`。
4. 重调度记录应能追溯到原剩余任务集合，便于后续检查是否漏排或误排。

## 12. 排除任务记录约定

`candidate.excluded_operations` 必须能记录因订单取消而排除的未完成机器工序。每条记录至少包含：

```matlab
job_id
operation_id
original_machine_id
original_start_time
original_end_time
status
exclude_reason
```

第一版排除原因固定为：

```text
cancelled_order_unfinished_operation
```

约定：

1. `candidate.excluded_operations` 来自 `state.cancelled_unfinished_operations`。
2. 这些记录不得出现在 `candidate.rescheduled_operations`。
3. 这些记录不得出现在最终合并后的候选机器表中。
4. AGV 侧被取消的未执行运输任务后续可在 `candidate.report.excludedAgvTasks` 中记录，不进入 `candidate.AGVTable`。

## 13. report 结构约定

`candidate.report` 用于说明完全重调度候选为什么可行或不可行。建议字段：

```matlab
candidate.report.errors
candidate.report.warnings
candidate.report.rejectedReasons
candidate.report.frozenOperationCount
candidate.report.frozenAgvTaskCount
candidate.report.rescheduledOperationCount
candidate.report.excludedOperationCount
candidate.report.excludedAgvTaskCount
candidate.report.machineConflictCheck
candidate.report.agvConflictCheck
candidate.report.jobSequenceCheck
candidate.report.frozenConsistencyCheck
candidate.report.cancelledTaskExclusionCheck
```

约定：

1. `errors` 记录导致 `candidate.isFeasible = false` 的错误。
2. `warnings` 记录不阻断候选生成的提示。
3. `rejectedReasons` 记录前置条件拒绝原因，例如 unsupported 状态。
4. `frozenOperationCount` 记录冻结机器工序数量。
5. `frozenAgvTaskCount` 记录冻结 AGV 任务数量。
6. `rescheduledOperationCount` 记录重新调度的机器工序数量。
7. `excludedOperationCount` 记录被排除的取消订单未完成机器工序数量。
8. `excludedAgvTaskCount` 记录被排除的取消订单未完成 AGV 任务数量。
9. `machineConflictCheck` 记录机器时间冲突检查结果。
10. `agvConflictCheck` 记录 AGV 时间冲突检查结果。
11. `jobSequenceCheck` 记录工件工序顺序检查结果。
12. `frozenConsistencyCheck` 记录冻结任务是否保持不变。
13. `cancelledTaskExclusionCheck` 记录被取消未完成任务是否被彻底排除。

## 14. 阶段 D 不计算最终评价指标

Step D2 以及阶段 D 的候选结构不计算最终评价指标。以下字段不应在 Step D2 中新增：

```matlab
Cmax_delta
SD
TD
energy_delta
Y
```

原因：

1. 阶段 D 只负责生成完全重调度候选。
2. 局部修复与完全重调度的比较属于阶段 E。
3. 评价权重 `Y` 的计算和选择逻辑属于阶段 E。

## 15. Step D3 冻结前缀提取

Step D3 从阶段 B 状态结果中提取完全重调度必须保留不变的冻结前缀。

新增文件：

```text
src/cancellation/extract_frozen_schedule_prefix.m
tests/test_order_cancellation_frozen_prefix.m
```

冻结规则：

```text
operation.end_time <= cancel.cancel_time
agv_task.end_time <= cancel.cancel_time
```

输出结构：

```matlab
prefix.frozen_operations
prefix.frozen_agv_tasks
prefix.unsupported_operations
prefix.unsupported_agv_tasks
prefix.has_unsupported_operations
prefix.has_unsupported_agv_tasks
prefix.isFeasible
prefix.report
```

约定：

1. `prefix.frozen_operations` 来自 `state.completed_operations`。
2. `prefix.frozen_agv_tasks` 来自 `state.completed_agv_tasks`。
3. 冻结任务的开始时间、结束时间、机器编号和 AGV 编号不改变。
4. `state.processing_operations` 不冻结，进入 `prefix.unsupported_operations`。
5. `state.processing_agv_tasks` 不冻结，进入 `prefix.unsupported_agv_tasks`。
6. 第一版只要存在正在加工或正在运输任务，`prefix.isFeasible = false`。
7. Step D3 不构造重调度任务集，不调用 independent 解码或搜索。

## 16. Step D4 剩余未完成任务集合

Step D4 构造完全重调度需要处理的剩余未完成机器工序集合。

新增文件：

```text
src/cancellation/build_remaining_operation_set.m
tests/test_order_cancellation_remaining_set.m
```

任务来源：

```matlab
state.remaining_unfinished_operations
```

必须排除：

```matlab
state.cancelled_unfinished_operations
cancel.job_id
state.completed_operations
```

输出结构：

```matlab
remainingSet.operations
remainingSet.excluded_operations
remainingSet.isFeasible
remainingSet.report
```

约定：

1. `remainingSet.operations` 只包含未取消订单的未完成机器工序。
2. `remainingSet.excluded_operations` 记录被取消订单的未完成机器工序。
3. 已完成历史工序不得进入 `remainingSet.operations`。
4. 每条剩余任务记录至少包含 `job_id` 和 `operation_id`。
5. 若原状态中有 `machine_id`、`block_index`、`start_time`、`end_time` 或 `status`，应保留为可追溯信息。
6. 如果发现取消订单未完成工序混入 `remainingSet.operations`，`remainingSet.isFeasible = false`。
7. Step D4 不构造 temporary problem，不调用 independent 解码或搜索。

## 17. Step D5 重调度问题实例

Step D5 把原 `problem` 改造成只包含剩余未完成工序的 temporary problem。

新增文件：

```text
src/cancellation/build_rescheduling_problem.m
tests/test_order_cancellation_rescheduling_problem.m
```

输入：

```matlab
problem
machineData
agvData
remainingSet
cancel
```

输出结构：

```matlab
reschedulingProblem.problem
reschedulingProblem.machineData
reschedulingProblem.agvData
reschedulingProblem.operation_map
reschedulingProblem.excluded_operations
reschedulingProblem.isFeasible
reschedulingProblem.report
```

temporary problem 必须保留 independent 解码层能识别的基础字段：

```matlab
reschedulingProblem.problem.jobNum
reschedulingProblem.problem.machineNum
reschedulingProblem.problem.operaNumVec
reschedulingProblem.problem.candidateMachine
reschedulingProblem.problem.jobInfo
```

约定：

1. `reschedulingProblem.problem` 只包含 `remainingSet.operations` 中的工序。
2. 被取消订单未完成工序不得进入 temporary problem。
3. `machineData` 原样保留在 `reschedulingProblem.machineData`。
4. `agvData` 原样保留在 `reschedulingProblem.agvData`。
5. 原 `problem` 不得被修改。
6. `operation_map` 记录 temporary job/operation 与原 job/operation 的对应关系。
7. Step D5 不调用 independent 解码或搜索。

## 18. Step D6 冻结约束接口

Step D6 定义完全重调度必须遵守的冻结约束接口。

新增文件：

```text
src/cancellation/build_rescheduling_constraints.m
tests/test_order_cancellation_rescheduling_constraints.m
```

输入：

```matlab
prefix
remainingSet
cancel
```

输出结构：

```matlab
constraints.earliest_start_time
constraints.frozen_machine_occupancy
constraints.frozen_agv_occupancy
constraints.isFeasible
constraints.report
```

冻结约束：

1. `constraints.frozen_machine_occupancy` 来自 `prefix.frozen_operations`。
2. `constraints.frozen_agv_occupancy` 来自 `prefix.frozen_agv_tasks`。
3. 冻结机器工序的 `start_time` 和 `end_time` 不得改变。
4. 冻结 AGV 任务的 `start_time` 和 `end_time` 不得改变。
5. `constraints.earliest_start_time = cancel.cancel_time`。
6. 剩余任务开始时间不得早于 `cancel.cancel_time`。
7. 若 `prefix.isFeasible == false`，冻结约束接口直接标记不可行。
8. Step D6 不调用 independent 解码或搜索。

## 19. Step D7 复用 independent 解码入口

Step D7 定义完全重调度候选的 independent 解码适配层。

新增文件：

```text
src/cancellation/decode_complete_rescheduling_candidate.m
tests/test_order_cancellation_rescheduling_decode.m
```

输入：

```matlab
reschedulingProblem
constraints
chrom
config
```

输出结构：

```matlab
candidate.machineTable
candidate.AGVTable
candidate.jobCompleteUnLoad
candidate.rescheduled_operations
candidate.excluded_operations
candidate.isFeasible
candidate.report
```

复用规则：

1. Step D7 不新写一套解码器。
2. Step D7 只调用 `src/decoding/decode_chromosome_independent.m`。
3. `chrom` 由调用方传入，Step D7 不生成种群，不启动搜索。
4. temporary job/operation 解码后必须通过 `reschedulingProblem.operation_map` 映射回原 job/operation。
5. 输出的 `candidate.machineTable` 和 `candidate.AGVTable` 不得包含被取消订单未完成任务。
6. 若 `reschedulingProblem.isFeasible == false` 或 `constraints.isFeasible == false`，直接拒绝解码。

## 20. Step D8 合并冻结计划与重调度计划

Step D8 把冻结前缀和完全重调度后缀合并成完整候选计划。

新增文件：

```text
src/cancellation/merge_frozen_and_rescheduled_schedule.m
tests/test_order_cancellation_schedule_merge.m
```

输入：

```matlab
constraints
decodedCandidate
cancel
```

输出：

```matlab
candidate.machineTable
candidate.AGVTable
candidate.report.mergeCheck
candidate.isFeasible
```

合并规则：

1. 冻结机器占用来自 `constraints.frozen_machine_occupancy`。
2. 冻结 AGV 占用来自 `constraints.frozen_agv_occupancy`。
3. 重调度后缀来自 D7 的 `decodedCandidate.machineTable` 和 `decodedCandidate.AGVTable`。
4. 冻结任务的开始时间和结束时间必须保持不变。
5. 重调度任务必须追加在 `cancel.cancel_time` 之后。
6. 被取消订单未完成任务不得出现在合并后的 `machineTable` 或 `AGVTable`。
7. 合并后的 `machineTable` 和 `AGVTable` 保持阶段 C 候选使用的 cell array 表结构。
8. Step D8 不调用 independent 解码或搜索。

## 21. Step D9 完全重调度可行性检查

Step D9 复用阶段 C 的检查函数验证完整完全重调度候选。

新增文件：

```text
src/cancellation/check_complete_rescheduling_candidate.m
tests/test_order_cancellation_complete_rescheduling_feasibility.m
```

复用阶段 C 检查：

```matlab
check_machine_table_feasibility(candidate.machineTable)
check_agv_table_feasibility(candidate.AGVTable)
check_job_operation_sequence(problem, candidate.machineTable, cancel)
```

阶段 D 补充检查：

```matlab
frozenConsistencyCheck
cancelledTaskExclusionCheck
```

输入：

```matlab
problem
candidate
constraints
cancel
```

输出：

```matlab
isFeasible
report.machineConflictCheck
report.agvConflictCheck
report.jobSequenceCheck
report.frozenConsistencyCheck
report.cancelledTaskExclusionCheck
```

约定：

1. 机器无时间冲突。
2. AGV 无时间冲突。
3. 工件工序顺序满足。
4. 冻结机器工序和 AGV 任务必须与 `constraints` 中记录的时间和资源一致。
5. `candidate.excluded_operations` 中的被取消未完成工序不得回流到 `machineTable` 或 `AGVTable`。
6. Step D9 不计算评价指标，不做局部修复和完全重调度比较。

## 22. Step D10 完全重调度候选生成

Step D10 组合 D3-D9，生成第一版完全重调度候选。

新增文件：

```text
src/cancellation/build_complete_rescheduling_candidate.m
tests/test_order_cancellation_complete_rescheduling_candidate.m
```

输入：

```matlab
problem
machineData
agvData
schedule
state
cancel
chrom
config
```

输出：

```matlab
candidate.machineTable
candidate.AGVTable
candidate.frozen_operations
candidate.frozen_agv_tasks
candidate.rescheduled_operations
candidate.excluded_operations
candidate.isFeasible
candidate.report
```

组合流程：

1. 校验 `cancel` 和 `state`。
2. 拒绝 unsupported 状态。
3. 调用 `extract_frozen_schedule_prefix` 提取冻结任务。
4. 调用 `build_remaining_operation_set` 构造剩余未完成任务集合。
5. 调用 `build_rescheduling_problem` 构造 temporary rescheduling problem。
6. 调用 `build_rescheduling_constraints` 构造冻结约束。
7. 调用 `decode_complete_rescheduling_candidate` 复用 independent 解码入口。
8. 调用 `merge_frozen_and_rescheduled_schedule` 合并冻结计划和重调度计划。
9. 调用 `check_complete_rescheduling_candidate` 做完整可行性检查。
10. 输出 `candidate.isFeasible`。

约定：

1. Step D10 第一版接收调用方提供的 `chrom`。
2. Step D10 不生成种群，不启动 NSGA-II 搜索。
3. Step D10 不计算评价指标 `Y`。
4. Step D10 只生成完全重调度候选，不与局部修复候选比较。

## 23. Step D11 完全重调度 smoke 测试

Step D11 用最小构造数据验证 D10，不跑正式实验。

新增文件：

```text
tests/test_order_cancellation_complete_rescheduling.m
```

测试内容：

1. 冻结任务保持不变。
2. 取消订单未完成工序被排除。
3. 剩余工序被重新调度。
4. 重调度任务 `start >= cancel_time`。
5. 机器时间冲突被拒绝。
6. AGV 时间冲突被拒绝。
7. 工序顺序错误被拒绝。
8. unsupported 状态被拒绝。

约定：

1. 不写 `outputs/`。
2. 不跑多随机种子。
3. 不做阶段 E 策略比较。
4. 不计算 `Y`。

## 24. Step D12 样例数据完全重调度 smoke 脚本

Step D12 在 `data_sample/Mk01.fjs` 上做最小 smoke。

新增文件：

```text
scripts/run_order_cancellation_complete_rescheduling_smoke.m
```

运行入口：

```matlab
run('scripts/run_order_cancellation_complete_rescheduling_smoke.m')
```

脚本输出：

1. `cancel.job_id`
2. `cancel.cancel_time`
3. `frozen_operations`
4. `frozen_agv_tasks`
5. `excluded_operations`
6. `rescheduled_operations`
7. `candidate.isFeasible`
8. 机器、AGV、工序顺序、冻结一致性和取消任务排除检查结果

约定：

1. 能生成 `cancel`。
2. 能提取状态。
3. 能构造完全重调度候选。
4. 不做阶段 E 策略选择。
5. 不写 `outputs/`。
6. 不启动正式 NSGA-II 实验。

## 25. Step D1 验收标准

Step D1 完成后应满足：

1. 明确冻结任务来自 `completed_operations` 和 `completed_agv_tasks`。
2. 明确重调度任务来自 `remaining_unfinished_operations`。
3. 明确 `cancelled_unfinished_operations` 不进入重调度任务集。
4. 明确 `unsupported` 状态直接拒绝。
5. 只新增契约文档，不新增完全重调度算法。

## 26. Step D2 验收标准

Step D2 完成后应满足：

1. 明确 `candidate` 输出结构。
2. 能记录哪些任务被冻结。
3. 能记录哪些任务被重新调度。
4. 能记录哪些被取消任务被排除。
5. 能记录不可行原因。
6. 暂不计算最终评价指标 `Y`。
7. 只更新契约文档，不新增完全重调度算法。

## 27. Step D3 验收标准

Step D3 完成后应满足：

1. 已完成机器工序进入 `frozen_operations`。
2. 已完成 AGV 任务进入 `frozen_agv_tasks`。
3. 冻结任务开始时间和结束时间不改变。
4. 正在加工任务不冻结，标记为 `unsupported_operations`。
5. 正在运输任务不冻结，标记为 `unsupported_agv_tasks`。
6. 不新增完全重调度算法。

## 28. Step D4 验收标准

Step D4 完成后应满足：

1. 被取消订单未完成工序不在 `remainingSet.operations`。
2. 未取消订单未完成工序在 `remainingSet.operations`。
3. 已完成历史工序不重复进入 `remainingSet.operations`。
4. `remainingSet.excluded_operations` 能记录被取消订单未完成工序。
5. 任务集合包含 `job_id`、`operation_id` 和可选机器信息。
6. 不新增完全重调度算法。

## 29. Step D5 验收标准

Step D5 完成后应满足：

1. temporary problem 不包含被取消订单未完成工序。
2. temporary problem 保留机器数量、候选机器和加工时间数据。
3. `machineData` 和 `agvData` 原样保留。
4. temporary problem 包含 independent 解码层需要的 `jobNum`、`machineNum`、`operaNumVec`、`candidateMachine` 和 `jobInfo`。
5. 原 `problem` 不被修改。
6. 不调用 independent 解码或搜索。

## 30. Step D6 验收标准

Step D6 完成后应满足：

1. 冻结任务时间保持不变。
2. 剩余任务开始时间不得早于 `cancel_time`。
3. 机器冻结占用能通过 `constraints.frozen_machine_occupancy` 传入后续解码或可行性检查。
4. AGV 冻结占用能通过 `constraints.frozen_agv_occupancy` 传入后续解码或可行性检查。
5. 不新增完全重调度算法。

## 31. Step D7 验收标准

Step D7 完成后应满足：

1. 不新写一套解码器。
2. 复用 `src/decoding/decode_chromosome_independent.m`。
3. 能输出重调度后的 `machineTable` 和 `AGVTable`。
4. 输出不包含被取消订单未完成任务。
5. 不启动 NSGA-II 搜索。

## 32. Step D8 验收标准

Step D8 完成后应满足：

1. 冻结任务保持原时间。
2. 重调度任务追加在 `cancel_time` 之后。
3. 被取消订单未完成任务不出现。
4. 合并后的 `machineTable` 和 `AGVTable` 格式与阶段 C 候选一致。
5. 不调用 independent 解码或搜索。

## 33. Step D9 验收标准

Step D9 完成后应满足：

1. 机器无时间冲突。
2. AGV 无时间冲突。
3. 工件工序顺序满足。
4. 冻结任务没有被改变。
5. 被取消任务没有回流。
6. 复用阶段 C 的机器、AGV 和工序顺序检查函数。
7. 不新增评价权重 `Y` 或正式实验逻辑。

## 34. Step D10 验收标准

Step D10 完成后应满足：

1. 冻结任务保持不变。
2. 被取消未完成任务被排除。
3. 剩余未完成任务能形成可行 FJSP-AGV 调度计划。
4. `candidate.isFeasible` 能反映完整可行性检查结果。
5. 不启动 NSGA-II 搜索。
6. 不新增评价权重 `Y` 或阶段 E 策略选择逻辑。

## 35. Step D11 验收标准

Step D11 完成后应满足：

1. `tests/test_order_cancellation_complete_rescheduling.m` 已存在。
2. smoke 测试只使用最小构造数据。
3. smoke 测试不写 `outputs/`。
4. smoke 测试不跑多随机种子。
5. smoke 测试不做阶段 E 策略比较。
6. smoke 测试不计算 `Y`。

## 36. Step D12 验收标准

Step D12 完成后应满足：

1. `scripts/run_order_cancellation_complete_rescheduling_smoke.m` 已存在。
2. 能生成 `cancel`。
3. 能提取状态。
4. 能构造完全重调度候选。
5. 能打印冻结任务数量、排除任务数量、重调度任务数量和可行性。
6. 不做阶段 E 策略选择。
7. 不写 `outputs/`。
8. 不启动正式 NSGA-II 实验。

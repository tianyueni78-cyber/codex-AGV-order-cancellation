# 阶段 C 局部修复输入与输出契约

本文档定义阶段 C 局部修复候选方案的输入、输出、前置条件、拒绝条件和禁止行为。Step C1 和 Step C2 只确认契约，不实现删除逻辑。

## 1. 阶段 C 目标

阶段 C 的目标是：

```text
删除取消订单未完成任务，并构造可行的局部修复计划。
```

第一版局部修复采用删除式修复思想：

1. 删除被取消订单尚未开工的机器工序。
2. 删除被取消订单尚未执行的 AGV 运输任务。
3. 保留已经完成的机器工序和 AGV 运输任务作为历史。
4. 不处理中断正在加工或正在运输的取消任务。
5. 不重新搜索，不调用 NSGA-II。

## 2. 输入契约

阶段 C 局部修复只接收阶段 B 的状态结果和原正常调度计划。

必须输入：

```matlab
problem
schedule.machineTable
schedule.AGVTable
state
cancel
```

其中：

1. `problem` 来自原正常调度数据读取链路。
2. `schedule.machineTable` 来自原正常调度结果。
3. `schedule.AGVTable` 来自原正常调度结果。
4. `state` 必须由 `extract_cancellation_state(problem, schedule, cancel)` 生成。
5. `cancel` 必须由 `create_order_cancellation_event` 创建，并通过 `validate_order_cancellation_event` 校验。

阶段 C 不直接重新提取状态。若输入的 `state` 与 `schedule` 或 `cancel` 不一致，后续实现应拒绝修复或在 report 中明确说明。

## 3. 支持的取消策略

阶段 C 第一版只支持：

```text
cancel_unstarted_operations_only
```

若 `cancel.policy` 不是该值，局部修复必须拒绝执行。

## 4. 必须拒绝进入局部修复的情况

以下任一条件成立时，阶段 C 第一版必须拒绝进入局部修复：

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
2. 缺少 `schedule.machineTable`。
3. 缺少 `schedule.AGVTable`。
4. 缺少 `state.cancelled_unfinished_operations`。
5. 缺少 `state.cancelled_unfinished_agv_tasks`。
6. `state.cancel.job_id` 与 `cancel.job_id` 不一致。
7. `state.cancel.cancel_time` 与 `cancel.cancel_time` 不一致。

## 5. 阶段 C 禁止行为

Step C1 以及阶段 C 第一版局部修复禁止：

1. 调用 `run_independent_nsga2`。
2. 调用任何 NSGA-II 正式搜索入口。
3. 新增完全重调度逻辑。
4. 新增评价权重 `Y` 的策略选择逻辑。
5. 修改 `raw_code/`。
6. 生成正式实验输出。
7. 在未确认前运行 MATLAB。

## 6. 局部修复候选输出结构

Step C2 定义局部修复候选方案的输出结构。后续删除机器工序、删除 AGV 任务、冲突检查和顺序检查都应写入同一个 `candidate`。

```matlab
candidate.machineTable
candidate.AGVTable
candidate.removed_operations
candidate.removed_agv_tasks
candidate.isFeasible
candidate.report
```

字段含义：

| 字段 | 含义 |
|---|---|
| `candidate.machineTable` | 局部修复后的机器表候选 |
| `candidate.AGVTable` | 局部修复后的 AGV 表候选 |
| `candidate.removed_operations` | 已从机器表删除的取消订单工序 |
| `candidate.removed_agv_tasks` | 已从 AGV 表删除的取消订单运输任务 |
| `candidate.isFeasible` | 当前候选是否通过阶段 C 可行性检查 |
| `candidate.report` | 修复过程、拒绝原因和检查结果 |

## 7. 删除记录约定

`candidate.removed_operations` 必须能记录删除了哪些机器工序。每条记录至少包含：

```matlab
job_id
operation_id
machine_id
block_index
start_time
end_time
status
```

`candidate.removed_agv_tasks` 必须能记录删除了哪些 AGV 运输任务。每条记录至少包含：

```matlab
job_id
operation_id
agv_id
block_index
start_time
end_time
from_machine
to_machine
status
```

第一版只允许删除 `status == 'unstarted'` 且 `job_id == cancel.job_id` 的记录。

## 8. report 结构约定

`candidate.report` 用于说明候选方案为什么可行或不可行。建议字段：

```matlab
candidate.report.errors
candidate.report.warnings
candidate.report.rejectedReasons
candidate.report.removedOperationCount
candidate.report.removedAgvTaskCount
candidate.report.machineConflictCheck
candidate.report.agvConflictCheck
candidate.report.jobSequenceCheck
```

约定：

1. `errors` 记录导致 `candidate.isFeasible = false` 的错误。
2. `warnings` 记录不阻断候选生成的提示。
3. `rejectedReasons` 记录前置条件拒绝原因，例如 unsupported 状态。
4. `removedOperationCount` 记录删除的机器工序数量。
5. `removedAgvTaskCount` 记录删除的 AGV 任务数量。
6. `machineConflictCheck` 记录机器时间冲突检查结果。
7. `agvConflictCheck` 记录 AGV 时间冲突检查结果。
8. `jobSequenceCheck` 记录工件工序顺序检查结果。

## 9. 阶段 C 不计算最终评价指标

Step C2 以及阶段 C 的候选结构不计算最终评价指标。以下字段不应在 Step C2 中新增：

```matlab
Cmax_delta
SD
TD
Y
objective
```

这些指标属于后续阶段 E 的评价与策略选择，不属于局部修复输出结构定义。

## 10. Step C1 验收标准

Step C1 完成条件：

1. 明确局部修复输入只来自阶段 B 的 `state` 和原正常调度 `schedule`。
2. 明确只处理 `cancel_unstarted_operations_only`。
3. 明确 `state.has_unsupported_operations == true` 时拒绝局部修复。
4. 明确 `state.has_unsupported_agv_tasks == true` 时拒绝局部修复。
5. 明确不重新搜索，不调用 NSGA-II。
6. 未新增局部修复算法代码。
7. 未新增完全重调度代码。

## 11. Step C2 验收标准

Step C2 完成条件：

1. 明确 `candidate.machineTable` 和 `candidate.AGVTable` 的用途。
2. 明确 `candidate.removed_operations` 用于记录删除了哪些机器工序。
3. 明确 `candidate.removed_agv_tasks` 用于记录删除了哪些 AGV 任务。
4. 明确 `candidate.report` 用于记录不可行原因和检查结果。
5. 明确 `candidate.isFeasible` 表示候选是否通过阶段 C 可行性检查。
6. 明确 Step C2 不计算最终评价指标。
7. 未新增局部修复算法代码。

## 12. Step C3：删除取消订单未完成机器工序

Step C3 只处理 `machineTable` 中的机器工序删除，不处理 AGV 任务，也不移动剩余工序时间。

新增函数：

```text
src/cancellation/remove_cancelled_machine_operations.m
```

第一版只允许删除：

```matlab
status == 'unstarted'
job_id == cancel.job_id
```

拒绝条件：

1. `state.has_unsupported_operations == true`。
2. `state.has_unsupported_agv_tasks == true`。
3. `cancel.policy` 不是 `cancel_unstarted_operations_only`。
4. `state.cancel` 与 `cancel` 不一致。

输出约定：

1. 删除后的机器表写入 `candidate.machineTable`。
2. 原 `schedule.AGVTable` 原样写入 `candidate.AGVTable`。
3. 删除的机器工序写入 `candidate.removed_operations`。
4. Step C3 不删除 AGV 任务，因此 `candidate.removed_agv_tasks` 为空。
5. 拒绝原因写入 `candidate.report.rejectedReasons`。

验收标准：

1. 被取消订单尚未开工工序不再出现在候选 `machineTable`。
2. 被取消订单已完成工序仍保留。
3. 正在加工工序不删除，而是拒绝修复。
4. 不移动其他工序时间。
5. 不计算最终评价指标。

## 13. Step C4：删除取消订单未完成 AGV 运输任务

Step C4 只处理 `AGVTable` 中的 AGV 运输任务删除，不处理机器工序，也不移动剩余 AGV 任务时间。

新增函数：

```text
src/cancellation/remove_cancelled_agv_tasks.m
```

第一版只允许删除：

```matlab
status == 'unstarted'
job_id == cancel.job_id
```

拒绝条件：

1. `state.has_unsupported_operations == true`。
2. `state.has_unsupported_agv_tasks == true`。
3. `cancel.policy` 不是 `cancel_unstarted_operations_only`。
4. `state.cancel` 与 `cancel` 不一致。

输出约定：

1. 原 `schedule.machineTable` 原样写入 `candidate.machineTable`。
2. 删除后的 AGV 表写入 `candidate.AGVTable`。
3. Step C4 不删除机器工序，因此 `candidate.removed_operations` 为空。
4. 删除的 AGV 任务写入 `candidate.removed_agv_tasks`。
5. 拒绝原因写入 `candidate.report.rejectedReasons`。

验收标准：

1. 被取消订单尚未执行运输不再出现在候选 `AGVTable`。
2. 被取消订单已完成运输仍保留。
3. 正在运输任务不删除，而是拒绝修复。
4. 不移动其他 AGV 任务时间。
5. 不计算最终评价指标。

## 14. Step C5：空闲块处理策略

阶段 C 第一版明确采用：

```text
删除式局部修复
```

含义：

1. 只删除被取消订单尚未开工的机器工序。
2. 只删除被取消订单尚未执行的 AGV 运输任务。
3. 删除后保留原时间轴上的空洞。
4. 不左移剩余机器工序。
5. 不左移剩余 AGV 任务。
6. 不压缩机器空闲块。
7. 不压缩 AGV 空闲块。
8. 不重新分配机器。
9. 不重新分配 AGV。
10. 不改变未取消订单的开始时间和结束时间。

选择该策略的原因：

1. 第一版最容易验证。
2. 删除任务不会引入新的机器时间冲突。
3. 删除任务不会引入新的 AGV 时间冲突。
4. 可以把“任务删除”和“计划优化”分开，避免阶段 C 过早变成完全重调度。

机器时间约束：

```matlab
candidate.machineTable
```

对于所有未取消订单的机器工序，`start` 和 `end` 必须与原 `schedule.machineTable` 中对应工序一致。

AGV 时间约束：

```matlab
candidate.AGVTable
```

对于所有未取消订单的 AGV 运输任务，`start` 和 `end` 必须与原 `schedule.AGVTable` 中对应任务一致。

删除后形成的空闲时间暂不合并、不压缩、不重新命名。后续若需要左移压缩，应作为新的扩展步骤单独设计和测试。

验收标准：

1. 文档写清楚第一版是“删除式局部修复”。
2. 不改变未取消订单的机器开始时间和结束时间。
3. 不改变未取消订单的 AGV 开始时间和结束时间。
4. 不因为删除任务而触发搜索、重排或优化。

## 15. Step C6：机器时间冲突检查

Step C6 验证候选 `machineTable` 中同一机器上的真实工序没有时间重叠。

新增函数：

```text
src/cancellation/check_machine_table_feasibility.m
```

检查范围：

1. 只检查 `job > 0` 的真实工序。
2. 忽略 `job <= 0` 的空闲块。
3. 检查每个真实工序是否满足 `end >= start`。
4. 检查同一机器上任意两个真实工序是否时间重叠。

时间重叠规则：

```matlab
current.start < previous.end
```

若上一个真实工序的 `end` 等于下一个真实工序的 `start`，不视为冲突。

输出约定：

```matlab
[isFeasible, report] = check_machine_table_feasibility(machineTable)
```

`report` 至少包含：

```matlab
report.errors
report.warnings
report.checkedOperationCount
report.isFeasible
```

验收标准：

1. 同一机器上真实工序不能时间重叠。
2. `end < start` 被拒绝。
3. 空闲块不参与真实工序冲突判断。
4. 能返回清晰 `report`。

## 16. Step C7：AGV 时间冲突检查

Step C7 验证候选 `AGVTable` 中同一 AGV 上的真实订单运输任务没有时间重叠。

新增函数：

```text
src/cancellation/check_agv_table_feasibility.m
```

检查范围：

1. 只检查 `job > 0` 的真实订单运输任务。
2. 忽略 `job <= 0` 的空闲或充电块。
3. 检查每个真实订单运输任务是否满足 `end >= start`。
4. 检查同一 AGV 上任意两个真实订单运输任务是否时间重叠。

时间重叠规则：

```matlab
current.start < previous.end
```

若上一个真实运输任务的 `end` 等于下一个真实运输任务的 `start`，不视为冲突。

输出约定：

```matlab
[isFeasible, report] = check_agv_table_feasibility(AGVTable)
```

`report` 至少包含：

```matlab
report.errors
report.warnings
report.checkedAgvTaskCount
report.isFeasible
```

验收标准：

1. 同一 AGV 上真实运输任务不能时间重叠。
2. `end < start` 被拒绝。
3. 空闲或充电块不作为订单运输冲突判断。
4. 能返回清晰 `report`。

## 17. Step C8：工件工序顺序检查

Step C8 验证候选 `machineTable` 中剩余工序仍满足同一工件内部顺序。

新增函数：

```text
src/cancellation/check_job_operation_sequence.m
```

检查范围：

1. 只检查 `job > 0` 的真实机器工序。
2. 按同一 `job_id` 聚合工序。
3. 同一工件内 `operation_id` 必须唯一，并且按工序编号形成严格顺序。
4. 后序工序的 `start` 不能早于前序工序的 `end`。
5. 后序工序的 `end` 不能早于前序工序的 `end`。
6. 被取消订单已经删除的未完成工序不要求重新出现。
7. 被取消订单已完成历史工序若仍在表中，则参与其自身剩余历史顺序检查。

输出约定：

```matlab
[isFeasible, report] = check_job_operation_sequence(problem, machineTable, cancel)
```

`report` 至少包含：

```matlab
report.errors
report.warnings
report.checkedOperationCount
report.isFeasible
```

验收标准：

1. 未取消订单的工序编号顺序不逆序。
2. 同一工件后序工序不能早于前序工序完成。
3. 被取消订单已删除的未完成工序不参与后续顺序约束。
4. 已完成历史工序保留。

## 18. Step C9：实现局部修复候选生成

Step C9 组合 Step C3 到 Step C8，生成第一版局部修复候选。

新增函数：

```text
src/cancellation/build_local_repair_candidate.m
```

执行顺序：

1. 调用 `remove_cancelled_machine_operations` 删除被取消订单尚未开工机器工序。
2. 调用 `remove_cancelled_agv_tasks` 删除被取消订单尚未执行 AGV 运输任务。
3. 调用 `check_machine_table_feasibility` 检查机器时间冲突。
4. 调用 `check_agv_table_feasibility` 检查 AGV 时间冲突。
5. 调用 `check_job_operation_sequence` 检查工件工序顺序。
6. 汇总检查结果到 `candidate.report`。
7. 输出 `candidate.isFeasible`。

拒绝条件：

1. `state.has_unsupported_operations == true`。
2. `state.has_unsupported_agv_tasks == true`。
3. `cancel.policy` 不是 `cancel_unstarted_operations_only`。
4. 删除步骤或可行性检查返回错误。

输出约定：

```matlab
candidate.machineTable
candidate.AGVTable
candidate.removed_operations
candidate.removed_agv_tasks
candidate.isFeasible
candidate.report
```

`candidate.report` 必须包含：

```matlab
candidate.report.machineConflictCheck
candidate.report.agvConflictCheck
candidate.report.jobSequenceCheck
```

验收标准：

1. 能拒绝 unsupported 状态。
2. 能删除取消订单未完成机器工序。
3. 能删除取消订单未完成 AGV 任务。
4. 能运行机器冲突、AGV 冲突、工序顺序检查。
5. 输出 `candidate.isFeasible`。
6. 不调用 NSGA-II。
7. 不计算最终评价指标。

## 19. Step C10：局部修复烟雾测试

Step C10 用最小构造数据验证 Step C9 的局部修复候选生成。

新增测试：

```text
tests/test_order_cancellation_local_repair.m
```

测试内容：

1. 正常删除一个未开工取消工序。
2. 正常删除一个未执行取消 AGV 任务。
3. 已完成取消任务保留。
4. 正在加工或正在运输的取消任务被拒绝。
5. 机器时间冲突被拒绝。
6. AGV 时间冲突被拒绝。
7. 工序顺序错误被拒绝。

验收标准：

1. 不跑 NSGA-II。
2. 不写 `outputs/`。
3. 不启动完整实验。
4. 只用最小构造数据。

## 20. Step C11：样例数据局部修复 smoke 脚本

Step C11 在 Step B8 的样例状态基础上执行删除式局部修复 smoke。

新增脚本：

```text
scripts/run_order_cancellation_local_repair_smoke.m
```

运行入口：

```matlab
run('scripts/run_order_cancellation_local_repair_smoke.m')
```

脚本流程：

1. 从 `data_sample/Mk01.fjs` 读取样例问题。
2. 构造与 B8 一致的最小正常 `schedule`。
3. 创建 `cancel`。
4. 调用 `extract_cancellation_state` 提取状态。
5. 调用 `build_local_repair_candidate` 生成删除式局部修复候选。
6. 打印删除数量和可行性统计。

输出统计至少包含：

```matlab
removed_operations
removed_agv_tasks
candidate.isFeasible
machineConflictCheck.isFeasible
agvConflictCheck.isFeasible
jobSequenceCheck.isFeasible
```

验收标准：

1. 能生成一个 `cancel`。
2. 能提取状态。
3. 能构造局部修复候选。
4. 能打印删除数量和可行性。
5. 不做完全重调度。
6. 不调用 NSGA-II。

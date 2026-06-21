# 阶段 C 工作记录：局部修复候选方案

本文档记录阶段 C 的目标、步骤、产物、验证结果和完成标志。阶段 C 第一版只做删除式局部修复，不做完全重调度，不调用 NSGA-II，不计算最终评价指标。

## 1. 阶段目标

阶段 C 的目标是：

```text
删除取消订单未完成任务，并构造可行的局部修复计划。
```

阶段 C 完成标志：

```text
已经能删除被取消订单的未完成机器工序和 AGV 运输任务，
并能验证剩余候选计划没有机器/AGV 时间冲突且满足工件工序顺序。
```

## 2. 第一版策略

第一版采用：

```text
删除式局部修复
```

含义：

1. 只删除被取消订单尚未开工的机器工序。
2. 只删除被取消订单尚未执行的 AGV 运输任务。
3. 已完成的机器工序和 AGV 任务保留为历史。
4. 正在加工或正在运输的取消任务不处理中断，直接标记为不支持并拒绝修复。
5. 删除后不左移、不压缩空闲块、不重排、不重新分配机器或 AGV。
6. 不调用 NSGA-II，不做完全重调度。

## 3. 输入与输出

局部修复输入：

```matlab
problem
schedule.machineTable
schedule.AGVTable
state
cancel
```

局部修复输出：

```matlab
candidate.machineTable
candidate.AGVTable
candidate.removed_operations
candidate.removed_agv_tasks
candidate.isFeasible
candidate.report
```

候选检查报告：

```matlab
candidate.report.machineConflictCheck
candidate.report.agvConflictCheck
candidate.report.jobSequenceCheck
```

## 4. 阶段 C 步骤记录

### Step C1：确认阶段 C 输入契约

新增并维护：

```text
docs/00_system_overview/stage_c_local_repair_contract.md
```

确认内容：

1. 局部修复只接收阶段 B 的状态结果和原正常调度计划。
2. 第一版只处理 `cancel_unstarted_operations_only`。
3. `state.has_unsupported_operations == true` 时拒绝局部修复。
4. `state.has_unsupported_agv_tasks == true` 时拒绝局部修复。
5. 不重新搜索，不调用 NSGA-II。

### Step C2：定义局部修复输出结构

在契约文档中定义 `candidate` 输出结构：

```matlab
candidate.machineTable
candidate.AGVTable
candidate.removed_operations
candidate.removed_agv_tasks
candidate.isFeasible
candidate.report
```

该结构可以记录删除了哪些工序、删除了哪些 AGV 任务，以及为什么不可行。

### Step C3：删除取消订单未完成机器工序

新增：

```text
src/cancellation/remove_cancelled_machine_operations.m
tests/test_order_cancellation_machine_removal.m
```

实现内容：

1. 只删除 `status == 'unstarted'` 且 `job_id == cancel.job_id` 的机器工序。
2. 已完成取消工序保留。
3. 正在加工取消工序拒绝修复。
4. 不移动其他机器工序时间。

### Step C4：删除取消订单未完成 AGV 运输任务

新增：

```text
src/cancellation/remove_cancelled_agv_tasks.m
tests/test_order_cancellation_agv_removal.m
```

实现内容：

1. 只删除 `status == 'unstarted'` 且 `job_id == cancel.job_id` 的 AGV 任务。
2. 已完成取消运输任务保留。
3. 正在运输取消任务拒绝修复。
4. 不移动其他 AGV 任务时间。

### Step C5：压缩或保留空闲块策略说明

在契约文档中明确：

```text
第一版不左移，只删除取消任务，保留其他任务原时间。
```

原因：

1. 最容易验证。
2. 删除任务不会引入新的机器或 AGV 时间冲突。
3. 可以把任务删除和计划优化分开，避免阶段 C 过早变成完全重调度。

### Step C6：机器时间冲突检查

新增：

```text
src/cancellation/check_machine_table_feasibility.m
tests/test_order_cancellation_machine_feasibility.m
```

检查内容：

1. 同一机器上真实工序不能时间重叠。
2. `end < start` 被拒绝。
3. 空闲块不参与真实工序冲突判断。
4. 返回清晰 `report`。

### Step C7：AGV 时间冲突检查

新增：

```text
src/cancellation/check_agv_table_feasibility.m
tests/test_order_cancellation_agv_feasibility.m
```

检查内容：

1. 同一 AGV 上真实运输任务不能时间重叠。
2. `end < start` 被拒绝。
3. 空闲或充电块不作为订单运输冲突判断。
4. 返回清晰 `report`。

### Step C8：工件工序顺序检查

新增：

```text
src/cancellation/check_job_operation_sequence.m
tests/test_order_cancellation_job_sequence.m
```

检查内容：

1. 未取消订单的工序编号顺序不逆序。
2. 同一工件后序工序不能早于前序工序完成。
3. 被取消订单已删除的未完成工序不参与后续顺序约束。
4. 已完成历史工序保留。

### Step C9：实现局部修复候选生成

新增：

```text
src/cancellation/build_local_repair_candidate.m
tests/test_order_cancellation_local_repair_candidate.m
```

组合流程：

1. 删除取消订单未完成机器工序。
2. 删除取消订单未完成 AGV 任务。
3. 运行机器冲突检查。
4. 运行 AGV 冲突检查。
5. 运行工件工序顺序检查。
6. 输出 `candidate.isFeasible`。

### Step C10：局部修复烟雾测试

新增：

```text
tests/test_order_cancellation_local_repair.m
```

测试内容：

1. 正常删除一个未开工取消工序。
2. 正常删除一个未执行取消 AGV 任务。
3. 已完成取消任务保留。
4. 正在加工或正在运输取消任务被拒绝。
5. 机器时间冲突被拒绝。
6. AGV 时间冲突被拒绝。
7. 工序顺序错误被拒绝。

### Step C11：样例数据局部修复 smoke 脚本

新增：

```text
scripts/run_order_cancellation_local_repair_smoke.m
```

运行入口：

```matlab
run('scripts/run_order_cancellation_local_repair_smoke.m')
```

脚本特点：

1. 从 `data_sample/Mk01.fjs` 读取样例问题。
2. 构造与阶段 B smoke 一致的最小正常 `schedule`。
3. 创建 `cancel`。
4. 提取状态。
5. 构造局部修复候选。
6. 打印删除数量和可行性。
7. 不做完全重调度，不调用 NSGA-II。

### Step C12：阶段 C 静态验收

静态验收结果：

1. `build_local_repair_candidate.m` 已存在。
2. 机器冲突检查已存在。
3. AGV 冲突检查已存在。
4. 工件工序顺序检查已存在。
5. 局部修复测试已存在。
6. 没有完全重调度代码。
7. 没有评价权重 `Y` 选择逻辑。
8. 没有正式实验。
9. `raw_code/` 无修改。

## 5. MATLAB 运行结果记录

已运行：

```matlab
run('scripts/run_order_cancellation_local_repair_smoke.m')
```

输出结果：

```text
order cancellation local repair smoke
dataset: data_sample/Mk01.fjs
cancel.job_id: 2
cancel.cancel_time: 10.000000
cancel.policy: cancel_unstarted_operations_only
cancelled_unfinished_operations: 1
cancelled_unfinished_agv_tasks: 1
unsupported_operations: 0
unsupported_agv_tasks: 0
removed_operations: 1
removed_agv_tasks: 1
candidate.isFeasible: 1
machineConflictCheck.isFeasible: 1
agvConflictCheck.isFeasible: 1
jobSequenceCheck.isFeasible: 1
error_count: 0
rejected_reason_count: 0
```

结果说明：

1. 成功生成取消事件。
2. 成功提取取消时刻状态。
3. 成功删除 1 个被取消订单未完成机器工序。
4. 成功删除 1 个被取消订单未完成 AGV 运输任务。
5. 候选局部修复方案可行。
6. 机器冲突检查通过。
7. AGV 冲突检查通过。
8. 工件工序顺序检查通过。
9. 无错误，无拒绝原因。

## 6. 阶段 C 完成标志

阶段 C 已完成：

```text
已经能删除被取消订单的未完成机器工序和 AGV 运输任务，
并能验证剩余候选计划没有机器/AGV 时间冲突且满足工件工序顺序。
```

后续可以进入阶段 D：

```text
完全重调度候选方案。
```

阶段 D 应与阶段 C 保持分离。阶段 C 的删除式局部修复候选不应被改造成 NSGA-II 搜索入口。

## 7. 已整合的原拆分文档

原 `stage_c_local_repair_contract.md` 中仍有价值的内容已经整合到本文档：

1. 输入契约：局部修复只接收 `problem`、原 `machineTable`、原 `AGVTable`、阶段 B 的 `state` 和 `cancel`。
2. 支持策略：第一版只支持 `cancel_unstarted_operations_only`。
3. 拒绝条件：存在正在加工的取消相关工序、正在运输的取消相关 AGV 任务，或 `state` 标记 unsupported 时拒绝修复。
4. 输出结构：`candidate.machineTable`、`candidate.AGVTable`、`removed_operations`、`removed_agv_tasks`、`isFeasible` 和 `report`。
5. 删除规则：只删除被取消订单中尚未开工的机器工序和尚未执行的 AGV 任务；已完成历史任务保留。
6. 空闲块策略：第一版不左移剩余任务，不改变未取消订单的原开始/结束时间。
7. 可行性检查：机器时间冲突、AGV 时间冲突、工件工序顺序均必须检查并写入 report。
8. 阶段边界：阶段 C 不计算 `Y`，不比较局部修复和完全重调度，不启动正式实验。

因此，阶段 C 的主阅读入口只保留本文档；`stage_c_local_repair_contract.md` 可作为历史过程记录。

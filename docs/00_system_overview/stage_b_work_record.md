# 阶段 B 工作记录：订单取消事件与状态提取

本文档记录阶段 B 的目标、步骤、产物、验证结果和进入阶段 C 的条件。阶段 B 只处理订单取消事件定义与 `cancel_time` 时刻状态提取，不做局部修复、完全重调度或正式实验。

## 1. 阶段目标

阶段 B 的目标是：

1. 定义最小订单取消事件。
2. 校验取消事件是否合法。
3. 明确工序和 AGV 运输任务在取消时刻的状态分类规则。
4. 从正常调度计划中提取 `cancel_time` 时刻的机器工序状态和 AGV 运输任务状态。
5. 用轻量测试和 smoke 脚本验证核心分类逻辑。

第一版策略为：

```text
cancel_unstarted_operations_only
```

该策略只允许删除被取消订单中尚未开工的机器工序和尚未执行的 AGV 运输任务。正在加工或正在运输的被取消任务在第一版中标记为不支持。

## 2. 输入与输出

阶段 B 的主要输入：

```matlab
problem
schedule.machineTable
schedule.AGVTable
cancel
```

`cancel` 结构字段：

```matlab
cancel.job_id
cancel.cancel_time
cancel.policy
```

状态提取输出字段：

```matlab
state.completed_operations
state.processing_operations
state.unstarted_operations
state.cancelled_unfinished_operations
state.remaining_unfinished_operations
state.unsupported_operations
state.completed_agv_tasks
state.processing_agv_tasks
state.unstarted_agv_tasks
state.cancelled_unfinished_agv_tasks
state.unsupported_agv_tasks
```

## 3. 状态分类规则

设 `t = cancel.cancel_time`。

机器工序和 AGV 运输任务共用同一时间分类规则：

| 状态 | 判定条件 | 第一版含义 |
|---|---|---|
| 已完成 | `end <= t` | 保留为历史，不删除 |
| 正在执行 | `start < t && t < end` | 若属于被取消订单，则标记为不支持 |
| 尚未执行 | `start >= t` | 若属于被取消订单，则列入取消任务 |

边界条件：

1. `cancel_time == end`：视为已完成。
2. `cancel_time == start`：视为尚未执行。
3. 只有 `start < cancel_time < end` 才视为正在执行。

详细规则见：

```text
docs/00_system_overview/order_cancellation_state_contract.md
```

## 4. 阶段 B 步骤记录

### Step B1：确认输入依赖

确认状态提取依赖正常调度结果：

```matlab
problem
schedule.machineTable
schedule.AGVTable
schedule.jobCompleteUnLoad
cancel
```

阶段 B 不生成新调度，不修改 `machineTable` 或 `AGVTable`。

### Step B2：定义订单取消事件结构

新增：

```text
src/cancellation/create_order_cancellation_event.m
```

作用：

1. 创建 `cancel.job_id`。
2. 创建 `cancel.cancel_time`。
3. 创建 `cancel.policy`。
4. 默认策略为 `cancel_unstarted_operations_only`。

### Step B3：校验订单取消事件

新增：

```text
src/cancellation/validate_order_cancellation_event.m
tests/test_order_cancellation_event.m
```

校验内容：

1. `job_id` 必须是有效工件编号。
2. `cancel_time` 必须是非负有限数。
3. `policy` 必须是支持的策略。

### Step B4：定义状态分类规则

新增：

```text
docs/00_system_overview/order_cancellation_state_contract.md
```

文档明确了已完成、正在执行、尚未执行三类状态，以及 `cancel_time == start` 和 `cancel_time == end` 的边界语义。

### Step B5：实现机器工序状态提取

新增：

```text
src/cancellation/extract_cancellation_state.m
tests/test_order_cancellation_state.m
```

实现内容：

1. 从 `schedule.machineTable` 中读取真实工序。
2. 忽略 `job <= 0` 的空闲块。
3. 将工序分为已完成、正在加工、尚未开工。
4. 单独列出被取消订单的未完成工序。
5. 单独列出未取消订单的剩余未完成工序。
6. 将被取消订单中正在加工的工序标记为不支持。

### Step B6：提取 AGV 任务状态

扩展：

```text
src/cancellation/extract_cancellation_state.m
tests/test_order_cancellation_state.m
```

实现内容：

1. 从 `schedule.AGVTable` 中读取真实运输任务。
2. 忽略 `job <= 0` 的空闲或充电块。
3. 将 AGV 任务分为已完成、正在运输、尚未执行。
4. 单独列出被取消订单的未完成 AGV 任务。
5. 将被取消订单中正在运输的任务标记为不支持。

### Step B7：写烟雾测试

测试入口：

```matlab
run('tests/test_order_cancellation_event.m')
run('tests/test_order_cancellation_state.m')
```

测试特点：

1. 使用最小构造数据。
2. 不依赖完整 NSGA-II。
3. 不写 `outputs/`。
4. 覆盖事件校验、机器工序分类、AGV 任务分类和 unsupported 标记。

### Step B8：样例数据 smoke 脚本

新增：

```text
scripts/run_order_cancellation_state_smoke.m
```

运行入口：

```matlab
run('scripts/run_order_cancellation_state_smoke.m')
```

脚本特点：

1. 从 `data_sample/Mk01.fjs` 读取样例问题。
2. 构造一个最小正常 `schedule`。
3. 生成一个合法 `cancel`。
4. 输出状态统计。
5. 不启动 NSGA-II。
6. 不做局部修复。
7. 不做完全重调度。
8. 不写 `outputs/`。

### Step B9：阶段 B 静态验收

验收结果：

1. `src/cancellation/` 已新增，且只包含事件与状态提取。
2. `tests/` 已有事件测试和状态测试。
3. 文档已说明状态分类规则。
4. 没有局部修复代码。
5. 没有完全重调度代码。
6. 没有新增正式实验。
7. `raw_code/` 没有修改。

## 5. MATLAB 运行结果记录

已运行：

```matlab
run('scripts/run_order_cancellation_state_smoke.m')
```

输出结果：

```text
order cancellation state smoke
dataset: data_sample/Mk01.fjs
cancel.job_id: 2
cancel.cancel_time: 10.000000
cancel.policy: cancel_unstarted_operations_only
operation_count: 6
completed_operations: 3
processing_operations: 2
unstarted_operations: 1
cancelled_unfinished_operations: 1
remaining_unfinished_operations: 2
unsupported_operations: 0
agv_task_count: 5
completed_agv_tasks: 3
processing_agv_tasks: 1
unstarted_agv_tasks: 1
cancelled_unfinished_agv_tasks: 1
unsupported_agv_tasks: 0
```

结果说明：

1. 成功读取样例数据 `data_sample/Mk01.fjs`。
2. 成功生成取消事件：取消 `job_id = 2`，取消时刻为 `10`。
3. 成功提取机器工序状态和 AGV 运输任务状态。
4. `unsupported_operations = 0`。
5. `unsupported_agv_tasks = 0`。

因此，该样例取消场景可以进入阶段 C 的删除式局部修复。

## 6. 阶段 B 完成标志

阶段 B 已完成：

```text
已经能定义订单取消事件，并从正常调度计划中提取 cancel_time 时刻状态。
```

后续可以进入阶段 C：

```text
局部修复候选方案。
```

阶段 C 的第一版应继续保持删除式局部修复：只删除被取消订单中尚未开工的机器工序和尚未执行的 AGV 运输任务，不移动其他任务时间，不调用 NSGA-II。

## 7. 已整合的原拆分文档

原 `order_cancellation_state_contract.md` 中仍有价值的内容已经整合到本文档：

1. 适用范围：阶段 B 只定义单订单取消事件和取消时刻状态提取。
2. 状态分类规则：`end <= cancel_time` 为已完成，`start < cancel_time < end` 为正在加工或运输，`start >= cancel_time` 为尚未开工或尚未执行。
3. 边界条件：`cancel_time == start` 归入尚未开工，`cancel_time == end` 归入已完成。
4. 被取消订单处理：已完成任务保留为历史，正在加工或运输第一版标记为 unsupported，尚未开工或尚未执行任务列入取消列表。
5. 后续复用方式：阶段 C 使用取消列表做删除式局部修复，阶段 D 使用完成前缀和剩余任务集做完全重调度。

因此，阶段 B 的主阅读入口只保留本文档；`order_cancellation_state_contract.md` 可作为历史过程记录。

## 16. 支持文档入口

README 只挂阶段 B 主文档；阶段 B 的状态分类契约可从这里进入：

| 文档 | 用途 |
|---|---|
| [订单取消状态分类契约](order_cancellation_state_contract.md) | 阶段 B 早期用于定义 completed / processing / unstarted、unsupported 和边界条件的契约文档 |

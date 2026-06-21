# 阶段 J 项目报告：订单变更统一框架

本文档是阶段 J 的主入口。阶段 J 的目标是把订单取消和新订单插入统一建模为任务集合变化，为后续更灵活的订单变更调度做准备。

阶段 J 不重写调度算法，不直接实现完整插单解码，也不加入机器故障、AGV 故障或强化学习。

## 1. Step J1：阶段 J 范围确认

Step J1 的目标是明确阶段 J 只做统一事件框架，不重写已有调度主线。

阶段 J 的核心范围：

- 订单取消继续复用阶段 B-I 已有链路。
- 新订单插入只预留事件结构和接口。
- 不实现完整插单解码。
- 不加入机器故障。
- 不加入 AGV 故障。
- 不加入强化学习。
- 不破坏已有订单取消测试。

阶段 J 的定位不是另起一套取消算法，而是在已有订单取消闭环之上抽象统一事件层：

```text
schedule_change_event
  -> cancel_order
  -> insert_order
```

其中 `cancel_order` 对应已经完成的订单取消链路，`insert_order` 只在阶段 J 预留结构。若插单需要大幅修改 `problem` 数据结构，阶段 J 停止在事件接口设计，不进入插单解码实现。

## 2. Step J1 验收结果

| 验收项 | 结果 |
|---|---|
| 订单取消继续复用阶段 B-I 已有链路 | 通过，阶段 J 不替换现有取消链路 |
| 新订单插入只预留事件结构和接口 | 通过，阶段 J 暂不实现完整插单调度 |
| 不实现完整插单解码 | 通过 |
| 不加入机器故障、AGV 故障、强化学习 | 通过 |
| 不破坏已有订单取消测试 | 通过，Step J1 只新增文档，不修改算法和测试 |

Step J1 完成标志：阶段 J 的边界已经固定。后续可以进入 Step J2：定义统一订单变更事件结构。

## 3. Step J2：定义统一订单变更事件结构

Step J2 新增统一事件创建函数：

```text
src/events/create_schedule_change_event.m
```

统一事件结构为：

```matlab
event.event_id
event.event_type
event.event_time
event.policy
event.payload
```

当前支持的 `event_type`：

```text
cancel_order
insert_order
```

`cancel_order` 用于表达现有订单取消事件。现有取消事件：

```matlab
cancel.job_id
cancel.cancel_time
cancel.policy
```

可以映射为：

```matlab
payload = struct();
payload.job_id = cancel.job_id;

event = create_schedule_change_event( ...
    eventId, ...
    'cancel_order', ...
    cancel.cancel_time, ...
    cancel.policy, ...
    payload);
```

其中：

- `event.event_type = 'cancel_order'`
- `event.event_time = cancel.cancel_time`
- `event.policy = cancel.policy`
- `event.payload.job_id = cancel.job_id`

`insert_order` 只作为接口预留，不要求完整调度。建议后续插单事件使用：

```matlab
payload = struct();
payload.new_job = newJob;

event = create_schedule_change_event( ...
    eventId, ...
    'insert_order', ...
    insertTime, ...
    'insert_order_interface_only', ...
    payload);
```

阶段 J2 只保证事件结构可表达插单意图，不修改 `problem` 数据结构，不实现插单解码。

## 4. Step J2 验收结果

| 验收项 | 结果 |
|---|---|
| `cancel_order` 能表达现有订单取消事件 | 通过，`payload.job_id` 保存被取消订单，`event_time` 对应 `cancel_time` |
| `insert_order` 有预留字段，但不要求完整调度 | 通过，`payload.new_job` 可作为后续插单信息入口 |
| `event_time` 非负 | 通过，`create_schedule_change_event.m` 对负数 `eventTime` 报错 |
| `policy` 可追踪 | 通过，统一事件保留 `event.policy` 字段 |
| `payload` 保存不同事件类型的专属信息 | 通过，取消使用 `payload.job_id`，插单预留 `payload.new_job` |

Step J2 完成标志：统一订单变更事件结构已经建立。后续可以进入 Step J3：把现有订单取消事件映射到统一结构。

## 5. Step J3：映射订单取消事件到统一结构

Step J3 新增两个适配函数：

```text
src/events/order_cancellation_to_schedule_change_event.m
src/events/schedule_change_event_to_order_cancellation.m
```

现有订单取消事件结构为：

```matlab
cancel.job_id
cancel.cancel_time
cancel.policy
```

映射到统一事件结构后为：

```matlab
event.event_type = 'cancel_order'
event.event_time = cancel.cancel_time
event.policy = cancel.policy
event.payload.job_id = cancel.job_id
```

使用方式：

```matlab
event = order_cancellation_to_schedule_change_event(cancel, eventId);
```

为了不大改阶段 B-I，统一事件也可以恢复成原来的 `cancel`：

```matlab
cancel = schedule_change_event_to_order_cancellation(event);
```

恢复后的结构仍是：

```matlab
cancel.job_id
cancel.cancel_time
cancel.policy
```

这意味着阶段 J 的统一事件层可以放在上层，阶段 B-I 的状态提取、局部修复、完全重调度、评价、混合策略和连续取消逻辑仍可继续使用原来的 `cancel` 输入。

## 6. Step J3 验收结果

| 验收项 | 结果 |
|---|---|
| 现有订单取消逻辑仍可从统一事件恢复 `cancel` | 通过，`schedule_change_event_to_order_cancellation.m` 可恢复 `job_id`、`cancel_time` 和 `policy` |
| 阶段 B-I 不需要大改 | 通过，新增的是上层适配函数，未修改阶段 B-I 主流程 |
| 原有取消测试不回退 | 通过，Step J3 未修改订单取消算法逻辑；后续 Step J8 再补统一事件接口测试 |

Step J3 完成标志：现有订单取消事件已经可以映射为统一 `cancel_order` 事件，也可以从统一事件恢复为阶段 B-I 使用的旧 `cancel` 结构。后续可以进入 Step J4：预留新订单插入事件结构。

## 7. Step J4：预留新订单插入事件结构

Step J4 新增插单事件接口：

```text
src/events/insert_order_to_schedule_change_event.m
```

该函数只创建统一事件，不修改 `problem`，不生成新调度，也不实现完整插单算法。

插单统一事件结构为：

```matlab
event.event_type = 'insert_order'
event.event_time = insertTime
event.policy = policy
event.payload.new_job = newJob
```

第一版预留的 `new_job` 字段：

```matlab
new_job.job_id
new_job.operations
new_job.processing_times
new_job.machine_options
new_job.due_date
```

使用方式：

```matlab
event = insert_order_to_schedule_change_event(newJob, insertTime, eventId);
```

默认 `policy` 为：

```text
insert_order_interface_only
```

这表示阶段 J 只承认“发生了一个插单事件”，并保留后续插单算法所需的最小信息。真正把 `new_job` 合并进 `problem`、更新编码长度、更新解码约束、处理新工件运输任务和重新评价候选计划，需要后续阶段单独完成。

插单与取消的主要差异：

- 订单取消是从未完成任务集合中删除任务。
- 新订单插入是向任务集合中增加新工件。
- 插单通常需要扩展 `problem` 数据结构，包括工件数、工序数、可选机器、加工时间和可能的交期字段。
- 插单还可能影响编码长度、初始化种群、解码器和评价函数，因此阶段 J 不进入完整插单解码实现。

## 8. Step J4 验收结果

| 验收项 | 结果 |
|---|---|
| 能创建 `insert_order` 事件 | 通过，`insert_order_to_schedule_change_event.m` 创建 `event_type = 'insert_order'` |
| 能校验基本字段 | 通过，函数检查 `new_job.job_id`、`operations`、`processing_times`、`machine_options` 和 `due_date` |
| 文档说明插单需要扩展 `problem` | 通过，本节说明插单会影响问题结构、编码和解码 |
| 阶段 J 暂不进入解码实现 | 通过，函数只创建事件，不修改 `problem`，不生成调度 |
| 不影响订单取消主线 | 通过，新增函数位于 `src/events/`，未修改阶段 B-I 取消链路 |

Step J4 完成标志：新订单插入已经有统一事件接口预留，但完整插单算法仍未展开。后续可以进入 Step J5：实现统一事件校验函数。

## 9. Step J5：实现统一事件校验函数

Step J5 新增统一事件校验函数：

```text
src/events/validate_schedule_change_event.m
```

函数入口：

```matlab
[isValid, report] = validate_schedule_change_event(event, problem)
```

校验内容：

- `event.event_type` 必须是支持类型：`cancel_order` 或 `insert_order`。
- `event.event_time` 必须是非负有限数值。
- `cancel_order` 必须包含 `event.payload.job_id`。
- 若传入 `problem.jobNum`，`cancel_order` 的 `job_id` 必须在合法工件编号范围内。
- `insert_order` 必须包含 `event.payload.new_job`。
- `insert_order` 的 `new_job` 必须包含第一版预留基础字段。

`insert_order` 的校验状态：

```matlab
report.status = 'pending'
report.isPending = true
```

这表示插单事件的接口字段是合法的，但完整插单调度算法尚未实现。阶段 J 不把 `insert_order` 送入解码、搜索或评价流程。

## 10. Step J5 验收结果

| 验收项 | 结果 |
|---|---|
| 合法 `cancel_order` 通过 | 通过，校验 `event_type`、`event_time` 和 `payload.job_id` |
| 非法 `event_type` 被拒绝 | 通过，不属于 `cancel_order` / `insert_order` 会写入 `report.errors` |
| 非法 `event_time` 被拒绝 | 通过，负数、非数值或非有限值会写入 `report.errors` |
| 缺少 `job_id` 的取消事件被拒绝 | 通过，`cancel_order` 必须有 `event.payload.job_id` |
| 插单事件能通过接口层校验 | 通过，`insert_order` 检查 `payload.new_job` 和基础字段 |
| 插单事件标记为未进入完整算法 | 通过，合法 `insert_order` 返回 `report.status = 'pending'` 和 `report.isPending = true` |

Step J5 完成标志：统一事件校验层已经建立。后续可以进入 Step J6：定义统一状态变化语义。

## 11. Step J6：定义统一状态变化语义

Step J6 的目标是把订单变更统一解释为任务集合变化。

订单取消语义：

```text
task_set_after = task_set_before - cancelled_unfinished_tasks
```

含义：取消事件发生后，被取消订单中尚未完成的机器工序和 AGV 运输任务从后续候选计划中删除；已完成历史任务保留。

新订单插入语义：

```text
task_set_after = task_set_before + new_job_tasks
```

含义：插单事件发生后，新工件的工序、可选机器、加工时间和相关运输任务需要加入后续候选计划。阶段 J 只定义这个语义，不实现插单解码。

取消和插单的共同点：

- 都发生在某个事件时间 `event.event_time`。
- 都需要冻结事件时间前已经完成的机器工序和 AGV 任务。
- 都需要提取事件时刻的调度状态。
- 都需要基于变更后的任务集合生成候选计划。
- 都需要评价候选结果。

取消和插单的差异：

| 维度 | 订单取消 | 新订单插入 |
|---|---|---|
| 任务集合变化 | 删除未完成任务 | 增加新工件任务 |
| 对 `problem` 的影响 | 通常不需要扩展原始问题结构 | 可能需要扩展工件数、工序数、加工时间和可选机器 |
| 对编码的影响 | 可排除取消任务或冻结历史任务 | 可能需要增加编码长度和初始化规则 |
| 对解码的影响 | 可复用现有删除式修复和重调度框架 | 需要处理新工件工序顺序、机器可选集和 AGV 运输 |
| 对约束的影响 | 主要检查剩余任务不冲突、不回流 | 更容易引入机器、AGV 和工序约束扩展 |

阶段 J 的统一语义边界：

- `cancel_order` 可以接入现有阶段 B-I 订单取消链路。
- `insert_order` 只预留事件、payload 和 pending 状态。
- 插单若需要修改 `problem`、编码、解码或搜索流程，必须进入后续阶段单独设计。

## 12. Step J6 验收结果

| 验收项 | 结果 |
|---|---|
| 文档说明订单取消是任务集合删除 | 通过，定义 `task_set_after = task_set_before - cancelled_unfinished_tasks` |
| 文档说明新订单插入是任务集合增加 | 通过，定义 `task_set_after = task_set_before + new_job_tasks` |
| 文档说明共同点 | 通过，覆盖事件时间、冻结任务、状态提取、候选生成和评价 |
| 文档说明差异 | 通过，覆盖任务变化方向、`problem`、编码、解码和约束影响 |
| 不进入插单解码实现 | 通过，Step J6 只更新文档，不修改算法代码 |

Step J6 完成标志：订单变更已被统一定义为任务集合变化。后续可以进入 Step J7：写阶段 J 统一框架文档整理。

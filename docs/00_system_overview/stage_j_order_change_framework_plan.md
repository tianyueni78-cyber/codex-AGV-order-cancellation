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

# 阶段 I 项目报告：多订单连续取消

本文档是阶段 I 的唯一主入口。阶段 I 目标是支持多个订单按时间顺序连续取消，验证状态回放、重复修复、重复重调度和已取消订单不回流能力。

阶段 I 不加入机器故障、新订单插入、连续加工抢占或强化学习。

## 1. 阶段 I 目标

阶段 I 的目标是：

```text
支持多个订单按 cancel_time 顺序连续取消，
每次取消后以上一次最终选择计划作为新基线，
验证阶段 B-H 链路能否重复运行。
```

阶段 I 不是重新设计调度器，而是在已有链路上做连续事件回放：

- 阶段 B：提取当前取消时刻状态。
- 阶段 C：生成局部修复候选。
- 阶段 D：生成完全重调度候选。
- 阶段 E：评价两个候选。
- 阶段 H：使用混合策略选择最终计划。
- 阶段 I：把上一轮最终计划作为下一轮新基线，继续处理下一个取消事件。

## 2. Step I1：输入契约

连续取消主函数建议输入：

```matlab
problem
machineData
agvData
initialSchedule
cancelEvents
config
```

建议主函数后续命名为：

```matlab
result = run_sequential_order_cancellations( ...
    problem, machineData, agvData, initialSchedule, cancelEvents, config)
```

## 3. 输入字段说明

| 输入 | 含义 | 阶段 I 用途 |
|---|---|---|
| `problem` | FJSP-AGV 问题实例 | 提供工件、工序、机器和基础问题信息 |
| `machineData` | 机器距离和能耗等数据 | 传入阶段 D/E，支持重调度和评价 |
| `agvData` | AGV 数量、速度和能耗等数据 | 传入阶段 D/E，支持运输调度和评价 |
| `initialSchedule` | 第一轮取消前的基线计划 | 第一次取消事件的状态提取基线 |
| `cancelEvents` | 多个取消事件列表 | 按 `cancel_time` 排序后逐个处理 |
| `config` | 评价、混合策略和阶段 I 控制配置 | 控制评价权重、混合策略阈值和 unsupported 处理方式 |

第一轮使用 `initialSchedule` 作为基线。

后续轮次使用上一轮最终选择的候选计划作为新基线。

## 4. Step I2：连续取消事件列表结构

`cancelEvents` 用于统一描述多个按时间发生的订单取消事件。每个事件必须包含：

```matlab
cancelEvents(i).event_id
cancelEvents(i).job_id
cancelEvents(i).cancel_time
cancelEvents(i).policy
```

字段含义：

| 字段 | 含义 | 第一版要求 |
|---|---|---|
| `event_id` | 连续取消事件编号 | 用于追踪第几次取消，建议唯一 |
| `job_id` | 被取消订单编号 | 必须是有效工件编号 |
| `cancel_time` | 取消发生时刻 | 必须非负 |
| `policy` | 取消处理策略 | 当前只支持 `cancel_unstarted_operations_only` |

当前第一版只支持：

```text
cancel_unstarted_operations_only
```

也就是只取消尚未开工的工序。若连续取消过程中出现正在加工任务取消，先记录为 `unsupported`，不扩展抢占或中断加工逻辑。

事件列表规则：

1. `cancelEvents` 至少包含 2 个取消事件。
2. 主流程需要按 `cancel_time` 升序处理事件。
3. 如果输入时不是升序，后续实现应在主函数或校验函数中稳定排序。
4. 相同 `job_id` 重复取消应拒绝，或标记为无效事件。
5. `cancel_time` 必须非负。
6. `policy` 当前只允许 `cancel_unstarted_operations_only`。

## 5. 基线更新规则

阶段 I 的关键规则是基线回放：

1. `currentSchedule = initialSchedule`。
2. 按 `cancel_time` 升序处理 `cancelEvents`。
3. 每次事件都基于 `currentSchedule` 提取状态。
4. 每次事件都生成局部修复候选和完全重调度候选。
5. 每次事件都调用阶段 E/H 评价并选择最终策略。
6. 如果本轮选择成功，则 `currentSchedule = decision.selected_candidate`。
7. 下一轮取消事件基于更新后的 `currentSchedule` 继续运行。

因此，后一次取消不是重新回到原始正常调度计划，而是接着前一次订单取消后的最终计划继续处理。

## 6. 边界和不做内容

阶段 I 当前明确不做：

- 机器故障。
- AGV 故障。
- 新订单插入。
- 多扰动混合。
- 强化学习。
- 全局最优证明。
- 正在加工任务取消的抢占或中断加工逻辑。

如果连续事件中出现正在加工工序或正在运输任务取消，第一版只记录为 `unsupported`。

## 7. Step I3：校验连续取消事件

阶段 I 新增连续取消事件校验函数：

```text
src/cancellation/validate_sequential_cancellation_events.m
```

建议调用方式：

```matlab
[isValid, sortedEvents, report] = ...
    validate_sequential_cancellation_events(cancelEvents, problem)
```

校验职责：

- 检查 `cancelEvents` 是结构体数组。
- 检查事件数量至少为 2。
- 检查每个事件包含 `event_id`、`job_id`、`cancel_time` 和 `policy`。
- 复用单事件校验逻辑，拒绝非法 `job_id`、非法 `cancel_time` 和未知 `policy`。
- 按 `cancel_time` 升序稳定排序；相同 `cancel_time` 保留输入顺序。
- 重复取消同一 `job_id` 在第一版中直接拒绝，并在 `report.unsupported_events` 中记录原因。

测试入口：

```matlab
run('tests/test_order_cancellation_sequential_event_validation.m')
```

该测试只验证事件校验和排序逻辑，不写 `outputs/`，不运行完整调度实验。

Step I3 完成时应满足：

- 非法 `job_id` 被拒绝。
- 非法 `cancel_time` 被拒绝。
- 未知 `policy` 被拒绝。
- 重复取消同一订单被拒绝并记录为 unsupported。
- 事件排序稳定可复现。

## 8. Step I1 验收标准

Step I1 完成时应满足：

- 明确连续取消主函数输入包括 `problem`、`machineData`、`agvData`、`initialSchedule`、`cancelEvents` 和 `config`。
- 明确 `cancelEvents` 是多个取消事件。
- 明确每个事件包含 `job_id`、`cancel_time` 和 `policy`。
- 明确第一轮使用 `initialSchedule` 作为基线。
- 明确后续轮次使用上一轮最终选择计划作为新基线。
- 明确阶段 I 不新增机器故障、新订单插入或强化学习。

## 9. Step I2 验收标准

Step I2 完成时应满足：

- 已明确 `cancelEvents(i).event_id`、`job_id`、`cancel_time` 和 `policy` 四个字段。
- 已明确至少支持 2 个连续取消事件。
- 已明确事件按 `cancel_time` 升序处理。
- 已明确相同 `job_id` 重复取消要拒绝或标记为无效。
- 已明确 `cancel_time` 非负。
- 已明确 `policy` 当前只支持 `cancel_unstarted_operations_only`。

## 10. 后续步骤入口

下一步进入 Step I4：实现连续取消主流程函数。

建议重点确认：

- 主流程如何把 `sortedEvents` 逐个送入阶段 B-H。
- 每轮最终计划如何更新为下一轮 `currentSchedule`。
- 每轮结果结构需要记录哪些字段。
- unsupported 后是停止后续事件，还是继续尝试处理后续事件。

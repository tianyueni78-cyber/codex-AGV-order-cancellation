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

## 4. cancelEvents 契约

`cancelEvents` 必须包含多个取消事件。每个事件至少包含：

```matlab
cancelEvents(i).job_id
cancelEvents(i).cancel_time
cancelEvents(i).policy
```

后续实现时建议补充：

```matlab
cancelEvents(i).event_id
```

当前第一版只支持：

```text
cancel_unstarted_operations_only
```

也就是只取消尚未开工的工序。若连续取消过程中出现正在加工任务取消，先记录为 `unsupported`，不扩展抢占或中断加工逻辑。

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

## 7. Step I1 验收标准

Step I1 完成时应满足：

- 明确连续取消主函数输入包括 `problem`、`machineData`、`agvData`、`initialSchedule`、`cancelEvents` 和 `config`。
- 明确 `cancelEvents` 是多个取消事件。
- 明确每个事件包含 `job_id`、`cancel_time` 和 `policy`。
- 明确第一轮使用 `initialSchedule` 作为基线。
- 明确后续轮次使用上一轮最终选择计划作为新基线。
- 明确阶段 I 不新增机器故障、新订单插入或强化学习。

## 8. 后续步骤入口

下一步进入 Step I2：定义连续取消事件列表结构。

建议重点确认：

- 是否给每个事件增加 `event_id`。
- 是否拒绝重复取消同一 `job_id`。
- 是否要求 `cancelEvents` 输入时已经有序，还是在主函数中排序。
- unsupported 后是停止后续事件，还是继续尝试处理后续事件。

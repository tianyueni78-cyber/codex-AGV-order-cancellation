# 阶段 K 项目报告：自适应策略选择

本文档是阶段 K 的主入口。阶段 K 的目标是让订单取消策略选择不只依赖固定权重，而能根据场景特征调整评价权重或选择规则。

阶段 K 第一版采用规则式自适应。数据驱动分类器和强化学习只作为后续创新方向，不作为阶段 K 的必要完成条件。

## 1. Step K1：阶段 K 范围确认

Step K1 的目标是明确阶段 K 只做规则式自适应策略选择。

阶段 K 的核心范围：

- 固定权重策略继续保留为 baseline。
- 阶段 K 不替换阶段 B-J。
- 阶段 K 不重写局部修复候选生成。
- 阶段 K 不重写完全重调度候选生成。
- 阶段 K 不重写评价函数。
- 阶段 K 不训练机器学习模型。
- 阶段 K 不把强化学习作为必要完成条件。

阶段 K 的第一版路线：

```text
场景特征
  -> 规则式权重调整
  -> 使用已有评价和策略选择链路
```

也就是说，阶段 K 只在“评价权重/选择规则”这一层做自适应，不改变底层解码器、搜索器和候选计划构造方式。

## 2. Step K1 验收结果

| 验收项 | 结果 |
|---|---|
| 固定权重策略仍保留为 baseline | 通过，阶段 K 不删除阶段 E/H 的固定权重流程 |
| 阶段 K 不替换阶段 B-J | 通过，阶段 K 只作为策略选择增强层 |
| 不重写局部修复、完全重调度、评价函数 | 通过，Step K1 只确认范围，不修改算法代码 |
| 不训练机器学习模型 | 通过，第一版只做规则式自适应 |
| 不把强化学习作为必要完成条件 | 通过，强化学习只作为后续创新方向 |

Step K1 完成标志：阶段 K 的范围已经固定。后续可以进入 Step K2：定义自适应特征集合。

## 3. Step K2：定义自适应特征集合

Step K2 的目标是定义规则式自适应策略选择需要的场景特征。第一版特征只来自阶段 B-H 已有状态、候选方案和评价前置结果，不额外运行实验，也不依赖 `outputs/`。

建议特征结构：

```matlab
features.cancel_time_ratio
features.remaining_operation_count
features.cancelled_operation_count
features.frozen_operation_ratio
features.remaining_agv_task_count
features.cancelled_agv_task_count
features.local_repair_feasible
features.complete_rescheduling_feasible
features.unsupported_flag
```

特征含义和来源：

| 特征 | 含义 | 主要来源 |
|---|---|---|
| `cancel_time_ratio` | 取消时刻占基线 `Cmax` 的比例 | `cancel.cancel_time` 和基线计划的 `Cmax` |
| `remaining_operation_count` | 取消后仍需处理的剩余机器工序数量 | 阶段 B 的 `state.remaining_unfinished_operations` |
| `cancelled_operation_count` | 被取消订单未完成机器工序数量 | 阶段 B 的 `state.cancelled_unfinished_operations` |
| `frozen_operation_ratio` | 已完成冻结工序占总工序比例 | 阶段 B 的 `state.completed_operations` 和总工序数 |
| `remaining_agv_task_count` | 取消后仍需处理的剩余 AGV 运输任务数量 | 阶段 B 的 AGV 状态或候选计划中的剩余运输任务 |
| `cancelled_agv_task_count` | 被取消订单未完成 AGV 运输任务数量 | 阶段 B 的 `state.cancelled_unfinished_agv_tasks` |
| `local_repair_feasible` | 局部修复候选是否可行 | 阶段 C 的 `localRepairCandidate.isFeasible` |
| `complete_rescheduling_feasible` | 完全重调度候选是否可行 | 阶段 D 的 `completeReschedulingCandidate.isFeasible` |
| `unsupported_flag` | 是否出现正在加工、正在运输等第一版不支持状态 | 阶段 B 的 unsupported 标记 |

这些特征用于解释权重变化。例如：

- `cancel_time_ratio` 低，表示早期取消，剩余任务多，后续可能更重视 `Cmax_delta` 和能耗。
- `frozen_operation_ratio` 高，表示大量任务已经完成，后续可能更重视扰动指标 `SD` 和 `TD`。
- `local_repair_feasible = false` 时，策略选择应优先考虑完全重调度或直接记录不可行原因。
- `unsupported_flag = true` 时，不应强行进行自适应选择，应保留 unsupported 结果。

## 4. Step K2 验收结果

| 验收项 | 结果 |
|---|---|
| 每个特征有清楚含义 | 通过，本文档已逐项说明 |
| 特征来自阶段 B-H 已有状态和候选结果 | 通过，来源限定为 `state`、`cancel`、局部修复候选和完全重调度候选 |
| 不额外运行实验 | 通过，Step K2 只定义特征，不运行 MATLAB |
| 不依赖 `outputs/` | 通过，特征从内存中的状态和候选结构提取 |

Step K2 完成标志：阶段 K 的自适应特征集合已经固定。后续可以进入 Step K3：实现特征提取函数。

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

## 5. Step K3：实现特征提取函数

Step K3 新增特征提取函数：

```text
src/cancellation/extract_cancellation_features.m
```

函数入口：

```matlab
features = extract_cancellation_features( ...
    baselineSchedule, ...
    state, ...
    cancel, ...
    localRepairCandidate, ...
    completeReschedulingCandidate)
```

第一版计算口径：

| 特征 | 计算方式 |
|---|---|
| `cancel_time_ratio` | `cancel.cancel_time / baseline_Cmax`，其中 `baseline_Cmax` 来自基线 `machineTable` 真实工序最大结束时间 |
| `remaining_operation_count` | `numel(state.remaining_unfinished_operations)` |
| `cancelled_operation_count` | `numel(state.cancelled_unfinished_operations)` |
| `frozen_operation_ratio` | `numel(state.completed_operations) / state.operation_count` |
| `remaining_agv_task_count` | `state.agv_task_count - completed_agv_tasks - cancelled_unfinished_agv_tasks` |
| `cancelled_agv_task_count` | `numel(state.cancelled_unfinished_agv_tasks)` |
| `local_repair_feasible` | `localRepairCandidate.isFeasible` |
| `complete_rescheduling_feasible` | `completeReschedulingCandidate.isFeasible` |
| `unsupported_flag` | 阶段 B 的 `has_unsupported_operations`、`has_unsupported_agv_tasks` 或 unsupported 列表非空 |

边界约定：

- `baselineSchedule.machineTable` 必须存在，并用于计算基线 `Cmax`。
- 若候选缺少 `isFeasible` 字段，第一版按 `false` 处理。
- 若分母为 0，比例特征按 0 处理，避免在最小构造数据中产生除零错误。
- 函数只提取特征，不修改候选，不重新评价，不写 `outputs/`。

## 6. Step K3 验收结果

| 验收项 | 结果 |
|---|---|
| 能计算取消时刻比例 | 通过，使用 `cancel.cancel_time / baseline_Cmax` |
| 能计算剩余工序数 | 通过，读取 `state.remaining_unfinished_operations` |
| 能计算被取消工序数 | 通过，读取 `state.cancelled_unfinished_operations` |
| 能计算冻结任务比例 | 通过，使用 `completed_operations / operation_count` |
| 能记录两个候选可行性 | 通过，读取局部修复和完全重调度候选的 `isFeasible` |
| unsupported 情况能进入特征 | 通过，输出 `features.unsupported_flag` |

Step K3 完成标志：阶段 K 已具备从阶段 B-H 结构中提取自适应策略特征的函数。后续可以进入 Step K4：定义规则式权重调整策略。

## 7. Step K4：定义规则式权重调整策略

Step K4 的目标是定义第一版规则式自适应权重策略。权重仍然作为 `config.weights` 进入阶段 E/H 的评价和选择流程，不写死在评价函数里。

第一版权重字段：

```matlab
weights.Cmax_delta
weights.SD
weights.TD
weights.energy_delta
```

固定权重 baseline 仍然保留。自适应权重只是在 baseline 之上，根据 `features` 调整权重倾向。

第一版规则：

| 规则 | 触发特征 | 权重倾向 | 解释 |
|---|---|---|---|
| 早期取消 | `cancel_time_ratio` 较低 | 提高 `Cmax_delta` 和 `energy_delta` | 剩余任务较多，完全重调度可能更有价值，优先关注完工时间和能耗改善 |
| 中期取消 | `cancel_time_ratio` 居中 | 平衡 `Cmax_delta`、`SD`、`TD`、`energy_delta` | 剩余任务和已完成任务都较多，需要兼顾效率和扰动 |
| 后期取消 | `cancel_time_ratio` 较高 | 提高 `SD` 和 `TD` | 已完成任务多，扰动越小越重要，局部修复往往更稳 |
| 冻结比例高 | `frozen_operation_ratio` 较高 | 提高 `SD` 和 `TD` | 冻结任务越多，后续计划越应减少机器和 AGV 扰动 |
| 剩余任务多 | `remaining_operation_count` 较高 | 提高 `Cmax_delta` 和 `energy_delta` | 剩余任务越多，重排空间越大，效率指标更重要 |
| 局部修复不可行 | `local_repair_feasible = false` | 直接偏向完全重调度 | 局部修复不能作为最终可行方案 |
| 完全重调度不可行 | `complete_rescheduling_feasible = false` | 直接偏向局部修复 | 完全重调度不能作为最终可行方案 |
| unsupported | `unsupported_flag = true` | 不做正常自适应选择 | 第一版不处理中断加工或运输，应保留 unsupported 结果 |

建议第一版时间段解释：

```text
early:  cancel_time_ratio < 0.33
middle: 0.33 <= cancel_time_ratio < 0.67
late:   cancel_time_ratio >= 0.67
```

建议归一化约定：

- 权重调整后必须非负。
- 权重总和建议归一化为 1。
- 若规则无法应用，返回固定权重 baseline。
- 若候选可行性已经排除某一方案，权重仍可记录，但最终选择应优先遵守可行性。

## 8. Step K4 验收结果

| 验收项 | 结果 |
|---|---|
| 每条规则可解释 | 通过，规则表已说明触发特征、权重倾向和原因 |
| 权重来自函数输出，不写死在评价函数里 | 通过，Step K4 约定由后续 `adapt_evaluation_weights.m` 输出 `weights` |
| 权重总和可归一化 | 通过，文档约定权重非负且总和归一化为 1 |
| 固定权重 baseline 仍可使用 | 通过，自适应规则只在 baseline 之上调整，无法应用时回退 baseline |

Step K4 完成标志：第一版规则式自适应权重策略已经定义。后续可以进入 Step K5：实现自适应权重函数。

## 9. Step K5：实现自适应权重函数

Step K5 新增自适应权重函数：

```text
src/cancellation/adapt_evaluation_weights.m
```

函数入口：

```matlab
[weights, report] = adapt_evaluation_weights(features, baseConfig)
```

输出权重字段：

```matlab
weights.Cmax_delta
weights.SD
weights.TD
weights.energy_delta
```

输出报告字段：

```matlab
report.reason
report.applied_rules
report.isAdaptive
report.preferred_strategy
report.baseline_weights
report.weights
```

第一版实现口径：

- 从 `baseConfig.weights` 读取固定权重 baseline。
- 若未传入完整 baseline，则使用等权重 `0.25 / 0.25 / 0.25 / 0.25`。
- 根据 Step K4 的规则调整权重。
- 调整后权重归一化，使四个权重总和为 1。
- `unsupported_flag = true` 时保留 baseline，并记录 `unsupported_state_keep_baseline`。
- 局部修复不可行且完全重调度可行时，返回偏效率权重，并记录 `preferred_strategy = 'complete_rescheduling'`。
- 完全重调度不可行且局部修复可行时，返回偏稳定权重，并记录 `preferred_strategy = 'local_repair'`。

第一版默认阈值：

```text
early:  cancel_time_ratio < 0.33
middle: 0.33 <= cancel_time_ratio < 0.67
late:   cancel_time_ratio >= 0.67
high frozen ratio: frozen_operation_ratio >= 0.67
many remaining operations: remaining_operation_count >= 3
```

`many remaining operations` 的阈值可以通过：

```matlab
baseConfig.adaptive.remaining_operation_count_high
```

覆盖。该阈值仍属于规则式配置，不属于机器学习训练结果。

## 10. Step K5 验收结果

| 验收项 | 结果 |
|---|---|
| 能返回完整权重 | 通过，输出 `Cmax_delta`、`SD`、`TD` 和 `energy_delta` |
| 权重非负 | 通过，归一化前会将非法权重按 0 处理 |
| 权重总和为 1 | 通过，`adapt_evaluation_weights.m` 对输出权重归一化 |
| 能记录应用了哪些规则 | 通过，输出 `report.applied_rules` |
| 能退回固定权重 baseline | 通过，unsupported、无可行候选或无调整时可保留 baseline |

Step K5 完成标志：阶段 K 已具备规则式自适应权重生成函数。后续可以进入 Step K6：接入策略选择流程。

## 11. Step K6：接入策略选择流程

Step K6 新增自适应策略选择 wrapper：

```text
src/cancellation/select_adaptive_cancellation_strategy.m
```

函数入口：

```matlab
result = select_adaptive_cancellation_strategy( ...
    baselineSchedule, ...
    state, ...
    cancel, ...
    localRepairCandidate, ...
    completeReschedulingCandidate, ...
    machineData, ...
    agvData, ...
    baseConfig)
```

第一版流程：

1. 调用 `extract_cancellation_features.m` 提取场景特征。
2. 调用 `adapt_evaluation_weights.m` 生成自适应权重。
3. 将自适应权重写入临时 `adaptiveConfig.weights`。
4. 复用 `evaluate_order_cancellation_candidate.m` 重新评价局部修复和完全重调度候选。
5. 复用 `select_order_cancellation_strategy.m` 选择 `Y` 更小或唯一可行的方案。
6. 返回特征、权重、评价结果和选择结果。

输出结构：

```matlab
result.features
result.weights
result.adaptive_report
result.config
result.localRepairEvaluation
result.completeReschedulingEvaluation
result.selection
result.isSelected
```

边界说明：

- 固定权重策略仍能直接走阶段 E/H 原流程。
- 自适应策略通过新 wrapper 单独调用。
- 阶段 K 不修改 `evaluate_order_cancellation_candidate.m`。
- 阶段 K 不修改 `select_order_cancellation_strategy.m`。
- 阶段 K 不修改 `select_hybrid_cancellation_policy.m`。
- 阶段 K 只把自适应权重作为临时配置传入已有评价和选择函数。

## 12. Step K6 验收结果

| 验收项 | 结果 |
|---|---|
| 固定权重策略仍能跑 | 通过，阶段 E/H 原函数未修改 |
| 自适应策略能单独调用 | 通过，新增 `select_adaptive_cancellation_strategy.m` |
| 输出包含 `features`、`weights`、`selection` | 通过，wrapper 输出对应字段 |
| 不重写阶段 E/H 核心逻辑 | 通过，wrapper 复用已有评价和选择函数 |

Step K6 完成标志：阶段 K 已能以独立 wrapper 的方式接入策略选择流程。后续可以进入 Step K7：写自适应权重单元测试。

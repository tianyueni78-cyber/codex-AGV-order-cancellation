# 阶段 F Step F1：实验范围确认

> 本文档已不再作为阶段 F 的主要阅读入口。阶段 F 的范围、配置、实验结果、结论和局限已整合到 [阶段 F 项目报告](stage_f_project_report.md)。本文档仅保留为历史过程记录。

本文档记录阶段 F Step F1 的范围确认结果。Step F1 只确认阶段 F 的实验边界，不新增实验配置，不实现实验脚本，不运行 MATLAB，不生成 `outputs/`。

## 1. Step F1 目标

Step F1 目标：

```text
明确阶段 F 只做小规模订单取消实验。
```

阶段 F 是订单取消第一版闭环的小规模实验阶段，目标是验证阶段 B-E 链路能否在早期取消、中期取消、后期取消场景下稳定运行。

## 2. 本阶段确认不加入的内容

阶段 F Step F1 明确排除：

1. 不加入机器故障。
2. 不加入新订单插入。
3. 不加入多个订单连续取消。
4. 不加入强化学习。
5. 不追求全局最优证明。

这些内容不是永久不做，而是不进入阶段 F 小规模实验。后续可在阶段 G-N 路线图中逐步扩展。

## 3. 阶段 F 实验对象

阶段 F 实验对象保持为：

```text
单订单取消。
```

第一版取消事件仍使用阶段 B 已定义的最小结构：

```matlab
cancel.job_id
cancel.cancel_time
cancel.policy
```

第一版策略仍为：

```text
cancel_unstarted_operations_only
```

阶段 F 不处理正在加工工序取消，不处理中途抢占，不处理取消时刻不确定。

## 4. 阶段 F 允许调用的链路

阶段 F 实验入口只允许串联阶段 B-E 已有链路：

1. 阶段 B：订单取消事件与状态提取。
2. 阶段 C：局部修复候选方案。
3. 阶段 D：完全重调度候选方案。
4. 阶段 E：评价与策略选择。

允许复用的代表性函数包括：

```text
create_order_cancellation_event.m
validate_order_cancellation_event.m
extract_cancellation_state.m
build_local_repair_candidate.m
build_complete_rescheduling_candidate.m
evaluate_order_cancellation_candidate.m
select_order_cancellation_strategy.m
```

阶段 F 不新增新的调度算法主线，不新增独立于阶段 B-E 的候选生成器。

## 5. 阶段 F 最小场景

阶段 F 后续 Step F2 才定义具体配置。Step F1 先确认最小场景集合为：

1. 早期取消。
2. 中期取消。
3. 后期取消。

建议后续以 `cancel_time_ratio` 表达取消时刻：

```text
early_cancel  = 0.25 * baseline_Cmax
middle_cancel = 0.50 * baseline_Cmax
late_cancel   = 0.75 * baseline_Cmax
```

具体数值和随机种子在 Step F2 配置中确定。

## 6. 阶段 F 验收标准

Step F1 对阶段 F 的验收标准确认如下：

1. 实验对象仍是单订单取消。
2. 实验入口只调用阶段 B-E 已有链路。
3. 不新增新的调度算法主线。
4. 不加入机器故障。
5. 不加入新订单插入。
6. 不加入多个订单连续取消。
7. 不加入强化学习。
8. 不追求全局最优证明。

## 7. Step F1 验收结果

Step F1 静态验收结果：

1. 阶段 F 范围已确认。
2. 阶段 F 只做小规模订单取消实验。
3. 阶段 F 后续从 Step F2：定义取消场景配置 开始。
4. 本步骤没有新增算法代码。
5. 本步骤没有运行 MATLAB。
6. 本步骤没有生成 `outputs/`。
7. 本步骤没有修改 `raw_code/`。

Step F1 完成标志：

```text
阶段 F 的实验范围已经收窄为单订单取消小规模实验，
并明确后续实验只串联阶段 B-E 既有链路，
不引入机器故障、新订单插入、连续取消、强化学习或全局最优证明。
```

## 8. 下一步

下一步进入：

```text
Step F2：定义取消场景配置。
```

Step F2 应新增或确认小规模实验配置，至少包含早期取消、中期取消、后期取消和多随机种子设置。

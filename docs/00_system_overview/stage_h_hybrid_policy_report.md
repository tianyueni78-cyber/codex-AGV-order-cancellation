# 阶段 H 项目报告：混合修复策略

本文档是阶段 H 的唯一主入口。阶段 H 不再为每个小步骤单独建立 README 主入口；配置、触发规则、测试入口、smoke 入口、局限和阶段 I 入口都统一放在本文档中。

## 1. 阶段 H 目标

阶段 H 的目标是在局部修复和完全重调度之间建立第一版可解释触发规则，形成混合订单取消处理策略。

阶段 H 不重新实现阶段 B-E：

- 阶段 B 负责取消事件和状态提取。
- 阶段 C 负责局部修复候选。
- 阶段 D 负责完全重调度候选。
- 阶段 E 负责候选评价和 `Y` 指标。
- 阶段 H 只读取已有候选和评价结果，决定采用哪一种处理策略。

## 2. 输入契约

混合策略层建议接收以下已有结果：

```text
problem
machineData
agvData
baselineSchedule
state
cancel
localRepairCandidate
completeReschedulingCandidate
evaluation
config
```

当前核心函数 `select_hybrid_cancellation_policy.m` 实际只需要读取两个候选、两个评价结果和配置：

```matlab
decision = select_hybrid_cancellation_policy( ...
    localRepairCandidate, completeReschedulingCandidate, ...
    localRepairEvaluation, completeReschedulingEvaluation, config)
```

阶段 H 不修改候选计划，不重新解码，不重新搜索，也不写 `outputs/`。

## 3. 配置

触发规则来自 `config.hybrid_policy`，不在函数内部写死业务阈值。

当前支持字段：

```matlab
config.hybrid_policy.enable_complete_if_local_infeasible
config.hybrid_policy.use_stage_e_y_selection
config.hybrid_policy.cmax_delta_threshold
config.hybrid_policy.energy_delta_threshold
config.hybrid_policy.idle_waste_threshold
config.hybrid_policy.threshold_validation_status
```

第一版默认含义：

| 字段 | 默认思路 | 含义 |
|---|---|---|
| `enable_complete_if_local_infeasible` | `true` | 局部修复不可行时尝试完全重调度 |
| `use_stage_e_y_selection` | `true` | 两个候选都可行时继续使用阶段 E 的 `Y` 比较 |
| `cmax_delta_threshold` | `0` | 局部修复使完工时间变差时可触发完全重调度 |
| `energy_delta_threshold` | `0` | 局部修复使能耗变差时可触发完全重调度 |
| `idle_waste_threshold` | `Inf` | 第一版保留空闲浪费接口，但默认不强制触发 |
| `threshold_validation_status` | `pending_stage_l_validation` | 阈值需要在阶段 L 用更大实验验证 |

这些阈值是可解释默认值，不是最终算法结论。后续阶段 L 需要用更多实例和随机种子验证阈值是否稳定。

## 4. 触发规则

第一版混合策略遵循以下规则：

1. 如果局部修复不可行，且完全重调度可行，则选择完全重调度，原因记为 `local_infeasible_trigger_complete`。
2. 如果局部修复可行、完全重调度不可行，且局部修复没有触发阈值，则选择局部修复，原因记为 `local_stable_enough`。
3. 如果局部修复可行但触发阈值，而完全重调度不可行，则回退选择局部修复，原因记为 `complete_triggered_but_infeasible`。
4. 如果两个候选都可行，且 `use_stage_e_y_selection = true`，则复用阶段 E 的 `Y` 选择规则。
5. 如果两个候选都可行但不使用 `Y`，则由阈值决定是否触发完全重调度。
6. 如果两个候选都不可行，则拒绝选择，原因记为 `both_infeasible`。

当前原因枚举包括：

```text
local_stable_enough
local_infeasible_trigger_complete
threshold_trigger_complete
complete_better_Y
local_better_Y
tie_break_local
both_infeasible
complete_triggered_but_infeasible
missing_required_input
unsupported_config
```

## 5. 输出结构

混合策略输出 `decision`，用于记录最终策略和选择原因。

主要字段：

```text
decision.isSelected
decision.selected_strategy
decision.selected_candidate
decision.reason
decision.triggered_complete_rescheduling
decision.local_repair_evaluation
decision.complete_rescheduling_evaluation
decision.local_repair_isFeasible
decision.complete_rescheduling_isFeasible
decision.threshold_report
decision.report
```

其中 `selected_strategy` 当前只允许：

```text
local_repair
complete_rescheduling
```

如果无可行候选，`decision.isSelected = false`，并通过 `decision.reason` 和 `decision.report.rejectedReasons` 说明原因。

## 6. 阈值指标口径

阶段 H 复用阶段 E 已有指标，不重复实现评价逻辑。

- `Cmax_delta`：来自 `localRepairEvaluation.metrics.Cmax_delta`。
- `energy_delta`：来自 `localRepairEvaluation.metrics.energy_delta`。
- `idle_waste`：优先来自 `localRepairEvaluation.metrics.idle_waste`；如果评价中没有，则读取 `localRepairCandidate.idle_waste`；如果都没有，第一版按 `0` 处理。

空闲浪费当前只是预留接口，因为“删除式局部修复”保留空闲块的口径还需要在更多场景中验证。第一版默认 `idle_waste_threshold = Inf`，避免用未验证指标强制触发完全重调度。

## 7. 新增文件

阶段 H 当前新增或使用的核心文件：

```text
src/cancellation/select_hybrid_cancellation_policy.m
tests/test_order_cancellation_hybrid_policy.m
scripts/run_order_cancellation_hybrid_policy_smoke.m
docs/00_system_overview/stage_h_hybrid_policy_report.md
```

历史过程计划保留在：

```text
docs/00_system_overview/stage_h_hybrid_policy_plan.md
```

README 只挂本文档作为阶段 H 主入口。

## 8. 测试入口

单元测试入口：

```matlab
run('tests/test_order_cancellation_hybrid_policy.m')
```

覆盖内容：

- 局部修复可行且稳定时选择 `local_repair`。
- 局部修复不可行、完全重调度可行时选择 `complete_rescheduling`。
- 两个候选都可行时按 `Y` 选择。
- `Y` 相同按第一版规则选择局部修复。
- 两个候选都不可行时拒绝选择。
- 修改 config 阈值会改变触发结果。
- 完全重调度被触发但不可行时回退局部修复。

该测试不写 `outputs/`，不运行 NSGA-II，不做正式实验。

## 9. Smoke 入口

样例 smoke 入口：

```matlab
run('scripts/run_order_cancellation_hybrid_policy_smoke.m')
```

该脚本会串联阶段 B-E 的已有链路：

1. 构造 `data_sample/Mk01.fjs` 的取消事件。
2. 提取取消状态。
3. 构造局部修复候选。
4. 构造完全重调度候选。
5. 评价两个候选。
6. 调用混合策略选择函数。
7. 打印选择策略、选择原因和阈值触发状态。

该 smoke 不写 `outputs/`，不做正式多随机种子实验。

当前状态：入口已完成，MATLAB 运行输出等待用户执行后补充到本报告。

## 10. 局限

阶段 H 当前仍有以下局限：

1. 阈值是可解释默认值，尚未经过大规模实验验证。
2. 空闲浪费只保留接口，尚未作为强制触发指标。
3. 当前策略只处理单订单取消，不处理多个订单连续取消。
4. 当前策略不加入机器故障、AGV 故障、新订单插入和强化学习。
5. 阶段 H 不是全局最优证明，只是可运行闭环上的第一版策略规则。
6. smoke 仍基于小样例，不能直接当作论文级结论。

## 11. 阶段 H 完成标志

阶段 H 的完成标志是：

- 已实现混合策略选择函数。
- 触发规则来自 `config`。
- 能记录最终策略、是否触发完全重调度和选择原因。
- 能处理局部修复可行、完全重调度可行、二者都不可行等基本情况。
- 已提供单元测试入口。
- 已提供样例 smoke 入口。
- README 只挂阶段 H 一个主入口。

阶段 H 的算法结论仍需要后续阶段 L 做稳定性验证。

## 12. 阶段 I 入口

阶段 I 建议进入“多订单连续取消”：

```text
阶段 I：多订单连续取消
核心问题：连续取消时，状态能否正确回放，修复策略能否重复调用，并且不会把已取消任务回流到后续计划。
```

阶段 I 不应直接把机器故障或新订单插入混进来，而是先验证“订单取消事件重复发生”时，阶段 B-H 的链路是否仍能稳定运行。

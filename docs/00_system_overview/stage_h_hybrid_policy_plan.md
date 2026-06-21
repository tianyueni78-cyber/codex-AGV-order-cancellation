# 阶段 H：混合修复策略工作计划

本文档是阶段 H 的主计划文档。阶段 H 承接阶段 G 的场景库实验结果，目标是在局部修复和完全重调度之间建立可解释的触发规则，形成第一版混合策略。

## 1. 阶段 H 目标

阶段 H 的目标是：

```text
在局部修复和完全重调度之间建立触发规则，
形成第一版混合订单取消处理策略。
```

阶段 H 不是重新写阶段 B-E，而是在已有链路上增加策略层：

```text
取消状态
  -> 局部修复候选
  -> 判断是否需要触发完全重调度
  -> 完全重调度候选
  -> 阶段 E 的 Y 选择
  -> 输出混合策略选择原因
```

## 2. 基本思路

第一版混合策略遵循以下顺序：

1. 先生成局部修复候选。
2. 如果局部修复不可行，触发完全重调度。
3. 如果局部修复可行，但 `Cmax_delta`、能耗或空闲浪费超过阈值，触发完全重调度。
4. 如果两个候选都可行，继续使用阶段 E 的 `Y` 选择。
5. 如果两个候选都不可行，输出无可行候选，并记录原因。

阶段 H 的核心不是替代阶段 E，而是在阶段 E 之前补一层“是否值得触发完全重调度”的规则。

## 3. 建议新增文件

源码：

```text
src/cancellation/select_hybrid_cancellation_policy.m
```

测试：

```text
tests/test_order_cancellation_hybrid_policy.m
```

文档：

```text
docs/00_system_overview/stage_h_hybrid_policy_plan.md
```

## 4. 配置来源

触发规则必须来自 `config`，不写死在函数里。

建议配置字段：

```matlab
config.hybrid_policy.enable_complete_if_local_infeasible
config.hybrid_policy.cmax_delta_threshold
config.hybrid_policy.energy_delta_threshold
config.hybrid_policy.idle_waste_threshold
config.hybrid_policy.use_stage_e_y_selection
```

第一版默认解释：

1. `enable_complete_if_local_infeasible = true`：局部修复不可行时尝试完全重调度。
2. `cmax_delta_threshold`：局部修复导致最大完工时间变差超过阈值时触发完全重调度。
3. `energy_delta_threshold`：局部修复能耗变差超过阈值时触发完全重调度。
4. `idle_waste_threshold`：局部修复保留过多空闲浪费时触发完全重调度。
5. `use_stage_e_y_selection = true`：两个候选都可行时继续用阶段 E 的综合指标 `Y` 决策。

如果阈值缺少实验依据，先使用可解释默认值，并在文档中标记为待阶段 L 验证。

## 5. 输出结构

建议输出：

```matlab
decision.selected_strategy
decision.selected_candidate
decision.isSelected
decision.reason
decision.triggered_complete_rescheduling
decision.local_repair_evaluation
decision.complete_rescheduling_evaluation
decision.report
```

建议 `reason` 取值：

```text
local_stable_enough
local_infeasible_trigger_complete
complete_better_Y
local_better_Y
tie_break_local
both_infeasible
complete_triggered_but_infeasible
threshold_trigger_complete
```

## 6. 具体工作流程

### Step H1：确认阶段 H 输入契约

目标：明确混合策略层接收哪些已有结果。

输入建议：

```matlab
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

验收标准：

1. 局部修复候选来自阶段 C。
2. 完全重调度候选来自阶段 D。
3. 候选评价来自阶段 E。
4. 阶段 H 不重新实现状态提取、局部修复、完全重调度或指标计算。

H1 确认结果：

1. `localRepairCandidate` 必须来自阶段 C 的 `build_local_repair_candidate.m`。
2. `completeReschedulingCandidate` 必须来自阶段 D 的 `build_complete_rescheduling_candidate.m`。
3. `evaluation` 必须来自阶段 E 的 `evaluate_order_cancellation_candidate.m` 和 `select_order_cancellation_strategy.m`。
4. `state` 必须来自阶段 B 的 `extract_cancellation_state.m`，阶段 H 只读取状态，不重新分类工序或 AGV 任务。
5. `cancel` 必须来自阶段 B 的 `create_order_cancellation_event.m`，并已通过 `validate_order_cancellation_event.m`。
6. `problem`、`machineData`、`agvData` 和 `baselineSchedule` 只作为上下文和指标解释来源，阶段 H 不修改这些输入。
7. `config` 是混合策略触发规则的唯一来源，后续 H2 负责定义 `config.hybrid_policy` 字段。

H1 禁止行为：

1. 不重新实现状态提取。
2. 不重新实现局部修复。
3. 不重新实现完全重调度。
4. 不重新实现 `Cmax_delta`、`SD`、`TD`、能耗或 `Y` 指标。
5. 不运行 MATLAB。
6. 不生成 `outputs/`。

H1 静态验收：

1. 阶段 C 候选生成入口已确认存在：`src/cancellation/build_local_repair_candidate.m`。
2. 阶段 D 候选生成入口已确认存在：`src/cancellation/build_complete_rescheduling_candidate.m`。
3. 阶段 E 候选评价入口已确认存在：`src/cancellation/evaluate_order_cancellation_candidate.m`。
4. 阶段 E 策略选择入口已确认存在：`src/cancellation/select_order_cancellation_strategy.m`。
5. H1 只更新文档，不新增源码、不新增测试、不运行实验。

### Step H2：定义混合策略配置

目标：把触发阈值写入 config。

建议先在测试中构造最小 config，后续再考虑是否落到 yaml。

验收标准：

1. 触发阈值来自 config。
2. 默认阈值有解释。
3. 缺少实验依据的阈值标记为待阶段 L 验证。
4. 函数内部不写死业务阈值。

H2 配置契约：

第一版混合策略配置统一放在：

```matlab
config.hybrid_policy
```

建议最小字段：

```matlab
config.hybrid_policy.enable_complete_if_local_infeasible
config.hybrid_policy.use_stage_e_y_selection
config.hybrid_policy.cmax_delta_threshold
config.hybrid_policy.energy_delta_threshold
config.hybrid_policy.idle_waste_threshold
config.hybrid_policy.threshold_validation_status
```

建议默认值：

```matlab
config.hybrid_policy.enable_complete_if_local_infeasible = true;
config.hybrid_policy.use_stage_e_y_selection = true;
config.hybrid_policy.cmax_delta_threshold = 0;
config.hybrid_policy.energy_delta_threshold = 0;
config.hybrid_policy.idle_waste_threshold = Inf;
config.hybrid_policy.threshold_validation_status = 'pending_stage_l_validation';
```

默认值解释：

1. `enable_complete_if_local_infeasible = true`：局部修复不可行时允许尝试完全重调度。
2. `use_stage_e_y_selection = true`：两个候选都可行时继续复用阶段 E 的 `Y` 选择规则。
3. `cmax_delta_threshold = 0`：局部修复只要让 `Cmax_delta` 变差到正值，就可以触发完全重调度评估。
4. `energy_delta_threshold = 0`：局部修复只要让能耗变化变差到正值，就可以触发完全重调度评估。
5. `idle_waste_threshold = Inf`：空闲浪费第一版先不作为强制触发项，只保留接口，避免用没有验证的口径影响策略。
6. `threshold_validation_status = 'pending_stage_l_validation'`：明确这些阈值目前是可解释默认值，不是统计验证后的最优阈值。

H2 实现边界：

1. H2 暂不新增 yaml 配置文件。
2. H2 建议先在 `tests/test_order_cancellation_hybrid_policy.m` 中构造最小 `config`。
3. 后续如果 H6 单元测试稳定，再考虑把 `config.hybrid_policy` 落到正式配置文件。
4. `select_hybrid_cancellation_policy.m` 内部不得写死上述业务阈值。
5. 如果缺少某个配置字段，后续实现应使用一个明确的默认配置构造函数或本地默认合并逻辑，并在 report 中记录默认来源。

H2 静态验收：

1. 已定义 `config.hybrid_policy` 作为混合策略配置入口。
2. 已定义局部修复不可行触发完全重调度的开关。
3. 已定义 `Cmax_delta`、能耗和空闲浪费阈值字段。
4. 已说明默认阈值含义。
5. 已标记阈值需要阶段 L 验证。
6. H2 只更新文档，不新增源码、不新增测试、不运行 MATLAB、不生成 `outputs/`。

### Step H3：定义输出与原因枚举

目标：统一 `decision` 结构和 `reason` 取值。

验收标准：

1. 能记录最终选择策略。
2. 能记录是否触发完全重调度。
3. 能记录选择原因。
4. 能记录两个候选的评价结果。

### Step H4：实现混合策略选择函数

建议新增：

```text
src/cancellation/select_hybrid_cancellation_policy.m
```

第一版逻辑：

1. 如果局部修复不可行，尝试完全重调度。
2. 如果局部修复可行且没有超过阈值，选择局部修复。
3. 如果局部修复可行但超过阈值，触发完全重调度。
4. 如果两个候选都可行，调用或复用阶段 E 的 `Y` 选择规则。
5. 如果两个候选都不可行，拒绝选择。

验收标准：

1. 能处理局部修复可行、完全重调度可行。
2. 能处理局部修复不可行、完全重调度可行。
3. 能处理两个候选都不可行。
4. 输出选择原因。

### Step H5：补充阈值指标

目标：确认 `Cmax_delta`、能耗和空闲浪费怎么进入触发规则。

第一版建议：

1. `Cmax_delta` 复用阶段 E 指标。
2. 能耗变化复用阶段 E 的 `energy_delta`。
3. 空闲浪费第一版可以先用局部修复保留空闲块的总时长近似。

验收标准：

1. 不重复实现阶段 E 已有指标。
2. 空闲浪费口径写清楚。
3. 如果空闲浪费难以稳定计算，先不作为强制触发项，只保留接口。

### Step H6：写单元测试

建议新增：

```text
tests/test_order_cancellation_hybrid_policy.m
```

测试内容：

1. 局部修复可行且稳定，选择 `local_repair`，原因 `local_stable_enough`。
2. 局部修复不可行、完全重调度可行，选择 `complete_rescheduling`，原因 `local_infeasible_trigger_complete`。
3. 两个候选都可行，完全重调度 `Y` 更小，选择 `complete_rescheduling`，原因 `complete_better_Y`。
4. 两个候选都可行，局部修复 `Y` 更小，选择 `local_repair`，原因 `local_better_Y`。
5. 两个候选都不可行，拒绝选择，原因 `both_infeasible`。
6. 阈值来自 config，修改阈值会改变触发结果。

验收标准：

1. 测试不写 `outputs/`。
2. 测试不跑 NSGA-II。
3. 测试只构造最小候选和评价结果。

### Step H7：样例 smoke

目标：在阶段 G 的 Mk01 场景库结果基础上验证混合策略能跑通。

建议入口后续新增：

```text
scripts/run_order_cancellation_hybrid_policy_smoke.m
```

验收标准：

1. 能生成局部修复和完全重调度候选。
2. 能评价两个候选。
3. 能输出混合策略选择原因。
4. 不做正式大规模实验。

### Step H8：阶段 H 工作记录或项目报告

目标：阶段 H 完成后只保留一个主文档。

建议主文档：

```text
docs/00_system_overview/stage_h_hybrid_policy_report.md
```

验收标准：

1. README 只挂阶段 H 一个主入口。
2. 报告包含配置、触发规则、测试入口、smoke 结果、局限和阶段 I 入口。
3. 不再为每个小 step 新建多个独立主入口。

## 7. 阶段 H 验收标准

阶段 H 完成时应满足：

1. 能处理局部修复可行、完全重调度可行。
2. 能处理局部修复不可行、完全重调度可行。
3. 能处理两个候选都不可行。
4. 触发规则来自 config，不写死在函数里。
5. 输出选择原因，例如 `local_stable_enough`、`complete_better_Y`、`local_infeasible_trigger_complete`。
6. 缺少实验依据的阈值已标记为待阶段 L 验证。
7. 不加入机器故障、新订单插入、连续取消或强化学习。

## 8. 停止条件

如果阈值缺少实验依据：

1. 不强行声称阈值最优。
2. 使用可解释的默认阈值。
3. 在阶段 H 文档中标记为待阶段 L 验证。
4. 后续由阶段 L 的大规模与统计验证决定阈值是否稳定。

## 9. 阶段 I 入口

阶段 H 完成后，阶段 I 建议进入：

```text
阶段 I：多订单连续取消
```

阶段 I 的核心问题是：

```text
连续取消时，状态能否正确回放和重复修复。
```

# 阶段 H：混合修复策略工作计划

> 阶段 H 的 README 主入口已统一为 [阶段 H 项目报告：混合修复策略](stage_h_hybrid_policy_report.md)。本文档仅保留为阶段 H 的过程计划记录。

本文档是阶段 H 的过程计划记录。阶段 H 承接阶段 G 的场景库实验结果，目标是在局部修复和完全重调度之间建立可解释的触发规则，形成第一版混合策略。

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

H3 输出结构契约：

阶段 H 的输出统一命名为：

```matlab
decision
```

建议字段：

```matlab
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

字段含义：

1. `decision.isSelected`：是否成功选出策略。
2. `decision.selected_strategy`：最终策略名称，取值建议为 `local_repair`、`complete_rescheduling` 或空字符串。
3. `decision.selected_candidate`：被选中的候选方案；没有可行候选时为空。
4. `decision.reason`：选择原因，必须来自 H3 的 reason 枚举。
5. `decision.triggered_complete_rescheduling`：是否触发完全重调度评估。
6. `decision.local_repair_evaluation`：阶段 E 对局部修复候选的评价结果。
7. `decision.complete_rescheduling_evaluation`：阶段 E 对完全重调度候选的评价结果。
8. `decision.local_repair_isFeasible`：局部修复候选是否可行。
9. `decision.complete_rescheduling_isFeasible`：完全重调度候选是否可行。
10. `decision.threshold_report`：记录哪些阈值被触发，例如 `cmax_delta_triggered`、`energy_delta_triggered`、`idle_waste_triggered`。
11. `decision.report`：记录错误、拒绝原因、默认配置来源和调试信息。

H3 reason 枚举：

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

reason 含义：

1. `local_stable_enough`：局部修复可行，且没有触发 `Cmax_delta`、能耗或空闲浪费阈值，因此直接选择局部修复。
2. `local_infeasible_trigger_complete`：局部修复不可行，触发完全重调度；完全重调度可行并被选中。
3. `threshold_trigger_complete`：局部修复可行，但至少一个阈值被触发，因此进入完全重调度评估。
4. `complete_better_Y`：两个候选都可行，完全重调度的 `Y` 更小，因此选择完全重调度。
5. `local_better_Y`：两个候选都可行，局部修复的 `Y` 更小，因此选择局部修复。
6. `tie_break_local`：两个候选都可行且 `Y` 相同，第一版按保守规则选择局部修复。
7. `both_infeasible`：两个候选都不可行，无法选择策略。
8. `complete_triggered_but_infeasible`：阈值或局部不可行触发了完全重调度，但完全重调度不可行；如果局部修复仍可行，可回退选择局部修复，否则拒绝选择。
9. `missing_required_input`：缺少 H1 输入契约中的必需字段。
10. `unsupported_config`：`config.hybrid_policy` 存在不支持的字段值或类型。

H3 记录规则：

1. 最终选择策略必须写入 `decision.selected_strategy`。
2. 是否触发完全重调度必须写入 `decision.triggered_complete_rescheduling`。
3. 选择原因必须写入 `decision.reason`，不得使用未列入枚举的临时字符串。
4. 两个候选的评价结果必须保留，便于阶段 L 后续统计阈值是否稳定。
5. 如果使用默认配置，必须在 `decision.report` 中记录默认来源。

H3 静态验收：

1. 已定义 `decision` 结构。
2. 已定义 `reason` 枚举。
3. 已说明每个 reason 的触发含义。
4. 已要求记录两个候选的评价结果。
5. H3 只更新文档，不新增源码、不新增测试、不运行 MATLAB、不生成 `outputs/`。

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

H4 实现结果：

已新增：

```text
src/cancellation/select_hybrid_cancellation_policy.m
```

函数职责：

1. 只读取阶段 C/D 已生成的候选和阶段 E 已生成的评价结果。
2. 不重新提取取消状态。
3. 不重新构造局部修复候选。
4. 不重新构造完全重调度候选。
5. 不重新计算 `Cmax_delta`、`SD`、`TD`、能耗或 `Y`。
6. 不写 `outputs/`。

当前支持的选择原因：

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

H4 静态验收：

1. 已实现局部修复可行、完全重调度可行时的 `Y` 选择。
2. 已实现局部修复不可行、完全重调度可行时选择完全重调度。
3. 已实现两个候选都不可行时拒绝选择。
4. 已实现选择原因输出到 `decision.reason`。
5. 已实现 `decision.triggered_complete_rescheduling`。
6. 已保留两个候选的评价结果。
7. 已从 `config.hybrid_policy` 读取阈值和开关，并提供带记录的默认配置。

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

H5 指标口径：

1. `Cmax_delta` 直接读取阶段 E 评价结果：

   ```matlab
   localRepairEvaluation.metrics.Cmax_delta
   ```

   阈值字段：

   ```matlab
   config.hybrid_policy.cmax_delta_threshold
   ```

   触发规则：

   ```matlab
   localRepairEvaluation.metrics.Cmax_delta > ...
       config.hybrid_policy.cmax_delta_threshold
   ```

2. 能耗变化直接读取阶段 E 评价结果：

   ```matlab
   localRepairEvaluation.metrics.energy_delta
   ```

   阈值字段：

   ```matlab
   config.hybrid_policy.energy_delta_threshold
   ```

   触发规则：

   ```matlab
   localRepairEvaluation.metrics.energy_delta > ...
       config.hybrid_policy.energy_delta_threshold
   ```

3. 空闲浪费第一版只保留接口，优先读取：

   ```matlab
   localRepairEvaluation.metrics.idle_waste
   ```

   如果评价结果中没有该字段，再尝试读取：

   ```matlab
   localRepairCandidate.idle_waste
   ```

   如果两处都没有，则按 `0` 处理。

   阈值字段：

   ```matlab
   config.hybrid_policy.idle_waste_threshold
   ```

   第一版默认：

   ```matlab
   config.hybrid_policy.idle_waste_threshold = Inf
   ```

   因此空闲浪费不会在第一版中强制触发完全重调度，只在 `decision.threshold_report` 中保留接口和记录位置。

H5 当前实现状态：

1. `select_hybrid_cancellation_policy.m` 已通过 `build_threshold_report` 读取 `Cmax_delta`、`energy_delta` 和 `idle_waste`。
2. `Cmax_delta` 和 `energy_delta` 复用阶段 E 已有评价结果，不重复计算。
3. 空闲浪费不重复扫描机器表或 AGV 表，第一版只读取现有字段；没有字段时默认 `0`。
4. 空闲浪费默认阈值为 `Inf`，因此当前只保留接口，不作为强制触发项。
5. 三类触发结果写入 `decision.threshold_report.cmax_delta_triggered`、`energy_delta_triggered`、`idle_waste_triggered` 和 `any_triggered`。

H5 静态验收：

1. 已确认 `Cmax_delta` 复用阶段 E 指标。
2. 已确认能耗变化复用阶段 E 的 `energy_delta`。
3. 已写清楚空闲浪费第一版口径。
4. 已说明空闲浪费难以稳定计算时只保留接口。
5. H5 不新增新的指标计算函数，不运行 MATLAB，不生成 `outputs/`。

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

H6 实现结果：

已新增：

```text
tests/test_order_cancellation_hybrid_policy.m
```

测试入口：

```matlab
run('tests/test_order_cancellation_hybrid_policy.m')
```

测试覆盖：

1. 局部修复可行且稳定，选择 `local_repair`，原因 `local_stable_enough`。
2. 局部修复不可行、完全重调度可行，选择 `complete_rescheduling`，原因 `local_infeasible_trigger_complete`。
3. 两个候选都可行，完全重调度 `Y` 更小，选择 `complete_rescheduling`，原因 `complete_better_Y`。
4. 两个候选都可行，局部修复 `Y` 更小，选择 `local_repair`，原因 `local_better_Y`。
5. 两个候选都可行且 `Y` 相同，选择 `local_repair`，原因 `tie_break_local`。
6. 两个候选都不可行，拒绝选择，原因 `both_infeasible`。
7. 修改 `config.hybrid_policy.cmax_delta_threshold` 会改变阈值触发结果。
8. 完全重调度被触发但不可行时，回退选择可行的局部修复，原因 `complete_triggered_but_infeasible`。

H6 静态验收：

1. 测试只构造最小候选和评价结果。
2. 测试不写 `outputs/`。
3. 测试不调用 NSGA-II。
4. 测试入口已写入本文档。

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

H7 实现结果：

已新增：

```text
scripts/run_order_cancellation_hybrid_policy_smoke.m
```

运行入口：

```matlab
run('scripts/run_order_cancellation_hybrid_policy_smoke.m')
```

脚本流程：

1. 读取 `data_sample/Mk01.fjs`。
2. 构造 Mk01 样例 baseline schedule。
3. 创建订单取消事件。
4. 调用阶段 B 提取取消状态。
5. 调用阶段 C 构造局部修复候选。
6. 调用阶段 D 构造完全重调度候选。
7. 调用阶段 E 评价两个候选。
8. 调用阶段 H 输出混合策略选择。
9. 打印 `decision.selected_strategy`、`decision.reason` 和阈值触发结果。

H7 边界：

1. 脚本不写 `outputs/`。
2. 脚本不运行正式多场景实验。
3. 脚本不启动 NSGA-II 长搜索。
4. 脚本只用于验证 H4 混合策略在 Mk01 样例链路上能跑通。

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

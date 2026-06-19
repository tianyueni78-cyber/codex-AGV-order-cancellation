# 项目目标与分阶段工作流

本文档使用 `define-goal` 的方式，把订单取消动态重调度项目拆成可验证的小目标。目标是控制研究范围、减少无关扫描和无效实现，保证每一步都能独立验收。

## 1. 项目结束目标

在原 `codex-AGV` 正常调度代码基础上，完成一个可复现的订单取消动态重调度框架：

```text
给定一个正常 FJSP-AGV 调度计划和一个订单取消事件，
程序能够提取取消时刻状态，
删除被取消订单的未完成任务，
生成局部修复与完全重调度两类候选方案，
计算效率、能耗和计划扰动指标，
并自动选择最终方案。
```

项目结束时应能回答：

1. 订单取消后，局部修复和完全重调度分别适合什么场景。
2. 在当前数据、取消场景、权重和搜索预算下，哪类策略更优。
3. 完工时间改善、能耗变化和计划扰动之间存在什么权衡。

项目结束时不应声称：

1. 证明订单取消问题的全局最优解。
2. 已解决机器故障与订单取消叠加问题。
3. 已完成强化学习调度策略。

## 2. 总体验收标准

项目收口至少满足以下条件：

1. 至少覆盖早期取消、中期取消、后期取消 `3` 类场景。
2. 每个场景都能生成原计划、局部修复方案、完全重调度方案和最终选择方案。
3. 每个候选方案都通过机器、工序和 AGV 约束检查。
4. 被取消订单的未完成任务不再出现在候选计划中。
5. 已完成任务不被重排。
6. 能计算最终卸载完工时间、总能耗、`Cmax_delta`、`SD`、`TD` 和 `Y`。
7. 每个正式场景至少完成 `5` 个随机种子实验。
8. 结果写入 `outputs/`，并有配置、脚本和文档说明如何复现。

## 3. Scope 控制

### 3.1 当前主线包含

1. 单个订单取消。
2. 取消时刻已知。
3. 机器和 AGV 均无故障。
4. 从原正常调度计划出发。
5. 删除被取消订单未完成任务。
6. 比较局部修复与完全重调度。
7. 使用原 `codex-AGV` 的 independent NSGA-II 作为完全重调度基线。

### 3.2 当前主线不包含

1. 机器故障。
2. 多个订单连续取消。
3. 新订单插入。
4. AGV 故障。
5. 取消时刻不确定。
6. 加工时间随机变化。
7. 强化学习。
8. 全局最优证明。

这些内容不是全部“不需要”，而是不能进入第一版主线。是否需要取决于后续论文或项目目标。

### 3.3 后续扩展优先级

| 内容 | 是否建议后续做 | 建议定位 | 原因 |
|---|---|---|---|
| 多个订单连续取消 | 建议做 | 第二阶段扩展 | 与订单取消主题直接相关，可验证事件连续发生时的状态回放和重复重调度能力。 |
| 新订单插入 | 可做 | 第三阶段或对比扩展 | 与订单取消同属任务集合变化，一个是删除任务，一个是新增任务，适合形成“订单变更重调度”统一框架。 |
| 机器故障 | 可做，但不要早做 | 多扰动统一框架 | 机器故障属于资源不可用问题，和订单取消机制不同；应等订单取消闭环稳定后再合并。 |
| AGV 故障 | 可选 | 更高阶资源扰动扩展 | 会引入运输资源不可用和路径/任务重分配，复杂度高，当前不是必要结束条件。 |
| 取消时刻不确定 | 可选 | 鲁棒性或随机扰动扩展 | 需要概率场景或鲁棒评价，适合在确定性取消时刻闭环后再做。 |
| 加工时间随机变化 | 可选 | 鲁棒调度扩展 | 会改变原 FJSP-AGV 问题假设，适合独立建模，不应混入第一版。 |
| 强化学习 | 可选创新 | 自适应策略选择 | 可用于学习选择局部修复、完全重调度、权重或搜索预算；不建议第一版直接用于完整排产。 |
| 全局最优证明 | 通常不作为目标 | 小规模验证或理论补充 | 大规模 FJSP-AGV 很难证明全局最优；可以在小规模实例上用枚举或精确算法做对照下界。 |

因此，第一版结束目标仍然是订单取消重调度闭环；后续优先考虑“多个订单连续取消”和“新订单插入”，再考虑多扰动、鲁棒性或强化学习。

## 4. 分阶段工作流

本项目按 A-F 六个阶段推进。每次只进入一个阶段；当前阶段未验收前，不提前实现后续阶段功能。

### 阶段 A：源码迁移与基线理解

目标：

```text
保留原 codex-AGV 正常调度基线，并识别正常调度调用链。
```

工作计划：

1. 确认 `raw_code/`、`src/`、`configs/`、`scripts/`、`tests/`、`data_sample/` 和 `docs/` 已从原 `codex-AGV` 迁移。
2. 静态阅读 `README.md`、`AGENTS.md`、`docs/00_system_overview/source_code_migration_map.md`。
3. 用 `rg` 精准查找正常调度入口，不递归阅读无关文档。
4. 梳理数据读取、编码、解码、AGV 调度、评价、NSGA-II 搜索、指标和可视化之间的调用关系。
5. 写一份基线调用链导读文档，说明订单取消第一版会复用哪些入口。
6. 在 README 的“关键文档入口”中挂上新增导读文档。

建议新增或更新文档：

```text
docs/00_system_overview/baseline_call_chain_map.md
README.md
```

验收标准：

1. 已迁移原 `codex-AGV` 源码目录。
2. 有源代码导读文档说明数据、编码、解码、搜索、评价、指标、可视化、脚本、测试和原始代码的用途。
3. 有基线调用链文档说明正常调度如何从配置和脚本进入。
4. 暂不新增订单取消算法。

验证方式：

```text
静态检查文档和文件结构。
不运行 MATLAB。
不生成 outputs。
```

停止条件：

```text
如果无法确认正常调度入口，停止在阶段 A，先补入口说明，不进入订单取消事件实现。
```

### 阶段 B：订单取消事件与状态提取

目标：

```text
定义最小订单取消事件，并提取 cancel_time 时刻的调度状态。
```

计划事件字段：

```matlab
cancel.job_id
cancel.cancel_time
cancel.policy
```

第一版策略：

```text
cancel_unstarted_operations_only
```

工作计划：

1. 定义订单取消事件结构，只支持单个订单取消。
2. 实现事件创建函数，统一补齐 `repair` 或机器故障无关字段之外的必要默认值。
3. 实现事件校验函数，检查 `job_id`、`cancel_time` 和 `policy`。
4. 基于正常机器表和 AGV 表，提取 `cancel_time` 时刻状态。
5. 区分已完成、正在加工和尚未开工的工序。
6. 区分已完成和尚未执行的 AGV 任务。
7. 列出被取消订单尚未完成的工序和运输任务。
8. 写轻量测试，先使用构造小样本，再接入迁移数据的烟雾测试。

建议新增文件：

```text
src/cancellation/create_order_cancellation_event.m
src/cancellation/validate_order_cancellation_event.m
src/cancellation/extract_cancellation_state.m
tests/test_order_cancellation_event.m
tests/test_order_cancellation_state.m
scripts/run_order_cancellation_state_smoke.m
docs/00_system_overview/order_cancellation_state_contract.md
```

验收标准：

1. 能识别已完成、正在加工和尚未开工的工序。
2. 能列出被取消订单尚未完成的工序。
3. 能列出被取消订单尚未执行的 AGV 任务。
4. 已完成任务不会进入后续可重调度集合。
5. 能在样例数据上通过烟雾测试。

验证方式：

```text
优先运行轻量测试。
运行 MATLAB 前需要确认。
不启动完整 NSGA-II。
```

停止条件：

```text
如果原调度结果中无法稳定识别 job_id、operation_id 或 AGV 任务所属订单，
先补编号映射说明，不进入局部修复。
```

### 阶段 C：局部修复候选方案

目标：

```text
删除取消订单未完成任务，并构造可行的局部修复计划。
```

工作计划：

1. 从阶段 B 的取消状态中读取冻结任务、取消任务和剩余任务。
2. 删除被取消订单尚未完成的机器工序。
3. 删除被取消订单相关尚未执行的 AGV 运输任务。
4. 保持未取消订单原机器分配和工序顺序。
5. 第一版先实现“删除版局部修复”，不强行做复杂左移。
6. 在删除版可行后，再尝试安全压缩空档或左移剩余任务。
7. 对候选计划做机器、工件和 AGV 约束检查。
8. 写小样本测试覆盖取消订单未完成任务不再出现。

建议新增文件：

```text
src/rescheduling/build_order_cancel_local_repair.m
src/rescheduling/audit_order_cancel_local_repair.m
tests/test_order_cancel_local_repair.m
scripts/run_order_cancel_local_repair_smoke.m
docs/04_decoding/order_cancel_local_repair_plan.md
```

验收标准：

1. 被取消订单的未完成工序不再出现在候选计划中。
2. 被取消订单的未执行 AGV 任务不再出现在候选计划中。
3. 剩余工序满足工件工序顺序。
4. 同一机器无时间冲突。
5. 同一 AGV 无时间冲突。
6. 工序开工不早于工件运输到达。

验证方式：

```text
先用构造小样本测试。
再用一个迁移数据 smoke 脚本验证。
不运行完整正式实验。
```

停止条件：

```text
如果局部修复必须大范围重写原 AGV 解码逻辑，
停止并保留“删除版局部修复”作为第一版基线。
```

### 阶段 D：完全重调度候选方案

目标：

```text
复用 independent 解码和搜索层，对剩余未完成工序重新调度。
```

工作计划：

1. 基于阶段 B 的状态构造订单取消冻结问题。
2. 冻结取消时刻前已完成任务。
3. 排除被取消订单尚未完成任务。
4. 提取未取消订单剩余工序的候选机器、AGV 和速度决策范围。
5. 先实现单个基线染色体解码，确认冻结边界和删除边界正确。
6. 再接入 independent NSGA-II，生成完全重调度候选。
7. 对解码结果做机器、工件、AGV 和最终卸载约束检查。
8. 写轻量测试和 smoke 脚本，不直接进入多随机种子正式实验。

建议新增文件：

```text
src/rescheduling/build_order_cancel_frozen_problem.m
src/rescheduling/decode_order_cancel_complete_reschedule.m
src/rescheduling/search_order_cancel_complete_reschedule.m
tests/test_order_cancel_frozen_problem.m
tests/test_order_cancel_complete_reschedule.m
scripts/run_order_cancel_complete_reschedule_smoke.m
docs/04_decoding/order_cancel_complete_reschedule_plan.md
```

验收标准：

1. 冻结任务保持不变。
2. 被取消的未完成任务被排除。
3. 剩余任务全部且仅出现一次。
4. 剩余任务能解码为可行的 FJSP-AGV 调度计划。
5. 完全重调度候选能输出最终卸载完工时间和总能耗。

验证方式：

```text
先验证单个染色体解码。
再验证小规模搜索。
运行 MATLAB 前需要确认。
```

停止条件：

```text
如果完整 NSGA-II 接入成本过高，
先收口为“冻结问题 + 单候选解码”阶段成果，不硬接搜索。
```

### 阶段 E：评价与策略选择

目标：

```text
比较局部修复和完全重调度，计算统一指标并选择最终方案。
```

指标：

```text
Cmax_delta = 候选最终卸载时间 - 原计划最终卸载时间
SD         = 剩余工序中机器分配发生变化的数量
TD         = 剩余订单完成时间总偏移
Y          = omega1*Cmax_delta + omega2*SD + omega3*TD
```

工作计划：

1. 定义局部修复和完全重调度的统一候选结构。
2. 计算最终卸载完工时间和总能耗。
3. 计算 `Cmax_delta`，衡量最终完工时间变化。
4. 计算 `SD`，衡量剩余工序机器分配变化数量。
5. 计算 `TD`，衡量未取消订单完成时间总偏移。
6. 设置默认权重并计算 `Y`。
7. 选择 `Y` 更小的候选方案作为最终策略。
8. 将原计划、局部修复、完全重调度和最终选择写入同一结果结构。

建议新增文件：

```text
src/evaluation/evaluate_order_cancel_candidate.m
src/evaluation/compute_order_cancel_disruption.m
src/evaluation/select_order_cancel_strategy.m
tests/test_order_cancel_strategy_metrics.m
scripts/run_order_cancel_strategy_smoke.m
docs/05_evaluation/order_cancel_metrics_guide.md
```

验收标准：

1. 能计算 `Cmax_delta`、`SD`、`TD`、能耗和 `Y`。
2. 指标计算有小样本测试。
3. 最终选择 `Y` 更小的候选方案。
4. 结果能写入 `outputs/`。

验证方式：

```text
先使用构造候选结果测试指标。
再接入阶段 C 和阶段 D 的候选结果。
生成 outputs 前需要确认。
```

停止条件：

```text
如果权重选择无法确定，先使用默认权重并在文档中标注敏感性分析待补。
```

### 阶段 F：小规模实验

目标：

```text
运行一组订单取消场景，比较局部修复和完全重调度，并形成初步研究结论。
```

最小场景：

1. 早期取消。
2. 中期取消。
3. 后期取消。

工作计划：

1. 定义 `3` 个取消场景，覆盖早期、中期和后期。
2. 为每个场景固定取消订单、取消时刻、策略和权重。
3. 建立 small 配置和 multiseed 配置。
4. 每个场景先运行单 seed smoke。
5. 单 seed 约束审计通过后，再做 `5` 个随机种子。
6. 汇总每个场景下局部修复和完全重调度的指标。
7. 统计最终策略选择次数、平均指标和最好指标。
8. 写实验结果说明和项目阶段结论。

建议新增文件：

```text
configs/order_cancel_small_config.m
configs/order_cancel_multiseed_config.m
scripts/run_order_cancel_strategy_comparison.m
scripts/run_order_cancel_multiseed_summary.m
docs/06_experiments/order_cancel_experiment_plan.md
docs/06_experiments/order_cancel_result_summary.md
```

验收标准：

1. 每个场景同时报告局部修复和完全重调度。
2. 每个场景均通过调度约束检查。
3. 每个正式场景至少 `5` 个随机种子。
4. 多随机种子汇总后再形成研究结论。
5. 输出写入 `outputs/`，且有配置和脚本可复现。

验证方式：

```text
先 smoke，后 multiseed。
运行 MATLAB 和生成 outputs 前需要确认。
```

停止条件：

```text
如果单场景约束审计未通过，不进入多随机种子正式实验。
```

## 5. Token 和范围控制规则

每次任务只打开必要文件：

1. 先读 `README.md`、`AGENTS.md` 和本目标文档。
2. 只读当前阶段相关目录。
3. 搜索优先使用 `rg` 精准查找入口和函数名。
4. 不递归分析无关文档。
5. 不扫描 `raw_code/` 全量内容，除非当前任务明确需要对照原始函数。

每次实现只做一个小目标：

1. 阶段 A 只整理调用链，不写算法。
2. 阶段 B 只定义事件和提取状态，不生成方案。
3. 阶段 C 只做局部修复，不接 NSGA-II。
4. 阶段 D 只做完全重调度候选，不做指标选择。
5. 阶段 E 只做指标与选择，不扩展场景。
6. 阶段 F 才做多场景多种子。

## 6. 强化学习定位

强化学习不是当前主线，也不是项目结束条件。

后续如果前述闭环稳定，可以把强化学习作为扩展方向，用于自适应选择：

1. 局部修复。
2. 完全重调度。
3. 不同 `omega` 权重。
4. 不同搜索预算。

但在第一版订单取消研究中，主线仍然是：

```text
事件触发式重调度 + 局部修复 + 受限 NSGA-II + 扰动度量选择
```

## 7. README 入口规则

后续凡是新增重要项目文档，都必须在 `README.md` 的“关键文档入口”中增加链接，避免文档散落后找不到。

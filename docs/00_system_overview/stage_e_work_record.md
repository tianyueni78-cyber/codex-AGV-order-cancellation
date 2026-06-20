# 阶段 E 工作记录：评价与策略选择

本文档记录阶段 E 的目标、输入契约、指标定义、`Y` 计算方式、策略选择规则、新增文件、测试入口、smoke 输出位置和阶段 F 入口说明。阶段 E 第一版只做小样例策略选择，不是正式实验，不形成研究结论。

## 1. 阶段目标

阶段 E 的目标是：

```text
比较局部修复和完全重调度。
```

阶段 E 第一版完成范围：

1. 评价阶段 C 的局部修复候选。
2. 评价阶段 D 的完全重调度候选。
3. 计算 `Cmax_delta`、`SD`、`TD`、能耗和 `Y`。
4. 选择 `Y` 更小的候选方案。
5. 在 smoke 脚本中把结果写入 `outputs/`。

阶段 E 不包含：

1. 不做多随机种子正式实验。
2. 不形成研究结论。
3. 不引入强化学习。
4. 不处理新订单插入。
5. 不处理机器故障。

## 2. 输入契约

阶段 E 输入：

```matlab
problem
machineData
agvData
baselineSchedule
localRepairCandidate
completeReschedulingCandidate
cancel
config
```

其中：

1. `baselineSchedule` 是订单取消前的原正常调度计划。
2. `localRepairCandidate` 来自阶段 C。
3. `completeReschedulingCandidate` 来自阶段 D。
4. 两个候选进入评价前必须已经通过各自阶段的可行性检查。
5. 阶段 E 不修改候选计划，不重新解码，不重新搜索。

完整契约见：

```text
docs/00_system_overview/stage_e_evaluation_contract.md
```

## 3. 指标定义

阶段 E 第一版指标：

| 指标 | 含义 |
|---|---|
| `Cmax` | 候选计划最大完工时间 |
| `Cmax_delta` | 候选 `Cmax` 减去原正常计划 `baseline Cmax` |
| `SD` | 未取消订单机器工序开始时间变化绝对值之和 |
| `TD` | 未取消订单 AGV 运输任务开始时间变化绝对值之和 |
| `energy` | 候选计划总能耗 |
| `energy_delta` | 候选能耗减去原正常计划能耗 |
| `Y` | 综合评价值，越小越好 |

`Cmax` 口径：

```matlab
Cmax = max(all real machine operation end times)
```

`SD` 口径：

```matlab
SD = sum(abs(candidate_start - baseline_start))
```

只统计未取消订单机器工序，空闲块不参与。

`TD` 口径：

```matlab
TD = sum(abs(candidate_transport_start - baseline_transport_start))
```

只统计未取消订单真实 AGV 工序运输任务，空闲、充电或辅助运输块不参与。真实 AGV 工序运输任务第一版定义为：

```matlab
job > 0 && opera > 0
```

取消订单已完成的 AGV 历史运输允许保留，但不计入 `TD`；取消订单未完成的真实 AGV 工序运输如果回流到候选计划，评价会拒绝。

能耗口径：

1. 机器能耗复用 `compute_machine_energy`。
2. 有 `agvEGRecord` 时 AGV 能耗复用 `compute_agv_energy`。
3. 无 `agvEGRecord` 时使用第一版简化 AGVTable 时长估计，并记录 `AGVTable_simplified`。

## 4. Y 的计算方式

第一版综合评价：

```matlab
Y = w1 * normalize(Cmax_delta)
  + w2 * normalize(SD)
  + w3 * normalize(TD)
  + w4 * normalize(energy_delta)
```

权重来自：

```matlab
config.weights.Cmax_delta
config.weights.SD
config.weights.TD
config.weights.energy_delta
```

归一化：

1. 两个候选使用同一套归一化口径。
2. 第一版使用两个候选共同 min-max。
3. 如果某个指标两个候选相同，分母为 `0`，归一化值设为 `0`。

方向：

```text
Y 越小越好。
```

## 5. 策略选择规则

策略选择函数：

```text
src/cancellation/select_order_cancellation_strategy.m
```

选择规则：

1. 两个候选都可行：选择 `Y` 更小者。
2. 只有一个候选可行：选择可行者。
3. 两个候选都不可行：拒绝选择。
4. `Y` 相同：第一版选择局部修复，因为删除式局部修复更保守、扰动更容易解释。

## 6. 新增文件清单

阶段 E 文档：

```text
docs/00_system_overview/stage_e_evaluation_contract.md
docs/00_system_overview/stage_e_work_record.md
```

阶段 E 源码：

```text
src/cancellation/evaluate_candidate_cmax.m
src/cancellation/evaluate_candidate_sd.m
src/cancellation/evaluate_candidate_td.m
src/cancellation/evaluate_candidate_energy.m
src/cancellation/evaluate_order_cancellation_candidate.m
src/cancellation/select_order_cancellation_strategy.m
```

阶段 E 测试：

```text
tests/test_order_cancellation_evaluation_cmax.m
tests/test_order_cancellation_evaluation_sd.m
tests/test_order_cancellation_evaluation_td.m
tests/test_order_cancellation_evaluation_energy.m
tests/test_order_cancellation_candidate_evaluation.m
tests/test_order_cancellation_strategy_selection.m
tests/test_order_cancellation_evaluation_pipeline.m
```

阶段 E smoke 脚本：

```text
scripts/run_order_cancellation_strategy_selection_smoke.m
```

## 7. 测试入口

单项指标测试：

```matlab
run('tests/test_order_cancellation_evaluation_cmax.m')
run('tests/test_order_cancellation_evaluation_sd.m')
run('tests/test_order_cancellation_evaluation_td.m')
run('tests/test_order_cancellation_evaluation_energy.m')
```

候选评价与选择测试：

```matlab
run('tests/test_order_cancellation_candidate_evaluation.m')
run('tests/test_order_cancellation_strategy_selection.m')
run('tests/test_order_cancellation_evaluation_pipeline.m')
```

样例数据 smoke 入口：

```matlab
run('scripts/run_order_cancellation_strategy_selection_smoke.m')
```

注意：smoke 脚本会写入 `outputs/`，运行前需要确认。

## 8. smoke 输出结果

E12 pipeline 测试已由用户在 MATLAB 中运行通过：

```text
test_order_cancellation_evaluation_pipeline passed
```

TD 单项测试在修正 AGV 辅助运输块口径后已由用户在 MATLAB 中运行通过：

```text
test_order_cancellation_evaluation_td passed
```

E13 样例数据策略选择 smoke 已由用户在 MATLAB 中运行通过。运行入口：

```matlab
run('scripts/run_order_cancellation_strategy_selection_smoke.m')
```

控制台输出：

```text
order cancellation strategy selection smoke
dataset: data_sample/Mk01.fjs
cancel.job_id: 2
cancel.cancel_time: 10.000000
cancel.policy: cancel_unstarted_operations_only
completed_operations: 3
cancelled_unfinished_operations: 1
remaining_unfinished_operations: 2
local_candidate.isFeasible: 1
complete_candidate.isFeasible: 1
local_repair.isFeasible: 1
local_repair.Cmax_delta: 0.000000
local_repair.SD: 0.000000
local_repair.TD: 0.000000
local_repair.energy: 62.400000
local_repair.energy_delta: -11.600000
local_repair.Y: 0.500000
complete_rescheduling.isFeasible: 1
complete_rescheduling.Cmax_delta: -2.000000
complete_rescheduling.SD: 3.333333
complete_rescheduling.TD: 0.000000
complete_rescheduling.energy: 60.366667
complete_rescheduling.energy_delta: -13.633333
complete_rescheduling.Y: 0.250000
selected.isSelected: 1
selected.name: complete_rescheduling
selected.reason: smaller_Y
selected.Y: 0.250000
output_dir: D:\CODEX\code_refactor_project\codex-AGV-order-cancellation\outputs\order_cancellation_strategy_selection\20260620_222023
summary_json: D:\CODEX\code_refactor_project\codex-AGV-order-cancellation\outputs\order_cancellation_strategy_selection\20260620_222023\summary.json
metrics_csv: D:\CODEX\code_refactor_project\codex-AGV-order-cancellation\outputs\order_cancellation_strategy_selection\20260620_222023\metrics.csv
selected_strategy_txt: D:\CODEX\code_refactor_project\codex-AGV-order-cancellation\outputs\order_cancellation_strategy_selection\20260620_222023\selected_strategy.txt
```

结果含义：

1. 阶段 B 识别出 3 个已完成机器工序、1 个被取消订单未完成工序、2 个未取消订单剩余未完成工序。
2. 阶段 C 生成的局部修复候选可行，阶段 D 生成的完全重调度候选也可行。
3. 局部修复候选相对基线 `Cmax_delta = 0`、`SD = 0`、`TD = 0`，说明删除式局部修复不改变未取消订单的机器和 AGV 开始时间。
4. 完全重调度候选 `Cmax_delta = -2`，说明样例中最大完工时间比原正常计划提前 2 个时间单位；`SD = 3.333333` 表示机器工序开始时间有扰动；`TD = 0` 表示真实 AGV 工序运输开始时间未产生扰动。
5. 完全重调度候选能耗为 `60.366667`，低于局部修复候选 `62.400000`。
6. 综合评价 `Y` 越小越好，本次 `complete_rescheduling.Y = 0.250000` 小于 `local_repair.Y = 0.500000`，因此最终选择 `complete_rescheduling`。
7. `selected.reason = smaller_Y` 表示两个候选都可行时，策略选择函数按更小的 `Y` 做出选择。

## 9. E13 输出数据分析

本节只分析 `data_sample/Mk01.fjs`、`cancel.job_id = 2`、`cancel.cancel_time = 10` 这一组 smoke 结果，不作为正式研究结论。

`metrics.csv` 中两种候选的核心结果为：

| 策略 | 可评价 | `Cmax` | `Cmax_delta` | `SD` | `TD` | `energy` | `energy_delta` | `Y` |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `local_repair` | 1 | 18.000000 | 0.000000 | 0.000000 | 0.000000 | 62.400000 | -11.600000 | 0.500000 |
| `complete_rescheduling` | 1 | 16.000000 | -2.000000 | 3.333333 | 0.000000 | 60.366667 | -13.633333 | 0.250000 |

对比解释：

1. 两个候选 `isFeasible = 1`，说明阶段 E 不是在“可行与不可行”之间选择，而是在两个可行候选之间按综合指标选择。
2. `local_repair` 的 `SD = 0`、`TD = 0`，符合删除式局部修复的设计：只删除取消订单未完成任务，不移动未取消订单的机器工序和真实 AGV 工序运输。
3. `local_repair.Cmax_delta = 0`，说明局部修复没有改善原计划最大完工时间；它的优势是扰动最小，劣势是没有利用订单取消释放出来的时间窗口。
4. `complete_rescheduling.Cmax = 16`，比 `local_repair.Cmax = 18` 少 2 个时间单位；`Cmax_delta = -2` 表明完全重调度在该样例中利用取消订单释放的资源，把剩余任务排得更早。
5. `complete_rescheduling.SD = 3.333333`，说明完全重调度通过改变未取消订单机器工序开始时间换取了更短的最大完工时间。这是一个典型权衡：效率更好，但计划扰动更大。
6. 两个候选的 `TD = 0`，说明本次完全重调度没有改变真实 AGV 工序运输的开始时间，或者 AGV 运输扰动在当前 TD 口径下没有增加。
7. 两个候选的 `energy_delta` 都为负，说明取消订单后两种策略相对原正常计划都降低了能耗；完全重调度 `energy = 60.366667`，低于局部修复 `62.400000`，因此在能耗维度也更优。
8. 本次 `Y` 使用两个候选共同 min-max 归一化和等权重。完全重调度在 `Cmax_delta` 和 `energy_delta` 上更优，在 `SD` 上更差，`TD` 相同；综合后 `Y = 0.250000` 小于局部修复 `Y = 0.500000`。
9. 因此，本次 smoke 选择 `complete_rescheduling` 的直接原因是：它虽然带来一定机器调度扰动，但同时缩短了最大完工时间并降低了能耗，综合评价更优。

局限说明：

1. 该结果只来自一个小样例、一个取消时刻和一个取消订单。
2. 当前完全重调度候选使用第一版构造方式，不代表已经完成多随机种子搜索或全局最优证明。
3. 当前 `energy` 在没有 `agvEGRecord` 时使用简化 AGVTable 时长估计，适合 smoke 比较，但正式实验需要在阶段 F 中继续说明和统一口径。
4. 当前 `Y` 的选择受权重和归一化方式影响。阶段 F 做多场景实验时，应同时报告原始指标和 `Y`，避免只用单个综合分数下结论。
5. 该 smoke 只能说明阶段 E 的评价与策略选择链路已跑通，不能说明完全重调度在所有订单取消场景下都优于局部修复。

## 10. outputs 结果含义

E13 smoke 写入：

```text
outputs/order_cancellation_strategy_selection/<timestamp>/summary.json
outputs/order_cancellation_strategy_selection/<timestamp>/metrics.csv
outputs/order_cancellation_strategy_selection/<timestamp>/selected_strategy.txt
```

`summary.json` 含义：

1. 记录数据集、取消事件、权重、归一化参数。
2. 记录阶段 B 状态计数。
3. 记录两个候选是否可行。
4. 记录两个候选的评价结果。
5. 记录最终选择结果。
6. 记录 scope 标记，说明不是正式实验、不是多随机种子、没有启动 NSGA-II。

`metrics.csv` 含义：

1. 每行对应一个候选策略。
2. 包含 `Cmax`、`Cmax_delta`、`SD`、`TD`、`energy`、`energy_delta` 和 `Y`。
3. 可用于快速比较局部修复与完全重调度。

`selected_strategy.txt` 含义：

1. 记录是否成功选出策略。
2. 记录被选中的策略名称。
3. 记录选择原因。
4. 记录被选中策略的 `Y`。

## 11. 阶段 E 完成标志

阶段 E 完成标志：

```text
已经能在小样例上同时评价局部修复候选和完全重调度候选，
计算 Cmax_delta、SD、TD、能耗和 Y，
并选择 Y 更小的订单取消处理策略，
同时把结果写入 outputs/。
```

当前状态：

1. E1-E13 文件和入口已建立。
2. E12 pipeline 测试已通过。
3. E13 smoke 已在 `data_sample/Mk01.fjs` 上运行通过，并已写入 `outputs/`。
4. E15 静态验收已完成。
5. 阶段 E 仍是小样例策略选择，不是正式实验。

## 12. 阶段 E 静态验收

Step E15 静态验收结果：

1. 能计算 `Cmax_delta`：`src/cancellation/evaluate_candidate_cmax.m` 已实现，`evaluate_order_cancellation_candidate.m` 已组合调用。
2. 能计算 `SD`：`src/cancellation/evaluate_candidate_sd.m` 已实现，统计未取消订单机器工序开始时间扰动。
3. 能计算 `TD`：`src/cancellation/evaluate_candidate_td.m` 已实现，统计未取消订单 AGV 运输任务开始时间扰动。
4. 能计算能耗：`src/cancellation/evaluate_candidate_energy.m` 已实现，机器能耗复用 `compute_machine_energy`，AGV 能耗优先复用 `compute_agv_energy`，缺少 `agvEGRecord` 时使用简化口径。
5. 能计算 `Y`：`src/cancellation/evaluate_order_cancellation_candidate.m` 已实现，权重来自 `config.weights`，归一化来自 `config.normalization`。
6. 能选择 `Y` 更小的候选：`src/cancellation/select_order_cancellation_strategy.m` 已实现。
7. 结果能写入 `outputs/`：`scripts/run_order_cancellation_strategy_selection_smoke.m` 已建立，写入 `summary.json`、`metrics.csv` 和 `selected_strategy.txt`。
8. 没有多随机种子正式实验：E13 smoke 中 `summary.scope.multiseed = false`，没有阶段 F 批量实验入口。
9. 没有强化学习：阶段 E 新增源码、测试和 smoke 脚本没有强化学习逻辑。
10. 没有新订单插入：阶段 E 新增源码、测试和 smoke 脚本没有新订单插入逻辑。
11. 没有机器故障逻辑：阶段 E 新增源码、测试和 smoke 脚本没有机器故障处理逻辑。
12. `raw_code/` 无修改。
13. `git diff --check` 通过。

本次静态验收没有由 Codex 运行 MATLAB。E12、TD 单测和 E13 smoke 由用户在 MATLAB 中运行，其中 E13 smoke 已生成 `outputs/order_cancellation_strategy_selection/20260620_222023/`。

阶段 E 当前完成标志：

```text
已经能在小样例上同时评价局部修复候选和完全重调度候选，
计算 Cmax_delta、SD、TD、能耗和 Y，
并选择 Y 更小的订单取消处理策略，
同时把结果写入 outputs/。
```

## 13. 阶段 F 入口说明

阶段 F 才进入小规模实验。

阶段 F 可接入内容：

1. 阶段 B 的取消状态提取。
2. 阶段 C 的局部修复候选。
3. 阶段 D 的完全重调度候选。
4. 阶段 E 的评价和策略选择。

阶段 F 应新增：

1. 早期取消场景。
2. 中期取消场景。
3. 后期取消场景。
4. 多随机种子汇总。
5. 汇总表和研究结论。

阶段 E 不负责这些正式实验内容。

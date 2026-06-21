# 阶段 F 工作计划：小规模订单取消实验

> 本文档已不再作为阶段 F 的主要阅读入口。阶段 F 的计划、运行入口、实验结果、结论和局限已整合到 [阶段 F 项目报告](stage_f_project_report.md)。本文档仅保留为历史过程记录。

本文档定义阶段 F 的工作计划。阶段 F 是订单取消问题第一版闭环中的小规模实验阶段，不是整个项目的最终阶段。A-F 的目标是先跑通“单订单取消 -> 状态提取 -> 两类候选 -> 评价选择 -> 小规模验证”的最小研究闭环；后续仍可继续扩展多订单连续取消、新订单插入、机器故障、AGV 故障、随机扰动、强化学习或更大规模实验。

## 1. 阶段 F 目标

阶段 F 目标：

```text
运行一组订单取消场景。
```

最小场景：

1. 早期取消。
2. 中期取消。
3. 后期取消。

验收标准：

1. 每个场景同时报告局部修复和完全重调度。
2. 每个场景均通过调度约束检查。
3. 多随机种子汇总后再形成研究结论。

## 2. 阶段 F 输入

阶段 F 复用阶段 B-E 的输出和函数：

```matlab
problem
machineData
agvData
baselineSchedule
cancel
state
localRepairCandidate
completeReschedulingCandidate
localEvaluation
completeEvaluation
selection
config
```

来源说明：

1. `problem` 来自样例数据读取。
2. `baselineSchedule` 来自正常调度计划或可复现的样例计划。
3. `cancel` 由场景配置生成。
4. `state` 来自阶段 B。
5. `localRepairCandidate` 来自阶段 C。
6. `completeReschedulingCandidate` 来自阶段 D。
7. `localEvaluation`、`completeEvaluation` 和 `selection` 来自阶段 E。

## 3. 阶段 F 输出

建议输出目录：

```text
outputs/order_cancellation_small_experiment/<timestamp>/
```

建议输出文件：

```text
scenario_results.csv
seed_results.csv
summary.json
selected_strategy_counts.csv
experiment_notes.md
```

字段建议：

| 字段 | 含义 |
|---|---|
| `scenario_name` | 早期、中期或后期取消 |
| `seed` | 随机种子 |
| `cancel_job_id` | 被取消订单编号 |
| `cancel_time` | 取消时刻 |
| `local_isFeasible` | 局部修复候选是否可评价 |
| `complete_isFeasible` | 完全重调度候选是否可评价 |
| `local_Cmax_delta` | 局部修复最大完工时间变化 |
| `complete_Cmax_delta` | 完全重调度最大完工时间变化 |
| `local_SD` / `complete_SD` | 机器工序扰动 |
| `local_TD` / `complete_TD` | AGV 运输扰动 |
| `local_energy_delta` | 局部修复能耗变化 |
| `complete_energy_delta` | 完全重调度能耗变化 |
| `local_Y` / `complete_Y` | 综合评价值 |
| `selected_strategy` | 最终选择策略 |
| `selected_reason` | 选择原因 |

## 4. Step F1：确认实验范围

目标：明确阶段 F 只做小规模订单取消实验。

工作内容：

1. 确认不加入机器故障。
2. 确认不加入新订单插入。
3. 确认不加入多个订单连续取消。
4. 确认不加入强化学习。
5. 确认不追求全局最优证明。

验收标准：

1. 实验对象仍是单订单取消。
2. 实验入口只调用阶段 B-E 已有链路。
3. 不新增新的调度算法主线。

## 5. Step F2：定义取消场景配置

目标：把早期、中期、后期取消写成可复现配置。

已新增：

```text
configs/order_cancellation_small_experiment.yaml
```

当前字段：

```yaml
dataset: data_sample/Mk01.fjs
cancel_policy: cancel_unstarted_operations_only
cancel_time_source: baseline_Cmax_ratio
scenarios:
  - name: early_cancel
    cancel_time_ratio: 0.25
  - name: middle_cancel
    cancel_time_ratio: 0.50
  - name: late_cancel
    cancel_time_ratio: 0.75
seeds: [1, 2, 3]
output_base_dir: outputs/order_cancellation_small_experiment
```

字段说明：

1. `dataset` 使用相对路径，不写死本机绝对路径。
2. `cancel_policy` 延续阶段 B 的 `cancel_unstarted_operations_only`。
3. `cancel_time_source = baseline_Cmax_ratio` 表示后续脚本用基线 `Cmax` 乘 `cancel_time_ratio` 得到取消时刻。
4. `scenarios` 包含早期、中期、后期三个取消场景。
5. `seeds` 明确小规模实验第一版使用 `1, 2, 3` 三个随机种子。
6. `output_base_dir` 指向阶段 F 输出根目录，后续脚本应在其下创建 `<timestamp>` 子目录。

验收标准：

1. 三个场景名称明确。
2. 取消时刻可由基线 `Cmax` 或固定样例时间换算得到。
3. 多随机种子列表明确。
4. 配置不写死本机绝对路径。

Step F2 静态验收结果：

1. `configs/order_cancellation_small_experiment.yaml` 已存在。
2. 已定义 `early_cancel`、`middle_cancel`、`late_cancel` 三个场景。
3. 已使用 `baseline_Cmax_ratio` 说明取消时刻换算口径。
4. 已定义随机种子 `[1, 2, 3]`。
5. 所有路径均为相对路径。
6. 本步骤未运行 MATLAB，未生成 `outputs/`，未修改 `raw_code/`。

## 6. Step F3：构造单场景运行函数

目标：对一个场景和一个随机种子运行阶段 B-E。

已新增：

```text
src/cancellation/run_order_cancellation_scenario.m
```

函数入口：

```matlab
result = run_order_cancellation_scenario( ...
    problem, machineData, agvData, baselineSchedule, ...
    scenario, seed, config)
```

流程：

1. 读取或接收 `problem`、`machineData`、`agvData` 和 `baselineSchedule`。
2. 根据场景生成 `cancel`。
3. 调用阶段 B 提取 `state`。
4. 调用阶段 C 构造 `localRepairCandidate`。
5. 调用阶段 D 构造 `completeReschedulingCandidate`。
6. 调用阶段 E 评价两个候选。
7. 调用阶段 E 选择策略。
8. 返回一行结构化结果。

输出结果包含：

```text
scenario_name
seed
cancel_job_id
cancel_time
local_candidate_isFeasible
complete_candidate_isFeasible
local_isFeasible
complete_isFeasible
local_Cmax_delta
complete_Cmax_delta
local_SD
complete_SD
local_TD
complete_TD
local_energy_delta
complete_energy_delta
local_Y
complete_Y
selected_strategy
selected_reason
selected_Y
details
```

说明：

1. `scenario.cancel_time` 可直接给定取消时刻。
2. 如果只给 `scenario.cancel_time_ratio`，函数用 `baseline_Cmax * cancel_time_ratio` 换算取消时刻。
3. `details` 保留 `cancel`、`state`、两个候选、两个评价结果和最终选择，便于后续调试。
4. 函数内部第一版使用确定性的 first-choice 染色体构造完全重调度候选，不启动正式 NSGA-II 长实验。
5. 函数不写 `outputs/`，由后续 Step F5/F6 的脚本负责落盘。

验收标准：

1. 一个场景能同时产生局部修复和完全重调度结果。
2. 两个候选的可行性检查结果被记录。
3. 不在单场景函数里写 `outputs/`。
4. 不启动正式 NSGA-II 长实验。

Step F3 静态验收结果：

1. `src/cancellation/run_order_cancellation_scenario.m` 已存在。
2. 函数入口接收 `problem`、`machineData`、`agvData`、`baselineSchedule`、`scenario`、`seed` 和 `config`。
3. 函数串联阶段 B-E 已有链路。
4. 函数返回一行结构化 `result`，并记录两个候选的可行性和评价指标。
5. 函数没有写 `outputs/`。
6. 函数没有调用正式 NSGA-II 长实验入口。
7. 本步骤未运行 MATLAB，未生成 `outputs/`，未修改 `raw_code/`。

## 7. Step F4：场景约束检查

目标：确保每个场景候选都通过调度约束检查，或清楚记录不可行原因。

复用检查函数：

```text
check_machine_table_feasibility.m
check_agv_table_feasibility.m
check_job_operation_sequence.m
check_complete_rescheduling_candidate.m
```

验收标准：

1. 每个局部修复候选报告机器冲突检查。
2. 每个局部修复候选报告 AGV 冲突检查。
3. 每个局部修复候选报告工件工序顺序检查。
4. 每个完全重调度候选报告冻结一致性检查。
5. 每个完全重调度候选报告取消任务排除检查。
6. 不可行时写明 `rejectedReasons`。
7. 不可行时保留 `errors` 计数。

已在单场景结果中记录的检查字段：

```text
local_machine_check_isFeasible
local_agv_check_isFeasible
local_job_sequence_check_isFeasible
complete_machine_check_isFeasible
complete_agv_check_isFeasible
complete_job_sequence_check_isFeasible
complete_frozen_check_isFeasible
complete_cancelled_exclusion_check_isFeasible
local_rejectedReasons
complete_rejectedReasons
local_error_count
complete_error_count
```

Step F4 静态验收结果：

1. 局部修复候选的机器冲突检查结果已从 `localCandidate.report.machineConflictCheck` 提取。
2. 局部修复候选的 AGV 冲突检查结果已从 `localCandidate.report.agvConflictCheck` 提取。
3. 局部修复候选的工件工序顺序检查结果已从 `localCandidate.report.jobSequenceCheck` 提取。
4. 完全重调度候选的机器、AGV、工序顺序、冻结一致性和取消任务排除检查结果已从 `completeCandidate.report.completeFeasibilityCheck` 提取。
5. 单场景结果已记录 `local_rejectedReasons` 和 `complete_rejectedReasons`。
6. 单场景结果已记录 `local_error_count` 和 `complete_error_count`。
7. 本步骤未运行 MATLAB，未生成 `outputs/`，未修改 `raw_code/`。

## 8. Step F5：实现小规模实验脚本

目标：串联多个场景和多个随机种子。

已新增：

```text
scripts/run_order_cancellation_small_experiment.m
```

运行入口：

```matlab
run('scripts/run_order_cancellation_small_experiment.m')
```

注意：该脚本会写入 `outputs/`，运行 MATLAB 前需要确认。

脚本行为：

1. 读取 `configs/order_cancellation_small_experiment.yaml`。
2. 读取 `data_sample/Mk01.fjs`。
3. 构造与阶段 E smoke 一致的小样例 `machineData`、`agvData` 和 `baselineSchedule`。
4. 遍历 `early_cancel`、`middle_cancel`、`late_cancel`。
5. 遍历随机种子 `[1, 2, 3]`。
6. 每次调用 `run_order_cancellation_scenario(...)`。
7. 在 `outputs/order_cancellation_small_experiment/<timestamp>/` 下写入基础结果。

当前 F5 基础输出：

```text
seed_results.csv
selected_strategy_counts.csv
run_summary.txt
```

说明：Step F6 已补齐 `scenario_results.csv`、`summary.json` 和 `experiment_notes.md` 的完整落盘口径。

验收标准：

1. 能遍历早期、中期、后期取消。
2. 能遍历多随机种子。
3. 每次运行都记录局部修复和完全重调度指标。
4. 每次运行都记录最终选择策略。
5. 不覆盖已有 timestamp 输出目录。

Step F5 静态验收结果：

1. `scripts/run_order_cancellation_small_experiment.m` 已存在。
2. 脚本读取阶段 F 小规模实验配置。
3. 脚本遍历早期、中期、后期取消场景。
4. 脚本遍历配置中的多个随机种子。
5. 脚本每次运行调用阶段 F3 单场景函数，并记录局部修复和完全重调度指标。
6. 脚本每次运行记录最终选择策略。
7. 脚本使用 timestamp 输出目录，避免覆盖旧结果。
8. 本步骤未运行 MATLAB，未生成 `outputs/`，未修改 `raw_code/`。

## 9. Step F6：结果落盘

目标：把每个场景和每个随机种子的结果写入 `outputs/`。

已实现输出：

```text
outputs/order_cancellation_small_experiment/<timestamp>/scenario_results.csv
outputs/order_cancellation_small_experiment/<timestamp>/seed_results.csv
outputs/order_cancellation_small_experiment/<timestamp>/summary.json
outputs/order_cancellation_small_experiment/<timestamp>/selected_strategy_counts.csv
outputs/order_cancellation_small_experiment/<timestamp>/experiment_notes.md
```

输出说明：

1. `scenario_results.csv` 按场景汇总均值、可行数量和策略选择次数。
2. `seed_results.csv` 保留每个场景、每个随机种子的原始运行结果。
3. `summary.json` 记录配置、数据集、权重、归一化说明和 scope。
4. `selected_strategy_counts.csv` 统计每类策略被选中的次数。
5. `experiment_notes.md` 说明本次实验范围和解释边界。

验收标准：

1. `scenario_results.csv` 汇总每个场景的均值。
2. `seed_results.csv` 保留每个随机种子的原始结果。
3. `summary.json` 记录配置、数据集、权重、归一化和 scope。
4. `selected_strategy_counts.csv` 统计每类策略被选中的次数。
5. `experiment_notes.md` 说明本次实验不是最终结论。

Step F6 静态验收结果：

1. `scripts/run_order_cancellation_small_experiment.m` 已写入 `scenario_results.csv`。
2. `scripts/run_order_cancellation_small_experiment.m` 已写入 `seed_results.csv`。
3. `scripts/run_order_cancellation_small_experiment.m` 已写入 `summary.json`。
4. `scripts/run_order_cancellation_small_experiment.m` 已写入 `selected_strategy_counts.csv`。
5. `scripts/run_order_cancellation_small_experiment.m` 已写入 `experiment_notes.md`。
6. 输出目录使用 `outputs/order_cancellation_small_experiment/<timestamp>/`，不会覆盖旧输出目录。
7. 本步骤未运行 MATLAB，未生成 `outputs/`，未修改 `raw_code/`。

## 10. Step F7：小规模实验测试

目标：先用最小构造数据验证汇总逻辑，不跑正式实验。

已新增：

```text
tests/test_order_cancellation_small_experiment_summary.m
```

测试内容：

1. 三个场景能被识别。
2. 多个 seed 结果能汇总。
3. 可行候选数量能统计。
4. 策略选择次数能统计。
5. 均值指标能计算。

验收标准：

1. 测试不写 `outputs/`。
2. 测试不运行完整 NSGA-II。
3. 测试只验证汇总逻辑。

Step F7 静态验收结果：

1. `src/cancellation/summarize_order_cancellation_results.m` 已新增为纯汇总函数。
2. `tests/test_order_cancellation_small_experiment_summary.m` 已新增。
3. 测试使用最小构造数据覆盖三个场景识别。
4. 测试使用多个 seed 行覆盖多随机种子汇总。
5. 测试覆盖可行候选数量统计。
6. 测试覆盖策略选择次数统计。
7. 测试覆盖均值指标计算。
8. 测试不写 `outputs/`。
9. 测试不调用完整 NSGA-II。
10. 本步骤未运行 MATLAB，未生成 `outputs/`，未修改 `raw_code/`。

## 11. Step F8：运行小规模实验

目标：在确认后运行阶段 F 实验脚本。

运行入口：

```matlab
run('scripts/run_order_cancellation_small_experiment.m')
```

验收标准：

1. 早期取消有结果。
2. 中期取消有结果。
3. 后期取消有结果。
4. 每个场景同时报告局部修复和完全重调度。
5. 每个场景均通过调度约束检查，或清楚报告不可行原因。
6. 多随机种子结果写入 `outputs/`。

## 12. Step F9：实验结果分析

目标：基于多随机种子汇总结果形成第一版小规模结论。

分析维度：

1. 哪些场景更倾向选择局部修复。
2. 哪些场景更倾向选择完全重调度。
3. 完全重调度是否稳定降低 `Cmax`。
4. 完全重调度是否带来更大 `SD` 或 `TD`。
5. 能耗变化是否稳定。
6. 不可行案例来自哪类约束。

验收标准：

1. 只基于多随机种子汇总结果下结论。
2. 结论同时报告原始指标和 `Y`。
3. 不声称全局最优。
4. 不把单个 smoke 结果当作研究结论。

已新增分析模板：

```text
docs/00_system_overview/stage_f_result_analysis_template.md
```

Step F9 当前状态：

1. 分析模板已建立。
2. Step F8 已运行，输出目录为 `outputs/order_cancellation_small_experiment/20260621_094024/`。
3. 已读取 `scenario_results.csv`、`seed_results.csv` 和 `selected_strategy_counts.csv`。
4. 已形成阶段 F 项目报告：`docs/00_system_overview/stage_f_project_report.md`。
5. 报告覆盖策略倾向、`Cmax`、`SD`、`TD`、能耗和不可行约束来源。
6. 当前 CSV 未保存详细 `rejectedReasons`，因此早期和后期取消的不可行原因只能记录为 `no_feasible_candidate`，不能进一步归因。
7. 本步骤未修改 `raw_code/`。

## 13. Step F10：阶段 F 工作记录

目标：记录阶段 F 做了什么、输出在哪里、结果说明和局限。

已新增：

```text
docs/00_system_overview/stage_f_work_record.md
```

文档必须包含：

1. 阶段 F 目标。
2. 实验配置。
3. 场景定义。
4. 随机种子设置。
5. 新增文件清单。
6. 测试入口。
7. 实验入口。
8. 输出目录。
9. 汇总结果。
10. 小规模结论。
11. 局限说明。
12. 后续扩展入口。

验收标准：

1. README 挂上阶段 F 工作记录入口。
2. 文档说明阶段 F 是小规模实验，不是最终大规模结论。
3. 文档说明后续扩展方向。

Step F10 当前状态：

1. 阶段 F 工作记录已建立。
2. README 已挂阶段 F 工作记录入口。
3. 工作记录已说明实验配置、场景定义、随机种子、测试入口、实验入口和输出目录。
4. 工作记录已说明汇总结果和小规模结论需要等待 Step F8 运行后填写。
5. 工作记录已说明阶段 F 是小规模实验，不是最终大规模结论。
6. 工作记录已说明后续扩展方向。
7. 本步骤未运行 MATLAB，未生成 `outputs/`，未修改 `raw_code/`。

## 14. 阶段 F 静态验收

阶段 F 完成前应检查：

1. 小规模实验配置存在。
2. 单场景运行函数存在。
3. 小规模实验脚本存在。
4. 汇总测试存在。
5. 输出写入 `outputs/order_cancellation_small_experiment/<timestamp>/`。
6. 输出目录至少包含 `scenario_results.csv`、`seed_results.csv`、`summary.json`、`selected_strategy_counts.csv` 和 `experiment_notes.md`。
7. 只新增本次 `<timestamp>` 输出目录，不覆盖或改写历史 `outputs/` 结果。
8. 每个场景同时报告局部修复和完全重调度。
9. 每个场景报告调度约束检查结果。
10. 多随机种子汇总后才写分析结论。
11. 没有机器故障逻辑。
12. 没有新订单插入逻辑。
13. 没有多个订单连续取消逻辑。
14. 没有强化学习。
15. 没有全局最优证明。
16. `raw_code/` 无修改。

## 15. 阶段 F 完成标志

阶段 F 完成标志：

```text
已经在早期取消、中期取消、后期取消三个场景上运行小规模实验；
每个场景同时报告局部修复和完全重调度；
每个场景均通过调度约束检查或清楚记录不可行原因；
多随机种子结果已汇总；
基于汇总结果形成第一版小规模实验结论；
结果已写入 outputs/。
```

当前完成状态：

1. 已在早期取消、中期取消、后期取消三个场景上运行小规模实验。
2. 每个场景同时报告局部修复和完全重调度字段。
3. 每个场景报告调度约束检查字段，或清楚记录 `no_feasible_candidate`。
4. 多随机种子结果已汇总。
5. 已基于汇总结果形成第一版小规模实验结论。
6. 结果已写入 `outputs/order_cancellation_small_experiment/20260621_094024/`。
7. 阶段 F 第一版小规模实验闭环已完成。

## 16. 后续扩展方向

阶段 F 之后可以进入第二轮研究扩展，但应另起阶段或另写计划。候选方向包括：

1. 多个订单连续取消。
2. 订单取消与新订单插入组合。
3. 订单取消与机器故障组合。
4. 取消时刻不确定。
5. 加工时间随机变化。
6. 更大规模实例。
7. 更多随机种子和统计检验。
8. 强化学习策略选择。
9. 与更多论文算法进行对比。

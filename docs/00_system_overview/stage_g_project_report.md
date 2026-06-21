# 阶段 G 项目报告：场景库与实验基准扩展

本文档是阶段 G 的唯一主入口，合并原来分散在范围确认、场景结构、工作记录和实验报告里的必要内容。README 中只保留本文档入口，避免阶段 G 文档过多导致阅读不直观。

本文档记录阶段 G 的目标、范围、配置、场景字段、job 分类、运行入口、真实实验输出、汇总结果、初步结论和阶段 H 入口。

## 0. 为什么合并文档

阶段 G 原来按小步骤拆成多个文档，适合开发过程控制，但不适合项目阅读。保留一个阶段一个主文档更清楚：

1. README 只需要一个阶段 G 入口。
2. 阶段 G 的计划、执行、结果和结论放在同一处。
3. 旧拆分文档不再作为主要阅读入口。
4. 后续如果更新阶段 G，只更新本文档。

## 1. 实验输出

本次阶段 G 实验入口：

```matlab
run('scripts/run_order_cancellation_scenario_library_experiment.m')
```

本次输出目录：

```text
outputs/order_cancellation_scenario_library/20260621_150617/
```

输出文件：

```text
scenario_library.csv
seed_results.csv
scenario_summary.csv
category_summary.csv
strategy_counts.csv
summary.json
experiment_notes.md
```

实验规模：

1. 数据集数量：`1`。
2. 数据集：`data_sample/Mk01.fjs`。
3. 场景数量：`45`。
4. 运行数量：`45`。
5. 时间窗口：`early`、`middle`、`late`。
6. 工件类别：`random`、`short`、`long`、`critical`、`noncritical`。
7. 随机种子：`1`、`2`、`3`。
8. 取消策略：`cancel_unstarted_operations_only`。

## 2. 阶段 G 范围

阶段 G 包含两部分：

1. G-A：生成可复现订单取消场景库。
2. G-B：基于场景库批量运行阶段 B-E 链路。

阶段 G 不包含：

1. 机器故障。
2. 新订单插入。
3. 多订单连续取消。
4. AGV 故障。
5. 强化学习。
6. 全局最优证明。

这些内容可以进入后续阶段，但不能混入阶段 G 的场景库主线。

## 3. 配置与场景字段

阶段 G 配置文件：

```text
configs/order_cancellation_scenario_library.yaml
```

配置范围：

1. 数据集：`data_sample/Mk01.fjs`。
2. 取消时间窗口：`early`、`middle`、`late`。
3. 工件类别：`random`、`short`、`long`、`critical`、`noncritical`。
4. 随机种子：`1`、`2`、`3`。
5. 输出目录：`outputs/order_cancellation_scenario_library`。

每个场景字段：

```matlab
scenario.scenario_id
scenario.dataset
scenario.seed
scenario.time_window
scenario.job_category
scenario.cancel.job_id
scenario.cancel.cancel_time
scenario.cancel.policy
scenario.cancel_time_ratio
scenario.notes
```

这些字段保证每个实验结果能追溯到数据集、取消时刻、取消工件类别和随机种子。

## 4. job 分类规则

第一版分类规则：

1. `random`：使用 `rng(seed)` 随机选择工件。
2. `short`：选择工序数最少的工件。
3. `long`：选择工序数最多的工件。
4. `critical`：选择 baselineSchedule 中最后完成的工件。
5. `noncritical`：选择 baselineSchedule 中最早完成的工件。

如果无法稳定判断 `critical` 或 `noncritical`，应跳过并写入 `notes`，不强行伪造。

## 5. 代码与运行入口

场景库生成函数：

```text
src/cancellation/build_order_cancellation_scenarios.m
```

单场景实验函数：

```text
src/cancellation/run_order_cancellation_library_scenario.m
```

汇总函数：

```text
src/cancellation/summarize_order_cancellation_library_results.m
```

测试入口：

```matlab
run('tests/test_order_cancellation_scenario_library.m')
run('tests/test_order_cancellation_scenario_library_experiment_summary.m')
```

实验入口：

```matlab
run('scripts/run_order_cancellation_scenario_library_experiment.m')
```

注意：实验入口会写入 `outputs/`，运行前需要确认。

## 6. 测试结果

阶段 G 汇总测试已通过：

```matlab
run('tests/test_order_cancellation_scenario_library_experiment_summary.m')
```

输出：

```text
test_order_cancellation_scenario_library_experiment_summary passed
```

该测试验证场景库实验结果汇总逻辑，包括按时间窗口、工件类别、策略次数和不可行数量统计。

## 7. 按取消时刻汇总

| time_window | run_count | local_feasible | complete_feasible | no_feasible | local_Cmax_delta_mean | complete_Cmax_delta_mean | local_SD_mean | complete_SD_mean | local_TD_mean | complete_TD_mean | local_energy_delta_mean | complete_energy_delta_mean | local_Y_mean | complete_Y_mean | selected_local | selected_complete |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| early | 15 | 12 | 0 | 3 | -0.750000 | NaN | 0.000000 | NaN | 0.000000 | NaN | -8.450000 | NaN | 0.248006 | NaN | 12 | 0 |
| middle | 15 | 15 | 12 | 0 | -0.600000 | -3.250000 | 0.000000 | 2.666667 | 0.000000 | 3.500000 | -9.080000 | -13.616667 | 0.350000 | 0.625000 | 15 | 0 |
| late | 15 | 6 | 0 | 9 | -1.500000 | NaN | 0.000000 | NaN | 0.000000 | NaN | -4.000000 | NaN | 0.247625 | NaN | 6 | 0 |

解释：

1. `early` 有 12 个场景局部修复可行，完全重调度没有进入最终可评价状态，3 个场景无可行候选。
2. `middle` 是完全重调度最有机会的时间窗口，12 个场景完全重调度可行，但最终仍没有被选中。
3. `late` 可行性最弱，15 个场景中 9 个无可行候选。
4. 完全重调度在 `middle` 的 `Cmax_delta` 和能耗上更好，但 `SD` 和 `TD` 明显增加，导致综合 `Y` 平均值高于局部修复。

## 8. 按工件类别汇总

| job_category | run_count | local_feasible | complete_feasible | no_feasible | local_Cmax_delta_mean | complete_Cmax_delta_mean | local_SD_mean | complete_SD_mean | local_TD_mean | complete_TD_mean | local_energy_delta_mean | complete_energy_delta_mean | local_Y_mean | complete_Y_mean | selected_local | selected_complete |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| random | 9 | 9 | 0 | 0 | 0.000000 | NaN | 0.000000 | NaN | 0.000000 | NaN | 0.000000 | NaN | 0.250000 | NaN | 9 | 0 |
| short | 9 | 3 | 3 | 6 | 0.000000 | -3.000000 | 0.000000 | 3.333333 | 0.000000 | 2.000000 | -11.600000 | -13.633333 | 0.500000 | 0.500000 | 3 | 0 |
| long | 9 | 6 | 3 | 3 | 0.000000 | -2.000000 | 0.000000 | 3.000000 | 0.000000 | 4.000000 | -10.800000 | -10.600000 | 0.249325 | 0.750000 | 6 | 0 |
| critical | 9 | 9 | 3 | 0 | -3.000000 | -6.000000 | 0.000000 | 1.333333 | 0.000000 | 4.000000 | -10.800000 | -19.633333 | 0.329992 | 0.500000 | 9 | 0 |
| noncritical | 9 | 6 | 3 | 3 | 0.000000 | -2.000000 | 0.000000 | 3.000000 | 0.000000 | 4.000000 | -10.800000 | -10.600000 | 0.249325 | 0.750000 | 6 | 0 |

解释：

1. `random` 类别全部选择局部修复，且没有不可行场景。
2. `short` 类别有 6 个无可行候选，是本次实验中最不稳定的类别。
3. `critical` 类别局部修复全部可行，并且完全重调度在部分场景中带来更大的 `Cmax_delta` 和能耗改善，但综合 `Y` 仍偏向局部修复。
4. `long` 和 `noncritical` 的统计结果一致，说明在当前 Mk01 样例和分类规则下，这两类场景可能选择到了同一类工件或相近扰动结构。

## 9. 策略选择统计

| selected_strategy | count |
|---|---:|
| local_repair | 33 |
| no_feasible_candidate | 12 |

本次 45 个场景中：

1. `local_repair` 被选择 33 次。
2. `complete_rescheduling` 被选择 0 次。
3. `no_feasible_candidate` 出现 12 次。

这说明在当前权重、当前 Mk01 数据和当前第一版完全重调度候选实现下，局部修复是更稳定的策略。

## 10. 初步结论

基于本次 45 个场景的小规模场景库实验，可以得到以下阶段 G 初步结论：

1. 场景库机制有效：配置生成了 45 个可追溯订单取消场景，并全部完成运行。
2. 中期取消最适合观察完全重调度：`middle` 场景中完全重调度可行 12 次，而 `early` 和 `late` 均为 0 次。
3. 完全重调度有优化潜力：在 `middle`、`short`、`critical` 等类别中，完全重调度能降低 `Cmax_delta` 和能耗。
4. 完全重调度的扰动代价明显：可行的完全重调度通常带来更高 `SD` 和 `TD`，综合 `Y` 因此没有胜过局部修复。
5. 局部修复更稳定：局部修复被选择 33 次，且在 `random`、`critical` 类别表现稳定。
6. 无可行候选不可忽视：12 个场景没有可选策略，主要集中在 `late` 和 `short` 类别，需要后续分析拒绝原因。

## 11. 对阶段 H 的启发

阶段 H 应重点研究混合修复策略，而不是简单地让完全重调度替代局部修复。

建议阶段 H 关注：

1. 什么时候完全重调度的 `Cmax_delta` 和能耗收益足以抵消 `SD`、`TD` 扰动。
2. 是否需要为 `middle` 取消单独设置重调度触发条件。
3. 是否需要为 `critical` 工件取消设计更积极的完全重调度策略。
4. 是否需要降低完全重调度的扰动，或在 `Y` 中重新校准权重。
5. 对 `no_feasible_candidate` 场景进行拒绝原因分类，补充更稳的候选生成逻辑。

## 12. 局限

本次结果仍有以下局限：

1. 只使用 `data_sample/Mk01.fjs`，不能代表大规模实例。
2. 只使用 3 个随机种子。
3. 只研究单订单取消。
4. 不包含机器故障、新订单插入、多个订单连续取消和强化学习。
5. 不证明全局最优。
6. 完全重调度候选仍是第一版实现，后续可继续改进可行性和扰动控制。

## 13. 阶段 G 完成判断

阶段 G 的完成标志已满足：

1. 已经能从配置生成可复现订单取消场景库。
2. 已经能用场景库批量运行阶段 B-E 链路。
3. 每个场景同时报告局部修复和完全重调度。
4. 每个场景报告约束检查结果或不可行原因。
5. 结果已写入 `outputs/order_cancellation_scenario_library/20260621_150617/`。
6. 能按 `time_window`、`job_category`、`seed` 和策略选择汇总。
7. 已基于输出形成阶段 G 项目报告。

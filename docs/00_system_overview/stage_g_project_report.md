# 阶段 G 项目报告：场景库与实验基准扩展

本文档基于阶段 G 场景库实验输出形成，记录本次实验范围、输出目录、汇总结果、初步结论和局限。

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

## 2. 测试结果

阶段 G 汇总测试已通过：

```matlab
run('tests/test_order_cancellation_scenario_library_experiment_summary.m')
```

输出：

```text
test_order_cancellation_scenario_library_experiment_summary passed
```

该测试验证场景库实验结果汇总逻辑，包括按时间窗口、工件类别、策略次数和不可行数量统计。

## 3. 按取消时刻汇总

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

## 4. 按工件类别汇总

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

## 5. 策略选择统计

| selected_strategy | count |
|---|---:|
| local_repair | 33 |
| no_feasible_candidate | 12 |

本次 45 个场景中：

1. `local_repair` 被选择 33 次。
2. `complete_rescheduling` 被选择 0 次。
3. `no_feasible_candidate` 出现 12 次。

这说明在当前权重、当前 Mk01 数据和当前第一版完全重调度候选实现下，局部修复是更稳定的策略。

## 6. 初步结论

基于本次 45 个场景的小规模场景库实验，可以得到以下阶段 G 初步结论：

1. 场景库机制有效：配置生成了 45 个可追溯订单取消场景，并全部完成运行。
2. 中期取消最适合观察完全重调度：`middle` 场景中完全重调度可行 12 次，而 `early` 和 `late` 均为 0 次。
3. 完全重调度有优化潜力：在 `middle`、`short`、`critical` 等类别中，完全重调度能降低 `Cmax_delta` 和能耗。
4. 完全重调度的扰动代价明显：可行的完全重调度通常带来更高 `SD` 和 `TD`，综合 `Y` 因此没有胜过局部修复。
5. 局部修复更稳定：局部修复被选择 33 次，且在 `random`、`critical` 类别表现稳定。
6. 无可行候选不可忽视：12 个场景没有可选策略，主要集中在 `late` 和 `short` 类别，需要后续分析拒绝原因。

## 7. 对阶段 H 的启发

阶段 H 应重点研究混合修复策略，而不是简单地让完全重调度替代局部修复。

建议阶段 H 关注：

1. 什么时候完全重调度的 `Cmax_delta` 和能耗收益足以抵消 `SD`、`TD` 扰动。
2. 是否需要为 `middle` 取消单独设置重调度触发条件。
3. 是否需要为 `critical` 工件取消设计更积极的完全重调度策略。
4. 是否需要降低完全重调度的扰动，或在 `Y` 中重新校准权重。
5. 对 `no_feasible_candidate` 场景进行拒绝原因分类，补充更稳的候选生成逻辑。

## 8. 局限

本次结果仍有以下局限：

1. 只使用 `data_sample/Mk01.fjs`，不能代表大规模实例。
2. 只使用 3 个随机种子。
3. 只研究单订单取消。
4. 不包含机器故障、新订单插入、多个订单连续取消和强化学习。
5. 不证明全局最优。
6. 完全重调度候选仍是第一版实现，后续可继续改进可行性和扰动控制。

## 9. 阶段 G 完成判断

阶段 G 的完成标志已满足：

1. 已经能从配置生成可复现订单取消场景库。
2. 已经能用场景库批量运行阶段 B-E 链路。
3. 每个场景同时报告局部修复和完全重调度。
4. 每个场景报告约束检查结果或不可行原因。
5. 结果已写入 `outputs/order_cancellation_scenario_library/20260621_150617/`。
6. 能按 `time_window`、`job_category`、`seed` 和策略选择汇总。
7. 已基于输出形成阶段 G 项目报告。

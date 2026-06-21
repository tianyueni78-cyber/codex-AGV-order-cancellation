# 阶段 F 工作记录：小规模订单取消实验

> 本文档已不再作为阶段 F 的主要阅读入口。阶段 F 的配置、运行输出、汇总结果、结论和局限已整合到 [阶段 F 项目报告](stage_f_project_report.md)。本文档仅保留为历史过程记录。

本文档记录阶段 F 已完成的工作、实验入口、输出位置、当前结果状态和局限。阶段 F 是订单取消第一版闭环中的小规模实验阶段，不是最终大规模研究结论。

## 1. 阶段 F 目标

阶段 F 的目标是运行一组订单取消场景：

1. 早期取消。
2. 中期取消。
3. 后期取消。

每个场景需要同时生成并评价：

1. 局部修复候选方案。
2. 完全重调度候选方案。

阶段 F 的完成条件是：在多随机种子结果汇总后，基于汇总结果形成第一版小规模结论。

## 2. 实验配置

配置文件：

```text
configs/order_cancellation_small_experiment.yaml
```

当前配置内容：

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

说明：

1. 数据集使用 `data_sample/Mk01.fjs`。
2. 取消策略使用阶段 B 定义的 `cancel_unstarted_operations_only`。
3. 取消时刻通过 `baseline_Cmax * cancel_time_ratio` 换算。
4. 输出根目录为 `outputs/order_cancellation_small_experiment`。
5. 配置中不写死本机绝对路径。

## 3. 场景定义

阶段 F 第一版包含三个场景：

| 场景 | 取消时刻比例 | 含义 |
|---|---:|---|
| `early_cancel` | `0.25` | 基线 `Cmax` 的早期取消 |
| `middle_cancel` | `0.50` | 基线 `Cmax` 的中期取消 |
| `late_cancel` | `0.75` | 基线 `Cmax` 的后期取消 |

当前仍只研究单订单取消，不加入机器故障、新订单插入或多个订单连续取消。

## 4. 随机种子设置

当前小规模实验种子为：

```text
[1, 2, 3]
```

说明：

1. 多随机种子用于避免只根据单次 smoke 结果下结论。
2. 阶段 F 的结论必须基于多个 seed 的汇总结果。
3. 当前种子数量较小，只能支持第一版小规模观察，不能支持强统计结论。

## 5. 新增文件清单

阶段 F 已新增或更新的主要文件：

```text
configs/order_cancellation_small_experiment.yaml
src/cancellation/run_order_cancellation_scenario.m
src/cancellation/summarize_order_cancellation_results.m
scripts/run_order_cancellation_small_experiment.m
tests/test_order_cancellation_small_experiment_summary.m
docs/00_system_overview/stage_f_scope_contract.md
docs/00_system_overview/stage_f_work_plan.md
docs/00_system_overview/stage_f_result_analysis_template.md
docs/00_system_overview/stage_f_work_record.md
```

说明：

1. `run_order_cancellation_scenario.m` 负责单个场景和单个 seed 的阶段 B-E 串联。
2. `summarize_order_cancellation_results.m` 负责多场景、多 seed 的汇总逻辑。
3. `run_order_cancellation_small_experiment.m` 是会写入 `outputs/` 的小规模实验入口。
4. `test_order_cancellation_small_experiment_summary.m` 只测试汇总逻辑，不写 `outputs/`。
5. `stage_f_result_analysis_template.md` 规定实验结果分析口径。

## 6. 测试入口

阶段 F 当前测试入口：

```matlab
run('tests/test_order_cancellation_small_experiment_summary.m')
```

测试覆盖：

1. 三个场景能被识别。
2. 多个 seed 结果能汇总。
3. 可行候选数量能统计。
4. 策略选择次数能统计。
5. 均值指标能计算。

测试边界：

1. 不写 `outputs/`。
2. 不运行完整 NSGA-II。
3. 不形成实验结论。

## 7. 实验入口

阶段 F 小规模实验入口：

```matlab
run('scripts/run_order_cancellation_small_experiment.m')
```

注意：

1. 该脚本会写入 `outputs/`。
2. 运行 MATLAB 和生成 `outputs/` 前需要确认。
3. 当前工作记录没有运行该脚本。

## 8. 输出目录

实验运行后应生成：

```text
outputs/order_cancellation_small_experiment/<timestamp>/
```

该目录应包含：

```text
scenario_results.csv
seed_results.csv
summary.json
selected_strategy_counts.csv
experiment_notes.md
```

输出含义：

1. `scenario_results.csv`：按场景汇总均值、可行数量和策略选择次数。
2. `seed_results.csv`：保留每个场景、每个 seed 的原始结果。
3. `summary.json`：记录配置、数据集、权重、归一化说明和 scope。
4. `selected_strategy_counts.csv`：统计每类策略被选中的次数。
5. `experiment_notes.md`：说明本次实验范围、解释边界和局限。

## 9. 汇总结果

Step F8 已运行，输出目录：

```text
outputs/order_cancellation_small_experiment/20260621_094024/
```

本次共运行 9 个场景-seed 组合：

1. `early_cancel`：3 次，局部修复和完全重调度均不可评价。
2. `middle_cancel`：3 次，局部修复和完全重调度均可评价。
3. `late_cancel`：3 次，局部修复和完全重调度均不可评价。

策略选择汇总：

1. 无可行候选：6 次。
2. `local_repair`：3 次。
3. `complete_rescheduling`：0 次。

## 10. 小规模结论

本次小规模结论：

1. 只有 `middle_cancel` 形成可评价候选。
2. `middle_cancel` 中完全重调度稳定降低 `Cmax`，`complete_Cmax_delta_mean = -3.000000`。
3. `middle_cancel` 中完全重调度能耗改善更大，`complete_energy_delta_mean = -13.633333`，局部修复为 `-11.600000`。
4. `middle_cancel` 中完全重调度扰动更大，`complete_SD_mean = 3.333333`，`complete_TD_mean = 2.000000`。
5. `middle_cancel` 中两类候选 `Y` 均为 `0.500000`，最终按 tie-break 规则选择 `local_repair`。
6. `early_cancel` 和 `late_cancel` 均为 `no_feasible_candidate`，当前 CSV 未保存详细 `rejectedReasons`，不能进一步归因到具体约束类型。

结论边界：

1. 只基于多随机种子汇总结果。
2. 同时报告原始指标和 `Y`。
3. 不声称全局最优。
4. 不把单个 smoke 结果当作研究结论。
5. 详细报告见 `docs/00_system_overview/stage_f_project_report.md`。

## 11. 局限说明

阶段 F 当前局限：

1. 只使用 `data_sample/Mk01.fjs` 小样例。
2. 只包含早期、中期、后期三个取消时刻比例。
3. 只使用 `[1, 2, 3]` 三个随机种子。
4. 只研究单订单取消。
5. 不包含机器故障。
6. 不包含新订单插入。
7. 不包含多个订单连续取消。
8. 不包含 AGV 故障。
9. 不包含取消时刻不确定。
10. 不包含加工时间随机变化。
11. 不包含强化学习。
12. 不证明全局最优。

因此，阶段 F 最多形成第一版小规模观察结论，不能作为最终大规模实验结论。

## 12. 后续扩展入口

阶段 F 之后可以继续扩展，但应另起阶段和文档，避免污染当前稳定闭环。

建议入口：

1. 扩展更多数据集和更大规模实例。
2. 增加更多随机种子和统计检验。
3. 增加多个订单连续取消。
4. 增加新订单插入。
5. 研究订单取消与机器故障组合。
6. 研究订单取消与 AGV 故障组合。
7. 增加取消时刻不确定。
8. 增加加工时间随机变化。
9. 在候选策略选择层引入强化学习。

后续总路线可参考：

```text
docs/00_system_overview/post_stage_f_flexible_dispatch_roadmap.md
```

## 13. 当前验收状态

当前 F10 静态验收：

1. `docs/00_system_overview/stage_f_work_record.md` 已新增。
2. 文档已说明阶段 F 目标、实验配置、场景定义和随机种子设置。
3. 文档已说明新增文件清单、测试入口、实验入口和输出目录。
4. 文档已补充 Step F8 输出目录和阶段 F 小规模结论。
5. 文档已说明阶段 F 是小规模实验，不是最终大规模结论。
6. 文档已说明后续扩展方向。
7. 本步骤读取了 Step F8 已生成的 `outputs/`，未新增实验输出。
8. 本步骤未修改 `raw_code/`。

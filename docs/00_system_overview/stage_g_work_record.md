# 阶段 G 工作记录：场景库与实验基准扩展

本文档记录阶段 G 已完成的工作、手动运行入口、当前验收状态和后续需要基于真实输出补充的项目报告内容。

## 1. 阶段 G 目标

阶段 G 的目标是：

```text
建立可复现的订单取消场景库，
并能用该场景库批量运行阶段 B-E 链路，
让订单取消实验不再只依赖单个 Mk01 smoke。
```

阶段 G 的价值不只看代码是否存在，还要看后续场景库实验输出是否能说明不同取消时刻、不同订单类型和不同 seed 下两类策略的表现差异。

## 2. 已完成内容

阶段 G 已完成两条链路。

G-A：场景库生成

1. 从配置读取数据集、取消时间窗口、工件类别和随机种子。
2. 根据 baseline Cmax 和 `cancel_time_ratio` 生成取消时刻。
3. 根据 job 分类规则选择取消工件。
4. 为每个场景生成可追溯的 `scenario_id`。
5. 返回场景列表和场景统计。

G-B：场景库实验

1. 接收场景库中的单个 scenario。
2. 调用阶段 B 提取取消状态。
3. 调用阶段 C 生成局部修复候选。
4. 调用阶段 D 生成完全重调度候选。
5. 调用阶段 E 评价两个候选并选择策略。
6. 批量实验脚本将结果写入 timestamp 输出目录。
7. 汇总函数支持按 `dataset`、`time_window`、`job_category`、`seed`、策略选择和可行性统计结果。

## 3. 新增或确认的文件

配置：

```text
configs/order_cancellation_scenario_library.yaml
```

核心函数：

```text
src/cancellation/build_order_cancellation_scenarios.m
src/cancellation/run_order_cancellation_library_scenario.m
src/cancellation/summarize_order_cancellation_library_results.m
```

脚本：

```text
scripts/run_order_cancellation_scenario_library_experiment.m
```

测试：

```text
tests/test_order_cancellation_scenario_library.m
tests/test_order_cancellation_scenario_library_experiment_summary.m
```

文档：

```text
docs/00_system_overview/stage_g_scope_contract.md
docs/00_system_overview/stage_g_scenario_structure_contract.md
docs/00_system_overview/stage_g_scenario_library_plan.md
docs/00_system_overview/stage_g_work_record.md
```

## 4. 配置说明

阶段 G 当前配置入口：

```text
configs/order_cancellation_scenario_library.yaml
```

当前配置范围：

1. 数据集：`data_sample/Mk01.fjs`。
2. 取消策略：`cancel_unstarted_operations_only`。
3. 取消时间窗口：`early`、`middle`、`late`。
4. 工件类别：`random`、`short`、`long`、`critical`、`noncritical`。
5. 随机种子：`1`、`2`、`3`。
6. 输出目录：`outputs/order_cancellation_scenario_library`。

## 5. 场景字段

每个场景应包含：

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

## 6. job 分类规则

第一版分类规则：

1. `random`：使用 `rng(seed)` 随机选择工件。
2. `short`：选择工序数最少的工件。
3. `long`：选择工序数最多的工件。
4. `critical`：选择 baselineSchedule 中最后完成的工件。
5. `noncritical`：选择 baselineSchedule 中最早完成的工件。

如果无法稳定判断 `critical` 或 `noncritical`，应跳过并写入 `notes`，不强行伪造。

## 7. 手动测试入口

场景库生成测试：

```matlab
run('tests/test_order_cancellation_scenario_library.m')
```

场景库实验汇总测试：

```matlab
run('tests/test_order_cancellation_scenario_library_experiment_summary.m')
```

这两个测试不应写入 `outputs/`，也不应运行正式实验。

## 8. 手动实验入口

场景库批量实验入口：

```matlab
run('scripts/run_order_cancellation_scenario_library_experiment.m')
```

该入口会写入：

```text
outputs/order_cancellation_scenario_library/<timestamp>/
```

运行前需要确认，因为它会启动 MATLAB 实验流程并生成输出。

## 9. 输出目录与文件含义

阶段 G 实验完成后，预期输出目录为：

```text
outputs/order_cancellation_scenario_library/<timestamp>/
```

预期文件：

```text
scenario_library.csv
seed_results.csv
scenario_summary.csv
category_summary.csv
strategy_counts.csv
summary.json
experiment_notes.md
```

含义：

1. `scenario_library.csv`：实际生成的场景库。
2. `seed_results.csv`：每个场景和 seed 的原始结果。
3. `scenario_summary.csv`：按时间窗口等维度汇总。
4. `category_summary.csv`：按工件类别汇总。
5. `strategy_counts.csv`：策略选择次数统计。
6. `summary.json`：实验配置、scope 和汇总元数据。
7. `experiment_notes.md`：本次实验说明和局限。

## 10. 当前输出状态

截至本文档编写时，本地未发现阶段 G 输出目录：

```text
outputs/order_cancellation_scenario_library/
```

因此当前不能给出阶段 G 的真实实验结论，也不能判断哪类场景下局部修复或完全重调度更有优势。

当前能确认的是工程闭环已经具备：

1. 能从配置生成场景库。
2. 能将单个场景接入阶段 B-E。
3. 能批量运行场景库实验脚本。
4. 能按场景维度汇总结果。

阶段 G 的研究价值需要等待你手动运行场景库实验后，根据 `outputs/order_cancellation_scenario_library/<timestamp>/` 中的结果再补充分析。

## 11. 结果分析口径

拿到真实输出后，阶段 G 项目报告应分析：

1. `early`、`middle`、`late` 哪类取消时刻更容易选择局部修复。
2. 哪类取消时刻更容易选择完全重调度。
3. `short`、`long`、`critical`、`noncritical` 工件取消时策略差异是否明显。
4. 完全重调度是否稳定降低 `Cmax_delta`。
5. 完全重调度是否带来更大的 `SD` 或 `TD`。
6. 能耗变化是否稳定。
7. 不可行案例主要来自机器冲突、AGV 冲突、工序顺序、冻结一致性还是取消任务回流。
8. 策略选择结果是否随 seed 波动明显。

结论必须基于多场景和多 seed 汇总，不应把单个 smoke 或单个场景当成研究结论。

## 12. 阶段 G 完成标志

阶段 G 完成标志：

1. 已经能从配置生成可复现订单取消场景库。
2. 已经能用场景库批量运行阶段 B-E 链路。
3. 每个场景同时报告局部修复和完全重调度。
4. 每个场景报告约束检查结果或不可行原因。
5. 结果写入 `outputs/order_cancellation_scenario_library/<timestamp>/`。
6. 能按 `time_window`、`job_category`、`seed` 和策略选择汇总。
7. 基于输出形成阶段 G 项目报告。

当前状态：

```text
工程闭环已完成；
真实实验输出尚未在本地发现；
阶段 G 项目报告的结果分析部分等待你运行实验后补充。
```

## 13. 局限

阶段 G 当前局限：

1. 仍只研究单订单取消。
2. 不包含机器故障。
3. 不包含新订单插入。
4. 不包含多个订单连续取消。
5. 不包含强化学习。
6. 不证明全局最优。
7. 当前配置只包含一个样例数据集，后续需要扩展更多小中规模样例。
8. `critical` 和 `noncritical` 的分类质量依赖 baselineSchedule 的完成时间信息。

## 14. 阶段 H 入口

阶段 H 建议进入：

```text
阶段 H：混合修复策略
```

阶段 H 应基于阶段 G 的真实输出回答：

```text
什么时候只做局部修复，
什么时候触发完全重调度。
```

如果阶段 G 输出显示完全重调度在某些场景下稳定降低 `Cmax_delta`，但扰动 `SD` 或 `TD` 明显增大，阶段 H 就可以设计阈值或规则，在效率收益和计划稳定性之间做自适应选择。

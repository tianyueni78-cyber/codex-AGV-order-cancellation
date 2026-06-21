# 阶段 G：场景库与实验基准扩展

> 阶段 G 的主要阅读入口已统一为 [阶段 G 项目报告](stage_g_project_report.md)。本文档仅保留历史过程记录，不再从 README 直接入口展示。

本文档是阶段 G 的总说明。阶段 G 承接阶段 F 的小规模实验闭环，把订单取消实验从少量固定场景扩展为可复现、可统计、可追溯的场景库。

## 1. 阶段 G 目标

阶段 G 的目标是：

```text
建立可复现的订单取消场景库，
并能用该场景库批量运行小规模实验，
验证不同取消时刻、不同订单类型和不同 seed 下策略表现。
```

阶段 G 不改变阶段 B-E 的核心调度链路。它只扩展实验对象、实验入口和汇总方式。

## 2. G-A：场景库生成

G-A 负责从配置生成订单取消场景。

入口函数：

```matlab
[scenarios, summary] = build_order_cancellation_scenarios( ...
    problem, baselineSchedule, config)
```

对应文件：

```text
src/cancellation/build_order_cancellation_scenarios.m
```

G-A 只生成场景，不运行调度实验，不写 `outputs/`。

生成内容包括：

1. 数据集。
2. 随机种子。
3. 取消时间窗口。
4. 取消工件类别。
5. `scenario_id`。
6. `cancel.job_id`。
7. `cancel.cancel_time`。
8. `cancel.policy`。

## 3. G-B：场景库实验

G-B 使用 G-A 生成的场景批量运行阶段 B-E。

单场景入口函数：

```matlab
result = run_order_cancellation_library_scenario( ...
    problem, machineData, agvData, baselineSchedule, scenario, config)
```

批量实验入口：

```matlab
run('scripts/run_order_cancellation_scenario_library_experiment.m')
```

G-B 对每个场景执行：

1. 阶段 B：提取取消时刻状态。
2. 阶段 C：构造局部修复候选。
3. 阶段 D：构造完全重调度候选。
4. 阶段 E：计算指标并选择策略。
5. 汇总不同时间窗口、工件类别和 seed 的结果。

G-B 会写入 `outputs/`，运行 MATLAB 前需要确认。

## 4. 配置说明

阶段 G 配置文件：

```text
configs/order_cancellation_scenario_library.yaml
```

当前配置字段：

```yaml
datasets:
  - data_sample/Mk01.fjs

cancel_policy: cancel_unstarted_operations_only

time_windows:
  - name: early
    cancel_time_ratio: 0.25
  - name: middle
    cancel_time_ratio: 0.50
  - name: late
    cancel_time_ratio: 0.75

job_categories:
  - random
  - short
  - long
  - critical
  - noncritical

seeds: [1, 2, 3]

output_base_dir: outputs/order_cancellation_scenario_library
```

约束：

1. 数据集路径必须是相对路径。
2. 输出目录必须是相对路径。
3. 场景库生成不写 `outputs/`。
4. 场景库实验写入 timestamp 子目录，不覆盖旧结果。

## 5. 场景字段

每个场景的结构约定如下：

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

字段含义：

1. `scenario_id`：唯一场景编号。
2. `dataset`：场景使用的数据集。
3. `seed`：用于可复现选择随机工件。
4. `time_window`：取消时间窗口，如 `early`、`middle`、`late`。
5. `job_category`：取消工件类别。
6. `cancel`：阶段 B-E 使用的订单取消事件。
7. `cancel_time_ratio`：取消时刻相对 baseline Cmax 的比例。
8. `notes`：记录跳过、退化或分类说明。

## 6. job 分类规则

第一版 job 分类规则：

1. `random`：使用 `rng(seed)` 随机选择 `job_id`。
2. `short`：选择工序数最少的工件。
3. `long`：选择工序数最多的工件。
4. `critical`：选择 baselineSchedule 中最后完成的工件。
5. `noncritical`：选择 baselineSchedule 中最早完成的工件。

停止条件：

1. 如果无法稳定判断 `critical`，该类别应跳过并写入 `notes`。
2. 如果无法稳定判断 `noncritical`，该类别应跳过并写入 `notes`。
3. 不允许为了凑类别强行伪造 `job_id`。

## 7. 测试入口

场景库生成测试：

```matlab
run('tests/test_order_cancellation_scenario_library.m')
```

验证内容：

1. 能生成场景。
2. 每个场景有 `scenario_id`。
3. 每个场景有完整 `cancel` 字段。
4. 场景数量统计正确。
5. `random` job 对 seed 可复现。
6. 不写 `outputs/`。

场景库实验汇总测试：

```matlab
run('tests/test_order_cancellation_scenario_library_experiment_summary.m')
```

验证内容：

1. 构造最小 result 数据。
2. 按 `time_window` 汇总正确。
3. 按 `job_category` 汇总正确。
4. 策略次数统计正确。
5. 不可行数量统计正确。
6. 不写 `outputs/`。

## 8. 实验入口

场景库批量实验入口：

```matlab
run('scripts/run_order_cancellation_scenario_library_experiment.m')
```

注意：

1. 该入口会运行 MATLAB 实验流程。
2. 该入口会写入 `outputs/`。
3. 运行前需要确认。
4. 第一版仍复用阶段 B-E 已有链路，不新增调度算法主线。

## 9. 输出目录说明

阶段 G 实验输出目录：

```text
outputs/order_cancellation_scenario_library/<timestamp>/
```

建议输出文件：

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

1. `scenario_library.csv`：生成的场景库。
2. `seed_results.csv`：每个场景和 seed 的原始结果。
3. `scenario_summary.csv`：按时间窗口等维度汇总的结果。
4. `category_summary.csv`：按工件类别汇总的结果。
5. `strategy_counts.csv`：局部修复、完全重调度和无可行候选的选择次数。
6. `summary.json`：配置、scope、权重和汇总元数据。
7. `experiment_notes.md`：本次实验说明、局限和注意事项。

## 10. 局限

阶段 G 的局限：

1. 当前仍是订单取消主线，不包含机器故障。
2. 当前不包含新订单插入。
3. 当前不包含多个订单连续取消。
4. 当前不包含强化学习。
5. 当前不证明全局最优。
6. 当前场景库主要服务小中规模可复现实验，不是最终论文级大规模统计结论。
7. `critical` 和 `noncritical` 的可靠性依赖 baselineSchedule 中是否能稳定识别工件完成时间。

## 11. 阶段 H 入口

阶段 G 完成后，阶段 H 建议进入：

```text
阶段 H：混合修复策略
```

阶段 H 的核心问题是：

```text
什么时候只做局部修复，
什么时候触发完全重调度。
```

阶段 H 可以基于阶段 G 的场景库结果，分析不同场景下局部修复和完全重调度的适用边界，再设计更稳定的策略触发规则。

## 12. 阶段 G 完成标志

阶段 G 完成标志：

1. 场景库配置存在。
2. 场景库生成函数存在。
3. 场景库生成测试存在。
4. 场景库实验单场景函数存在。
5. 场景库批量实验脚本存在。
6. 场景库汇总函数存在。
7. 场景库汇总测试存在。
8. README 已挂阶段 G 总入口。
9. 未修改 `raw_code/`。
10. 未引入机器故障、新订单插入、强化学习或全局最优证明。

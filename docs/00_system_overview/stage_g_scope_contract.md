# 阶段 G Step G1：范围确认

本文档确认阶段 G 的研究范围和执行边界。阶段 G 是阶段 F 小规模实验闭环之后的扩展阶段，目标是建立可复现的订单取消场景库，并允许后续基于该场景库批量运行实验。

## 1. 阶段 G 目标

阶段 G 的目标是：

```text
建立可复现的订单取消场景库，
并为后续基于场景库运行实验提供入口。
```

阶段 G 不直接修改阶段 B-E 的核心调度逻辑，而是把实验对象从单个 `Mk01` smoke 场景扩展为一组可复现、可统计、可追踪的取消场景。

## 2. 阶段 G 两部分

阶段 G 包含两部分：

```text
G-A：生成场景库
G-B：基于场景库运行实验
```

### 2.1 G-A：生成场景库

G-A 只负责生成取消场景，不运行调度实验。

应包含：

1. 数据集路径。
2. 取消时间窗口。
3. 取消订单类型。
4. 随机种子。
5. `scenario_id`。
6. `cancel.job_id`。
7. `cancel.cancel_time`。
8. `cancel.policy`。

G-A 禁止：

1. 不写 `outputs/`。
2. 不运行 MATLAB 正式实验。
3. 不调用 NSGA-II。
4. 不生成局部修复或完全重调度候选。
5. 不形成实验结论。

### 2.2 G-B：基于场景库运行实验

G-B 使用 G-A 生成的场景库批量运行阶段 B-E 链路。

应包含：

1. 对每个场景提取取消状态。
2. 对每个场景构造局部修复候选。
3. 对每个场景构造完全重调度候选。
4. 对每个场景计算评价指标。
5. 对每个场景记录策略选择。
6. 汇总不同时间窗口、订单类型和 seed 的结果。

G-B 会写入：

```text
outputs/order_cancellation_scenario_library/<timestamp>/
```

G-B 运行前必须确认，因为它会运行 MATLAB 并生成 `outputs/`。

## 3. 阶段 G 包含内容

阶段 G 包含：

1. 多个取消时刻：早期、中期、后期。
2. 多类取消订单：随机工件、短工件、长工件、关键路径工件、非关键工件。
3. 多个随机种子。
4. 多个小中规模样例数据的扩展入口。
5. 场景库生成测试。
6. 场景库实验汇总测试。
7. 场景库实验脚本入口。

## 4. 阶段 G 不包含内容

阶段 G 不加入：

1. 机器故障。
2. 新订单插入。
3. AGV 故障。
4. 多订单连续取消。
5. 强化学习。
6. 全局最优证明。
7. 论文级大规模结论。

这些内容可以作为后续阶段扩展，但不能混入阶段 G 的场景库主线。

## 5. 运行边界

阶段 G 的运行边界：

1. 场景库生成函数不写 `outputs/`。
2. 场景库测试不写 `outputs/`。
3. 场景库实验脚本会写 `outputs/`。
4. 运行场景库实验前需要确认。
5. 输出目录必须使用相对路径和 timestamp 子目录。
6. 不覆盖历史输出目录。
7. 不修改 `raw_code/`。

## 6. 验收标准

Step G1 的验收标准：

1. 已明确阶段 G 包含 G-A 和 G-B。
2. 已明确场景库生成不写 `outputs/`。
3. 已明确场景库实验会写 `outputs/`。
4. 已明确运行实验前需要确认。
5. 已明确不加入机器故障。
6. 已明确不加入新订单插入。
7. 已明确不加入强化学习。
8. 已明确不声称全局最优。
9. README 已挂阶段 G 范围确认入口。
10. 本步骤未运行 MATLAB。
11. 本步骤未生成 `outputs/`。
12. 本步骤未修改 `raw_code/`。

## 7. 下一步

下一步进入：

```text
Step G2：定义场景库配置
```

建议新增：

```text
configs/order_cancellation_scenario_library.yaml
```

## 8. Step G2：场景库配置

已新增：

```text
configs/order_cancellation_scenario_library.yaml
```

当前配置：

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

配置说明：

1. `datasets` 使用相对路径，当前先从 `data_sample/Mk01.fjs` 开始。
2. `cancel_policy` 延续阶段 B-F 的 `cancel_unstarted_operations_only`。
3. `time_windows` 覆盖 early、middle、late 三个取消时刻。
4. `job_categories` 覆盖 random、short、long、critical、noncritical。
5. `seeds` 明确使用 `[1, 2, 3]`。
6. `output_base_dir` 使用相对路径，供 G-B 场景库实验脚本写入 timestamp 输出目录。

Step G2 验收状态：

1. 数据集路径是相对路径。
2. 取消时刻覆盖 early、middle、late。
3. 工件类别覆盖 random、short、long、critical、noncritical。
4. 多 seed 已明确。
5. 输出目录是相对路径。
6. 本步骤未运行 MATLAB。
7. 本步骤未生成 `outputs/`。
8. 本步骤未修改 `raw_code/`。

下一步进入：

```text
Step G3：定义场景结构
```

## 9. Step G3：场景结构

场景结构契约已新增：

```text
docs/00_system_overview/stage_g_scenario_structure_contract.md
```

每个场景必须包含：

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

Step G3 验收状态：

1. 已定义 `scenario_id` 唯一编号规则。
2. 已定义 `dataset`、`time_window`、`job_category` 和 `seed` 追溯字段。
3. 已定义 `cancel.job_id`、`cancel.cancel_time` 和 `cancel.policy`。
4. 已定义 `cancel_time_ratio` 的含义。
5. 已定义 `notes` 用于记录降级或跳过原因。
6. 已说明关键路径无法稳定判断时不强行伪造。
7. 本步骤未运行 MATLAB。
8. 本步骤未生成 `outputs/`。
9. 本步骤未修改 `raw_code/`。

下一步进入：

```text
Step G4：实现场景库生成函数
```

## 10. Step G4：场景库生成函数

已新增：

```text
src/cancellation/build_order_cancellation_scenarios.m
```

函数入口：

```matlab
[scenarios, summary] = build_order_cancellation_scenarios( ...
    problem, baselineSchedule, config)
```

当前功能：

1. 根据配置中的 `datasets`、`time_windows`、`job_categories` 和 `seeds` 生成场景组合。
2. 复用 `evaluate_candidate_cmax` 计算 baseline `Cmax`。
3. 根据 `baseline_Cmax * cancel_time_ratio` 计算 `cancel.cancel_time`。
4. 根据 `job_category` 选择 `cancel.job_id`。
5. 生成可追溯的 `scenario_id`。
6. 返回 `summary.total_count`、`summary.by_dataset`、`summary.by_time_window`、`summary.by_job_category` 和 `summary.by_seed`。

边界说明：

1. 函数不读文件。
2. 函数不写 `outputs/`。
3. 函数不运行调度实验。
4. 函数不调用 NSGA-II。
5. `critical` 和 `noncritical` 若无法从 baseline 机器表稳定判断，会跳过并写入 `summary.skipped`。

Step G4 验收状态：

1. 已能生成场景列表。
2. 已能统计场景数量。
3. 已按配置生成 `scenario_id`。
4. 已按 `baseline_Cmax * cancel_time_ratio` 生成取消时刻。
5. 已按 job category 选择取消订单。
6. 本步骤未运行 MATLAB。
7. 本步骤未生成 `outputs/`。
8. 本步骤未修改 `raw_code/`。

下一步进入：

```text
Step G5：实现 job 分类规则
```

## 11. Step G5：job 分类规则

job 分类规则已在以下函数中实现：

```text
src/cancellation/build_order_cancellation_scenarios.m
```

第一版规则：

1. `random`：使用 `rng(seed)` 可复现随机选择 `job_id`，选择后恢复原随机数状态。
2. `short`：选择工序数最少的 job；若并列，选择 `job_id` 最小者。
3. `long`：选择工序数最多的 job；若并列，选择 `job_id` 最小者。
4. `critical`：选择 `baselineSchedule` 机器表中最后完成的 job；若并列，选择 `job_id` 最小者。
5. `noncritical`：选择 `baselineSchedule` 机器表中最早完成的 job；若并列，选择 `job_id` 最小者。

停止条件：

```text
如果无法从 baselineSchedule.machineTable 稳定判断 critical 或 noncritical，
则跳过对应场景，并把原因写入 summary.skipped.notes。
不强行伪造关键路径判断。
```

安全约束：

1. 生成的 `job_id` 必须满足 `1 <= job_id <= problem.jobNum`。
2. `short` 和 `long` 优先使用 `problem.operaNumVec`，没有时使用 `problem.jobInfo` 的行数。
3. `critical` 和 `noncritical` 只读取真实机器工序，不读取 `outputs/`。
4. 函数不运行局部修复、完全重调度或 NSGA-II。

Step G5 验收状态：

1. `random` job 可由 seed 复现。
2. `short` job 可按最少工序数生成。
3. `long` job 可按最多工序数生成。
4. `critical` job 可按最晚完工时间生成，无法判断时跳过并记录原因。
5. `noncritical` job 可按最早完工时间生成，无法判断时跳过并记录原因。
6. `job_id` 已做越界检查。
7. 场景 `notes` 已记录 job 分类选择口径或跳过原因。
8. 本步骤未运行 MATLAB。
9. 本步骤未生成 `outputs/`。
10. 本步骤未修改 `raw_code/`。

下一步进入：

```text
Step G6：场景库静态测试
```

## 12. Step G6：场景库静态测试

已新增：

```text
tests/test_order_cancellation_scenario_library.m
```

运行入口：

```matlab
run('tests/test_order_cancellation_scenario_library.m')
```

测试内容：

1. 能生成场景。
2. 每个场景有 `scenario_id`。
3. 每个场景有完整 `cancel` 字段。
4. 场景数量统计正确。
5. `random` job 对 seed 可复现。
6. `short`、`long`、`critical` 和 `noncritical` 分类结果符合最小构造 baseline。
7. 不写 `outputs/`。
8. 不运行 NSGA-II。

Step G6 验收状态：

1. 测试入口已存在。
2. 测试使用最小构造 `problem` 和 `baselineSchedule`。
3. 测试不依赖完整实验。
4. 测试不写 `outputs/`。
5. 测试不调用局部修复、完全重调度或 NSGA-II。
6. 本步骤未运行 MATLAB。
7. 本步骤未生成 `outputs/`。
8. 本步骤未修改 `raw_code/`。

下一步进入：

```text
Step G7：实现单场景库实验函数
```

## 13. Step G7：单场景库实验函数

已新增：

```text
src/cancellation/run_order_cancellation_library_scenario.m
```

函数入口：

```matlab
result = run_order_cancellation_library_scenario( ...
    problem, machineData, agvData, baselineSchedule, scenario, config)
```

当前功能：

1. 接收一个阶段 G 场景库 `scenario`。
2. 校验 `scenario_id`、`dataset`、`seed`、`time_window`、`job_category`、`cancel` 和 `cancel_time_ratio`。
3. 将场景库结构适配为阶段 F 单场景函数可识别的扁平结构。
4. 复用 `run_order_cancellation_scenario` 调用阶段 B-E 链路。
5. 返回一行 `result`。
6. 在 `result` 中补充 `scenario_id`、`dataset`、`time_window`、`job_category`、`cancel_time_ratio`、`library_seed` 和 `scenario_notes`。

边界说明：

1. 函数内部不写 `outputs/`。
2. 函数不读配置文件。
3. 函数不创建 timestamp 输出目录。
4. 函数不启动正式 NSGA-II 长实验。
5. 第一版复用阶段 D 当前候选生成方式。

Step G7 验收状态：

1. 单场景库实验函数已存在。
2. 每个 `result` 同时包含局部修复和完全重调度指标，这些字段来自既有 `run_order_cancellation_scenario`。
3. 每个 `result` 记录机器、AGV、工序顺序、冻结一致性和取消任务排除等约束检查字段。
4. 函数不在内部写 `outputs/`。
5. 函数不启动正式 NSGA-II 长实验。
6. 本步骤未运行 MATLAB。
7. 本步骤未生成 `outputs/`。
8. 本步骤未修改 `raw_code/`。

下一步进入：

```text
Step G8：实现场景库实验脚本
```

## 14. Step G8：场景库实验脚本

已新增：

```text
scripts/run_order_cancellation_scenario_library_experiment.m
```

运行入口：

```matlab
run('scripts/run_order_cancellation_scenario_library_experiment.m')
```

脚本功能：

1. 读取 `configs/order_cancellation_scenario_library.yaml`。
2. 遍历配置中的 `datasets`。
3. 为每个 dataset 读取 `problem` 并构造样例 `machineData`、`agvData` 和 `baselineSchedule`。
4. 调用 `build_order_cancellation_scenarios` 生成场景库。
5. 遍历所有场景。
6. 对每个场景调用 `run_order_cancellation_library_scenario`，复用阶段 B-E 链路。
7. 汇总结果。
8. 写入 timestamp 输出目录。

输出目录：

```text
outputs/order_cancellation_scenario_library/<timestamp>/
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

边界说明：

1. 该脚本会写入 `outputs/`，运行前需要确认。
2. 脚本使用 timestamp 子目录，不覆盖旧输出。
3. 脚本不修改 `raw_code/`。
4. 脚本第一版复用阶段 D 当前候选生成方式，不启动正式 NSGA-II 长实验。
5. 单个场景报错时会写入失败行，不中断整个场景库实验。

Step G8 验收状态：

1. 场景库实验脚本已存在。
2. 每个场景都会生成实验结果行，包含局部修复和完全重调度字段。
3. 每个场景结果会记录机器、AGV、工序顺序、冻结一致性和取消任务排除检查字段。
4. 输出会写入 `outputs/order_cancellation_scenario_library/<timestamp>/`。
5. 输出不会覆盖旧 timestamp 目录。
6. 本步骤未运行 MATLAB。
7. 本步骤未生成新的 `outputs/`。
8. 本步骤未修改 `raw_code/`。

下一步进入：

```text
Step G9：场景库实验汇总函数
```

## 15. Step G9：场景库实验汇总函数

已新增：

```text
src/cancellation/summarize_order_cancellation_library_results.m
```

函数入口：

```matlab
summary = summarize_order_cancellation_library_results(results)
```

汇总维度：

1. `summary.by_dataset`
2. `summary.by_time_window`
3. `summary.by_job_category`
4. `summary.by_seed`
5. `summary.by_selected_strategy`
6. `summary.by_feasibility`

指标：

1. `local_Cmax_delta_mean`
2. `complete_Cmax_delta_mean`
3. `local_SD_mean`
4. `complete_SD_mean`
5. `local_TD_mean`
6. `complete_TD_mean`
7. `local_energy_delta_mean`
8. `complete_energy_delta_mean`
9. `local_Y_mean`
10. `complete_Y_mean`
11. `selected_strategy_count`
12. `no_feasible_candidate_count`

脚本复用：

`scripts/run_order_cancellation_scenario_library_experiment.m` 已改为调用该汇总函数生成：

```text
scenario_summary.csv
category_summary.csv
strategy_counts.csv
```

Step G9 验收状态：

1. 能按 `time_window` 汇总。
2. 能按 `job_category` 汇总。
3. 能按 `dataset` 和 `seed` 汇总。
4. 能统计不可行数量。
5. 能统计策略选择次数。
6. 能输出均值指标。
7. 汇总函数不读文件、不写 `outputs/`、不运行调度实验。
8. 本步骤未运行 MATLAB。
9. 本步骤未生成 `outputs/`。
10. 本步骤未修改 `raw_code/`。

下一步进入：

```text
Step G10：场景库实验测试
```

## 16. Step G10：场景库实验汇总测试

已新增：

```text
tests/test_order_cancellation_scenario_library_experiment_summary.m
```

运行入口：

```matlab
run('tests/test_order_cancellation_scenario_library_experiment_summary.m')
```

测试内容：

1. 构造最小 result 数据。
2. 按 `time_window` 汇总正确。
3. 按 `job_category` 汇总正确。
4. 按 `seed` 汇总正确。
5. 策略次数统计正确。
6. 可行性类别统计正确。
7. 不可行数量统计正确。
8. 均值指标计算正确。

Step G10 验收状态：

1. 汇总测试入口已存在。
2. 测试只调用 `summarize_order_cancellation_library_results`。
3. 测试不运行场景库实验脚本。
4. 测试不写 `outputs/`。
5. 测试不运行调度实验或 NSGA-II。
6. 本步骤未运行 MATLAB。
7. 本步骤未生成 `outputs/`。
8. 本步骤未修改 `raw_code/`。

下一步进入：

```text
Step G11：写阶段 G 文档
```

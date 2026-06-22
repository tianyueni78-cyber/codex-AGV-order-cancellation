# 阶段 L 项目报告：大规模与统计验证

本文档是阶段 L 的主入口。阶段 L 的目标是验证订单取消处理策略在更多实例、更多场景和更多随机种子下是否稳定。

阶段 L 是验证阶段，不新增主算法。它承接阶段 B-K 已经形成的状态提取、候选生成、评价、混合策略和自适应权重流程，只扩展实验实例、场景、随机种子和统计汇总。

## 1. Step L1：阶段 L 范围确认

Step L1 的目标是明确阶段 L 的边界，防止验证阶段变成新的算法开发阶段。

阶段 L 允许做的事情：

1. 扩展 FJSP-AGV 数据实例。
2. 扩展订单取消场景。
3. 扩展随机种子数量。
4. 汇总均值、标准差、胜率和不可行率。
5. 记录每个实例、每个场景和每个 seed 的原始结果。
6. 基于统计范围形成稳定性结论。

阶段 L 不允许做的事情：

1. 不新增机器故障逻辑。
2. 不新增完整插单算法。
3. 不新增强化学习。
4. 不重写局部修复逻辑。
5. 不重写完全重调度逻辑。
6. 不重写评价函数。
7. 不重写自适应权重逻辑。
8. 不声称全局最优。

阶段 L 的验证对象是已有订单取消处理链路：

```text
订单取消事件
  -> 状态提取
  -> 局部修复候选
  -> 完全重调度候选
  -> 评价指标
  -> 混合或自适应策略选择
  -> 多实例、多场景、多 seed 统计验证
```

## 2. Step L1 验收结果

| 验收项 | 结果 |
|---|---|
| 不新增机器故障逻辑 | 通过，阶段 L 只验证订单取消策略 |
| 不新增完整插单算法 | 通过，`insert_order` 仍保持阶段 J 的接口预留状态 |
| 不新增强化学习 | 通过，阶段 L 不训练模型，不引入 RL |
| 不重写局部修复、完全重调度、评价或自适应权重逻辑 | 通过，阶段 L 复用阶段 B-K 已有链路 |
| 只扩展实例、场景、随机种子和统计汇总 | 通过，阶段 L 的新增工作限定在 benchmark 配置、运行入口和汇总分析 |

Step L1 完成标志：阶段 L 已被限定为“大规模与统计验证”阶段。后续可以进入 Step L2：定义 benchmark 配置。

## 3. Step L2：定义 benchmark 配置

Step L2 新增 benchmark 总控配置：

```text
configs/order_cancellation_benchmark.yaml
```

配置内容：

```yaml
datasets:
  - data_sample/Mk01.fjs

scenario_library_config: configs/order_cancellation_scenario_library.yaml

strategies:
  - fixed_weight
  - adaptive_weight

seeds: [1, 2, 3, 4, 5]

max_runtime_minutes: 30
output_base_dir: outputs/order_cancellation_benchmark
```

字段含义：

| 字段 | 含义 |
|---|---|
| `datasets` | benchmark 要遍历的数据实例列表，第一版先保留 `data_sample/Mk01.fjs`，后续可追加更多相对路径实例 |
| `scenario_library_config` | 复用阶段 G 场景库配置，避免在 benchmark 中重复定义场景生成规则 |
| `strategies` | 需要比较的策略，当前包含固定权重 `fixed_weight` 和自适应权重 `adaptive_weight` |
| `seeds` | benchmark 使用的随机种子列表，第一版为 5 个 seed |
| `max_runtime_minutes` | 运行预算字段，后续脚本应在超过预算时停止或缩小实验规模并记录原因 |
| `output_base_dir` | benchmark 输出根目录，后续运行脚本应写入 timestamp 子目录 |

阶段 L2 只定义配置，不运行 benchmark，不写 `outputs/`。

## 4. Step L2 验收结果

| 验收项 | 结果 |
|---|---|
| 每个实例路径都是相对路径 | 通过，当前为 `data_sample/Mk01.fjs` |
| 每个实例有配置记录 | 通过，实例统一记录在 `datasets` 列表中 |
| 随机种子明确 | 通过，`seeds: [1, 2, 3, 4, 5]` |
| 是否启用固定权重、自适应权重明确 | 通过，`strategies` 包含 `fixed_weight` 和 `adaptive_weight` |
| 有运行预算字段 | 通过，`max_runtime_minutes: 30` |

Step L2 完成标志：阶段 L benchmark 配置入口已经建立。后续可以进入 Step L3：定义 benchmark 单次运行结果结构。

## 5. Step L3：定义 benchmark 输出结构

Step L3 定义阶段 L benchmark 的标准输出目录和文件结构。后续运行脚本必须写入 timestamp 子目录，避免覆盖旧实验结果。

建议输出目录：

```text
outputs/order_cancellation_benchmark/<timestamp>/
```

建议输出文件：

```text
benchmark_config_used.yaml
seed_results.csv
scenario_summary.csv
dataset_summary.csv
strategy_summary.csv
feasibility_summary.csv
benchmark_summary.json
benchmark_notes.md
```

输出文件含义：

| 文件 | 含义 |
|---|---|
| `benchmark_config_used.yaml` | 记录本次 benchmark 实际使用的配置，包含数据集、场景库配置、策略列表、seed、运行预算和输出目录 |
| `seed_results.csv` | 保存每个 dataset / scenario / strategy / seed 的原始结果，保证每个 seed 可追踪 |
| `scenario_summary.csv` | 按场景汇总均值、标准差、可行率、胜率和不可行原因数量 |
| `dataset_summary.csv` | 按数据集汇总各策略的整体表现 |
| `strategy_summary.csv` | 分开统计 `fixed_weight` 和 `adaptive_weight` 的指标均值、标准差、胜率和选择次数 |
| `feasibility_summary.csv` | 汇总局部修复、完全重调度、固定权重策略和自适应权重策略的可行性结果 |
| `benchmark_summary.json` | 保存机器可读的总摘要，包括运行时间、配置摘要、样本数量、策略胜率和主要限制 |
| `benchmark_notes.md` | 保存人工可读说明，解释本次 benchmark 的范围、运行预算、异常情况和结论边界 |

输出结构要求：

1. 每个输出目录必须带 timestamp。
2. 不覆盖旧的 benchmark 输出目录。
3. 每个 seed 的原始结果必须保留在 `seed_results.csv`。
4. 场景、数据集、策略和可行性必须分别有汇总表。
5. 固定权重和自适应权重必须能分开统计。
6. 结论必须说明统计范围，不能声称全局最优。

阶段 L3 只定义输出结构，不创建 `outputs/`，不运行 benchmark。

## 6. Step L3 验收结果

| 验收项 | 结果 |
|---|---|
| 每个 seed 原始结果可追踪 | 通过，定义 `seed_results.csv` 保存每个 seed 的原始结果 |
| 每个场景有汇总 | 通过，定义 `scenario_summary.csv` |
| 每个数据集有汇总 | 通过，定义 `dataset_summary.csv` |
| 固定权重和自适应权重能分开统计 | 通过，定义 `strategy_summary.csv` 并要求按 `fixed_weight` / `adaptive_weight` 分组 |
| 输出目录带 timestamp，不覆盖旧结果 | 通过，定义 `outputs/order_cancellation_benchmark/<timestamp>/` |

Step L3 完成标志：阶段 L benchmark 的落盘结构已经固定。后续可以进入 Step L4：实现 benchmark 单次结果行结构。

## 7. Step L4：构造 benchmark 单次运行结果行

Step L4 定义 `seed_results.csv` 中每个 dataset / scenario / seed / strategy 的结果字段。每一行代表一个策略模式在一个场景和一个随机种子上的结果。

单次结果行字段：

| 字段 | 含义 |
|---|---|
| `dataset` | 数据实例相对路径 |
| `scenario_id` | 场景库生成的唯一场景编号 |
| `time_window` | 取消时刻窗口，例如 early / middle / late |
| `job_category` | 被取消订单类别，例如 random / short / long / critical / noncritical |
| `seed` | 随机种子 |
| `strategy_mode` | 策略模式，当前为 `fixed_weight` 或 `adaptive_weight` |
| `selected_strategy` | 当前策略模式最终选择的候选方案，例如 `local_repair` 或 `complete_rescheduling` |
| `is_selected` | 是否成功选出方案 |
| `local_feasible` | 局部修复候选是否可评价可行 |
| `complete_feasible` | 完全重调度候选是否可评价可行 |
| `Cmax_delta` | 被选中方案的最大完工时间变化 |
| `SD` | 被选中方案的机器工序扰动指标 |
| `TD` | 被选中方案的 AGV 运输扰动指标 |
| `energy_delta` | 被选中方案的能耗变化 |
| `Y` | 被选中方案的综合评价分数 |
| `constraint_feasible` | 被选中方案是否通过对应调度约束检查 |
| `no_feasible_candidate` | 是否两个候选都不可行或无法选择 |
| `runtime_seconds` | 当前行对应策略模式的运行时间记录 |
| `error_count` | 运行或评价错误数量 |
| `rejected_reason_count` | 不可行或拒绝原因数量 |

字段解释边界：

1. 指标字段记录“被选中方案”的指标，而不是同时展开局部修复和完全重调度的全部指标。
2. 局部修复和完全重调度的可行性通过 `local_feasible` 与 `complete_feasible` 保留。
3. 固定权重和自适应权重通过 `strategy_mode` 分开记录。
4. 不可行原因数量先记录为计数，详细文本后续可在需要时扩展到日志文件。
5. `runtime_seconds` 用于预算控制和实验规模评估，不作为调度目标。

## 8. Step L4 验收结果

| 验收项 | 结果 |
|---|---|
| 每个场景都有原始 seed 结果 | 通过，`seed_results.csv` 每行绑定 `dataset`、`scenario_id`、`seed` 和 `strategy_mode` |
| 指标字段包括 `Cmax_delta`、`SD`、`TD`、`energy_delta`、`Y` | 通过，结果行已包含这些字段 |
| 能记录不可行原因数量 | 通过，结果行包含 `rejected_reason_count` |
| 能记录运行时间 | 通过，结果行包含 `runtime_seconds` |

Step L4 完成标志：benchmark 原始结果行结构已经固定。后续可以进入 Step L5：实现 benchmark 脚本。

## 9. Step L5：实现 benchmark 脚本

Step L5 新增 benchmark 脚本：

```text
scripts/run_order_cancellation_benchmark.m
```

运行入口：

```matlab
run('scripts/run_order_cancellation_benchmark.m')
```

脚本流程：

1. 读取 `configs/order_cancellation_benchmark.yaml`。
2. 读取并复用 `configs/order_cancellation_scenario_library.yaml`。
3. 遍历 benchmark 配置中的 `datasets`。
4. 为每个 dataset 生成场景库。
5. 遍历每个 scenario 和 seed。
6. 先运行已有阶段 B-E 管线，得到候选方案和固定权重选择结果。
7. 对 `fixed_weight` 写入固定权重结果行。
8. 对 `adaptive_weight` 复用同一批候选，调用阶段 K 的自适应权重策略选择。
9. 写入 `outputs/order_cancellation_benchmark/<timestamp>/`。
10. 写出 `seed_results.csv`、各类 summary、`benchmark_summary.json` 和 `benchmark_notes.md`。

注意：该脚本会写入 `outputs/`，运行 MATLAB 前需要确认。

## 10. Step L5 验收结果

| 验收项 | 结果 |
|---|---|
| 能遍历多个 dataset | 通过，脚本遍历 `benchmarkConfig.datasets` |
| 能遍历多个场景 | 通过，脚本调用 `build_order_cancellation_scenarios` 生成场景库后逐个运行 |
| 能遍历多个 seed | 通过，benchmark seeds 会覆盖场景库 seeds |
| 能同时比较 `fixed_weight` 和 `adaptive_weight` | 通过，脚本按 `strategy_mode` 输出两类结果行 |
| 运行前需要确认，因为会写 `outputs/` | 通过，文档已明确；本步骤未运行脚本 |

Step L5 完成标志：阶段 L benchmark 运行入口已经建立，但尚未执行实验。后续可以进入 Step L6：实现或完善 benchmark 汇总测试。

## 11. Step L6：实现 benchmark 汇总函数

Step L6 新增 benchmark 汇总函数：

```text
src/cancellation/summarize_order_cancellation_benchmark.m
```

汇总维度：

1. `by_dataset`
2. `by_scenario`
3. `by_time_window`
4. `by_job_category`
5. `by_strategy_mode`
6. `by_selected_strategy`
7. `by_feasibility`

统计指标：

1. `mean`
2. `std`
3. `win_rate`
4. `infeasible_rate`
5. `selected_count`
6. `no_feasible_candidate_count`

指标字段：

```text
Cmax_delta
SD
TD
energy_delta
Y
```

第一版 `win_rate` 定义为 `is_selected == true` 的比例；`infeasible_rate` 定义为 `no_feasible_candidate == true` 的比例。它们用于阶段 L 统计验证，不表示全局最优胜率。

## 12. Step L6 验收结果

| 验收项 | 结果 |
|---|---|
| 能计算均值 | 通过，汇总函数为每个指标输出 `_mean` |
| 能计算标准差 | 通过，汇总函数为每个指标输出 `_std` |
| 能计算策略胜率 | 通过，输出 `win_rate` |
| 能计算不可行率 | 通过，输出 `infeasible_rate` |
| 能区分固定权重和自适应权重 | 通过，输出 `by_strategy_mode` |

Step L6 完成标志：benchmark 汇总函数已经独立出来，脚本也可复用该函数写出 summary。

## 13. Step L7：补充统计测试

Step L7 新增统计测试：

```text
tests/test_order_cancellation_benchmark_summary.m
```

运行入口：

```matlab
run('tests/test_order_cancellation_benchmark_summary.m')
```

测试内容：

1. 构造最小 benchmark 结果。
2. 验证均值。
3. 验证标准差。
4. 验证胜率。
5. 验证不可行率。
6. 验证按 dataset 汇总。
7. 验证按 strategy 汇总。

测试边界：

1. 不写 `outputs/`。
2. 不运行 NSGA-II。
3. 只验证汇总逻辑。
4. 不启动 benchmark 实验。

## 14. Step L7 验收结果

| 验收项 | 结果 |
|---|---|
| 测试不写 `outputs/` | 通过，测试只构造内存结构体 |
| 测试不运行 NSGA-II | 通过，测试只调用汇总函数 |
| 只验证汇总逻辑 | 通过 |
| 不启动 benchmark 实验 | 通过 |

Step L7 完成标志：阶段 L 汇总函数已有独立测试入口。后续可以进入 Step L8：运行小规模 benchmark smoke。

## 15. Step L8：运行小规模 benchmark smoke

Step L8 新增小规模 benchmark smoke 脚本：

```text
scripts/run_order_cancellation_benchmark_smoke.m
```

运行入口：

```matlab
run('scripts/run_order_cancellation_benchmark_smoke.m')
```

smoke 范围：

| 项目 | 设置 |
|---|---|
| dataset | `data_sample/Mk01.fjs` |
| scenarios | early / middle / late 各 1 类 |
| seeds | `[1, 2]` |
| strategies | `fixed_weight` / `adaptive_weight` |
| output base dir | `outputs/order_cancellation_benchmark_smoke` |

输出文件：

```text
outputs/order_cancellation_benchmark_smoke/<timestamp>/seed_results.csv
outputs/order_cancellation_benchmark_smoke/<timestamp>/scenario_summary.csv
outputs/order_cancellation_benchmark_smoke/<timestamp>/strategy_summary.csv
outputs/order_cancellation_benchmark_smoke/<timestamp>/feasibility_summary.csv
outputs/order_cancellation_benchmark_smoke/<timestamp>/benchmark_summary.json
outputs/order_cancellation_benchmark_smoke/<timestamp>/benchmark_notes.md
```

解释边界：

1. smoke 用于验证 benchmark 输出链路，不作为最终结论。
2. smoke 只覆盖 Mk01、3 类取消时刻、2 个 seed 和 2 类策略。
3. smoke 会写入 `outputs/`，运行 MATLAB 前需要确认。
4. smoke 不新增机器故障、完整插单、强化学习或全局最优证明。

## 16. Step L8 验收结果

| 验收项 | 结果 |
|---|---|
| 能写入 `outputs/` | 通过，脚本输出到 `outputs/order_cancellation_benchmark_smoke/<timestamp>/` |
| 能产生 `seed_results.csv` | 通过，脚本定义并写出 `seed_results.csv` |
| 能产生 summary | 通过，脚本写出 scenario / strategy / feasibility summary 和 `benchmark_summary.json` |
| 能对比 `fixed_weight` 和 `adaptive_weight` | 通过，脚本对两个 `strategy_mode` 分别写结果行 |
| 不作为最终结论 | 通过，`benchmark_notes.md` 和本文档均说明 smoke 仅验证输出链路 |

Step L8 完成标志：阶段 L 已有小规模 benchmark smoke 入口。后续可以手动运行 smoke，并把输出补入本报告；通过后再进入 Step L9 正式 benchmark。

已收到一次 smoke 运行输出：

```text
order cancellation benchmark smoke
dataset: data_sample/Mk01.fjs
scenario_count: 6
seed_count: 2
strategy_count: 2
result_row_count: 12
output_dir: outputs/order_cancellation_benchmark_smoke/20260622_162245
```

对应输出目录：

```text
outputs/order_cancellation_benchmark_smoke/20260622_162245/
```

本次 smoke 结果解读：

1. 一共生成了 6 个场景：`early/middle/late` 各自配合 `seed 1/2`。
2. 每个场景分别比较 `fixed_weight` 和 `adaptive_weight`，因此得到 12 行原始结果。
3. `middle_seed_1` 和 `middle_seed_2` 两个场景中，两种策略都成功选出了 `local_repair`。
4. `early_seed_1`、`early_seed_2`、`late_seed_1`、`late_seed_2` 中，两种策略都没有选出可行候选。
5. 从当前 smoke 看，固定权重和自适应权重的结果一致，还没有出现“自适应权重改变最终选择”的样例。

本次 summary 关键信息：

1. `strategy_summary.csv` 显示：
   `fixed_weight` 的 `win_rate = 0.333333`，`infeasible_rate = 0.666667`；
   `adaptive_weight` 的 `win_rate = 0.333333`，`infeasible_rate = 0.666667`。
2. `feasibility_summary.csv` 显示：
   `no_candidate_feasible = 8`，占比 `0.666667`；
   `both_candidates_feasible = 4`，占比 `0.333333`。
3. `scenario_summary.csv` 显示：
   只有 `middle_seed_1` 和 `middle_seed_2` 的 `win_rate = 1.0`；
   early 和 late 四个场景的 `win_rate = 0.0`，`infeasible_rate = 1.0`。

这个 smoke 说明：

1. 阶段 L 的输出链路已经打通，`seed_results.csv`、summary、json 和 notes 都能生成。
2. 当前 Mk01 smoke 规模下，固定权重和自适应权重尚未拉开差异。
3. 当前主要瓶颈不是“策略模式谁更好”，而是 early 和 late 这两类 smoke 场景下候选可行性不足。
4. 因此，正式 benchmark 的价值会更多体现在：扩大场景库后，观察哪些时间窗口、哪些订单类别、哪些策略模式更稳定。

该结果仍然只是 smoke 验证，不作为最终阶段 L 统计结论。

## 17. 阶段 L 测试和运行入口

当前阶段 L 可手动运行的入口：

```matlab
run('tests/test_order_cancellation_benchmark_summary.m')
run('scripts/run_order_cancellation_benchmark_smoke.m')
run('scripts/run_order_cancellation_benchmark.m')
```

其中 `run_order_cancellation_benchmark_smoke.m` 和 `run_order_cancellation_benchmark.m` 会写入 `outputs/`，运行前需要确认；`test_order_cancellation_benchmark_summary.m` 不写 `outputs/`，只验证汇总逻辑。

## 18. 支持文档入口

README 只挂阶段 L 主文档；阶段 L 依赖的上游文档可从这里进入。

| 文档 | 和阶段 L 的关系 |
|---|---|
| [阶段 G：场景库项目报告](stage_g_project_report.md) | 阶段 L 的场景扩展应复用阶段 G 的场景库思想 |
| [阶段 H：混合修复策略报告](stage_h_hybrid_policy_report.md) | 阶段 L 要验证混合策略触发规则是否稳定 |
| [阶段 K：自适应策略选择](stage_k_adaptive_strategy_plan.md) | 阶段 L 要验证自适应权重规则在更多实例和 seed 下是否稳定 |
| [阶段 E：评价与策略选择](stage_e_work_record.md) | 阶段 L 的统计指标仍来自阶段 E 的 Cmax_delta、SD、TD、energy_delta 和 Y |
| [阶段 G-N 后续路线图](post_stage_f_flexible_dispatch_roadmap.md) | 说明阶段 L 在长期路线中负责稳定性验证，而不是算法扩展 |

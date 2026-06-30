# 主实验入口分析

## 1. 这份文档讲什么

这份文档分析的是主实验入口 `scripts/run_random_order_cancellation_batch.m`。

它做的不是单次演示，而是把“一个批次的订单取消实验”拆成稳定的流水线：

```text
准备 baseline 正常计划
-> 枚举 dataset × strategyPolicy × cancelTime × seed
-> 对每个组合调用一次订单取消主流程
-> 把每次结果写成一行 CSV
```

这份文档只解释入口脚本本身，不展开算法内部实现细节。

## 2. 入口在做什么

这个脚本是主实验的批处理入口。它负责三件事：

1. 读取或生成 baseline 正常调度计划。
2. 组合实验参数，批量触发订单取消场景。
3. 汇总每个场景的结果，写入 `outputs/` 下的 CSV。

它的角色是“实验编排器”，不是“求解器本体”。

## 3. 参数是怎么展开的

脚本默认按四层循环跑：

```text
dataset
-> strategyPolicy
-> cancelTime
-> seed
```

默认参数在脚本顶部通过变量名覆盖：

```text
seeds = 1:30
cancelTimes = [5, 9, 13]
datasets = 5 个 Brandimarte 数据集
strategyPolicies = {'auto_selection'}
```

因此，实验行数是由这四个维度相乘得到的，不是手工逐条写死。

例如：

```text
1 个 dataset × 3 个 cancelTime × 30 个 seed × 1 个 policy = 90 行
```

如果再扩展到多个数据集或多个策略，行数会按同样规则增长。

## 4. baseline 正常计划怎么准备

每个 dataset 在进入取消实验前，都会先准备一个 baseline 正常调度计划。

当前入口支持三种 baseline 模式：

1. `sample`
2. `instance_decoded`
3. `static_solver`

它们的含义分别是：

1. `sample`：用样例机器 / AGV 数据和样例计划构造 baseline。
2. `instance_decoded`：先构造一个确定性 baseline 染色体，再走解码流程得到 baseline。
3. `static_solver`：先用一个小规模静态求解器跑出 baseline，再拿这个 baseline 进入取消实验。

baseline 生成后，会再做一次可行性检查。

这一步的作用是确认：

```text
baseline 自己先是可行的
后面的取消实验才有可对照的起点
```

## 5. 每个场景怎么跑

对每一个 `dataset + policy + cancelTime + seed` 组合，脚本会调用一次单场景处理流程。

输入主要是：

```text
datasetState
dataset
seed
cancelTime
strategyPolicy
```

场景处理时会先检查：

```text
cancelTime 是否落在 baseline Cmax 之前
是否存在可取消订单
```

然后构造取消场景，再进入订单取消主链路。

单场景结果会被整理成一条 row，最后统一写入 CSV。

## 6. 输出是什么

主入口的最终输出是一个批量 CSV：

```text
outputs/batch_random_order_cancellation/<timestamp>/batch_random_order_cancellation.csv
```

每一行代表一个实验组合。

常见字段包括：

```text
dataset
seed
cancel_time
strategy_policy
selected_strategy
run_through
feasible
Cmax_delta
SD
TD
Y
error_message
```

所以这个入口的核心价值不是“跑一遍看结果”，而是“把每个组合都变成可追踪的实验记录”。

## 7. 这份入口能验证什么

它能验证的是：

1. 主实验批处理流程能否稳定展开。
2. baseline 准备是否可行。
3. 每个取消场景是否能进入主链路。
4. 结果是否能落到 CSV。
5. 失败时是否保留错误信息。

它不能直接证明的是：

1. 全局最优。
2. 所有数据集都一样有效。
3. 所有策略在所有场景下都一致。
4. 这就是最终论文结论。

## 8. 运行方式

推荐在仓库根目录启动 MATLAB，然后运行批入口：

```matlab
run('scripts/run_random_order_cancellation_batch.m')
```

也可以先在工作区里覆盖参数，再运行入口脚本，例如：

```matlab
seeds = 1:3;
cancelTimes = [5 9];
datasets = {'data_sample/Mk01.fjs'};
strategyPolicies = {'auto_selection'};
baseline_mode = 'static_solver';
baselinePop = 8;
baselineMaxGen = 3;
baselineSeed = 1;
run('scripts/run_random_order_cancellation_batch.m')
```

## 9. 它和其他文档的关系

这份文档只解释主实验入口，不替代下面这些文档：

1. `docs/repro/order_cancellation_repro_guide.md`：复现说明。
2. `docs/repro/order_cancellation_strategy_baseline_results.md`：策略基线结果。
3. `docs/repro/order_cancellation_output_traceability.md`：输出追踪说明。
4. `docs/repro/project_final_summary.md`：总收口结论。

如果你是想快速看懂“主实验到底怎么批量跑起来的”，先看这份文档。

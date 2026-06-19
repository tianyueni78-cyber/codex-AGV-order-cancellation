# 评价层 Wrapper 验收说明

## 1. 评价层负责什么

评价层回答的问题是：

```text
这一条染色体对应的调度方案好不好？
```

在当前项目里，一条染色体的评价链路是：

```text
chrom
-> raw fitness.m
-> makespan
-> 机器能耗
-> AGV 能耗
-> 总能耗
-> 目标向量
```

评价层不负责搜索新的染色体。它只负责评价一条已经给定的染色体。

## 2. 当前入口

当前评价层 wrapper 入口是：

```text
src/evaluation/evaluate_chromosome.m
```

函数形式：

```matlab
result = evaluate_chromosome(chrom, problem, machineData, agvData, config)
```

这是单条染色体评价入口，不是种群搜索入口，也不会运行完整 NSGA-II。

## 3. 当前仍依赖 raw fitness.m

当前阶段不是独立 evaluation 实现。

当前 wrapper 仍依赖：

```text
raw_code/NSGA-II/fitness.m
```

调用 `evaluate_chromosome` 前，需要把对应 raw 算法目录加入 MATLAB path。

当前 wrapper 做的事情是：

```text
检查必要字段
检查明显错误的 chrom 格式
调用 raw fitness.m
把 raw 输出整理成 result 结构
```

它不重写 `fitness.m`，也不改变原始算法逻辑。

## 4. 输入结构

`chrom`

```text
一条染色体行向量。
当前编码长度必须等于 5 * sum(problem.operaNumVec)。
```

`problem`

必需字段：

```text
jobNum
jobInfo
operaNumVec
machineNum
candidateMachine
```

`machineData`

必需字段：

```text
distance_matrix
machineEnergy
```

`agvData`

必需字段：

```text
AGVNum
AGVSpeed
AGVEnergy
```

`config`

必需字段：

```text
AGVEG_MAX
AGVEG_MIN
eChargeSpeed
```

## 5. 输出 result 结构

`evaluate_chromosome` 返回 `result` 结构体，包含：

```text
FUNC
objectives
makespan
machineEnergy
agvEnergy
totalEnergy
machineTable
AGVTable
agvEGRecord
agvChargeNum
```

主要目标字段是：

```text
result.objectives   [makespan, totalEnergy]
result.makespan     调度完成时间
result.totalEnergy  machineEnergy + agvEnergy
```

调度表相关字段来自 raw `fitness.m` 的输出。

## 6. 如何复现这一层

在 MATLAB 中切到项目根目录：

```matlab
cd('D:\CODEX\code_refactor_project')
```

运行 smoke test：

```matlab
run('tests/test_evaluate_chromosome.m')
```

运行 invalid case 测试：

```matlab
run('tests/test_evaluation_invalid_cases.m')
```

正常通过时会看到类似：

```text
test_evaluate_chromosome passed: makespan=..., totalEnergy=...
test_evaluation_invalid_cases passed
```

这些测试使用小样本数据，不运行完整 NSGA-II，不运行 medium/formal 实验。

## 7. 测试通过代表什么

测试通过说明：

```text
一条染色体可以通过 wrapper 被评价
makespan 可以返回
totalEnergy 可以返回
缺必要字段时能清楚报错
fitness.m 不在 MATLAB path 时能清楚报错
明显错误的 chrom 格式会在进入 raw fitness.m 前被拦住
smoke test 不会在项目根目录新增文件
```

测试通过只代表 raw evaluation chain 已经可以通过稳定 wrapper 调用。

测试通过不代表项目已经有了独立 evaluation 实现。

## 8. 当前阶段没有完成什么

当前阶段没有完成：

```text
独立 makespan 计算
独立机器能耗计算
独立 AGV 能耗计算
替换 raw fitness.m
NSGA-II 搜索验证
medium/formal 实验验证
指标或画图
```

一句话总结：

```text
当前阶段 = raw fitness wrapper 验收。
不是当前阶段 = 独立 evaluation 重写。
```

## 9. 后续如何脱离 raw fitness.m

如果后续要去掉 raw `fitness.m` 依赖，需要另开小任务。

建议顺序：

```text
1. 保留当前 wrapper 作为 raw baseline。
2. 把 makespan 计算拆成纯函数。
3. 把机器能耗计算拆成纯函数。
4. 把 AGV 能耗计算拆成纯函数。
5. 构建独立 objective vector 函数。
6. 每个独立输出都用小样本和 raw fitness.m 对照。
7. 全部对照通过后，再考虑替换 wrapper 路径。
```

不要把这些工作和 wrapper 验收混在同一个阶段里做。

# 编码层 variation 结构说明：交叉与变异如何改变 chrom

本文只基于 `raw_code/NSGA-II/variation.m` 的静态阅读整理。当前只说明结构，不拆代码，不修改 `raw_code`，不调用 `sorting.m`、`fitness.m` 或 `NSGA2.m`。

## 1. variation.m 的作用

`variation.m` 属于编码层和搜索层之间的连接点。它不评价一个方案好不好，也不把方案排成时间表；它只做一件事：

```text
输入父代 population
通过交叉和变异生成 offspring population
```

它处理的染色体仍然是编码层结构：

```text
chrom = [OS(n), MS(n), AS(n), SS(2n)]
总长度 = 5n
n = sum(operaVec)
```

## 2. variation.m 如何切 chrom

代码里先计算：

```text
operaNum = sum(operaVec)
n_var = 5 * operaNum
os_len = operaNum
rs_len = 4 * operaNum
```

然后把一条染色体分成两大段：

```text
OS = chrom(1 : os_len)
RS = chrom(os_len + 1 : n_var)
```

其中：

```text
RS = [MS, AS, SS]
MS 长度 = n
AS 长度 = n
SS 长度 = 2n
RS 总长度 = 4n
```

所以，`variation.m` 没有把 `MS / AS / SS` 分开处理交叉，而是把它们合成 `RS` 统一处理。

## 3. UP 上界如何构造

`UP` 是 `RS = [MS, AS, SS]` 每个位置的取值上界，用于变异时重新随机取值。

构造规则是：

```text
MS 上界：每道工序候选机器数量 length(candidateMachine{job, operation})
AS 上界：AGVNum，重复 n 次
SS 上界：length(AGVSpeed)，重复 2n 次
```

也就是：

```text
UP = [
  每道工序的候选机器数量,
  AGVNum * ones(1, n),
  length(AGVSpeed) * ones(1, 2n)
]
```

下界没有单独写成 `LOW`，因为代码用：

```matlab
randperm(UP(k), 1)
```

这天然表示从 `1...UP(k)` 中随机选一个整数。

## 4. 父代选择

对每次循环，代码随机选一个父代：

```text
parent_1
```

如果触发交叉，则再随机选一个不同的：

```text
parent_2
```

如果不触发交叉，孩子默认就是 `parent_1` 的核心编码拷贝。

注意：`variation.m` 只取父代的前 `n_var = 5n` 列作为编码，不处理目标值、排序等级、拥挤度等搜索辅助列。

## 5. OS 使用 IPOX 交叉

`OS` 是工件顺序编码。它必须保持每个工件出现次数不变，否则就会破坏工序数量约束。

`variation.m` 对 `OS` 使用 IPOX 交叉：

```text
随机选择一组 job_set
在 parent_1_os 中保留不属于 job_set 的位置
空出来的位置按 parent_2_os 中属于 job_set 的相对顺序填入
另一个孩子反向操作
```

这样做的目的：

```text
既混合两个父代的 OS 顺序
又保持每个工件出现次数不变
```

所以，`OS` 不是普通数值向量，不能随便逐点随机替换。它是带重复工件编号的排列型结构。

## 6. RS 使用 MPX 交叉

`RS = [MS, AS, SS]` 是整数选择型结构。

`variation.m` 对 `RS` 使用 MPX 交叉：

```text
随机选择若干 RS 位置
child_1_rs 先复制 parent_2_rs
child_2_rs 先复制 parent_1_rs
在随机位置上再交换回对应父代的值
```

可以理解为：

```text
RS 交叉是按位置混合两个父代的机器选择、AGV 选择和速度选择
```

因为 `MS / AS / SS` 每个位置都有明确上界，所以这种按位置混合不会改变长度，也不会改变位置含义。

## 7. OS 使用交换变异

如果触发变异，代码先对 `OS` 做交换变异：

```text
随机选两个 OS 位置
要求两个位置的工件编号不同
交换这两个位置的值
```

这样做会改变工件处理顺序，但不会改变每个工件出现次数。

## 8. RS 使用多点重采样变异

同一次变异里，代码还会对 `RS` 做多点变异：

```text
随机决定若干 RS 位置
对每个选中位置，根据 UP(k) 从 1...UP(k) 重新随机取值
```

这意味着：

```text
MS 位置重新选择候选机器索引
AS 位置重新选择 AGV 编号
SS 位置重新选择速度档编号
```

变异比例大约来自：

```text
round(0.05 * rs_len)
```

代码实际会先在 `1...round(0.05 * rs_len)` 里随机选一个数量，再随机挑这些 RS 位置变异。

## 9. 输出 offspring 的数量特点

`variation.m` 的外层循环跑 `N_size` 次。每次可能产生：

```text
未交叉：1 个 child
交叉：2 个 child
```

然后把 child 追加到 `off_spring` 里。

所以 `off_spring` 的行数不一定严格等于父代行数，后续搜索层通常还会通过筛选或替换函数控制种群规模。

## 10. F3 后续封装建议

后续封装可以继续拆成这些小函数：

```text
build_rs_upper_bounds(problem, agvData)
    构造 RS = [MS, AS, SS] 的 UP 上界

crossover_os_ipox(parent1OS, parent2OS, jobNum)
    只处理 OS 的 IPOX 交叉

crossover_rs_mpx(parent1RS, parent2RS)
    只处理 RS 的 MPX 交叉

mutate_os_swap(OS)
    只处理 OS 的交换变异

mutate_rs_resample(RS, UP)
    只处理 RS 的多点重采样变异

generate_offspring(parentPopulation, problem, agvData, options)
    组合以上步骤，输出 offspring population
```

完成整个 F3 时，需要满足：

```text
输入父代 population
输出 offspring population
offspring 每条 chrom 都通过 validate_chromosome 或 validate_population
不调用 sorting.m
不调用 fitness.m
不调用 NSGA2.m
```

当前本文只完成 F3.1：读懂 `variation.m` 并形成结构说明。

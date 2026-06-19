# 编码层结构笔记：chrom 是怎么生成和变化的

## 1. 这份笔记解决什么问题

这份笔记只回答编码层问题：

```text
算法搜索的 chrom 到底长什么样？
它是怎么生成的？
交叉和变异时哪些部分会变？
每一段的取值范围由什么决定？
```

它不分析 `sorting.m`，不分析 `fitness.m`，也不解释完整实验流程。

## 2. 编码层在五层结构中的位置

当前系统核心分为五层：

```text
Data -> Encoding -> Decoding -> Evaluation -> Search
```

编码层位于数据层之后、解码层之前。

数据层提供：

```text
jobNum
operaVec
candidateMachine
AGVNum
AGVSpeed
```

编码层把这些信息变成算法可以搜索的染色体：

```text
chrom = [OS, MS, AS, SS]
```

## 3. 编码层主代码对应哪些文件

当前编码层主代码主要对应两个原始函数：

| 文件 | 作用 | 当前封装状态 |
|---|---|---|
| `raw_code/NSGA-II/init.m` | 生成初始 `chrom` 种群 | 仍使用原始函数，尚未封装到 `src/encoding/` |
| `raw_code/NSGA-II/variation.m` | 在搜索过程中对 `chrom` 做交叉和变异，生成新的 `chrom` | 仍由原始 `NSGA2.m` 内部调用，尚未封装 |

当前已经确认的编码层主结构是：

```text
chrom = [OS(n), MS(n), AS(n), SS(2n)]
总长度 = 5n
init.m 负责生成初始 chrom
variation.m 负责交叉/变异后生成新 chrom
```

这里的 `n` 是：

```text
n = operaNum = sum(operaVec)
```

所以当前编码层状态可以概括为：

```text
主代码结构已经拆清楚。
编码层函数还没有正式封装。
后续要把 split / validate / generate 入口放到 src/encoding/。
```

## 4. chrom 的真实结构

设：

```text
n = operaNum = sum(operaVec)
```

那么一条核心染色体长度是：

```text
5 * n
```

结构为：

| 段 | 位置 | 长度 | 含义 |
|---|---|---:|---|
| OS | `1 : n` | `n` | 工件顺序 |
| MS | `n+1 : 2n` | `n` | 候选机器选择 |
| AS | `2n+1 : 3n` | `n` | AGV 选择 |
| SS | `3n+1 : 5n` | `2n` | 速度档选择 |

所以：

```text
chrom = OS(n) + MS(n) + AS(n) + SS(2n)
```

## 5. 四段编码分别起什么作用

编码层的四段不是四条独立算法，而是同一条调度决策的四个侧面。

| 编码段 | 它决定什么 | 它保证什么 | 它不保证什么 |
|---|---|---|---|
| `OS` | 工件出现顺序，也就是“下一步优先调度哪个工件的下一道工序” | 每个工件出现次数等于该工件工序数 | 不直接给出每道工序的开始/结束时间 |
| `MS` | 每道工序在候选机器列表里选第几个机器 | 不会选出候选机器范围之外的索引 | 不保证机器时间不冲突 |
| `AS` | 每道工序由哪辆 AGV 搬运 | AGV 编号在 `1...AGVNum` 内 | 不保证 AGV 当前有空，也不保证运输时间可行 |
| `SS` | 每道工序对应两个速度档选择 | 速度档在 `1...length(AGVSpeed)` 内 | 不直接说明这两个速度分别用于哪个运输阶段 |

因此，编码层只保证“决策表达合法”。它不负责把方案排成真实时间轴。

真实调度约束，例如：

```text
前一道工序完成后，后一道工序才能开始
机器同一时间只能加工一个任务
AGV 需要先去取工件，再把工件送到目标机器
工件加工完成后才能被送往下一位置
AGV 电量不足时可能需要充电
```

这些不由编码层直接完成，而是交给后续解码层 `sorting.m` 处理。编码层给出“选择”，解码层负责判断这些选择如何落成可执行调度。

## 6. 编码层的整体流程

编码层相关流程可以先理解成：

```text
数据层提供结构信息
-> init.m 生成初始 chrom
-> NSGA2.m 把 chrom 送去评价
-> variation.m 在搜索过程中产生新的 chrom
-> 新 chrom 再被送去评价和筛选
```

其中数据层提供：

```text
jobNum
operaVec
candidateMachine
AGVNum
AGVSpeed
```

这些数据决定了编码的长度和边界：

```text
operaVec 决定 OS/MS/AS/SS 的长度
candidateMachine 决定 MS 的上界
AGVNum 决定 AS 的上界
AGVSpeed 决定 SS 的上界
```

## 7. init.m 做了什么

`init.m` 负责生成初始种群。

生成流程是：

```text
1. 根据 operaVec 生成 OS 的工件编号池
2. 打乱 OS，得到工序调度顺序
3. 为每道工序随机选择一个候选机器索引，得到 MS
4. 为每道工序随机选择 AGV，得到 AS
5. 为每道工序生成两个速度档选择，得到 SS
6. 拼成 chrom = [OS, MS, AS, SS]
```

其中：

```text
OS 来自工件编号的随机排列
MS 来自每道工序候选机器数量
AS 来自 AGVNum
SS 来自 speedNum
```

## 8. NSGA2.m 怎么使用 chrom

`NSGA2.m` 中确认：

```text
dim = 5 * operaNum
```

前 `dim` 列是真正编码。

算法运行时，会在后面追加：

```text
目标值
非支配排序信息
拥挤度等搜索辅助信息
```

但这些追加列不属于编码层核心结构。

真正送去评价时，仍然只取：

```text
chrom(:, 1:dim)
```

## 9. variation.m 怎么处理 chrom

`variation.m` 把染色体分成两大部分：

```text
OS = chrom(1:n)
RS = chrom(n+1:5n)
```

其中：

```text
RS = [MS, AS, SS]
```

也就是说：

```text
RS 长度 = 4n
MS 长度 = n
AS 长度 = n
SS 长度 = 2n
```

交叉时：

```text
OS 使用 IPOX 方式交叉
RS 使用 MPX 方式交叉
```

变异时：

```text
OS：交换两个位置
RS：随机选一些位置，按对应上界重新取值
```

这里可以理解为：

```text
OS 维护工序顺序这种“排列型结构”
RS 维护机器、AGV、速度这些“整数选择型结构”
```

所以 `variation.m` 不是随便改数字，而是在不同结构上用不同方式变化：

| 部分 | 为什么单独处理 | 变化方式 |
|---|---|---|
| `OS` | 必须保持每个工件出现次数不变 | 交叉时按工件集合交换；变异时交换两个位置 |
| `RS = [MS, AS, SS]` | 每个位置都有自己的整数上界 | 交叉时按位置混合；变异时按 `UP` 重新取值 |

## 10. MS / AS / SS 的上界

`variation.m` 构造了一个 `UP`，用于限制 RS 变异后的取值范围。

`UP` 的结构是：

```text
MS 上界：每道工序候选机器数量
AS 上界：AGVNum
SS 上界：length(AGVSpeed)
```

因此：

| 段 | 下界 | 上界 |
|---|---:|---|
| MS | 1 | `length(candidateMachine{job, operation})` |
| AS | 1 | `AGVNum` |
| SS | 1 | `length(AGVSpeed)` |

下界没有显式写成 `LOW`，因为代码用 `randperm(UP(k), 1)`，天然表示从 `1...UP(k)` 中取一个整数。

## 11. 编码层和解码层的边界

这一点很重要：编码层不是完整调度方案，它只是“调度决策表达”。

例如：

| 问题 | 编码层能回答吗 | 谁来真正处理 |
|---|---|---|
| 这道工序排在调度序列中的什么位置？ | 能，靠 `OS` | 编码层 |
| 这道工序选第几个候选机器？ | 能，靠 `MS` | 编码层 |
| 这道工序由哪辆 AGV 搬？ | 能，靠 `AS` | 编码层 |
| 这次运输用哪个速度档？ | 能，靠 `SS` | 编码层 |
| 这道工序什么时候开始加工？ | 不能 | 解码层 `sorting.m` |
| 机器是否有空闲时间可以插入？ | 不能 | 解码层 `sorting.m` |
| AGV 是否要先空载去取工件？ | 不能 | 解码层 `sorting.m` |
| 加工完之后能不能马上运输？ | 不能 | 解码层 `sorting.m` |
| 电量不够是否要充电？ | 不能 | 解码层 `sorting.m` |
| 最终 makespan 和 energy 是多少？ | 不能 | 评价层 `fitness.m` |

所以当前笔记只确认编码层结构。你提到的“做完一个工序后才能送去下一台机器”“AGV 送到一个机器之后才能继续送下一段”等，是更接近解码层的时间和资源约束，后续需要在解码层结构笔记中单独展开。

## 12. 当前仍未确认的点

`SS` 长度是 `2 * operaNum`。

从命名和长度看，它应该表示每道工序两个速度档选择。很可能对应空载运输速度和负载运输速度。

但具体两个速度分别用于哪个运输阶段，需要等解码层读取 `sorting.m` 时确认。

## 13. 编码层下一步封装依据

根据当前结构，后续编码层封装可以围绕三个能力展开：

```text
split_chromosome
validate_chromosome
generate_initial_population
```

其中：

```text
split_chromosome 负责拆出 OS / MS / AS / SS
validate_chromosome 负责检查长度和取值范围
generate_initial_population 负责统一生成初始种群
```

第一轮封装不应该改 `init.m`，而是先建立自己的入口，内部暂时调用原始 `init.m`。

## 14. 为什么先封装一条 chrom

当前已经新增的第一步封装是：

```text
src/encoding/split_chromosome.m
```

它只做一件事：

```text
把一条 chrom 向量按位置拆成 OS / MS / AS / SS。
```

这里的“只拆一条”不是说正式项目只处理一条染色体。正式搜索算法当然会处理一个种群，也就是很多条染色体。

之所以第一步先处理一条，是因为：

```text
一条 chrom 是编码层的最小单位。
种群 population 只是很多条 chrom 叠在一起。
```

所以封装顺序是：

```text
先把 1 条 chrom 的结构拆清楚
-> 再检查 1 条 chrom 是否合法
-> 再对种群里的每一条 chrom 重复这个检查
-> 最后接入初始种群生成和搜索脚本
```

换句话说：

```text
split_chromosome 处理 1 条 chrom。
后续测试或上层函数可以循环处理很多条 chrom。
```

这样做的原因是降低风险。如果一条染色体都拆不对，就不应该直接处理整个种群。

当前 `split_chromosome` 不做：

```text
不生成 chrom
不判断 chrom 是否完整合法
不调用 NSGA-II
不调用 sorting.m
不调用 fitness.m
不保存 outputs
```

这些会分给后续函数：

```text
validate_chromosome：判断 1 条 chrom 是否合法
generate_initial_population：生成多条 chrom，也就是初始种群
test_encoding_layer：用小样本检查编码层最小闭环
```

当前已经新增：

```text
src/encoding/split_chromosome.m
src/encoding/validate_chromosome.m
```

其中 `validate_chromosome.m` 只检查编码层合法性：

```text
chrom 长度是否至少包含 5n 个核心编码位
OS 中每个工件出现次数是否等于工序数
MS 是否在每道工序的候选机器范围内
AS 是否在 1...AGVNum 内
SS 是否在 1...length(AGVSpeed) 内
```

它不检查：

```text
机器时间是否冲突
AGV 时间是否冲突
工序能不能按时间执行
电量是否足够
makespan 和 energy 是多少
```

这些仍然属于后续解码层和评价层。

## 15. validate_chromosome 的用途与边界

`validate_chromosome` 是编码层的合法性检查函数。它的用法是：

```matlab
[isValid, report] = validate_chromosome(chrom, problem, agvData);
```

它检查的是一条 `chrom` 的编码层合法性，也就是这条染色体能不能被看作合法的：

```text
chrom = [OS(n), MS(n), AS(n), SS(2n)]
```

其中：

```text
n = sum(problem.operaNumVec)
核心编码长度 = 5n
```

### 输入

`chrom` 是一条染色体向量。它至少要包含 `5n` 个核心编码位，分别对应 `OS / MS / AS / SS`。如果核心编码后面还有目标值、排序信息、拥挤度等额外列，函数会把这些额外列记录到 `report.extraColumnCount`，并给出 warning。

`problem` 是问题结构信息，至少需要包含：

```text
problem.jobNum
problem.operaNumVec
problem.candidateMachine
```

它们分别用于判断工件数量、每个工件的工序数、每道工序可选机器范围。

`agvData` 是 AGV 和速度档信息，至少需要包含：

```text
agvData.AGVNum
agvData.AGVSpeed
```

它们分别用于判断 AGV 编号范围和速度档编号范围。

### 输出

`isValid` 是快速判断结果：

```text
true：没有发现编码错误
false：发现至少一个编码错误
```

`report` 是详细检查报告，主要包含：

```text
report.errors：错误列表
report.warnings：警告列表
report.extraColumnCount：核心 5n 后面多出来的列数
report.operaNum：总工序数 n
report.dim：核心编码长度 5n
report.isValid：和 isValid 一致
```

所以，`isValid` 用来快速判断“这条 chrom 能不能过编码层检查”，`report` 用来查看“具体哪里不合法”。

### 检查内容

`validate_chromosome` 当前检查这些编码层合法性：

```text
chrom 长度是否至少包含 5n 个核心编码位
OS 中每个工件出现次数是否等于该工件的工序数
MS 是否在每道工序的候选机器范围内
AS 是否在 1...AGVNum 内
SS 是否在 1...length(AGVSpeed) 内
```

更具体地说：

| 编码段 | 检查内容 |
|---|---|
| `OS` | 必须是整数；工件编号必须在 `1...problem.jobNum`；每个工件出现次数必须等于 `problem.operaNumVec` |
| `MS` | 必须是整数；每个位置的机器索引必须在对应工序的 `candidateMachine{job, operation}` 范围内 |
| `AS` | 必须是整数；AGV 编号必须在 `1...agvData.AGVNum` 内 |
| `SS` | 必须是整数；速度档编号必须在 `1...length(agvData.AGVSpeed)` 内 |

### 不负责内容

`validate_chromosome` 只检查“编码写得是否合法”，不负责把方案排成真实时间表。

它不做：

```text
不生成 chrom
不生成初始种群
不解码 schedule
不调用 sorting.m
不调用 fitness.m
不运行 NSGA-II
不计算 makespan
不计算 energy
不检查机器时间冲突
不检查 AGV 时间冲突
不检查工序前后约束是否能在时间线上成立
不检查 AGV 电量是否足够
不生成 outputs
不写结果文件
```

这些内容属于后续的解码层、评价层和搜索层。
## 16. 2026-05-25 编码层封装完成状态

当前编码层第一版正式封装已经完成。这里的“完成”指编码层本身可以独立生成、检查和变化染色体，不代表解码层、评价层、搜索层已经全部完成。

### 已完成函数清单

| 函数 | 作用 |
|---|---|
| `split_chromosome(chrom, problem)` | 把一条 `chrom` 拆成 `OS / MS / AS / SS / extraColumns` |
| `validate_chromosome(chrom, problem, agvData)` | 检查一条 `chrom` 的编码层合法性 |
| `validate_population(population, problem, agvData)` | 逐条检查 population，统计 `validCount / invalidCount / invalidIndexes` |
| `generate_initial_population(popSize, problem, agvData)` | 生成初始 population，并调用 `validate_population` |
| `build_rs_upper_bounds(problem, agvData)` | 构造 `RS = [MS, AS, SS]` 的每个位置上界 `UP` |
| `crossover_os_ipox(parent1OS, parent2OS, jobNum)` | 只处理 `OS` 的 IPOX 交叉 |
| `crossover_rs_mpx(parent1RS, parent2RS)` | 只处理 `RS` 的 MPX 交叉 |
| `mutate_os_swap(OS)` | 只处理 `OS` 的交换变异 |
| `mutate_rs_resample(RS, UP)` | 只处理 `RS` 的多点重采样变异 |
| `generate_offspring(parentPopulation, problem, agvData, options)` | 组合交叉和变异，生成 offspring，并验证 offspring |

### 当前调用关系

```text
generate_initial_population
-> validate_population
   -> validate_chromosome
      -> split_chromosome

generate_offspring
-> build_rs_upper_bounds
-> crossover_os_ipox
-> crossover_rs_mpx
-> mutate_os_swap
-> mutate_rs_resample
-> validate_population
```

### 当前测试入口

```matlab
run('tests/test_encoding_layer.m')
run('tests/test_encoding_invalid_cases.m')
run('scripts/run_encoding_smoke.m')
```

`test_encoding_layer.m` 验证正常闭环：

```text
读 sample 数据
-> 生成初始 population
-> 验证 population
-> 生成 offspring
-> 再次验证 offspring
```

`test_encoding_invalid_cases.m` 验证异常输入：

```text
非法长度
OS 错误
MS 错误
AS 错误
SS 错误
混合 population 统计
```

### 当前边界

编码层已经脱离：

```text
raw_code/NSGA-II/init.m
raw_code/NSGA-II/variation.m
sorting.m
fitness.m
NSGA2.m
outputs
```

编码层仍然需要输入结构：

```text
problem.jobNum
problem.operaNumVec
problem.candidateMachine
agvData.AGVNum
agvData.AGVSpeed
```

下一阶段重点不再是编码层本身，而是：

```text
Decoding Layer：sorting.m 结构拆解与封装
Search Layer：正式 NSGA-II 如何接入新编码层
```

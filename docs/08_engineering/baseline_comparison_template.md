# baseline 对比模板

## 这份模板解决什么问题

论文里如果要证明“本文算法比 baseline 好”，不能临时手动跑几个脚本、复制几个结果。

baseline 对比必须做到：

```text
同一数据
同一 seed 或 seedList
同一 pop / max_gen
同一评价函数
统一 obj_matrix 输出
统一 metrics
统一图表
统一结果表
```

当前阶段不是正式 baseline 对比。

当前阶段只是建立 baseline 对比模板，不运行算法，不生成 outputs。

## baseline 和 variant 定义

`baseline` 是论文对比中的参考算法。

`variant` 是你提出的新算法或改进版本。

例子：

```text
baseline:
  NSGA-II
  MOEA/D
  MOPSO
  MOSSA
  SPEA2
  原始 INSGA-II

variant:
  改进 NSGA-II
  加 VNS 的 NSGA-II
  加自适应变异的 NSGA-II
  加新目标函数的版本
  加 Q-learning 算子选择的版本
```

不要把 baseline 和本文算法混在同一个名字里。

## 当前可用 baseline 算法

只读盘点 raw 目录后，当前可作为 baseline 参考的算法包括：

```text
raw_code/NSGA-II/
  主要入口：NSGA2.m
  相关函数：init.m, fitness.m, sorting.m, variation.m,
           non_domination.m, tournament_selection.m, replace_chrom.m

raw_code/INSGA-II/
  主要入口：INSGA_II.m
  相关函数：VNS.m, improved_elitism.m, reverse_pop.m,
           both_reverse_pop.m, fitness.m, sorting.m, variation.m

raw_code/MOEAD/
  主要入口：MOEAD.m
  相关函数：generateLamda.m, get_neighbor.m, update_neighbor.m,
           compare.m, fitness.m, sorting.m, variation.m

raw_code/MOSSA/
  主要入口：MOSSA.m
  相关函数：fitness.m, sorting.m, non_domination.m

raw_code/MOPSO/
  主要入口：MOPSO.m
  相关函数：fitness.m, sorting.m, non_domination.m

raw_code/SPEA2/
  主要入口：spea2.m 或 main.m
  相关函数：BinaryTournamentSelection.m, Crossover.m, Mutate.m,
           Dominates.m, fitness.m, sorting.m
```

这些 raw 算法多数共享当前问题的编码、解码、`fitness.m` 或 `sorting.m` 思路。

raw 目录只作为参考和 baseline 来源，不直接修改。

## 输入公平性规则

所有 baseline 和 variant 必须使用同一组输入：

```text
dataset
problem
machineData
agvData
candidateMachine
AGV 参数
energy 参数
pop
max_gen
p_cross
p_mutation
seed / seedList
```

如果某个算法有特有参数，必须记录在：

```text
run_info.txt
```

例如：

```text
VNS maxIter
Q-learning alpha / gamma / epsilon
MOEA/D neighbor size
MOPSO inertia weight
SPEA2 archive size
```

公平性原则：

```text
不能 baseline 用小数据、variant 用大数据
不能 baseline 用少代数、variant 用多代数
不能只给 variant 调参
不能不同算法用不同评价函数
不能不同算法用不同 seedList
```

## 统一输出结构

每个算法最终必须输出：

```text
algorithmName
runType
seed
obj_matrix
chrom 或 solutionSet
runTime
bestMakespan
bestTotalEnergy
paretoSolutionCount
```

推荐输出目录：

```text
outputs/comparison_<experiment_name>/<timestamp>/<algorithmName>/<seed>/
```

每个算法 seed 目录至少包含：

```text
result.mat
summary.txt
run_info.txt
```

其中：

```text
result.mat
  保存 obj_matrix、解集、config、runInfo

summary.txt
  保存快速结果摘要

run_info.txt
  保存输入、seed、参数、算法名、输出目录
```

这样 metrics 和 visualization 层才能统一读取。

## metrics 对比规则

对比指标建议：

```text
HV
IGD
Spacing
C-metric
runTime
paretoSolutionCount
bestMakespan
bestTotalEnergy
```

注意：

```text
HV 需要 referencePoint
IGD 需要 referenceFront
C-metric 是两两算法比较
Spacing 衡量解集分布
runTime 要说明机器和环境
```

metrics 不应该混在算法运行脚本里。

推荐流程：

```text
1. 先跑算法
2. 保存 obj_matrix
3. 再统一跑 metrics
4. 写 metrics/summary.txt
5. 最后汇总结果表
```

如果新目标导致 `obj_matrix` 维度变化，必须先更新 metrics 文档和测试。

## 多 seed 对比流程

正式论文对比不建议只跑一个 seed。

推荐：

```matlab
seedList = [42, 43, 44, 45, 46];
```

每个算法、每个 seed 都生成独立目录：

```text
outputs/comparison_xxx/<timestamp>/<algorithm>/<seed>/
```

最终汇总：

```text
mean
std
best
worst
```

多 seed 的好处：

```text
减少单次随机结果偶然性
可以报告稳定性
可以做表格统计
可以画 boxplot
```

## 结果表模板

整体指标表：

| Algorithm | HV mean | HV std | IGD mean | IGD std | Spacing mean | Runtime mean | Best Cmax | Best Energy |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| NSGA-II |  |  |  |  |  |  |  |  |
| MOEA/D |  |  |  |  |  |  |  |  |
| MOPSO |  |  |  |  |  |  |  |  |
| Variant |  |  |  |  |  |  |  |  |

C-metric 两两对比表：

| Algorithm A | Algorithm B | C(A,B) | C(B,A) |
|---|---|---:|---:|
| Variant | NSGA-II |  |  |
| Variant | MOEA/D |  |  |
| Variant | MOPSO |  |  |

如果论文需要显著性检验，可以另加：

```text
Wilcoxon
t-test
rank
```

但统计检验应单独记录方法，不要混在算法运行中。

## 图表模板

推荐图表：

```text
Pareto scatter comparison
Convergence curve comparison
Boxplot for HV / IGD
Runtime bar chart
Gantt chart for representative solution
Energy curve for representative solution
```

输出路径：

```text
outputs/comparison_<experiment_name>/<timestamp>/figures/
```

图表生成原则：

```text
先读取 result.mat / metrics summary
再统一生成图片
不要在算法运行时顺手画图
不要写 raw_code/figures
不要写项目根目录图片
```

如果是二维目标：

```text
x = makespan
y = totalEnergy
```

如果新增目标，要明确图中展示哪两个或哪三个目标。

## baseline 对比运行顺序

推荐顺序：

```text
1. 先跑 config dry-run
2. 跑 small baseline check
3. 跑 single-seed comparison smoke
4. 跑 medium comparison
5. 跑 formal multi-seed comparison
6. 跑 metrics
7. 跑 visualization
8. 写结果表
```

不要：

```text
不要一上来跑 formal multi-seed
不要一边改算法一边跑对比
不要不同算法使用不同数据
不要不同算法使用不同 pop / max_gen
不要手动复制结果覆盖 outputs
不要把 metrics 写死在某个算法脚本里
```

## single-seed smoke 对比

在正式多 seed 前，先做一次小规模单 seed smoke：

```text
seed = 42
pop <= 10
max_gen <= 2
```

目标：

```text
每个算法入口能跑
每个算法 obj_matrix 非空
每个算法输出结构一致
summary / run_info 存在
不污染 raw_code
```

这个阶段不追求论文结果，只检查流程。

## medium 对比

single-seed smoke 通过后，再做 medium：

```text
pop = medium config
max_gen = medium config
seed = 42
```

目标：

```text
确认算法能在中等规模下跑完
确认输出目录和 metrics 可读
确认没有路径问题和索引越界
```

medium 通过后才进入 formal multi-seed。

## formal multi-seed 对比

formal 对比必须单独开任务。

需要先确认：

```text
formal preflight 通过
seedList 确认
baseline 列表确认
variant 列表确认
输出目录确认
磁盘空间确认
```

然后按 seed 和 algorithm 逐个运行，避免一次性不可控。

## checklist

运行 baseline 对比前检查：

```text
[ ] baseline 列表已确定
[ ] variant 列表已确定
[ ] 所有算法使用同一 dataset
[ ] 所有算法使用同一 machineData / agvData
[ ] 所有算法使用同一 pop / max_gen
[ ] 所有算法使用同一 seedList
[ ] 所有算法使用同一 evaluation
[ ] 每个算法输出 obj_matrix
[ ] 每个算法保存 summary.txt
[ ] 每个算法保存 run_info.txt
[ ] 每个算法 run_info 记录特有参数
[ ] metrics 单独运行
[ ] figures 单独生成
[ ] outputs 不进 Git
[ ] raw_code 未修改
```

运行后检查：

```text
[ ] 每个算法每个 seed 都有 result.mat
[ ] 每个 result.mat 都有 obj_matrix
[ ] metrics/summary.txt 存在
[ ] figures 进入 comparison figures 目录
[ ] 汇总表记录 mean / std / best / worst
[ ] Git 工作区没有误 stage outputs
```

## 完成标准

一个 baseline 对比任务完成，至少满足：

```text
baseline / variant 定义清楚
输入公平性规则清楚
每个算法输出结构一致
每个算法参数可追溯
多 seed 结果可汇总
metrics 可统一计算
figures 可统一生成
结果表可直接写论文
raw_code 未修改
outputs 不进 Git
```

如果只是模板阶段，则完成标准是：

```text
有中文 baseline 对比模板
说明 baseline / variant
说明公平输入规则
说明统一输出结构
说明 metrics 和图表
说明多 seed
说明结果表
说明运行顺序
有 checklist
不改代码
不跑实验
```

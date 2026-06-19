# 第 3 步：封装单条染色体评价入口

## 1. 这一步在做什么

第 2 步已经拆清楚：

```text
fitness.m 需要 chrom、problem、machineData、agvData、config 里的参数
fitness.m 会调用 sorting.m
sorting.m 排出 machineTable / AGVTable
fitness.m 再算 makespan 和 energy
```

第 3 步开始封装这个入口。

新增函数：

```text
src/evaluation/evaluate_chromosome.m
```

它的作用是：

```text
把一长串原始 fitness.m 参数，整理成一个更清楚的调用入口。
```

原来调用类似：

```matlab
fitness(chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed)
```

现在准备变成：

```matlab
result = evaluate_chromosome(chrom, problem, machineData, agvData, config)
```

## 2. 这一步在复现时干什么

它在复现时不是完整实验，而是为了建立一个更清楚的“单方案评价入口”。

以后复现时，一条调度方案的评价可以拆成：

```text
准备 chrom
准备 problem
准备 machineData
准备 agvData
准备 config
调用 evaluate_chromosome
得到 makespan 和 totalEnergy
```

这样做的好处是：

- 不用每次手动拼十几个 `fitness.m` 参数。
- 更容易看出哪些数据来自 `.fjs`，哪些来自 Excel，哪些来自实验参数。
- 后续写测试时，只需要检查 `evaluate_chromosome` 是否能输出目标值。
- 后续小种群实验也可以反复调用同一个评价入口。

一句话记：

```text
第 2 步是弄清楚 fitness/sorting 要什么。
第 3 步是把这个入口封装成一个可复用函数。
```

## 3. 输入分别来自哪里

| 输入 | 来源 | 含义 |
|---|---|---|
| `chrom` | 编码层，后续由 `init.m` 或测试样例提供 | 一条调度方案 |
| `problem` | `read_fjsp.m` | 工件、工序、候选机器、加工时间 |
| `machineData` | `read_machine_data.m` | 距离矩阵、机器能耗 |
| `agvData` | `read_agv_data.m` | AGV 数量、速度、能耗 |
| `config` | 后续配置化，现在先手动提供 | AGV 电量上限、充电阈值、充电速度 |

当前 `config` 至少需要：

```matlab
config.AGVEG_MAX
config.AGVEG_MIN
config.eChargeSpeed
```

## 4. 输出是什么

`evaluate_chromosome.m` 返回 `result` 结构：

| 字段 | 含义 |
|---|---|
| `result.objectives` | `[makespan, totalEnergy]` |
| `result.makespan` | 最大完工时间 |
| `result.machineEnergy` | 机器能耗 |
| `result.agvEnergy` | AGV 能耗 |
| `result.totalEnergy` | 机器能耗 + AGV 能耗 |
| `result.machineTable` | 机器时间表 |
| `result.AGVTable` | AGV 时间表 |
| `result.agvEGRecord` | AGV 电量变化 |
| `result.agvChargeNum` | AGV 充电次数 |

## 5. 这一步没有做什么

这一步没有：

- 修改 `raw_code/`。
- 修改 `fitness.m`。
- 修改 `sorting.m`。
- 修改 `dif_main.m` 或 `same_main.m`。
- 新增测试。
- 运行 MATLAB 验证。

也就是说，它只是一个旁路封装：

```text
新入口调用旧算法
旧算法逻辑不变
```

## 6. 使用前要注意什么

`evaluate_chromosome.m` 不会偷偷修改 MATLAB 路径。

所以使用前，需要你明确把目标算法目录加到路径，例如基础 NSGA-II：

```matlab
addpath(fullfile(projectRoot, 'raw_code', 'NSGA-II'))
addpath(fullfile(projectRoot, 'src', 'evaluation'))
```

这样做是为了避免一个隐蔽问题：

```text
raw_code 里有很多同名 fitness.m 和 sorting.m。
```

你加了哪个算法目录，MATLAB 就会调用哪个目录下的 `fitness.m`。

当前建议先用：

```text
raw_code/NSGA-II
```

因为它是基础算法链路，比改进算法更适合做最小复现入口。

## 7. 下一步是什么

这一步完成后，`fitness/sorting` 线的状态是：

```text
拆解：已完成
封装：已完成第一版
测试：已新增 tests/test_evaluate_chromosome.m
```

正式测试会检查：

```text
读取小样本
生成 1 条 chrom
调用 evaluate_chromosome
确认 result.makespan 和 result.totalEnergy 非空
确认项目根目录没有被乱写文件
```

所以单条染色体评价这条线已经形成：

```text
拆解 -> 封装 -> 测试
```

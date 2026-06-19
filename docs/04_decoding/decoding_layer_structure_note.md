# 解码层结构说明：sorting.m 如何把 chrom 变成调度过程

## 1. 这份笔记解决什么问题

这份笔记记录 D1 对 `raw_code/NSGA-II/sorting.m` 的结构拆解结果。

它回答的是：

```text
编码层给出一条 chrom 以后，系统如何把它翻译成机器加工表、AGV 运输表和调度过程？
```

它不回答：

```text
chrom 如何生成
chrom 如何交叉变异
makespan / energy 最终如何计算
NSGA-II 如何选择、排序、替换种群
```

这些分别属于编码层、评价层和搜索层。

## 2. 解码层是什么

当前项目可以按五层理解：

```text
Data -> Encoding -> Decoding -> Evaluation -> Search
```

解码层位于编码层之后、评价层之前。

编码层输出的是一条抽象决策：

```text
chrom = [OS, MS, AS, SS]
```

解码层负责把这条抽象决策落成具体调度过程：

```text
chrom
-> 每一步调度哪个工件
-> 该工件当前是哪道工序
-> 选哪台机器加工
-> 用哪辆 AGV 搬运
-> 空载/负载运输用哪个速度档
-> 插入机器加工时间块
-> 插入 AGV 空载、负载、充电时间块
-> 得到 machineTable / AGVTable / jobCompleteUnLoad / agvEGRecord
```

一句话：

```text
编码层给出选择。
解码层把选择排成可执行时间表。
评价层再根据时间表算目标值。
```

## 3. sorting.m 的角色

`sorting.m` 是当前 NSGA-II 基础算法里的解码层核心。

它的函数形式是：

```matlab
[machineTable, AGVTable, jobCompleteUnLoad, agvEGRecord, agvChargeNum] = sorting( ...
    chrom, jobNum, jobInfo, operaVec, ...
    AGVNum, AGVSpeed, ...
    candidateMachine, distance_matrix, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed, ...
    machineTable, AGVTable)
```

它的输入可以分成四类：

| 输入类别 | 代表变量 | 用途 |
|---|---|---|
| 编码决策 | `chrom` | 一条染色体，包含 OS / MS / AS / SS |
| 工件与机器数据 | `jobNum`, `jobInfo`, `operaVec`, `candidateMachine` | 确定工序数量、候选机器、加工时间 |
| AGV 与能耗数据 | `AGVNum`, `AGVSpeed`, `AGVEnergy`, `AGVEG_MAX`, `AGVEG_MIN`, `eChargeSpeed` | 确定 AGV 速度、能耗、电量、充电 |
| 调度环境状态 | `distance_matrix`, `machineTable`, `AGVTable` | 提供距离矩阵、机器时间表、AGV 时间表 |

它的输出是：

| 输出 | 含义 |
|---|---|
| `machineTable` | 每台机器上的加工时间块 |
| `AGVTable` | 每辆 AGV 上的空载、负载、充电时间块 |
| `jobCompleteUnLoad` | 每个工件最终送到卸载站的完成时间 |
| `agvEGRecord` | 每辆 AGV 的电量变化记录 |
| `agvChargeNum` | 每辆 AGV 的充电次数 |

所以 `sorting.m` 输出的是调度过程表，不是 Pareto 结果，也不是最终目标矩阵。

## 4. chrom 到调度过程的转换链

`sorting.m` 先把染色体切成四段：

```matlab
operaNum = sum(operaVec);
OS = chrom(1: operaNum);
MS = chrom(operaNum + 1: 2 * operaNum);
AS = chrom(2 * operaNum + 1 : 3 * operaNum);
SS = chrom(3 * operaNum + 1: 5 * operaNum);
```

也就是：

```text
n = operaNum = sum(operaVec)

chrom = [OS(n), MS(n), AS(n), SS(2n)]
总长度 = 5n
```

主流程可以理解成：

```text
1. 按 OS 顺序依次取出当前工件 curJob
2. 根据该工件出现次数推断当前是第几道工序 jobOpera
3. 用 curJob + jobOpera 找到全局工序位置 rSIndex
4. 用 MS(rSIndex) 从 candidateMachine 中选真实机器
5. 用 AS(rSIndex) 选择 AGV
6. 用 SS 的两个位置选择空载速度档和负载速度档
7. 检查 AGV 电量，不足则插入去卸载站充电的时间块
8. 插入 AGV 空载移动时间块
9. 插入 AGV 负载运输时间块
10. 在目标机器的空闲时间块中插入加工时间块
11. 如果当前是该工件最后一道工序，则安排 AGV 把工件送到卸载站
```

这条链就是解码层的主逻辑。

## 5. OS / MS / AS / SS 在解码中的作用

| 编码段 | 解码时的作用 | 说明 |
|---|---|---|
| `OS` | 决定调度顺序 | `OS(i)` 表示第 `i` 步优先处理哪个工件的下一道工序 |
| `MS` | 决定机器选择 | `MS(rSIndex)` 表示当前工序选择候选机器列表里的第几个机器 |
| `AS` | 决定 AGV 选择 | `AS(rSIndex)` 表示当前工序由哪辆 AGV 搬运 |
| `SS` | 决定运输速度档 | 每道工序占两个位置，分别对应空载速度档和负载速度档 |

关键索引是：

```matlab
rSIndex = sum(operaVec(1: curJob - 1)) + jobOpera;
```

它把：

```text
当前工件 curJob
当前工序 jobOpera
```

映射到 `MS / AS / SS` 的全局位置。

`SS` 的用法可以确定为：

```text
第 k 道全局工序：
SS(2k - 1) = 空载速度档
SS(2k)     = 负载速度档
```

但最后一道工序完成后送往卸载站时，代码默认使用 `AGVSpeed(3)`，这部分不由 `SS` 决定。

## 6. 解码层内部维护的调度状态

`sorting.m` 在解码过程中维护这些状态：

| 状态变量 | 作用 |
|---|---|
| `operaRec` | 记录每个工件当前已经调度到第几道工序 |
| `curJobTime` | 记录每个工件上一道工序的完成时间 |
| `jobPosition` | 记录每个工件当前所在位置，初始为 `-1` |
| `jobCompleteUnLoad` | 记录每个工件最终送到卸载站的时间 |
| `agvRealTimeEG` | 记录每辆 AGV 当前电量 |
| `agvEGRecord` | 记录每辆 AGV 电量变化轨迹 |
| `agvChargeNum` | 记录每辆 AGV 充电次数 |
| `machineTable` | 记录机器加工时间块 |
| `AGVTable` | 记录 AGV 空载、负载、充电时间块 |

这些状态说明：解码层不是单纯拆向量，而是在构造一个动态调度过程。

## 7. 解码层和其他层的边界

### 解码层不负责编码生成

这些属于编码层：

```text
生成初始 chrom
检查 OS / MS / AS / SS 是否在合法范围
交叉变异生成 offspring
```

对应当前新封装代码：

```text
src/encoding/generate_initial_population.m
src/encoding/validate_chromosome.m
src/encoding/generate_offspring.m
```

### 解码层不负责目标评价

这些属于评价层：

```text
计算 makespan
计算 totalEnergy
形成目标值矩阵
判断一个解好不好
```

当前仍需要后续拆解 `fitness.m` 才能完全确认。

### 解码层不负责搜索策略

这些属于搜索层：

```text
选择父代
非支配排序
拥挤度计算
种群替换
迭代终止
```

当前对应原始 NSGA-II 中的搜索逻辑。

## 8. 当前仍未封装的部分

当前 D2 只是结构说明，没有新增解码层代码。

解码层仍未封装的内容包括：

```text
src/decoding/decode_chromosome.m 尚未建立
src/decoding/decode_population.m 尚未建立
解码层 smoke test 尚未建立
sorting.m 的行为尚未和新 decode_chromosome 做对比
table_insert 的插入规则尚未拆出
spare_transfer_time_compute / load_transfer_time_compute 尚未拆出
machineTable / AGVTable 的初始结构尚未独立封装
fitness.m 如何消费 sorting.m 输出尚未确认
```

因此当前结论是：

```text
解码层主流程已经完成结构拆解和文档化。
解码层代码封装尚未开始。
```

下一步 D3 应该先确认未来解码函数的输入输出契约，再决定如何封装。

## 9. D3 是什么：先定接口，不急着写代码

D3 的目的不是运行算法，也不是马上封装新函数，而是先确认未来解码函数的接口。

这里的“接口”可以理解为：

```text
这个函数需要输入什么？
这个函数会输出什么？
每个输入输出分别代表什么？
```

D3 建议的解码层主接口是：

```matlab
[schedule, report] = decode_chromosome(chrom, problem, machineData, agvData, config)
```

它表示：

```text
输入：
chrom       一条染色体
problem     工件、工序、候选机器、加工时间信息
machineData 机器距离等数据
agvData     AGV 数量、速度、能耗等数据
config      电量阈值、充电速度、初始时间表等运行参数

输出：
schedule    解码后的调度过程
report      解码是否合法、是否失败、失败原因是什么
```

之所以把 `config` 单独作为输入，是因为 `sorting.m` 不只需要数据，还需要运行参数：

```text
AGVEG_MAX
AGVEG_MIN
eChargeSpeed
```

这些参数不应该写死，也不应该混进 `agvData` 里。单独放在 `config` 里更利于复现。

## 10. D4 第一版封装状态

当前已经新增第一版单条染色体解码入口：

```text
src/decoding/decode_chromosome.m
```

第一版采用保守封装方式：

```text
1. 检查 problem / machineData / agvData / config 必要字段
2. 调用 validate_chromosome 检查编码层合法性
3. 调用 split_chromosome 拆出 OS / MS / AS / SS
4. 调用原始 sorting.m 生成调度过程
5. 返回 schedule 和 report
```

这版不修改 `raw_code`，也不重新实现 `sorting.m` 内部细节。

因为 D4 不读取 `fitness.m`，也不读取 `table_insert.m` 等解码工具函数，所以当前版本不猜测 `machineTable / AGVTable` 的初始结构，而是要求调用者显式传入：

```text
config.machineTable
config.AGVTable
```

当前输出字段包括：

```text
schedule.machineTable
schedule.AGVTable
schedule.jobCompleteUnLoad
schedule.agvEGRecord
schedule.agvChargeNum
schedule.parts
schedule.operaNum
schedule.dim
```

当前边界：

```text
不计算 makespan
不计算 totalEnergy
不保存 outputs
不运行 NSGA-II
不生成初始 machineTable / AGVTable
不封装 table_insert / 运输时间计算工具
```

这些内容留给后续 D5-D8 继续拆。

## 11. D5-D6 最小测试与 population 解码

D5 已新增最小解码层 smoke test：

```text
tests/test_decoding_layer.m
```

它验证：

```text
读取 sample 数据
生成合法 chrom
构造最小 machineTable / AGVTable
调用 decode_chromosome
检查 schedule 的核心结构
检查解码后的机器加工工序数等于 sum(problem.operaNumVec)
```

D6 已新增 population 级别解码入口：

```text
src/decoding/decode_population.m
```

它的接口是：

```matlab
[schedules, report] = decode_population(population, problem, machineData, agvData, config)
```

它做的事情是：

```text
逐条调用 decode_chromosome
把每条 chrom 的 schedule 存入 schedules
统计 successCount / failureCount
记录 failedIndexes
保存每条 chrom 的 decodingStatus / errors / warnings
```

当前解码层调用关系变成：

```text
decode_population
-> decode_chromosome
   -> validate_chromosome
   -> split_chromosome
   -> sorting.m
```

当前边界仍然不变：

```text
不计算 makespan
不计算 totalEnergy
不调用 fitness.m
不运行完整 NSGA-II
不生成 outputs
```

## 12. D1-D8 完成状态

截至 2026-05-25，解码层已经完成第一轮拆解、封装和测试闭环。

| 阶段 | 状态 | 说明 |
|---|---|---|
| D1 | 已完成 | 只读 `sorting.m`，拆解输入、输出、OS/MS/AS/SS 使用方式和调度状态 |
| D2 | 已完成 | 新增本结构说明文档 |
| D3 | 已完成 | 确认接口 `[schedule, report] = decode_chromosome(chrom, problem, machineData, agvData, config)` |
| D4 | 已完成 | 新增 `src/decoding/decode_chromosome.m` |
| D5 | 已完成并跑通 | 新增 `tests/test_decoding_layer.m`，用户已跑通 |
| D6 | 已完成并跑通 | 新增 `src/decoding/decode_population.m`，并扩展 population 级别测试 |
| D7 | 已完成并跑通 | 新增 `tests/test_decoding_invalid_cases.m`，非法输入可识别 |
| D8 | 已完成并跑通 | 新增 `tests/test_decoding_compare_sorting.m`，和原始 `sorting.m` 输出一致 |

用户已确认的运行结果：

```text
test_decoding_layer passed: population=3, operations=55, AGVNum=3
test_decoding_invalid_cases passed
test_decoding_compare_sorting passed: fields matched=5
```

当前结论：

```text
解码层已经完成第一轮拆解、封装、测试。
decode_chromosome 是对原始 sorting.m 行为的稳定封装。
decode_population 可以对 population 逐条解码并给出成功/失败报告。
```

当前还不能说评价层已经封装完成；`makespan / totalEnergy` 仍属于后续 `fitness.m` 拆解范围。

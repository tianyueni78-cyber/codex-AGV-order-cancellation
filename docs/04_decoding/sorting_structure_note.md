# 解码层结构说明：sorting.m 如何把 chrom 变成调度时间表

本文只基于 `raw_code/NSGA-II/sorting.m` 的静态阅读整理，不拆代码，不修改 `raw_code`，也不调用 `sorting.m`。

## 1. sorting.m 的位置

编码层给出的是一条决策向量：

```text
chrom = [OS(n), MS(n), AS(n), SS(2n)]
```

`sorting.m` 属于解码层。它的职责是把这条 `chrom` 解释成真实调度过程，输出机器时间表、AGV 时间表、工件完成卸载时间、AGV 电量记录和充电次数。

函数入口是：

```matlab
[machineTable, AGVTable, jobCompleteUnLoad, agvEGRecord, agvChargeNum] = sorting( ...
    chrom, jobNum, jobInfo, operaVec, AGVNum, AGVSpeed, ...
    candidateMachine, distance_matrix, AGVEnergy, ...
    AGVEG_MAX, AGVEG_MIN, eChargeSpeed, machineTable, AGVTable)
```

## 2. 输入大致分成几类

`chrom` 是编码层给出的调度决策。

`jobNum / jobInfo / operaVec / candidateMachine` 描述工件、工序、加工时间和候选机器。

`AGVNum / AGVSpeed / AGVEnergy / AGVEG_MAX / AGVEG_MIN / eChargeSpeed` 描述 AGV 数量、速度档、能耗、电池容量、充电阈值和充电速度。

`distance_matrix` 描述装载站、卸载站、机器之间的运输距离。

`machineTable / AGVTable` 是解码开始前已经初始化好的时间表，`sorting.m` 会在里面插入加工、运输和充电事件。

## 3. 第一件事：切 chrom

`sorting.m` 开头把一条 `chrom` 切成四段：

```text
operaNum = sum(operaVec)
OS = chrom(1 : operaNum)
MS = chrom(operaNum + 1 : 2 * operaNum)
AS = chrom(2 * operaNum + 1 : 3 * operaNum)
SS = chrom(3 * operaNum + 1 : 5 * operaNum)
```

这和编码层已经确认的结构一致：

```text
OS(n), MS(n), AS(n), SS(2n)
```

## 4. 主循环：按 OS 逐个安排工序

`sorting.m` 的主循环按 `OS` 从左到右处理。每读到一个工件编号，就把这个工件的当前工序数加一，从而知道这次处理的是该工件的第几道工序。

核心状态变量包括：

| 变量 | 作用 |
|---|---|
| `operaRec` | 记录每个工件已经处理到第几道工序 |
| `curJobTime` | 记录每个工件上一道工序完成时间 |
| `jobPosition` | 记录每个工件当前所在位置，初始为装载站 |
| `jobCompleteUnLoad` | 记录每个工件最终送到卸载站的时间 |
| `agvRealTimeEG` | 记录每辆 AGV 当前电量 |
| `agvEGRecord` | 记录每辆 AGV 的电量变化过程 |
| `agvChargeNum` | 记录每辆 AGV 充电次数 |

## 5. 每道工序如何从编码变成具体选择

对当前工件 `curJob` 和当前工序 `jobOpera`，代码先计算它在 `MS / AS / SS` 中对应的位置：

```text
rSIndex = sum(operaVec(1 : curJob - 1)) + jobOpera
```

然后：

```text
MS(rSIndex) -> 从 candidateMachine{curJob, jobOpera} 中选实际机器
AS(rSIndex) -> 选择执行搬运的 AGV
SS(2*rSIndex-1) -> 空载速度档
SS(2*rSIndex) -> 负载速度档
```

所以 `SS(2n)` 的结构在 `sorting.m` 里已经变明确：每道工序对应两个速度选择，一个用于空载运输，一个用于负载运输。

## 6. 充电逻辑

在安排当前工序搬运前，`sorting.m` 会检查所有 AGV 的当前电量。

如果某辆 AGV 电量低于或等于 `AGVEG_MIN`：

```text
如果 AGV 不在卸载站，就先空载前往卸载站
然后插入充电事件
充电到 AGVEG_MAX
记录电量变化
充电次数加一
```

这里有一个重要边界：充电过程没有被编码到 `chrom` 里。代码默认使用速度 3 处理前往卸载站充电的移动。

## 7. 运输逻辑

每道工序加工前，AGV 运输分成两段：

```text
空载转移：AGV 从当前位置去工件当前位置
负载转移：AGV 带着工件去目标机器
```

空载速度来自：

```text
AGVSpeed(SS(2*rSIndex-1))
```

负载速度来自：

```text
AGVSpeed(SS(2*rSIndex))
```

运输时间由距离矩阵和速度计算，运输结束后会更新：

```text
AGVTable
agvRealTimeEG
agvEGRecord
```

## 8. 机器加工逻辑

AGV 把工件送到目标机器后，`sorting.m` 在目标机器的 `machineTable` 中寻找空闲时间块。

插入加工块时，要同时满足：

```text
机器该时间段空闲
AGV 已经把工件送到
该工件上一道工序已经完成
```

插入成功后更新：

```text
curJobTime(curJob)
jobPosition(curJob)
machineTable{machine}
```

这一步说明解码层不是简单把工序排在机器末尾，而是在机器时间表中寻找可插入空隙。

## 9. 最后一道工序后的卸载逻辑

如果当前工序是某个工件的最后一道工序，`sorting.m` 会额外安排一辆 AGV 把该工件从最后加工机器送到卸载站。

选择 return AGV 的逻辑大致是：

```text
计算每辆 AGV 最早能到达当前机器的时间
结合工件加工完成时间，选择最早可以离开的 AGV
如果并列，再按代码规则选一个
```

卸载运输同样会更新：

```text
AGVTable
agvRealTimeEG
agvEGRecord
jobCompleteUnLoad(curJob)
```

## 10. 输出是什么

`sorting.m` 输出：

| 输出 | 含义 |
|---|---|
| `machineTable` | 每台机器上的加工块和空闲块 |
| `AGVTable` | 每辆 AGV 的空载、负载、充电、卸载相关事件 |
| `jobCompleteUnLoad` | 每个工件最终到达卸载站的时间 |
| `agvEGRecord` | 每辆 AGV 电量变化记录 |
| `agvChargeNum` | 每辆 AGV 充电次数 |

这些输出会被评价层继续使用，例如计算 makespan、机器能耗、AGV 能耗和总能耗。

## 11. 解码层和编码层的边界

编码层负责回答：

```text
下一步处理哪个工件
这道工序选哪台候选机器
这道工序用哪辆 AGV
空载和负载运输各用哪个速度档
```

解码层负责回答：

```text
这些选择落到真实时间轴上以后，什么时候运输
什么时候加工
机器是否有空隙可插入
AGV 是否需要先移动或充电
工件最终什么时候到卸载站
```

因此，`validate_chromosome` 只能检查编码是否合法；`sorting.m` 才决定这条合法编码对应的真实调度过程。

## 12. 下一步拆解时可以形成的函数边界

后续如果要封装解码层，可以按以下小任务继续拆：

```text
split_decoding_inputs：整理 sorting 需要的输入结构
initialize_decoding_state：初始化 operaRec、curJobTime、jobPosition、电量记录等状态
decode_operation_choice：从 OS/MS/AS/SS 解析当前工序的机器、AGV、速度
ensure_agv_charge：处理低电量 AGV 的充电事件
schedule_empty_transfer：安排空载转移
schedule_loaded_transfer：安排负载转移
insert_machine_operation：在 machineTable 中插入加工块
schedule_final_unload：最后一道工序后送往卸载站
```

这些只是结构边界建议，不代表本轮已经开始拆代码。

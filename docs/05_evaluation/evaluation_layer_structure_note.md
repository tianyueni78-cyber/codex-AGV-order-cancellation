# 评价层结构说明：fitness.m 如何把 schedule 变成目标值

## 1. 这份笔记解决什么问题

这份笔记记录 V1 对 `raw_code/NSGA-II/fitness.m` 的结构拆解结果。

它回答的是：

```text
一条 chrom 被解码成调度过程以后，项目如何计算 makespan 和 totalEnergy？
```

它不回答：

```text
chrom 如何生成
chrom 如何交叉变异
sorting.m 如何逐步排机器和 AGV
NSGA-II 如何非支配排序和选择
```

这些分别属于编码层、解码层和搜索层。

## 2. 评价层是什么

评价层负责回答：

```text
这个调度方案好不好？
```

解码层输出的是调度过程：

```text
schedule.machineTable
schedule.AGVTable
schedule.jobCompleteUnLoad
schedule.agvEGRecord
schedule.agvChargeNum
```

评价层把这些调度过程压缩成目标值：

```text
[makespan, totalEnergy]
```

一句话：

```text
解码层负责“排出来”。
评价层负责“算好不好”。
```

## 3. fitness.m 的角色

`fitness.m` 是当前原始 NSGA-II 中的评价层入口。

函数形式是：

```matlab
[FUNC, machineTable, AGVTable, makespan, EG_M_SUM, EG_A_SUM, agvEGRecord, agvChargeNum] = ...
    fitness(chrom, jobNum, jobInfo, operaVec, machineNum, AGVNum, AGVSpeed, candidateMachine, ...
    distance_matrix, machineEnergy, AGVEnergy, AGVEG_MAX, AGVEG_MIN, eChargeSpeed)
```

它的输入可以分成四类：

| 输入类别 | 代表变量 | 用途 |
|---|---|---|
| 编码决策 | `chrom` | 一条染色体 |
| 工件和机器数据 | `jobNum`, `jobInfo`, `operaVec`, `machineNum`, `candidateMachine` | 初始化机器表、传给解码、计算机器能耗 |
| AGV 和距离数据 | `AGVNum`, `AGVSpeed`, `distance_matrix`, `AGVEnergy` | 传给解码、计算 AGV 能耗 |
| 能耗和充电参数 | `machineEnergy`, `AGVEG_MAX`, `AGVEG_MIN`, `eChargeSpeed` | 机器能耗、AGV 电量和充电参数 |

它的输出包括：

| 输出 | 含义 |
|---|---|
| `FUNC` | 目标值 cell，内容为 `[makespan, totalEnergy]` |
| `machineTable` | 解码后的机器时间表 |
| `AGVTable` | 解码后的 AGV 时间表 |
| `makespan` | 最大完工/卸载完成时间 |
| `EG_M_SUM` | 机器总能耗 |
| `EG_A_SUM` | AGV 总能耗 |
| `agvEGRecord` | AGV 电量变化记录 |
| `agvChargeNum` | AGV 充电次数 |

## 4. fitness.m 内部做了哪几步

`fitness.m` 当前不是纯评价函数，它混合了三类职责。

### 第一步：初始化 machineTable

每台机器初始有一个空闲时间块：

```text
start = 0
end = Inf
job = 0
opera = 0
```

这里 `job = 0` 表示空闲。

### 第二步：初始化 AGVTable

每辆 AGV 初始有一个时间块：

```text
start = 0
end = Inf
job = 0
opera = 0
load_status = 0
from_machine = -1
to_machine = 0
charge = 0
```

其中：

```text
from_machine = -1 表示装载站
to_machine = 0 表示空闲或占位
charge = 0 表示正常状态
```

### 第三步：调用 sorting.m 解码

`fitness.m` 调用：

```matlab
[machineTable, AGVTable, jobCompleteUnLoad, agvEGRecord, agvChargeNum] = sorting(...)
```

这一步本质上是：

```text
chrom -> schedule
```

当前新解码层的 `decode_chromosome` 已经封装了这一步。

### 第四步：计算 makespan

`sorting.m` 返回每个工件最终送到卸载站的时间：

```text
jobCompleteUnLoad
```

`fitness.m` 取最大值：

```matlab
makespan = max(jobCompleteUnLoad);
```

所以当前项目里的完工时间不是只看最后一道工序加工完成，还包括工件被 AGV 送到卸载站。

### 第五步：计算机器能耗

`fitness.m` 遍历 `machineTable`：

```text
job == 0  -> 空闲时间 machine_spare
job ~= 0 -> 加工时间 machine_work
```

然后计算：

```matlab
EG_M_SUM = machineEnergy.work(1:machineNum)' * machine_work ...
         + machineEnergy.free(1:machineNum)' * machine_spare;
```

也就是：

```text
机器总能耗 = 加工能耗 + 空闲能耗
```

### 第六步：计算 AGV 能耗

AGV 能耗来自 `agvEGRecord` 的电量下降量。

`fitness.m` 遍历每辆 AGV 的电量记录：

```text
如果后一条电量低于前一条，差值计入 AGV 消耗。
如果后一条电量高于前一条，说明发生充电，不计为消耗。
```

最后：

```matlab
EG_A_SUM = sum(EG_AGV);
```

### 第七步：形成目标值

最终目标值是：

```matlab
FUNC = {[makespan, EG_M_SUM + EG_A_SUM]};
```

也就是：

```text
目标 1 = makespan
目标 2 = totalEnergy = 机器能耗 + AGV 能耗
```

## 5. 评价层和解码层的边界

当前已经可以把边界拆清楚：

```text
解码层：
chrom -> machineTable / AGVTable / jobCompleteUnLoad / agvEGRecord / agvChargeNum

评价层：
schedule -> makespan / EG_M_SUM / EG_A_SUM / FUNC
```

但原始 `fitness.m` 把它们放在同一个函数里：

```text
fitness.m
-> 初始化 schedule 空表
-> 调用 sorting.m 解码
-> 计算目标值
```

所以后续封装时，不应该直接把 `fitness.m` 整个复制成一个大 wrapper，而应该拆成更清楚的小函数。

## 6. 后续建议封装边界

建议后续评价层按以下能力拆：

```text
create_initial_schedule_tables
    构造 machineTable / AGVTable 初始时间表

calculate_makespan
    输入 jobCompleteUnLoad
    输出 makespan

calculate_machine_energy
    输入 machineTable / machineEnergy
    输出 EG_M_SUM

calculate_agv_energy
    输入 agvEGRecord
    输出 EG_A_SUM

evaluate_schedule
    输入 schedule / machineData / agvData
    输出 makespan / EG_M_SUM / EG_A_SUM / objective

evaluate_chromosome_refactored
    输入 chrom / problem / machineData / agvData / config
    内部调用 decode_chromosome 和 evaluate_schedule
```

理想链路是：

```text
chrom
-> decode_chromosome
-> schedule
-> evaluate_schedule
-> [makespan, totalEnergy]
```

## 7. 当前仍未封装的部分

评价层仍未封装：

```text
create_initial_schedule_tables.m
calculate_makespan.m
calculate_machine_energy.m
calculate_agv_energy.m
evaluate_schedule.m
evaluate_chromosome_refactored.m
```

当前搜索层仍然调用原始 `fitness.m` 计算目标值。

因此当前结论是：

```text
评价层结构已经完成 V1/V2 理解和文档化。
评价层代码封装尚未开始。
```

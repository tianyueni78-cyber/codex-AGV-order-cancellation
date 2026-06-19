# 独立 decoding 实现说明

## 当前阶段目标

当前阶段的目标是新增 independent decoding：

```text
src/decoding/decode_chromosome_independent.m
src/decoding/decode_population_independent.m
```

它不调用 raw `sorting.m`，而是在 `src/decoding` 内部独立实现染色体到调度表的转换。

原有 wrapper：

```text
src/decoding/decode_chromosome.m
src/decoding/decode_population.m
```

仍然保留，用于 raw 对照和迁移过渡。

## 输入

独立 decoder 输入：

```matlab
[schedule, report] = decode_chromosome_independent( ...
    chrom, problem, machineData, agvData, config)
```

字段含义：

```text
chrom
  一条染色体，结构为 OS + MS + AS + SS

problem
  jobNum
  jobInfo
  operaNumVec
  candidateMachine

machineData
  distance_matrix

agvData
  AGVNum
  AGVSpeed
  AGVEnergy

config
  AGVEG_MAX
  AGVEG_MIN
  eChargeSpeed
  machineTable
  AGVTable
```

## 输出

输出 `schedule` 至少包含：

```text
machineTable
AGVTable
jobCompleteUnLoad
agvEGRecord
agvChargeNum
scheduleContext
parts
operaNum
dim
```

其中：

```text
machineTable
  每台机器上的加工块和空闲块

AGVTable
  每台 AGV 的空载、负载、充电和空闲块

jobCompleteUnLoad
  每个 job 最终运到卸载站的时间

scheduleContext
  解码过程中的状态记录，例如 curJobTime、jobPosition、AGV 电量
```

## 当前实现范围

当前独立实现复刻 raw `sorting.m` 的核心规则：

```text
OS 决定工序调度顺序
MS 选择候选机器
AS 选择 AGV
SS 选择空载/负载速度档位
AGV 电量低于阈值时安排充电
工序插入 machineTable 的可用空闲块
最后一道工序完成后安排 AGV 运到卸载站
```

同时在 independent decoder 内部实现：

```text
machine block insert
AGV block insert
spare transfer time
load transfer time
```

因此它不需要调用：

```text
sorting.m
table_insert.m
spare_transfer_time_compute.m
load_transfer_time_compute.m
```

## 测试入口

只跑 decoding 相关测试：

```matlab
run('tests/test_decoding_independent_layer.m')
run('tests/test_decoding_independent_invalid_cases.m')
run('tests/test_decoding_independent_compare_sorting.m')
```

如果需要回归旧 wrapper，也可以跑：

```matlab
run('tests/test_decoding_layer.m')
run('tests/test_decoding_invalid_cases.m')
run('tests/test_decoding_compare_sorting.m')
```

## raw 对照

`test_decoding_independent_compare_sorting.m` 使用同一条 toy chrom：

```text
raw sorting.m
independent decoder
```

并对比：

```text
machineTable
AGVTable
jobCompleteUnLoad
agvEGRecord
agvChargeNum
```

对照测试只读 raw，不修改 raw。

## 当前没有完成什么

当前阶段只完成 independent decoding。

它还没有替换：

```text
evaluation
search
formal / medium 入口
```

下一步应进入：

```text
22. 独立 evaluation 实现
```

不要在本阶段直接改 `fitness.m` 或 search 层。

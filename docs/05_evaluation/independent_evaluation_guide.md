# 独立 evaluation 实现说明

## 当前阶段目标

当前阶段新增 independent evaluation：

```text
src/evaluation/evaluate_decoded_schedule.m
```

它不调用 raw `fitness.m`。

它只接收已经解码好的 schedule，并复用 evaluation 层的小函数计算目标值。

## 输入

入口：

```matlab
result = evaluate_decoded_schedule(decodedResult, problem, machineData, agvData, config)
```

输入结构：

```text
decodedResult
  machineTable
  AGVTable
  jobCompleteUnLoad
  agvEGRecord
  agvChargeNum

problem
  jobNum

machineData
  machineEnergy

agvData
  AGVNum

config
  AGVEG_MAX
  AGVEG_MIN
  eChargeSpeed
```

## 输出

输出 `result` 包含：

```text
objectives
makespan
machineEnergy
agvEnergy
totalEnergy
FUNC
detail
```

其中当前默认目标仍然是：

```text
objectives = [makespan, totalEnergy]
```

`detail` 保存本次评价对应的 schedule 细节：

```text
machineTable
AGVTable
jobCompleteUnLoad
agvEGRecord
agvChargeNum
scheduleContext
```

## 当前计算规则

当前 independent evaluation 复用：

```text
compute_makespan_from_schedule
compute_machine_energy
compute_agv_energy
build_objectives
```

对应 raw `fitness.m` 的计算规则：

```text
makespan = max(jobCompleteUnLoad)

machineEnergy =
  机器加工时间 * machineEnergy.work
  + 机器空闲时间 * machineEnergy.free

agvEnergy =
  agvEGRecord 中所有电量下降量之和

totalEnergy = machineEnergy + agvEnergy

objectives = [makespan, totalEnergy]
```

## 和 raw wrapper 的区别

raw wrapper：

```text
evaluate_chromosome
```

仍然调用 raw `fitness.m`。

independent evaluation：

```text
evaluate_decoded_schedule
```

不调用 `fitness.m`，只评价已经解码出的 schedule。

因此完整 independent 链路是：

```text
chrom
  -> decode_chromosome_independent
  -> evaluate_decoded_schedule
```

## 测试入口

只跑 evaluation / decoding 相关测试：

```matlab
run('tests/test_evaluation_independent_toy.m')
run('tests/test_evaluation_independent_invalid_cases.m')
run('tests/test_evaluation_independent_integration.m')
run('tests/test_evaluation_independent_compare_raw.m')
```

建议同时回归：

```matlab
run('tests/test_evaluation_components.m')
run('tests/test_evaluation_components_compare_raw.m')
run('tests/test_evaluate_chromosome.m')
run('tests/test_evaluation_invalid_cases.m')
run('tests/test_decoding_independent_layer.m')
run('tests/test_decoding_independent_compare_sorting.m')
```

## raw 对照

`test_evaluation_independent_compare_raw.m` 使用同一条 toy chrom，对比：

```text
evaluate_chromosome(raw wrapper)
decode_chromosome_independent + evaluate_decoded_schedule
```

对比字段：

```text
makespan
machineEnergy
agvEnergy
totalEnergy
objectives
```

当前容差：

```text
1e-9
```

## 当前没有完成什么

当前阶段只完成 independent evaluation。

它还没有替换：

```text
search
small / medium / formal 入口
```

下一步应进入：

```text
23. 独立 NSGA-II search 实现
```

不要在本阶段直接改 search、scripts 或 configs。

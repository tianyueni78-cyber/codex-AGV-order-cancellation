# 第 22 步：独立 evaluation 实现

## 目标

这一阶段的目标是让评价层不再调用 raw `fitness.m`，而是基于 independent decoding 的输出计算目标值：

```text
decodedResult -> makespan / machineEnergy / agvEnergy / totalEnergy / objectives
```

## 新增入口

代码入口：

```text
src/evaluation/evaluate_decoded_schedule.m
```

复用组件：

```text
src/evaluation/compute_makespan_from_schedule.m
src/evaluation/compute_machine_energy.m
src/evaluation/compute_agv_energy.m
src/evaluation/build_objectives.m
```

说明文档：

```text
docs/05_evaluation/independent_evaluation_guide.md
```

## 测试入口

```matlab
run('tests/test_evaluation_independent_toy.m')
run('tests/test_evaluation_independent_invalid_cases.m')
run('tests/test_evaluation_independent_integration.m')
run('tests/test_evaluation_independent_compare_raw.m')
```

## 已完成内容

```text
手工 schedule 可独立评价
chrom -> independent decode -> independent evaluate 可串起来
raw wrapper 与 independent evaluation 有对照测试
invalid case 已覆盖
raw_code 未修改
```

## 当前结论

第 22 步完成后，评价层已经具备脱离 raw `fitness.m` 的第一版 independent 实现。


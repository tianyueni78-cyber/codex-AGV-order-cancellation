# 第 21 步：独立 decoding 实现

## 目标

这一阶段的目标是让解码层不再调用 raw `sorting.m`，而是由 `src/decoding/` 里的 independent decoder 自己完成：

```text
chrom -> machineTable / AGVTable / jobCompleteUnLoad / scheduleContext
```

## 新增入口

代码入口：

```text
src/decoding/decode_chromosome_independent.m
src/decoding/decode_population_independent.m
```

说明文档：

```text
docs/04_decoding/independent_decoding_guide.md
```

## 测试入口

```matlab
run('tests/test_decoding_independent_layer.m')
run('tests/test_decoding_independent_invalid_cases.m')
run('tests/test_decoding_independent_compare_sorting.m')
```

## 已完成内容

```text
单条 chrom 可独立解码
population 可独立解码
invalid case 已覆盖
同一 chrom 下与 raw sorting.m 有对照测试
raw_code 未修改
```

## 当前结论

第 21 步完成后，解码层已经具备脱离 raw `sorting.m` 的第一版 independent 实现。


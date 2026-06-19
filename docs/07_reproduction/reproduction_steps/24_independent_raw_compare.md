# 第 24 步：raw 对照测试总验收

## 目标

这一阶段的目标是系统确认 independent 链路和 raw 链路一致或差异可解释。

对照矩阵：

```text
decoding raw sorting.m vs independent decoding
evaluation raw fitness wrapper vs independent evaluation
search raw/refactored small vs independent small
```

## 新增测试入口

```matlab
run('tests/test_independent_decoding_compare_raw.m')
run('tests/test_independent_evaluation_compare_raw.m')
run('tests/test_independent_search_compare_raw.m')
```

说明文档：

```text
docs/07_reproduction/independent_raw_compare_acceptance.md
```

## 已完成内容

```text
decoding raw 对照通过
evaluation raw 对照通过
search small raw 对照通过
makespan / energy 有容差说明
Pareto set 不要求逐点完全相同，但 obj_matrix 结构可比
raw_code 未修改
outputs 未提交
```

## 当前结论

第 24 步完成后，independent 链路不是“只要能跑就算”，而是有 raw baseline 对照门槛。


# independent 与 raw 对照测试总验收

## 本阶段目标

本阶段目标是系统性确认 independent 链路和 raw 链路的关系：

```text
decoding raw vs independent
evaluation raw vs independent
search raw small vs independent small
```

当前阶段不跑 medium，不跑 formal，不生成 outputs。

## compare matrix

| 层 | raw 参考 | independent 链路 | 测试入口 | 验收方式 |
|---|---|---|---|---|
| decoding | `sorting.m` | `decode_chromosome_independent` | `tests/test_independent_decoding_compare_raw.m` | 5 个 schedule 字段 `isequaln` 完全一致 |
| evaluation | `evaluate_chromosome` / raw `fitness.m` | `decode_chromosome_independent` + `evaluate_decoded_schedule` | `tests/test_independent_evaluation_compare_raw.m` | makespan / energy / objectives 在 `1e-9` 容差内一致 |
| search | raw/refactored-variation small smoke | `run_independent_nsga2` | `tests/test_independent_search_compare_raw.m` | 结构可比：非空 obj_matrix、目标列一致、curve generation 一致 |

## 容差设计

decoding：

```text
machineTable
AGVTable
jobCompleteUnLoad
agvEGRecord
agvChargeNum
```

要求完全一致。

evaluation：

```text
makespan tolerance = 1e-9
machineEnergy tolerance = 1e-9
agvEnergy tolerance = 1e-9
totalEnergy tolerance = 1e-9
objectives tolerance = 1e-9
```

search：

```text
obj_matrix 非空
objective column count 一致
curve generation count 一致
所有 objective 值有限
```

search 不要求 Pareto 点逐点完全一致。

原因：

```text
independent search 使用自己的排序、拥挤距离、锦标赛和环境选择
raw/refactored-variation smoke 的 tie-break 和随机调用顺序可能不同
同一 seed 下结构应可比，但 Pareto set 不必逐点相同
```

## 固定条件

所有 compare 测试使用：

```text
small config
seed = 42
pop <= 10
max_gen <= 2
```

不会运行：

```text
medium
formal
完整正式实验
```

不会写：

```text
outputs
raw_code
项目根目录 data.mat
```

## 测试命令

在 MATLAB 中运行：

```matlab
run('tests/test_independent_decoding_compare_raw.m')
run('tests/test_independent_evaluation_compare_raw.m')
run('tests/test_independent_search_compare_raw.m')
```

## 当前验收结论记录方式

每个测试会把对照说明输出到 MATLAB console。

通过代表：

```text
decoding 有 raw 对照
evaluation 有 raw 对照
search small 有 raw 结构对照
差异有容差和解释
没有隐藏 raw dependency 的证据
```

## 当前没有完成什么

本阶段不是 independent medium/formal 验收。

本阶段没有新增 independent 实验入口。

下一步应进入：

```text
25. independent small / medium / formal 验收
```

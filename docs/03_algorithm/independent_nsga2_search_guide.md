# 独立 NSGA-II search 实现说明

## 当前阶段目标

当前阶段新增：

```text
src/search/run_independent_nsga2.m
```

它不调用 raw：

```text
NSGA2.m
non_domination.m
tournament_selection.m
replace_chrom.m
fitness.m
sorting.m
```

搜索流程只调用当前项目自己的层：

```text
src/encoding
src/decoding
src/evaluation
src/search
```

## 当前 search 链路

独立 search 流程：

```text
1. generate_initial_population
2. decode_chromosome_independent
3. evaluate_decoded_schedule
4. non_dominated_sort_independent
5. crowding_distance_independent
6. tournament_selection_independent
7. generate_offspring
8. environmental_selection_independent
9. 记录 curve.min / curve.avg
10. 输出 obj_matrix / chrom / details
```

## 新增入口

```matlab
[NSGA2_Result, initialPopulation, runInfo] = run_independent_nsga2( ...
    config, problem, machineData, agvData, options)
```

输出：

```text
NSGA2_Result.obj_matrix
NSGA2_Result.chrom
NSGA2_Result.curve.min
NSGA2_Result.curve.avg
NSGA2_Result.pop_history
NSGA2_Result.details

initialPopulation
runInfo
```

`runInfo` 明确记录：

```text
isIndependent = true
usedRawSearch = false
usedRawDecoding = false
usedRawEvaluation = false
```

## 新增 search helper

```text
src/search/non_dominated_sort_independent.m
src/search/crowding_distance_independent.m
src/search/tournament_selection_independent.m
src/search/environmental_selection_independent.m
```

这些 helper 只处理搜索逻辑，不读写文件，不运行实验入口。

## 固定输出结构

当前目标仍然是：

```text
objectives = [makespan, totalEnergy]
```

因此：

```text
obj_matrix(:, 1) = makespan
obj_matrix(:, 2) = totalEnergy
```

curve：

```text
curve.min(objectiveIndex, generation)
curve.avg(objectiveIndex, generation)
```

## 测试入口

small loop：

```matlab
run('tests/test_search_independent_small_loop.m')
```

raw 结构对照 smoke：

```matlab
run('tests/test_search_independent_compare_raw.m')
```

这两个测试都使用 small config：

```text
pop <= 10
max_gen <= 2
seed 固定
```

## raw 对照说明

`test_search_independent_compare_raw.m` 不要求 independent search 和 raw search 的 Pareto 点逐点完全一致。

原因是：

```text
独立排序/选择实现和 raw 实现的 tie-break 可能不同
同一 seed 下随机调用顺序也可能不同
```

当前对照目标是：

```text
两边 obj_matrix 非空
目标列数一致
curve generation 数一致
目标值均为有限值
```

更严格的数值对照应放到第 24 步 raw 对照测试总验收。

## 当前没有完成什么

当前阶段只完成 independent search small loop。

还没有新增：

```text
independent small / medium / formal scripts
independent configs
formal independent 运行入口
```

这些应在第 25 步完成。

## 安全边界

当前阶段不运行：

```text
medium
formal
完整正式实验
```

当前阶段不修改：

```text
raw_code
scripts
configs
```

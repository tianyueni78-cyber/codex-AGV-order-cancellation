# 第 23 步：独立 NSGA-II search 实现

## 目标

这一阶段的目标是让搜索层不再调用 raw：

```text
NSGA2.m
non_domination.m
tournament_selection.m
replace_chrom.m
```

搜索流程只调用自己的 encoding / decoding / evaluation / search 组件。

## 新增入口

核心搜索入口：

```text
src/search/run_independent_nsga2.m
```

搜索组件：

```text
src/search/non_dominated_sort_independent.m
src/search/crowding_distance_independent.m
src/search/tournament_selection_independent.m
src/search/environmental_selection_independent.m
```

说明文档：

```text
docs/03_algorithm/independent_nsga2_search_guide.md
```

## 测试入口

```matlab
run('tests/test_search_independent_small_loop.m')
run('tests/test_search_independent_compare_raw.m')
```

## 已完成内容

```text
independent small search 可运行
obj_matrix 非空
curve.min / curve.avg 可用
seed 固定
runInfo 标记 usedRawSearch / usedRawDecoding / usedRawEvaluation 均为 false
raw_code 未修改
```

## 当前结论

第 23 步完成后，项目已经有第一版完全 independent 的 NSGA-II search 函数。


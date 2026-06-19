# 搜索层小闭环验收说明

## 1. 搜索层是干什么的

搜索层负责在一组染色体之间迭代搜索更好的调度方案。

在当前项目里，一次搜索闭环大致是：

```text
生成初始种群
-> 评价每条染色体
-> 非支配排序
-> 选择父代
-> 交叉/变异生成子代
-> 评价子代
-> 合并并替换种群
-> 进入下一代
```

搜索层不是单条染色体评价，也不是单独解码。它负责让一个 population
经过若干 generation 迭代。

## 2. 小闭环验收是什么意思

小闭环验收不是正式实验。

当前阶段只是 small search loop acceptance。

它的目标是确认：

```text
小 population 可以跑
小 generation 可以跑
搜索结果结构非空
目标矩阵非空
seed 和配置可追溯
不会误跑 medium/formal
不会修改 raw_code
```

这一阶段不追求论文结果，也不比较最终算法优劣。

## 3. 当前入口在哪里

推荐的测试入口是：

```text
tests/test_search_small_loop.m
```

这个测试会调用：

```text
configs/small_nsga2_config.m
src/search/run_nsga2_with_encoding.m
src/search/nsga2_with_encoding_variation.m
```

它使用 refactored encoding 和 refactored variation，但当前搜索闭环仍会依赖 raw
NSGA-II 中的部分函数。

已有辅助测试入口：

```text
tests/test_small_nsga2.m
tests/test_small_nsga2_config.m
tests/test_small_nsga2_refactored_encoding.m
```

脚本入口是：

```text
scripts/run_small_nsga2.m
scripts/run_small_nsga2_refactored.m
```

注意：脚本入口会写 `outputs/`，测试入口默认不写正式输出。

## 4. 当前是否依赖 raw NSGA-II

依赖。

当前 small search loop 还不是独立搜索实现。

`run_nsga2_with_encoding` 默认仍可调用 raw `NSGA2.m`。

当 `useRefactoredVariation = true` 时，会调用：

```text
src/search/nsga2_with_encoding_variation.m
```

但这个 refactored variation search loop 仍依赖 raw 里的：

```text
fitness
non_domination
tournament_selection
replace_chrom
```

所以当前阶段只是验证小闭环可运行，不代表已经脱离 raw search。

## 5. 当前参数是多少

当前 small 配置来自：

```text
configs/small_nsga2_config.m
```

关键参数：

```text
pop = 10
max_gen = 2
p_cross = 0.8
p_mutation = 0.2
```

这满足小闭环限制：

```text
pop <= 10
max_gen <= 2
```

## 6. seed 是多少

当前 seed 是：

```text
seed = 42
```

测试入口会执行：

```matlab
rng(config.random.seed)
```

这样同一配置下的小闭环结果更容易复现。

## 7. 怎么在 MATLAB 里运行

先切到项目根目录：

```matlab
cd('D:\CODEX\code_refactor_project')
```

推荐运行：

```matlab
run('tests/test_search_small_loop.m')
```

也可以运行已有辅助测试：

```matlab
run('tests/test_small_nsga2.m')
run('tests/test_small_nsga2_config.m')
run('tests/test_small_nsga2_refactored_encoding.m')
```

不要在本阶段运行：

```text
scripts/run_medium_nsga2.m
scripts/run_formal_nsga2.m
```

## 8. 通过后应该看到什么

`tests/test_search_small_loop.m` 通过时，会看到类似：

```text
test_search_small_loop passed: pop=10, max_gen=2, seed=42, paretoSolutionCount=..., bestMakespan=..., bestTotalEnergy=...
```

这说明：

```text
小闭环已跑完
NSGA2_Result 是结构体
chrom 初始种群非空
obj_matrix 非空
obj_matrix 有两个目标
curve.min 非空
runInfo 可追溯
```

## 9. 输出会不会生成，在哪里

推荐的测试入口：

```text
tests/test_search_small_loop.m
```

不会写正式 `outputs/` 结果。

脚本入口会写输出：

```text
scripts/run_small_nsga2.m
    -> outputs/small_nsga2/<timestamp>/

scripts/run_small_nsga2_refactored.m
    -> outputs/small_nsga2_refactored/<timestamp>/
```

脚本会保存：

```text
*.mat
summary.txt
```

这些输出目录在 `.gitignore` 中，不应提交到 Git。

不允许写：

```text
raw_code/results.txt
raw_code/data.mat
项目根目录 data.mat
随意散落的 .mat/.csv/.xlsx
```

## 10. 当前没有完成什么

当前阶段没有完成：

```text
正式 medium 实验
正式 formal 实验
论文结果复现
独立 search 实现
完全脱离 raw NSGA-II
metrics 指标计算
图表生成
```

当前阶段只说明：

```text
小规模搜索闭环可以运行，并且结果结构可检查。
```

## 11. 后续 medium/formal 应该另开任务

medium/formal 不应混在当前小闭环验收里。

后续应另开任务处理：

```text
实验入口规范化
medium 配置验收
formal 配置验收
outputs 目录规则
run log 和参数记录
指标和图表
```

进入 medium/formal 前，应先确保：

```text
small search loop 已通过
输出策略已明确
seed 和配置可追溯
不会覆盖旧 outputs
```

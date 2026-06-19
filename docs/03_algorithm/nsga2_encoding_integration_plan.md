# NSGA-II 接入新编码层方案

本文只规划正式 NSGA-II 如何接入新的编码层函数，不直接修改 `raw_code/NSGA-II/NSGA2.m`。

## 1. 当前已经完成的编码层入口

当前 `src/encoding/` 已经可以独立完成：

```text
generate_initial_population
validate_population
build_rs_upper_bounds
generate_offspring
```

也就是：

```text
读 sample 数据
-> 生成初始 population
-> 验证 population
-> 生成 offspring
-> 再次验证 offspring
```

## 2. NSGA2.m 当前和编码层有关的位置

基于 `raw_code/NSGA-II/NSGA2.m` 的静态阅读，当前主函数里和编码层相关的位置有两个。

第一处是初始种群：

```matlab
%chrom = init(pop, jobNum, operaVec, candidateMachine, AGVNum, speedNum);
```

这一行在当前 `NSGA2.m` 中已经被注释。也就是说，当前 `NSGA2.m` 的初始 `chrom` 是从外部传入的。

第二处是迭代中的交叉变异：

```matlab
offspring_ = variation(p_cross, p_mutation, parent_, jobNum, operaVec, AGVNum, AGVSpeed, candidateMachine);
```

这仍然直接调用原始 `variation.m`。

## 3. 建议接入顺序

第一步：不改 `NSGA2.m`，先让运行脚本在进入 `NSGA2.m` 前使用新函数生成初始种群。

```text
run_small_nsga2 / run_formal_nsga2
-> read_fjsp / read_agv_data
-> generate_initial_population
-> NSGA2(..., chrom, ...)
```

这个部分已经和当前 `NSGA2.m` 的接口兼容，因为 `NSGA2.m` 本来就接收外部传入的 `chrom`。

第二步：暂时不要直接改 `raw_code/NSGA-II/NSGA2.m`，而是新增一个包装版搜索入口，例如：

```text
src/search/run_nsga2_with_encoding.m
```

包装入口内部可以先继续调用原始 `NSGA2.m`，但把初始 population 生成逻辑固定为 `generate_initial_population`。

第三步：如果要替换 `variation.m`，建议不要直接改原始 `NSGA2.m`，而是复制/封装一个新搜索函数，例如：

```text
src/search/nsga2_encoding_step.m
```

或者后续形成：

```text
src/search/run_nsga2_refactored.m
```

在新函数里把：

```matlab
variation(...)
```

替换成：

```matlab
generate_offspring(parent_, problem, agvData, options)
```

## 4. 为什么不能马上直接替换 variation.m

`NSGA2.m` 里的 `parent_` 不一定只包含核心 `5n` 编码列。经过评价和非支配排序后，`chrom` 后面会追加：

```text
目标值
非支配排序等级
拥挤度
```

新的 `generate_offspring` 当前只处理前 `5n` 个核心编码列，这一点和原始 `variation.m` 一致。但正式接入时要确认：

```text
parent_ 输入是否可能带有额外列
offspring_ 输出是否只需要核心编码列
评价后目标值是否仍由 fitness 追加
non_domination / replace_chrom 的列布局是否保持不变
```

这些属于搜索层接入风险，不应该在编码层封装阶段直接改。

## 5. 建议的正式接入验收标准

正式接入前，应先满足：

```text
scripts/run_encoding_smoke.m 能跑通
tests/test_encoding_layer.m 能跑通
generate_initial_population 不依赖 raw_code/init.m
generate_offspring 不调用 sorting.m / fitness.m / NSGA2.m
offspring 全部通过 validate_population
```

正式接入时，再单独验证：

```text
small NSGA-II 仍能跑通
输出 Pareto 结构不变
目标值列位置不变
non_domination / replace_chrom 不受影响
```

## 6. 当前结论

当前阶段可以先完成：

```text
编码层 demo 入口：scripts/run_encoding_smoke.m
正式 NSGA-II 接入方案：本文档
```

是否修改 `NSGA2.m`，应等搜索层接入任务单独确认后再做。
## 7. 2026-05-25 更新：G3 接入实现

当前已经新增旁路搜索层入口，不修改 `raw_code/NSGA-II/NSGA2.m`。

新增文件：

| 文件 | 作用 |
|---|---|
| `src/search/run_nsga2_with_encoding.m` | 搜索层包装入口：用 `generate_initial_population` 生成初始 population，然后运行 NSGA-II |
| `src/search/nsga2_with_encoding_variation.m` | 复制 NSGA-II 主循环边界，把原始 `variation(...)` 替换为 `generate_offspring(...)` |
| `scripts/run_small_nsga2_refactored.m` | 小规模运行脚本：使用新编码层生成初始 population，并使用新编码层生成 offspring |
| `tests/test_small_nsga2_refactored_encoding.m` | 小规模搜索接入测试：不写 outputs，只确认结果结构可用 |

接入分两档：

```text
useRefactoredVariation = false
    只替换初始种群生成：
    generate_initial_population -> raw NSGA2.m

useRefactoredVariation = true
    替换初始种群生成
    并在新搜索循环中用 generate_offspring 替换 raw variation.m
```

手动运行小规模 refactored 脚本：

```matlab
run('scripts/run_small_nsga2_refactored.m')
```

它会生成输出到：

```text
outputs/small_nsga2_refactored/时间戳/
```

只做结构测试、不生成 outputs：

```matlab
run('tests/test_small_nsga2_refactored_encoding.m')
```

当前仍然保留的依赖：

```text
fitness.m
sorting.m
non_domination.m
replace_chrom.m
tournament_selection.m
```

这说明 G3 只是把编码层接入搜索流程，不代表搜索层、解码层、评价层都已经完成重构。

## 8. 2026-05-25 运行结果记录

用户已运行正式小规模 refactored 入口：

```matlab
run('scripts/run_small_nsga2_refactored.m')
```

输出：

```text
RUNNING --------> NSGA-II with refactored encoding <-------- RUNNING
工件数：10 机器数 6 AGV数 3
GEN: 1  MIN Cmax: 138.5  MIN Energy:1936.65
GEN: 2  MIN Cmax: 138.5  MIN Energy:1936.65
运行时间：0.25258
small NSGA-II refactored encoding finished.
pop: 10, max_gen: 2
paretoSolutionCount: 1
bestMakespan: 138.456667
bestTotalEnergy: 1936.654667
outputDir: D:\CODEX\code_refactor_project\outputs\small_nsga2_refactored\20260525_192659
```

本次运行说明：

```text
generate_initial_population 已用于初始 population
generate_offspring 已用于迭代 offspring
refactored 小规模搜索流程可以跑通
结果结构包含 obj_matrix 和 curve
```

边界说明：

```text
这是“编码层接入搜索层”的验证。
它仍然会调用评价链路中的 fitness.m 和 sorting.m。
它不表示 decoding/evaluation/search 全部完成重构。
```

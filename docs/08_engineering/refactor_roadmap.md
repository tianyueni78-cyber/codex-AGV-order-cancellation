# 复现与封装路线：遇到问题时怎么办

## 1. 先说结论

复现和封装不是一上来重构全部算法，而是先把最短链路稳定下来：

```text
读数据
-> 生成一个染色体
-> 用 fitness 评价这个染色体
-> 得到 makespan 和 energy
```

这条链路稳了，再去整理算法、实验、画图和指标。

## 2. 为什么不能直接大改

当前 MATLAB 代码有几个特点：

- 主脚本里同时做了读数据、设参数、跑算法、画图、写结果。
- 很多路径依赖当前工作目录。
- 有些函数会自动写文件。
- 多个算法目录里有重复的 `fitness.m`、`sorting.m` 等函数。
- 随机过程没有统一 seed。

所以后期封装的原则是：

```text
先固定输入输出，再拆函数。
先验证小链路，再跑完整实验。
```

## 3. 复现风险与解决方案

| 问题 | 当前表现 | 复现时怎么办 | 后期封装方案 |
|---|---|---|---|
| `data.mat` 不知道从哪来 | `benchmarkRead.m` 读取 `.fjs` 后自动保存 | 运行前确认当前目录下 `data.mat` 是由哪个 `.fjs` 生成的 | 使用 `read_fjsp.m` 返回 `problem`，不再依赖 `data.mat` |
| Excel 被改写 | `distance_from_xy.m` 会写回 `机器数据.xlsx` | 运行前备份原 Excel，或先不调用距离回写逻辑 | 距离计算函数只返回矩阵，输出写到 `outputs/` |
| 路径错 | 代码里有 `cd('NSGA-II')`、`xlsread('机器数据.xlsx')` | MATLAB 当前目录必须在 `raw_code` 或脚本预期目录 | 用 `projectRoot` 和 `fullfile` 拼路径，不依赖手动 `cd` |
| 每次结果不同 | `rand`、`randperm`、`randn` 未固定 | 记录每次运行时间和参数，不要只保存最终图 | 每次实验开头设置并保存 `rng(seed)` |
| 输出混在一起 | `results.txt` 追加写，图名固定 | 每次运行前备份旧结果或清楚知道会追加 | 每次实验建立独立 `outputs/实验名/` 目录 |
| 参数分散 | 主脚本和算法内部都写参数 | 复现实验时记录主脚本参数和算法内部默认值 | 用配置文件集中管理参数 |
| 函数名重复 | 多个算法目录都有 `fitness.m`、`sorting.m` | 当前跑哪个算法，就确认 MATLAB 当前路径在哪个目录 | 后期提取公共模型函数，算法只保留搜索逻辑 |

## 4. 推荐封装顺序

不要从算法主函数开始拆。推荐顺序如下。

### 第一步：数据读取稳定

目标：

```text
文件 -> MATLAB 结构体
```

已完成：

```text
src/data/read_fjsp.m
```

下一步可做：

```text
read_machine_data.m
read_agv_data.m
```

要求：

- 只读取，不跑算法。
- 只返回数据，不写文件。
- 文件路径从外部传入。

### 第二步：建立统一数据包

目标：

把分散变量整理成几个容易传递的结构：

```text
problem      工件、工序、候选机器、加工时间
machineData  距离矩阵、机器能耗
agvData      AGV 数量、速度、电量、能耗、充电参数
config       算法参数、随机种子、输出目录
```

这样后面函数不需要传一长串变量。

### 第三步：单个染色体评价

目标：

```text
给一条 chrom，稳定算出 [makespan, totalEnergy]
```

这是最关键的封装点。

因为所有算法最终都在反复做这件事：

```text
生成染色体 -> 评价染色体 -> 根据目标值筛选
```

建议先做一个测试：

```text
test_fitness_smoke.m
```

测试内容：

- 读取小样本。
- 生成一个小种群。
- 取第一条染色体。
- 调用 `fitness`。
- 确认输出两个非空数字。

### 第四步：初始化和变异合法性检查

目标：

确认 `init.m` 和 `variation.m` 生成的染色体不会让 `sorting.m` 索引越界。

重点检查：

- `OS` 中每个工件出现次数是否等于工序数。
- `MS` 是否超出 `candidateMachine` 范围。
- `AS` 是否在 `1...AGVNum` 内。
- `SS` 是否在 `1...speedNum` 内。

### 第五步：小参数跑通一个算法

目标：

不是追求论文结果，而是确认算法闭环能跑。

建议参数：

```text
pop = 10
max_gen = 2
seed = 固定值
```

输出只需要确认：

- `obj_matrix` 非空。
- `curve.min` 非空。
- 没有路径错误。
- 没有索引错误。

### 第六步：整理完整实验

等上面都稳定后，再整理：

- `dif_main.m` 算法对比实验。
- `same_main.m` 消融实验。
- HV / Spacing / C-metric / IGD。
- Pareto 图、迭代图、甘特图。
- `outputs/实验名/` 输出目录。

## 5. 暂时不要动什么

当前阶段不建议马上动：

- 不要重写 `sorting.m`。
- 不要重写 `fitness.m`。
- 不要同时合并所有算法目录。
- 不要一次性改 `dif_main.m` 和 `same_main.m`。
- 不要一边改路径、一边改算法逻辑。

原因：

```text
sorting 和 fitness 是系统核心，一旦改错，所有算法结果都会变。
```

正确做法是先写旁路函数和测试，确认新旧结果一致，再逐步替换。

## 6. 最小稳定链路

后续所有封装都围绕这条链路：

```mermaid
flowchart TD
    FJS[".fjs 小样本"]
    MACHINE["机器数据"]
    AGV["AGV 数据"]
    INIT["生成一条 chrom"]
    FITNESS["fitness.m"]
    SORTING["sorting.m"]
    OBJ["makespan + totalEnergy"]

    FJS --> INIT
    MACHINE --> FITNESS
    AGV --> FITNESS
    INIT --> FITNESS
    FITNESS --> SORTING
    SORTING --> OBJ
```

只要这条链路稳定，算法层就是在外面反复调用它。

## 7. 以后每次封装的检查清单

每拆一个模块，都问：

1. 它吃什么输入？
2. 它吐什么输出？
3. 它有没有写文件？
4. 它有没有依赖当前目录？
5. 它有没有随机过程？
6. 它有没有改变原始数据？
7. 有没有一个小测试能证明它没坏？

如果这七个问题答不清楚，就先不要继续往下拆。

## 8. 当前进度与下一步

当前 small / medium / formal 可复用运行骨架已经跑通。

后续已选择：

```text
路线 A：继续工程化
```

因此下一步不建议继续盲目放大参数，也不建议马上进入完整论文实验。

路线 A 已经推进到第 17 步：

```text
第 17 步：指标入口设计
```

已经完成：

```text
configs/formal_nsga2_config.m
tests/test_formal_nsga2_config.m
scripts/run_formal_nsga2.m
formal 手动跑通
docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md
```

当前指标入口的最小读取版已经实现，并已由你在 MATLAB 中手动跑通。

当前已经新增：

```text
configs/formal_nsga2_config.m
```

它只负责保存 formal 配置，已经被 `scripts/run_formal_nsga2.m` 使用。

当前已经新增 formal 配置读取测试：

```text
tests/test_formal_nsga2_config.m
```

它只检查配置字段，不运行正式算法。

当前已经新增：

```text
scripts/run_formal_nsga2.m
```

它是 formal NSGA-II 的第一版运行骨架，已经由你在 MATLAB 中手动跑通。

formal 第一版已经手动跑通：

```text
run('scripts/run_formal_nsga2.m')
pop = 30
max_gen = 10
paretoSolutionCount = 2
bestMakespan = 134.446667
bestTotalEnergy = 1770.988667
outputDir = outputs/formal_nsga2/20260520_224558
```

第 17 步已经进入指标入口设计：

```text
scripts/run_metrics.m
```

当前已经新增 `scripts/run_metrics.m`。核心关系是：

```text
run_formal_nsga2.m -> 生成 formal_nsga2_result.mat
run_metrics.m      -> 读取 formal_nsga2_result.mat 并生成最小指标摘要
```

指标结果未来应保存到：

```text
outputs/formal_nsga2/时间戳/metrics/
```

`run_metrics.m` 已经由你在 MATLAB 中跑通：

```text
sourceRunDir = outputs/formal_nsga2/20260520_224558
paretoSolutionCount = 2
bestMakespan = 134.446667
bestTotalEnergy = 1770.988667
metricsDir = outputs/formal_nsga2/20260520_224558/metrics
```

因此第一阶段工程化闭环已经完成。当前不建议继续堆功能，下一条主线建议转向：

```text
编码-解码应用理解
```

也就是基于当前 FJSP-AGV 项目，整理“调度对象 -> 决策变量 -> 编码 -> 解码 -> 评价 -> 搜索”的可迁移理解框架。

## 9. 2026-05-22 盘点版：当前最重要缺口

本节只记录当前还缺什么，不指定下一步先做哪一个。

当前已经完成：

```text
数据读取封装
单条染色体评价 wrapper
small / medium / formal NSGA-II 运行入口
formal 结果保存
metrics 最小读取摘要
```

当前还没有完成：

| 缺口 | 当前表现 | 风险 | 封装完成后的理想状态 |
|---|---|---|---|
| 编码层封装不足 | `init.m` 仍来自原始 NSGA-II 目录 | 后续换算法或换论文时，不容易复用染色体生成逻辑 | 有独立的染色体生成、拆分、合法性检查函数 |
| 解码层仍依赖原始 `sorting.m` | 目前只通过文档理解其作用，没有拆出子模块 | 机器时间轴、AGV 时间轴、电量、插空逻辑仍耦合在一个核心函数里 | 解码主流程和关键子逻辑边界清楚，可单独解释和测试 |
| 评价层仍依赖原始 `fitness.m` | `evaluate_chromosome.m` 只是 wrapper | 目标值计算能跑，但 makespan、机器能耗、AGV 能耗边界还不够清楚 | 目标函数拆成可解释、可测试的评价子函数 |
| 完整指标缺失 | `run_metrics.m` 只生成最小摘要 | 还不能支持完整论文指标表 | HV / IGD / Spacing / C-metric 可从已保存结果中独立计算 |
| 搜索层只完成 NSGA-II 单线 | small / medium / formal 都是 NSGA-II | 多算法对比、消融实验、改进算法分析还不能复用同一套入口 | 各算法共享数据读取、评价、输出和 metrics 规则 |
| 图表层未建立 | 还没有独立 Pareto 图、收敛图、甘特图、论文表格入口 | 写论文时还需要手动整理结果 | 图表生成与算法运行分开，可从 outputs 中重建 |

按长期目标看：

| 长期目标 | 当前状态 | 主要缺口 |
|---|---|---|
| 看懂这篇论文代码逻辑 | 第一版已经比较完整 | 染色体小例子、`sorting.m` 变量流向、`fitness.m` 能耗数字例子、INSGA-II 改进点 |
| 把有用代码封装成以后能复用的工具 | 已完成最小工程闭环，但核心模块还没完全拆出 | 编码、解码、评价指标、搜索实验、图表输出 |

当前状态可以概括为：

```text
能跑，不等于已经完全封装。
数据层基本可复用。
评价层有 wrapper。
编码、解码、完整指标、搜索实验和图表层仍是主要缺口。
```
## 10. 2026-05-25 更新：编码层 E/F/G1 状态

编码层当前已经从“结构理解”推进到“第一版正式封装 + 异常测试”。

已完成：

| 阶段 | 状态 | 说明 |
|---|---|---|
| E1-E6 | 已完成 | 确认 `chrom = [OS, MS, AS, SS]`，建立编码层最小闭环 |
| F1 | 已完成 | `generate_initial_population.m` 已脱离 `raw_code/NSGA-II/init.m` |
| F2 | 已完成 | 新增 `validate_population.m`，可统计 `validCount / invalidCount / invalidIndexes` |
| F3 | 已完成 | 封装 `build_rs_upper_bounds`、OS/RS 交叉、OS/RS 变异、`generate_offspring` |
| F4 | 已完成 | `tests/test_encoding_layer.m` 已验证 population 和 offspring 都合法 |
| F5.1 | 已完成 | 新增 `scripts/run_encoding_smoke.m`，作为编码层 demo 入口 |
| F5.2 | 已完成 | 新增 `docs/03_algorithm/nsga2_encoding_integration_plan.md`，规划正式搜索层接入 |
| G1 | 已完成 | 新增 `tests/test_encoding_invalid_cases.m`，非法输入测试已由用户跑通 |

当前编码层可以独立完成：

```text
读 sample 数据
-> 生成初始 population
-> 验证 population
-> 生成 offspring
-> 再次验证 offspring
```

当前编码层不依赖：

```text
raw_code/NSGA-II/init.m
raw_code/NSGA-II/variation.m
sorting.m
fitness.m
NSGA2.m
outputs
```

下一阶段主线建议转向：

```text
Decoding Layer：sorting.m 的结构拆解、状态变量梳理、可测试子函数边界
Search Layer：新增包装入口，逐步让正式 NSGA-II 使用新编码层
```

## 11. 2026-05-25 更新：G3 搜索层接入验证

G3 已完成第一版旁路接入：不修改 `raw_code`，新增 `src/search/` 包装搜索入口，让完整小规模 NSGA-II 使用新编码层。

已完成：

| 阶段 | 状态 | 说明 |
|---|---|---|
| G3.1 | 已完成 | 确认 `NSGA2.m` 初始 `init(...)` 已注释，`chrom` 从外部传入；迭代里原本调用 `variation(...)` |
| G3.2 | 已完成 | 新增 `src/search/run_nsga2_with_encoding.m` |
| G3.3 | 已完成 | 新增 `scripts/run_small_nsga2_refactored.m` |
| G3.4 | 已完成 | 新增 `src/search/nsga2_with_encoding_variation.m`，用 `generate_offspring` 替代 raw `variation(...)` |
| G3.5 | 已跑通正式小规模脚本 | 用户已运行 `scripts/run_small_nsga2_refactored.m` 并得到结果 |

用户运行结果：

```text
pop = 10
max_gen = 2
paretoSolutionCount = 1
bestMakespan = 138.456667
bestTotalEnergy = 1936.654667
outputDir = outputs/small_nsga2_refactored/20260525_192659
```

当前结论：

```text
编码层正式封装代码已经接入搜索流程。
新入口可以跑完整小规模 NSGA-II。
raw_code 未修改。
```

仍未完成：

```text
Decoding Layer：sorting.m 仍未封装
Evaluation Layer：fitness.m 仍未拆解
Metrics：HV / IGD / Spacing / C-metric 仍未完整封装
Search Layer：目前只完成 NSGA-II refactored encoding 旁路，不代表所有算法都已统一
```

## 2026-05-25 更新：解码层 D1-D8 状态

解码层当前已经完成第一轮“拆解 -> 封装 -> 测试 -> 对比原始行为”的闭环。

| 阶段 | 状态 | 产物 |
|---|---|---|
| D1 | 已完成 | `sorting.m` 主流程拆解 |
| D2 | 已完成 | `docs/04_decoding/decoding_layer_structure_note.md` |
| D3 | 已完成 | 解码接口契约：`decode_chromosome(chrom, problem, machineData, agvData, config)` |
| D4 | 已完成 | `src/decoding/decode_chromosome.m` |
| D5 | 已完成并跑通 | `tests/test_decoding_layer.m` |
| D6 | 已完成并跑通 | `src/decoding/decode_population.m`，population 级别解码 |
| D7 | 已完成并跑通 | `tests/test_decoding_invalid_cases.m` |
| D8 | 已完成并跑通 | `tests/test_decoding_compare_sorting.m` |

用户已运行并确认：

```text
test_decoding_layer passed: population=3, operations=55, AGVNum=3
test_decoding_invalid_cases passed
test_decoding_compare_sorting passed: fields matched=5
```

当前结论：

```text
解码层第一轮正式封装完成。
decode_chromosome 与原始 sorting.m 在小样本手工案例的 5 个核心输出字段一致。
decode_population 已能对 population 逐条解码并统计失败。
```

当前仍未完成：

```text
Evaluation Layer: fitness.m 拆解和封装
Metrics: HV / IGD / Spacing / C-metric 完整封装
Search Layer: 完整脱离 raw_code 的统一搜索流程
```

# 知识地图工作表

## 当前总目标

用这篇 FJSP-AGV 论文代码作为样本，建立一套自己能看懂、后期能复用、以后能迁移到相近智能调度项目的运行骨架和知识地图。

这不是为了展示，也不是为了堆文档。每个模块都要服务三个问题：

1. 我能不能看懂这套代码在干什么？
2. 我以后能不能复用这套结构来放数据、改参数、跑小实验和排查问题？
3. 我换一篇智能调度论文时，能不能复用这套理解方法？

## 使用方式

这个文件是**总进度台账**，不是临时任务单。

以后回头看它时，重点看三件事：

1. 哪些认知模块已经有第一版。
2. 每个模块对应哪些文档。
3. 哪些内容属于后续按需要深化，而不是当前必须继续扩写。

## 第一轮模块完成台账

| 编号 | 模块 | 主要回答 | 当前状态 | 对应文档 | 后续可选深化 |
|---|---|---|---|---|---|
| 1 | 项目总览 | 这套代码整体在干什么？我该怎么读？ | 第一版完成 | `beginner_reading_guide.md`、`system_layer_architecture.md` | 按你的真实困惑改得更顺口 |
| 2 | 数据来源 | `.fjs`、Excel、距离、能耗参数从哪来？ | 第一版完成 | `data_layer_map.md` | 补字段级说明：变量长什么样 |
| 3 | 染色体编码 | `OS / MS / AS / SS` 分别表达什么决策？ | 应用理解总览已补 | `search_layer_overview.md`、`decoding_layer_overview.md`、`encoding_decoding_application_overview.md` | 后续可补一个最小染色体例子 |
| 4 | 解码过程 | `sorting.m` 怎么把染色体变成真实调度？ | 应用理解总览已补，代码主流程第一版完成 | `decoding_layer_overview.md`、`encoding_decoding_application_overview.md` | 补 `curJob`、`jobOpera`、时间轴变量流向 |
| 5 | 评价机制 | `fitness.m` 怎么计算完工时间和能耗？ | 第一版完成 | `evaluation_layer_overview.md` | 补机器能耗、AGV 能耗的数字例子 |
| 6 | 搜索基础 | 算法怎么生成、评价、筛选新方案？ | 第一版完成 | `search_layer_overview.md` | 后续再单独分析 VNS、Q-learning、反向学习 |
| 7 | 实验流程 | `dif_main.m`、`same_main.m` 到底跑了什么实验？ | 第一版完成 | `experiment_flow.md` | 补 HV、IGD、Spacing、C-metric 的函数细节 |
| 8 | 复现与封装路线 | 后期怎么分块、处理数据、封装才不容易报错？ | 第一版完成 | `data_reproduction_risks.md`、`refactor_roadmap.md` | 进入代码封装时继续细化成任务清单 |

## 第一轮完成情况

当前第一轮目标已经基本完成：8 个基础模块都有第一版或可用入口。

现在这套知识地图已经能回答：

- 这个项目研究什么调度问题？
- 数据从哪里来，进入哪些变量？
- 一个调度方案为什么能表示成染色体？
- `sorting.m` 为什么是核心解码器？
- `fitness.m` 为什么决定方案好坏？
- 算法为什么是在搜索染色体，而不是直接操作工厂？
- 一键运行脚本到底做了哪些实验，输出了哪些图和指标？
- 以后要封装和复现，最容易出错的点在哪里？

## 五层结构当前进度表

这张表回答一个更直接的问题：

```text
五层结构现在分别走到哪了？
```

| 五层 | 当前进度 | 已有成果 | 还没有做什么 | 下一步方向 |
|---|---|---|---|---|
| Data Layer 数据层 | 已经比较扎实 | `.fjs`、机器 Excel、AGV Excel 已拆出读取函数；已有轻量测试；small/medium/formal 都通过配置读取数据 | 还没有做字段级数据字典；新数据集批量管理还没做 | 后续换数据时再补字段说明和数据集管理规则 |
| Encoding Layer 编码层 | 已进入应用理解线 | `OS / MS / AS / SS` 的含义已说明；已新增编码-解码应用总览；当前仍使用原始 `init.m` 生成染色体 | 还没有单独封装染色体生成/合法性检查；还没有染色体小例子 | 后续可补“1 条 chrom 长什么样”的小例子 |
| Decoding Layer 解码层 | 已进入应用理解线，保持原算法 | `sorting.m` 已明确为核心解码器；已说明它如何处理工序顺序、机器、AGV、速度、电量和插空 | 没有重构 `sorting.m`；没有拆机器/AGV 时间轴子函数 | 后续按需要补变量流向图 |
| Evaluation Layer 评价层 | 基础目标值已跑通，指标入口最小读取版已跑通 | `evaluate_chromosome.m` 已封装单条评价；formal 能输出 makespan 和 totalEnergy；`run_metrics.m` 已读取 formal 结果并生成最小摘要 | `HV / IGD / Spacing / C-metric` 还没有完整实现 | 后续可按需要扩展完整指标 |
| Search Layer 搜索层 | NSGA-II 单算法骨架已跑通 | small、medium、formal 三个 NSGA-II 档位已跑通；formal 已输出到 `outputs/formal_nsga2/` | 多算法对比、消融实验、高级改进算法还没有进入 | 等指标入口稳定后，再考虑多算法对比 |

当前最关键的结论：

```text
数据层和 NSGA-II 搜索骨架已经能跑。
解码层和评价层仍依赖原始 sorting/fitness，暂时不重构。
工程化第一阶段已经闭环，当前主线转入“编码-解码应用理解”。
```

第 18 步已经新增编码-解码应用理解总览：

```text
docs/04_decoding/encoding_decoding_application_overview.md
```

它不讲逐行代码，而是回答：以后看新智能调度课题时，如何从调度对象、决策变量、编码、解码、评价、搜索这条链路理解问题。

## 第二轮深化池

第二轮不是固定顺序，而是根据你之后真正卡住的地方回头细化。

| 卡点 | 回头细化方向 |
|---|---|
| 看不懂 `OS / MS / AS / SS` | 补染色体小例子 |
| 看不懂 `sorting.m` | 补 `curJob`、`jobOpera`、`machineTable`、`AGVTable` 变量流向 |
| 看不懂 `fitness.m` | 补机器能耗、AGV 能耗、空闲能耗计算例子 |
| 不知道一键运行发生什么 | 补 `dif_main.m` 执行顺序 |
| 想开始封装代码 | 补最小稳定链路：数据读取 -> 单个染色体评价 |
| 想理解算法改进 | 分别分析 VNS、Q-learning、反向学习，不混在基础搜索里 |

## 后续更新规则

后续不是每做一步都重写这个文件，而是只在两种情况下更新：

1. 新增了一个重要知识模块。
2. 某个模块从“第一版”变成“已经可用于复现/封装”。

这样它保持为长期工作台账，而不是临时流水账。

## 当前工程进度台账

这个表记录“能跑到哪一步”，不是知识文档数量。

| 阶段 | 目标 | 当前状态 | 对应文件 |
|---|---|---|---|
| 数据读取 | 文件能稳定读进 MATLAB | 已拆解、已封装、已有测试 | `src/data/read_fjsp.m`、`src/data/read_machine_data.m`、`src/data/read_agv_data.m`、`tests/test_read_*.m` |
| 单条染色体评价 | 1 条 `chrom` 能被 `fitness/sorting` 评价 | 已拆解、已封装、已补正式测试 | `src/evaluation/evaluate_chromosome.m`、`tests/test_evaluate_chromosome.m` |
| 当前串联入口 | 把数据读取、生成 chrom、评价、输出串起来 | 已有脚本，已由你手动跑通 | `scripts/run_single_evaluation.m` |
| 小种群短迭代 | 小规模 NSGA-II 闭环运行 | 已由你本地跑通，正式测试也已跑通 | `scripts/run_small_nsga2.m`、`tests/test_small_nsga2.m` |
| 配置化运行入口 | 换数据/改参数时优先改配置而不是改脚本 | 已新增配置入口，已由你本地跑通 | `configs/small_nsga2_config.m`、`scripts/run_small_nsga2.m` |
| 数据与配置扩展准备 | 扩大规模前先明确换数据、改参数、检查输出的流程 | 已建立说明，步骤检查已由你本地跑通 | `docs/07_reproduction/reproduction_steps/07_data_config_extension.md` |
| 配置入口测试 | 在运行算法前检查配置文件、路径和参数是否合理 | 已由你本地跑通 | `tests/test_small_nsga2_config.m`、`docs/07_reproduction/reproduction_steps/08_config_entry_test.md` |
| 小幅放大参数运行 | 用 medium 档位检查配置化骨架能否轻微放大 | 已由你本地跑通 | `configs/medium_nsga2_config.m`、`scripts/run_medium_nsga2.m`、`docs/07_reproduction/reproduction_steps/09_medium_nsga2_run.md` |
| 运行入口分层整理 | 把 test / small / medium / 未来正式实验入口分清楚 | 已建立复现总入口说明 | `docs/07_reproduction/reproduction_steps/10_reproduction_entry_layers.md` |
| 阶段总结与下一阶段路线 | 总结 small/medium 骨架完成度，并选择后续主线 | 已完成，后续选择路线 A | `docs/07_reproduction/reproduction_steps/11_stage_summary_next_routes.md` |
| outputs 输出结构整理 | 明确 single / small / medium 输出目录和保存内容 | 已建立输出规则 | `docs/07_reproduction/reproduction_steps/12_outputs_structure.md` |
| 运行日志与参数记录 | 明确每次运行要记录哪些参数、结果和输出目录 | 已建立记录规则 | `docs/07_reproduction/reproduction_steps/13_run_log_and_parameter_record.md` |
| formal 入口设计 | 明确 small / medium / formal / metrics 的入口关系 | 已完成设计，formal 入口已落地 | `docs/07_reproduction/reproduction_steps/14_formal_experiment_entry_design.md` |
| formal 配置 | 建立正式运行配置字段和配置文件 | 已新增配置，配置测试已跑通 | `configs/formal_nsga2_config.m`、`tests/test_formal_nsga2_config.m` |
| formal 运行 | 跑通 NSGA-II formal 第一版 | 已由你在 MATLAB 中跑通 | `scripts/run_formal_nsga2.m` |
| 指标入口最小读取版 | 读取 formal 结果，生成最小指标摘要 | 已新增脚本，等待你在 MATLAB 中运行 | `scripts/run_metrics.m`、`docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md` |
| 完整论文实验 | 对比/消融/指标/图表 | 远期可选，不是当前主线 | 后续按需要整理 |

第一轮最小复现链路已经跑通。

这里的“第一轮”不是完整论文实验，而是指：

```text
数据读取
-> 单条染色体评价
-> 单条评价脚本
-> 小种群 NSGA-II 2 代短迭代
-> 配置化 small_nsga2
-> 输出到 outputs
```

这说明当前仓库已经具备一个小型、可控、可复用的运行骨架。

还没有进入的部分是：

```text
完整论文实验
完整评价指标
批量对比实验
消融实验
完整图表生成
HV / IGD / Spacing / C-metric 等指标汇总
```

这些属于后续扩展，不是第一轮最小复现链路的一部分。

第 5 步本地跑通记录：

```text
RUNNING --------> NSGA-II <-------- RUNNING
工件数：10 机器数 6 AGV数 3
GEN: 1  MIN Cmax: 155.9  MIN Energy:1890.05
GEN: 2  MIN Cmax: 155.9  MIN Energy:1890.05
运行时间：0.36357
small NSGA-II finished.
pop: 10, max_gen: 2
paretoSolutionCount: 3
bestMakespan: 155.886667
bestTotalEnergy: 1890.048000
outputDir: D:\CODEX\code_refactor_project\outputs\small_nsga2\20260519_222017
```

正式测试已由你本地跑通：

```text
RUNNING --------> NSGA-II <-------- RUNNING
工件数：10 机器数 6 AGV数 3
GEN: 1  MIN Cmax: 155.9  MIN Energy:1890.05
GEN: 2  MIN Cmax: 155.9  MIN Energy:1890.05
运行时间：0.55764
test_small_nsga2 passed: paretoSolutionCount=3, bestMakespan=155.886667, bestTotalEnergy=1890.048000
```

第 5 步已经形成：

```text
拆解 -> 串联脚本 -> 手动运行 -> 正式测试
```

当时进入：

```text
第 6 步：配置化 small_nsga2。
```

这一步的目标不是完整论文实验，而是形成可复用运行骨架：

```text
configs 决定数据和参数
scripts 按配置运行
outputs 保存结果
```

第 6 步本地跑通记录：

```text
RUNNING --------> NSGA-II <-------- RUNNING
工件数：10 机器数 6 AGV数 3
GEN: 1  MIN Cmax: 155.9  MIN Energy:1890.05
GEN: 2  MIN Cmax: 155.9  MIN Energy:1890.05
运行时间：0.27769
small NSGA-II finished.
pop: 10, max_gen: 2
paretoSolutionCount: 3
bestMakespan: 155.886667
bestTotalEnergy: 1890.048000
outputDir: D:\CODEX\code_refactor_project\outputs\small_nsga2\20260520_112624
```

这说明当前最远进度已经变成：

```text
数据 -> 配置入口 -> 小种群 NSGA-II 2 代短迭代 -> Pareto 解集摘要 -> outputs
```

## 下一阶段建议

下一阶段不建议立刻进入完整论文实验，也不建议现在就生成图片。

更合理的顺序是：

```text
扩大规模前，先整理数据和配置
```

也就是先回答：

```text
换一个 .fjs 怎么放？
换一套机器/AGV Excel 怎么放？
pop / max_gen / seed / 能耗参数应该在哪里改？
outputs 里每次结果怎么区分？
哪些参数放大以后最容易报错？
```

因此下一阶段建议命名为：

```text
第 7 步：数据与配置扩展准备
```

它的目标不是跑大实验，而是让后面扩大规模时不乱：

```text
先让“换数据、改参数、小规模验证”变成稳定流程
再考虑完整评价指标和图表
```

小规模阶段暂时不必生成图片。现在更重要的是确认：

```text
能读数据
能生成染色体
能调用原始算法
能输出目标值
能把结果放进 outputs
能通过配置复用
```

第 7 步已经建立为复现说明页：

```text
docs/07_reproduction/reproduction_steps/07_data_config_extension.md
```

它目前不新增代码，先把以后扩大规模前的检查顺序固定下来。

第 7 步建议的检查流程已经由你在 MATLAB 中跑通：

```text
读取检查 -> 单条评价检查 -> 小种群检查 -> 配置化运行
```

配置化小种群脚本也已经重复运行通过，最近一次输出目录为：

```text
outputs/small_nsga2/20260520_115204
```

第 8 步配置入口测试已经由你在 MATLAB 中跑通：

```text
test_small_nsga2_config passed: pop=10, max_gen=2, seed=42
```

第 9 步已经建立 medium 档位：

```text
small:  pop=10, max_gen=2
medium: pop=20, max_gen=5
```

第 9 步要验证的是：

```text
配置改大一点以后，算法是否还能跑完并输出到 outputs/medium_nsga2/
```

第 9 步已经由你在 MATLAB 中跑通：

```text
pop = 20
max_gen = 5
paretoSolutionCount = 4
bestMakespan = 135.743333
bestTotalEnergy = 1824.221333
outputDir = D:\CODEX\code_refactor_project\outputs\medium_nsga2\20260520_125615
```

medium 档位之后又重复运行通过，最近一次输出目录为：

```text
outputs/medium_nsga2/20260520_132626
```

第 10 步最初把入口分成三层：

```text
检查入口：tests/
运行入口：scripts/
未来正式实验入口：当时后续再整理
```

现在这部分已经继续推进：

```text
formal 配置：configs/formal_nsga2_config.m
formal 运行：scripts/run_formal_nsga2.m
metrics 设计：docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md
```

第 11 步已经完成阶段总结：

```text
当前阶段：可复用小规模运行骨架已完成
后续选择：路线 A，继续工程化
当时下一步建议：整理 outputs 输出结构
```

第 12 步已经建立输出规则：

```text
single -> outputs/single_evaluation/时间戳/
small  -> outputs/small_nsga2/时间戳/
medium -> outputs/medium_nsga2/时间戳/
outputs/ 不提交 GitHub
```

第 13 步已经建立运行日志与参数记录规则：

```text
每次运行要能追溯：
用的哪个脚本
用的哪个 config
用的哪组数据
seed 和算法参数是多少
结果保存到哪个 outputDir
bestMakespan / bestTotalEnergy / paretoSolutionCount 是多少
```

对应文档：

```text
docs/07_reproduction/reproduction_steps/13_run_log_and_parameter_record.md
```

这一步仍然属于路线 A：继续工程化。它不是跑更大的实验，而是让已经跑通的 small / medium 骨架更适合以后复现和回看。

第 14 步已经整理正式实验入口设计：

```text
当前已实现：
single / small / medium / formal

已实现：
metrics 最小读取版
```

对应文档：

```text
docs/07_reproduction/reproduction_steps/14_formal_experiment_entry_design.md
```

这一步的核心作用是把“检查、运行、正式复现、指标计算”分开，后面实现代码时不要把所有事情重新塞进一个大脚本。

第 15 步已经整理正式实验配置设计：

```text
formal 配置建议包含：
experiment / paths / dataset / random / algorithm / energy / output
```

对应文档：

```text
docs/07_reproduction/reproduction_steps/15_formal_config_design.md
```

当前已经选择 B，并新增：

```text
configs/formal_nsga2_config.m
```

它目前是 formal 配置入口，已经由 `scripts/run_formal_nsga2.m` 读取。

formal 配置读取测试也已新增：

```text
tests/test_formal_nsga2_config.m
```

它只检查字段完整性，不运行 NSGA-II。

formal 运行脚本已新增：

```text
scripts/run_formal_nsga2.m
```

当前它只实现单算法 NSGA-II 的 formal 骨架，输出到：

```text
outputs/formal_nsga2/时间戳/
```

多算法对比、完整指标和图表生成仍未进入。

formal 第一版已经由你在 MATLAB 中手动跑通：

```text
script: scripts/run_formal_nsga2.m
config: configs/formal_nsga2_config.m
dataset: Mk01
seed: 42
pop: 30
max_gen: 10
paretoSolutionCount: 2
bestMakespan: 134.446667
bestTotalEnergy: 1770.988667
outputDir: outputs/formal_nsga2/20260520_224558
```

这说明当前工程已经从 small / medium 骨架推进到 formal NSGA-II 单算法入口。  
下一步不建议立刻堆更多大实验，而是先由你运行 `run_metrics.m`，确认 formal 输出结果能被读取并生成最小摘要。

第 17 步已经整理指标入口设计，并新增最小读取版：

```text
script: scripts/run_metrics.m
input: outputs/formal_nsga2/时间戳/formal_nsga2_result.mat
core data: NSGA2_Result.obj_matrix
output: outputs/formal_nsga2/时间戳/metrics/
```

对应文档：

```text
docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md
```

这一步把搜索和指标计算分开：`run_formal_nsga2.m` 负责生成结果，`run_metrics.m` 负责读取结果并生成最小指标摘要。

`run_metrics.m` 已由你在 MATLAB 中手动跑通：

```text
script: scripts/run_metrics.m
sourceRunDir: outputs/formal_nsga2/20260520_224558
paretoSolutionCount: 2
bestMakespan: 134.446667
bestTotalEnergy: 1770.988667
metricsDir: outputs/formal_nsga2/20260520_224558/metrics
```

这说明第一阶段工程化闭环已经完成：

```text
配置 formal
-> 运行 formal NSGA-II
-> 保存 formal 结果
-> 读取 formal 结果
-> 生成最小 metrics 摘要
```

后续如果继续，不建议马上扩成完整论文实验。更合适的下一条主线是回到编码-解码应用理解：弄清楚一个调度问题如何从“对象和决策”变成“编码、解码、评价和搜索”。

## 2026-05-22 盘点版：五层完成度与缺口

本次盘点只回答“现在已经做到哪里、还差什么”，不制定下一步任务。

当前项目已经完成的是：**最小可复现工程闭环**。也就是说，项目已经能从配置读取数据，运行 formal NSGA-II，保存结果，再由 metrics 入口读取结果并生成最小摘要。

当前还没有完成的是：**核心编码、解码、评价指标和搜索实验的完整可复用封装**。

| 层次 | 已经做到什么 | 当前状态 | 还差什么 | 对长期目标的意义 |
|---|---|---|---|---|
| Data Layer 数据层 | `.fjs`、机器 Excel、AGV Excel 已拆成读取函数；已有测试；small / medium / formal 都能通过配置读取数据 | 基本拆完，可复用 | 字段级数据字典、新数据集批量管理规则还没补 | 以后换数据、换算例，这层已经可以作为模板 |
| Encoding Layer 编码层 | 已经讲清 `OS / MS / AS / SS` 分别代表什么；有编码-解码理解文档 | 理解完成，代码封装未完成 | 还没封装染色体生成、合法性检查、染色体小例子 | 论文编码逻辑已经能讲，但以后复用代码时还不够稳 |
| Decoding Layer 解码层 | 已确认 `sorting.m` 是核心解码器；已经说明它处理机器、AGV、速度、电量、插空等约束 | 理解完成，主代码未拆 | `sorting.m` 没拆；机器时间轴、AGV 时间轴、电量更新、插空逻辑还没分模块 | 论文逻辑能讲，但可复用解码器还没做出来 |
| Evaluation Layer 评价层 | 已有 `src/evaluation/evaluate_chromosome.m`，能包装原始 `fitness.m`，输出 makespan、energy、时间轴等 | 半封装完成 | `fitness.m` 本体还没拆；完整 HV / IGD / Spacing / C-metric 还没实现 | 单条染色体评价已经可复用，但完整论文指标还没齐 |
| Search Layer 搜索层 | small / medium / formal NSGA-II 已经跑通；配置、脚本、outputs、metrics 最小摘要已形成闭环 | NSGA-II 单算法骨架已跑通 | 多算法对比、消融实验、INSGA-II 改进点、批量运行入口还没封装 | 能跑一条 formal NSGA-II 线，但还不是完整论文实验平台 |

按两个长期目标拆开看：

| 目标 | 当前完成度判断 | 已经完成 | 还差什么 |
|---|---|---|---|
| 理解论文逻辑 | 已完成第一版，约 70% - 80% | 五层结构、数据流、编码含义、解码作用、评价机制、NSGA-II 搜索骨架都已有文档 | 一条染色体小例子；`sorting.m` 变量流向；`fitness.m` 能耗计算例子；INSGA-II 改进点说明 |
| 封装可复用代码 | 已完成一部分，约 40% - 50% | 数据读取封装；单染色体评价 wrapper；small / medium / formal 运行入口；metrics 最小读取入口 | 编码模块封装；解码模块封装；评价指标模块封装；搜索算法入口标准化；实验批量运行入口；图表与论文表格输出 |

最重要的缺口：

| 优先级 | 缺口 | 当前表现 | 为什么重要 |
|---|---|---|---|
| 1 | 编码层还没封装 | 当前 `init.m` 仍来自原始 NSGA-II 目录 | 还没有自己的“染色体生成 / 合法性检查”模块 |
| 2 | 解码层还没拆 | `sorting.m` 是核心解码器，但目前只是理解清楚 | 它决定编码如何变成真实机器和 AGV 调度，是论文逻辑核心 |
| 3 | 评价层只做了 wrapper | `evaluate_chromosome.m` 调用原始 `fitness.m` | makespan、机器能耗、AGV 能耗还没有拆成清楚子模块 |
| 4 | 完整指标没做 | `run_metrics.m` 目前只是最小摘要 | HV / IGD / Spacing / C-metric 才是完整论文实验常用指标 |
| 5 | 搜索层只有 NSGA-II 单线 | formal NSGA-II 能跑，但多算法对比和消融实验还没系统整理 | 还不能支撑完整论文实验对比 |
| 6 | 图表层还没有 | 还没有独立 Pareto 图、收敛图、甘特图、论文表格入口 | 写论文时还需要可复用的图表输出流程 |

一句话总结：

```text
当前已经有“能跑的工程骨架”和“论文逻辑地图”。
还没完成的是把核心编码、解码、评价、搜索真正拆成以后可迁移复用的模块。
```

## 2026-05-22 编码层工作表

本节只整理编码层的定义、边界、已完成内容、缺口和完成标准，不开始执行代码分析或代码修改。

### 1. 编码层是什么

编码层回答的问题是：

```text
一个真实调度方案，怎么表示成算法可以搜索的一串数字？
```

在当前 FJSP-AGV 项目中，算法不是直接操作甘特图，也不是直接移动机器和 AGV。算法真正操作的是一条染色体 `chrom`。

当前项目的染色体主要表达四类调度决策：

| 编码段 | 含义 | 回答的问题 |
|---|---|---|
| `OS` | Operation Sequence，工序顺序 | 先调度哪个工件的下一道工序？ |
| `MS` | Machine Selection，机器选择 | 这道工序放到哪台候选机器上加工？ |
| `AS` | AGV Selection，AGV 选择 | 这道工序由哪辆 AGV 搬运？ |
| `SS` | Speed Selection，速度选择 | AGV 空载/负载运输时用哪个速度档？ |

编码层只负责把调度决策表达成染色体。它不负责把染色体排成时间轴，也不负责计算目标值。

### 2. 哪些内容属于编码层

凡是回答“染色体长什么样、怎么生成、是否合法”的内容，都属于编码层。

| 内容 | 是否属于编码层 | 说明 |
|---|---|---|
| `chrom` 的结构 | 是 | 一条染色体由哪些段组成 |
| `OS / MS / AS / SS` 的含义 | 是 | 每段代表什么调度决策 |
| `init.m` 生成初始种群 | 是 | 它负责生成第一批染色体 |
| 染色体长度计算 | 是 | 通常和总工序数有关 |
| 每段编码的取值范围 | 是 | 机器、AGV、速度档不能越界 |
| 染色体合法性检查 | 是 | 判断编码是否可能让解码器报错 |
| 交叉、变异后的编码合法性 | 部分属于 | 如果关注染色体结构和合法性，就属于编码层 |
| `sorting.m` 解码调度 | 否 | 属于解码层 |
| `fitness.m` 计算目标值 | 否 | 属于评价层 |
| NSGA-II 选择 Pareto 解 | 否 | 属于搜索层 |

### 3. 编码层当前已经完成什么

当前编码层已经完成的是**理解层面**，还没有完成**封装层面**。

| 已完成内容 | 当前证据 |
|---|---|
| 已知道当前项目用 `OS / MS / AS / SS` 表示调度决策 | `docs/04_decoding/encoding_decoding_application_overview.md` |
| 已知道算法搜索的是染色体，不是直接搜索甘特图 | 五层结构文档和搜索层文档 |
| 已能通过原始 `init.m` 生成种群 | small / medium / formal NSGA-II 都已跑通 |
| 已知道编码会被 `sorting.m` 解码成真实调度 | 解码层文档 |
| 已知道编码和数据层有关 | `MS` 依赖 `candidateMachine`，`AS` 依赖 `AGVNum`，`SS` 依赖速度档数量 |

### 4. 编码层还没有完成什么

| 未完成内容 | 为什么重要 |
|---|---|
| 没有自己的编码层封装函数 | 当前仍依赖 `raw_code/NSGA-II/init.m` |
| 没有染色体结构说明函数 | 以后看到一条 `chrom`，不容易快速拆成 `OS / MS / AS / SS` |
| 没有合法性检查函数 | 不能单独确认一条染色体是否会让 `sorting.m` 越界 |
| 没有最小染色体例子 | 理解论文编码逻辑时不够直观 |
| 没有编码层轻量测试 | 不能单独证明“编码层没坏” |
| 没有交叉、变异后的合法性检查 | 后面封装搜索算法时容易出现隐性错误 |

### 5. 编码层要服务的目标

编码层要同时服务两个长期目标：理解论文逻辑，以及封装可复用代码。

| 目标 | 编码层需要做到什么 |
|---|---|
| 拆解论文逻辑 | 能说清楚调度问题有哪些决策，这些决策为什么能编码成 `OS / MS / AS / SS` |
| 封装代码 | 有统一入口生成、拆分、检查和描述染色体 |
| 测试复现 | 有轻量测试确认染色体长度、取值范围、seed 可复现 |
| 以后迁移 | 换一篇调度论文时，能复用“对象 -> 决策 -> 编码”的理解方法 |

### 6. 编码层建议形成的封装能力

编码层不需要一开始重写原始算法逻辑。更稳的方式是先建立自己的入口，内部暂时仍可调用原始 `init.m`。

建议形成的能力包括：

| 能力 | 作用 |
|---|---|
| 生成初始种群 | 根据 `problem`、AGV 数量、速度档数量生成 `chrom` |
| 拆分染色体 | 把一条 `chrom` 拆成 `OS / MS / AS / SS` |
| 检查合法性 | 检查 `OS` 次数、`MS` 范围、`AS` 范围、`SS` 范围 |
| 描述染色体 | 输出人能看懂的结构摘要，帮助学习和排错 |

可能的函数方向：

```text
generate_initial_population
split_chromosome
validate_chromosome
describe_chromosome
```

这些名字只是能力方向，最终文件名和函数名要等真正进入编码层封装任务时再定。

### 7. 编码层测试应覆盖什么

编码层测试不需要跑完整 NSGA-II，也不需要生成 outputs。它只检查编码本身。

| 测试点 | 目的 |
|---|---|
| 染色体长度正确 | 确认 `chrom` 结构和总工序数匹配 |
| `OS` 中每个工件出现次数正确 | 确认工序顺序编码没有丢工序或多工序 |
| `MS` 不超过候选机器范围 | 避免解码时机器索引越界 |
| `AS` 在 `1...AGVNum` 内 | 避免 AGV 索引越界 |
| `SS` 在 `1...speedNum` 内 | 避免速度档索引越界 |
| 固定 seed 时可复现 | 保证后续实验可追踪 |

### 8. 编码层处理时的禁止事项

处理编码层时，暂时不要碰后面几层：

```text
不改 sorting.m
不改 fitness.m
不改 NSGA-II 主循环
不跑完整 formal
不生成 outputs
不修改 raw_code
```

原因是编码层只解决“染色体表达和合法性”。解码、评价、搜索是后面的层，混在一起会让问题来源变得不清楚。

### 9. 编码层完成标准

编码层完成，不是指“把算法跑一遍”，而是指：

```text
能生成一条合法染色体，
能拆开它，
能解释每一段代表什么，
能测试它不会让后续解码越界，
并且以后换论文时能复用这套编码理解方法。
```

对应到可检查标准：

| 完成项 | 标准 |
|---|---|
| 能解释 | 能用一条小染色体说明 `OS / MS / AS / SS` |
| 能生成 | 能通过统一入口生成初始种群 |
| 能拆分 | 能把 `chrom` 拆成结构化的编码段 |
| 能检查 | 能判断染色体是否合法 |
| 能测试 | 有轻量测试验证长度、范围和 seed |
| 能复用 | 后续搜索算法不直接依赖散落的原始编码逻辑 |

编码层完成后，应该能清楚回答：

```text
这篇论文到底把什么决策交给算法搜索？
算法搜索的变量长什么样？
这条染色体为什么能代表一个调度方案？
它哪些部分由编码保证，哪些部分交给解码保证？
```

## 2026-05-22 编码层封装阶段工作计划

本节记录编码层进入“封装阶段”后的拆分计划。目标是把编码层拆成小任务，一次只做一个，避免把结构分析、函数封装、测试和算法运行混在一起。

### 总原则

编码层封装阶段只处理：

```text
chrom 结构
chrom 拆分
chrom 合法性检查
初始种群生成入口
编码层轻量测试
```

编码层封装阶段暂时不处理：

```text
sorting.m 解码
fitness.m 评价
NSGA-II 主循环
formal 实验
outputs 生成
raw_code 修改
```

### 编码层封装阶段任务表

| 编号 | 任务 | 任务目标 | 允许范围 | 禁止内容 | 预期输出 | 完成后动作 |
|---|---|---|---|---|---|---|
| E1 | 确认当前 `chrom` 真实结构 | 只读现有代码，确认一条 `chrom` 到底怎么分段、长度怎么算 | `raw_code/NSGA-II/init.m`、`raw_code/NSGA-II/NSGA2.m`、`tests/test_small_nsga2.m`、`scripts/run_small_nsga2.m` | 不修改文件；不运行 MATLAB；不生成 outputs；不读无关算法目录；不读 `sorting.m` / `fitness.m` | `chrom` 总长度规则；`OS / MS / AS / SS` 位置；是否还有其他编码段；每段取值范围；不确定点 | 停止，等待确认 |
| E2 | 写编码层结构说明文档 | 把 E1 结果整理成文档，避免以后反复翻 `init.m` | 只基于 E1 已确认内容和现有工作表 | 不写代码；不运行 MATLAB；不生成 outputs；不改 `raw_code` | 编码层结构说明，说明 `chrom` 的分段、长度和取值边界 | 停止，等待确认 |
| E3 | 封装 `split_chromosome` | 新增只负责拆分染色体的函数 | `src/encoding/`、必要的轻量测试文件 | 不调用 `sorting.m`；不调用 `fitness.m`；不调用 `NSGA2.m`; 不改 `init.m`; 不改 `raw_code`; 不生成 outputs | 能把一条 `chrom` 拆成结构化编码段 | 停止，等待确认 |
| E4 | 封装 `validate_chromosome` | 新增染色体合法性检查函数 | `src/encoding/`、必要的轻量测试文件 | 不运行完整算法；不调用 `sorting.m`; 不调用 `fitness.m`; 不改 `raw_code`; 不生成 outputs | 能检查长度、`OS` 次数、`MS` 范围、`AS` 范围、`SS` 范围 | 停止，等待确认 |
| E5 | 封装 `generate_initial_population` | 建立自己的编码层生成入口，第一版内部可暂时调用原始 `init.m` | `src/encoding/`、必要的轻量测试文件 | 不改 `init.m`; 不重写随机生成逻辑；不改 `NSGA2.m`; 不运行 formal；不生成 outputs | 统一入口生成初始种群，并能配合合法性检查 | 停止，等待确认 |
| E6 | 编码层 smoke test | 写轻量测试，证明编码层最小闭环可用 | `tests/`、`src/encoding/` | 不调用 `sorting.m`; 不调用 `fitness.m`; 不运行 `NSGA2.m`; 不生成 outputs | 测试链路：读取 sample 数据 -> 生成种群 -> 拆分第一条 `chrom` -> 合法性检查通过 | 停止，等待确认 |

### 任务之间的关系

```text
E1 先看清楚 chrom 真实结构
E2 把结构写清楚
E3 能拆 chrom
E4 能检查 chrom
E5 能统一生成 chrom
E6 能测试编码层
```

### 为什么要这样拆

编码层封装最怕混成一团：

```text
一边猜 chrom 结构
一边写 split
一边写 validate
一边改 init
一边跑算法
```

这样一旦出错，很难判断问题来自编码结构、拆分函数、合法性检查，还是搜索算法本身。

所以当前采用更小的顺序：

```text
先只读确认
再写说明
再写拆分
再写检查
再统一生成入口
最后做 smoke test
```

### 编码层封装阶段完成标准

当 E1-E6 都完成后，编码层第一轮封装才算完成：

```text
知道 chrom 结构
有文档说明
有 split 函数
有 validate 函数
有统一生成入口
有轻量测试
不依赖猜测
不改 raw_code
不动 sorting / fitness
```

## 2026-05-22 当前各层封装状态速查

这个表只回答一个问题：哪些层已经有可用封装，哪些还只是脚本或文档。

| 层 | 封装函数状态 | 脚本入口状态 | 规则/文档状态 | 当前结论 |
|---|---|---|---|---|
| Data Layer 数据层 | 已有 `src/data/read_fjsp.m`、`read_machine_data.m`、`read_agv_data.m` | 被 single/small/medium/formal 脚本调用 | 有数据层认知地图、数据读取复现步骤 | 数据读取函数第一版已封装 |
| Encoding Layer 编码层 | 已新增 `src/encoding/split_chromosome.m` 和 `validate_chromosome.m`，可拆分并检查单条 `chrom` | 生成种群仍由原始 `init.m` 支撑，变异仍由原始 `variation.m` 支撑 | 已有编码层工作表和结构笔记 | 编码层函数封装已开始，仍缺 generate / smoke test |
| Decoding Layer 解码层 | 还没有新封装函数 | 仍依赖原始 `sorting.m` | 有解码层认知文档 | 理解第一版完成，代码封装未开始 |
| Evaluation Layer 评价层 | 已有 `src/evaluation/evaluate_chromosome.m` wrapper | 有 `scripts/run_single_evaluation.m` | 有评价层文档和单条评价复现步骤 | 有 wrapper，但 `fitness.m` 本体未拆 |
| Search Layer 搜索层 | 还没有新搜索函数封装 | 有 `run_small_nsga2.m`、`run_medium_nsga2.m`、`run_formal_nsga2.m` | 有搜索层文档、运行入口和配置说明 | 有脚本入口，仍调用原始 `NSGA2.m` |
| Metrics / 指标层 | 还没有完整指标函数 | 有 `scripts/run_metrics.m` 最小读取版 | 有指标入口设计文档 | 能读 formal 结果并生成最小摘要，完整指标未做 |
| 工程复现层 | 不属于算法函数层 | 有 scripts、tests、configs | 有入口地图、输出规则、日志规则 | 最小工程闭环已跑通 |

一句话：

```text
数据层函数封装最完整。
评价层有 wrapper。
搜索层有运行脚本但没有新搜索函数。
编码层已有拆分和合法性检查函数，仍未完成整层封装。
解码层还没有函数封装。
```
## 2026-05-25 更新：编码层接入搜索层已跑通

本次记录的是编码层从“独立封装”进入“搜索层接入”的验证结果。

用户已在 MATLAB 中运行：

```matlab
run('scripts/run_small_nsga2_refactored.m')
```

运行结果：

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

这说明：

```text
新编码层 generate_initial_population 已经接入小规模 NSGA-II
新编码层 generate_offspring 已经替代 raw variation.m 进入新搜索循环
refactored 小规模搜索能跑完 2 代
obj_matrix / curve / 输出摘要结构可用
raw_code 没有被修改
```

当前编码层完成范围：

| 范围 | 状态 |
|---|---|
| 结构拆解 | 已完成 |
| 生成初始 population | 已完成，正式代码在 `src/encoding/generate_initial_population.m` |
| 单条 chrom 合法性检查 | 已完成，正式代码在 `src/encoding/validate_chromosome.m` |
| population 合法性检查 | 已完成，正式代码在 `src/encoding/validate_population.m` |
| 交叉/变异封装 | 已完成，正式代码在 `src/encoding/*crossover*`、`src/encoding/*mutate*`、`src/encoding/generate_offspring.m` |
| 编码层正常测试 | 已完成，`tests/test_encoding_layer.m` 已由用户跑通 |
| 编码层异常测试 | 已完成，`tests/test_encoding_invalid_cases.m` 已由用户跑通 |
| 编码层 demo 入口 | 已完成，`scripts/run_encoding_smoke.m` |
| 搜索层旁路接入 | 已初步完成，`scripts/run_small_nsga2_refactored.m` 已由用户跑通 |

结论：

```text
编码层已经不是临时小代码，而是第一版正式封装代码。
它已经脱离 raw init.m / raw variation.m。
但完整项目还没有全部封装完：解码层 sorting.m、评价层 fitness.m、完整指标和多算法实验仍是后续阶段。
```

## 2026-05-25 更新：解码层完成状态与评价层下一步工作表

### 当前结论

解码层第一轮已经完成“拆解 + 封装 + 测试”闭环。

当前已经完成：

| 范围 | 状态 | 说明 |
|---|---|---|
| 解码层结构拆解 | 已完成 | 已说明 `sorting.m` 如何把 `chrom` 转成调度过程 |
| 单条 chrom 解码 | 已完成 | `src/decoding/decode_chromosome.m` |
| population 解码 | 已完成 | `src/decoding/decode_population.m` |
| 正常测试 | 已完成并跑通 | `tests/test_decoding_layer.m` |
| 异常测试 | 已完成并跑通 | `tests/test_decoding_invalid_cases.m` |
| 原始行为对比 | 已完成并跑通 | `tests/test_decoding_compare_sorting.m`，5 个核心字段一致 |

当前解码层负责：

```text
chrom -> schedule
```

其中 `schedule` 包含：

```text
machineTable
AGVTable
jobCompleteUnLoad
agvEGRecord
agvChargeNum
```

当前解码层不负责：

```text
makespan
totalEnergy
objectiveVector
non-domination
Pareto 筛选
outputs 保存
```

这些进入评价层和搜索层。

### 为什么后面要进入评价层

原始 `fitness.m` 同时做了三件事：

```text
1. 初始化 machineTable / AGVTable
2. 调用 sorting.m 解码
3. 根据解码结果计算 makespan / totalEnergy
```

现在第 2 步已经有了新的解码层封装：

```text
decode_chromosome
decode_population
```

所以接下来要拆的是第 1 步和第 3 步，也就是评价层。

### 下一阶段工作表：Evaluation Layer

| 编号 | 任务 | 任务目标 | 允许范围 | 禁止内容 | 预期输出 | 完成后动作 |
|---|---|---|---|---|---|---|
| V1 | 只读 `fitness.m`，拆解评价层结构 | 理解 `fitness.m` 如何初始化时间表、调用解码、计算目标值 | `raw_code/NSGA-II/fitness.m`, `docs/04_decoding/`, `src/decoding/` | 不修改文件；不运行 MATLAB；不生成 outputs；不读其他算法目录 | `fitness.m` 输入/输出、内部步骤、和解码层的边界 | 停止等待确认 |
| V2 | 写评价层结构说明文档 | 把 V1 理解写进 GitHub 文档 | `docs/05_evaluation/`, `docs/00_system_overview/` | 不改代码；不运行 MATLAB；不生成 outputs | `evaluation_layer_structure_note.md` | 停止等待确认 |
| V3 | 封装初始时间表构造 | 把 `machineTable / AGVTable` 初始化从 `fitness.m` 中拆出来 | `src/evaluation/`, `tests/`, `docs/05_evaluation/` | 不改 raw_code；不运行完整算法；不生成 outputs | `create_initial_schedule_tables.m` 或等价函数 | 停止等待确认 |
| V4 | 封装 schedule 评价函数 | 输入 `schedule`，计算 `makespan / energy` | `src/evaluation/`, `src/decoding/`, `tests/` | 不改 raw_code；不跑完整 NSGA-II；不生成 outputs | `evaluate_schedule.m` | 停止等待确认 |
| V5 | 封装单条 chrom 评价入口 | 串起 `decode_chromosome -> evaluate_schedule` | `src/evaluation/`, `src/decoding/`, `tests/` | 不改 raw_code；不改搜索主流程；不生成 outputs | `evaluate_chromosome_refactored.m` | 停止等待确认 |
| V6 | 对比原始 `fitness.m` 行为 | 同一条 chrom，对比原始 `fitness.m` 和新评价入口输出 | `tests/`, `src/evaluation/`, `src/decoding/`, 必要时只读 `raw_code/NSGA-II/fitness.m` | 不改 raw_code；不运行完整算法；不生成正式 outputs | 对比测试，确认 makespan/energy 一致或差异可解释 | 停止等待确认 |
| V7 | 更新文档和入口 | 让 GitHub 能找到评价层函数、测试、边界 | `README.md`, `docs/00_system_overview/`, `docs/05_evaluation/`, `docs/08_engineering/` | 不改算法代码；不运行 MATLAB；不生成 outputs | README/entrypoint/file guide/roadmap 更新 | 停止等待确认 |
| V8 | 规划搜索层接入新评价函数 | 只规划，不直接改搜索主流程 | `src/search/`, `src/evaluation/`, `docs/03_algorithm/`, `docs/05_evaluation/` | 不改 raw_code；不运行 MATLAB；不生成 outputs | 新评价层如何替换 `fitness.m` 的接入方案 | 停止等待确认 |

评价层完成后的理想链路是：

```text
chrom
-> decode_chromosome
-> schedule
-> evaluate_schedule
-> [makespan, totalEnergy]
```

再往后才适合让搜索层调用新的评价入口。
## 2026-05-29 更新：independent 主线实施地图

第 21-25 步已经把项目从“raw wrapper 可控复现”推进到“第一版 independent 可复现框架”。

| 步骤 | 目标 | 已完成入口 | 当前状态 |
|---|---|---|---|
| 21. 独立 decoding | 不再调用 raw `sorting.m` | `src/decoding/decode_chromosome_independent.m`、`src/decoding/decode_population_independent.m` | 已完成，raw compare 通过 |
| 22. 独立 evaluation | 不再调用 raw `fitness.m` | `src/evaluation/evaluate_decoded_schedule.m` | 已完成，raw wrapper compare 通过 |
| 23. 独立 search | 不再调用 raw `NSGA2.m` / raw selection / raw replacement | `src/search/run_independent_nsga2.m` | 已完成，small loop 通过 |
| 24. raw 对照总验收 | 系统确认 independent 与 raw 一致或差异可解释 | `tests/test_independent_*compare_raw.m` | 已完成，decoding/evaluation/search small 均有对照 |
| 25. independent 实验入口 | 建立 independent small / medium / formal preflight | `scripts/run_independent_*_nsga2.m` | 已完成，small/medium 已运行，formal preflight 通过 |

当前项目分层状态更新为：

| 层 | 当前结论 |
|---|---|
| raw_code | 只读 baseline，不再作为新实现主线 |
| encoding | 已有 refactored 生成、校验、交叉、变异入口 |
| decoding | 已有 independent decoder |
| evaluation | 已有 independent schedule evaluator |
| search | 已有 independent NSGA-II small/medium 可运行入口 |
| experiments | 已有 independent small / medium / formal preflight 配置和脚本 |
| tests | 已有 independent 验收和 raw 对照 |
| docs | 已补 independent decoding/evaluation/search/raw compare/experiment entry 说明 |

当前能力边界：

```text
已经具备：脱离 raw_code 的第一版 independent 可复现框架。
尚未完成：independent formal 正式运行、formal outputs 接 metrics/visualization、baseline 对比、多 seed 统计、新项目迁移演练。
```

下一阶段实施地图：

| 编号 | 下一步 | 目标 |
|---|---|---|
| 26 | independent formal 真正运行 | 产出 independent formal 的 result/summary/run_info |
| 27 | independent metrics / visualization 接 outputs | 让 independent formal 输出能生成指标和基础图 |
| 28 | baseline 对比实验跑通 | raw baseline 与 independent variant 同数据同 seed 对比 |
| 29 | 多 seed 统计汇总 | 形成 mean/std/best/worst 统计 |
| 30 | 新项目迁移演练 | 验证这套框架如何迁移到新选题 |

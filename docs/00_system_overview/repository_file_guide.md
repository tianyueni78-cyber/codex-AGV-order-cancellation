# 项目文件导览：每个板块是干什么的

这个文档不是讲算法原理，而是回答一个更基础的问题：

> 我打开这个仓库时，每个文件夹、每个文件大概在干什么？以后我要用它来做什么？

先记住一句话：

```text
raw_code 保存原始论文代码
src 保存慢慢拆出来的新函数
tests 保存你可以自己跑的小检查
docs 保存理解系统的知识地图
data_sample 保存小样本数据
configs 以后保存实验参数
outputs 以后保存运行结果
```

## 1. 根目录文件

| 文件 | 现在是干什么的 | 以后怎么用 |
|---|---|---|
| `README.md` | 仓库首页和文档导航 | 你在 GitHub 上先看这里，点进去找知识地图 |
| `AGENTS.md` | 给 AI 助手看的工作规则 | 约束我不能乱改 `raw_code/`、不能一次性大重构、要保证复现 |

## 2. `raw_code/`：原始论文代码区

这个文件夹是“原始档案”，原则上不改。它的作用是保留论文代码原貌，方便对照、复现和回查。

| 文件或文件夹 | 现在是干什么的 | 以后怎么用 |
|---|---|---|
| `dif_main.m` | 对比实验主脚本 | 论文里不同算法对比时，通常从这里看实验怎么跑 |
| `same_main.m` | 消融或同类实验主脚本 | 看改进策略之间怎么比较 |
| `benchmarkRead.m` | 原始 `.fjs` 标准算例读取脚本 | 只用来对照，现在新读取函数在 `src/data/read_fjsp.m` |
| `distance_from_xy.m` | 根据机器坐标计算距离，并写回 Excel | 有副作用，后续要谨慎处理，不建议直接当纯读取函数用 |
| `init.m` | 生成初始染色体 | 理解 `OS / MS / AS / SS` 从哪里来 |
| `non_domination_only.m` | 非支配排序相关工具 | 多目标筛选时用 |
| `calculateHVSP.m` | 计算 HV、Spacing 等指标的入口之一 | 看实验评价指标怎么从结果表里读出来 |
| `energy_plot.m` | 画 AGV 电量变化图 | 看充电、电量曲线展示 |
| `machine_AGV_gantt_chart.m` | 画机器和 AGV 甘特图 | 看一个调度方案最终长什么样 |
| `colorScheme.m` | 画图配色 | 只影响展示，不影响算法逻辑 |
| `data.mat` | 原始脚本自动保存的中间数据 | 这是副作用文件，后续复现时要避免被静默覆盖 |
| `results.txt` | 原始运行结果文本 | 只作历史结果参考 |
| `*.fig / *.emf / figures/` | MATLAB 图和导出的图 | 论文画图或复查结果时看，不是算法核心 |
| `*.xlsx` | 原始 Excel 数据 | 包括机器数据、AGV 数据、参数测试数据等 |
| `fjsp/` | 标准 FJSP 算例库 | `.fjs` 算例来源，后续跑不同规模实验会用 |
| `NSGA-II/` | 基础 NSGA-II 算法实现 | 适合先看：`init`、`variation`、`sorting`、`fitness`、`NSGA2` |
| `INSGA-II/` | 改进 NSGA-II 实现 | 包含 VNS、Q-learning、改进精英策略等论文改进点 |
| `MOEAD/` | MOEA/D 对比算法 | 对比实验用，不建议一开始深看 |
| `MOPSO/` | MOPSO 对比算法 | 对比实验用 |
| `MOSSA/` | MOSSA 对比算法 | 对比实验用 |
| `SPEA2/` | SPEA2 对比算法 | 对比实验用 |
| `HV/` | HV 指标计算 | 衡量 Pareto 解集覆盖空间大小 |
| `IGD/` | IGD 指标计算 | 衡量解集靠近参考前沿的程度 |
| `Spacing/` | Spacing 指标计算 | 衡量解集分布均匀性 |
| `C-metric/` | C-metric 指标计算 | 衡量一个算法解集覆盖另一个算法解集的程度 |
| `新建文件夹/` | 原始数据备份或重复样本 | 暂时只作历史备份，不作为新代码默认入口 |

### 算法文件夹里常见文件怎么理解

很多算法文件夹里会重复出现同名文件，它们大致分工一致：

| 文件名 | 中文理解 | 在系统中的位置 |
|---|---|---|
| `init.m` | 先造一批可能的调度方案 | 搜索层入口 |
| `variation.m` | 通过交叉、变异生成新方案 | 搜索层更新 |
| `sorting.m` | 把染色体变成机器/AGV 时间表 | 解码层核心 |
| `fitness.m` | 计算完工时间和能耗 | 评价层核心 |
| `non_domination.m` | 判断哪些方案互相不可支配 | 多目标筛选 |
| `replace_chrom.m` | 根据评价结果更新种群 | 搜索层筛选 |
| `tournament_selection.m` | 从种群里选择父代 | 搜索层选择 |
| `table_insert.m` | 把加工或运输任务插入时间轴 | 解码层工具 |
| `decompose_machineTable.m` | 拆机器时间块 | 解码层工具 |
| `decompose_AGVTable.m` | 拆 AGV 时间块 | 解码层工具 |
| `load_transfer_time_compute.m` | 计算负载运输时间 | AGV 调度工具 |
| `spare_transfer_time_compute.m` | 计算空载运输时间 | AGV 调度工具 |

## 3. `src/`：新封装代码区

这个文件夹是以后慢慢整理出来的“干净代码”。它和 `raw_code/` 最大区别是：尽量一个函数只做一件事，减少自动保存文件、写 Excel、依赖当前工作目录这类副作用。

### `src/data/`

| 文件 | 现在是干什么的 | 以后怎么用 |
|---|---|---|
| `read_fjsp.m` | 读取 `.fjs` 标准算例，返回 `problem` 结构 | 用它替代原来 `benchmarkRead.m` 里混在一起的读取逻辑 |
| `read_machine_data.m` | 读取机器 Excel 里的距离矩阵和机器能耗 | 后续算法运行前，用它准备 `distance_matrix` 和 `machineEnergy` |
| `read_agv_data.m` | 读取 AGV Excel 里的 AGV 数量、速度、空载/负载能耗 | 后续算法运行前，用它准备 `AGVNum`、`AGVSpeed`、`AGVEnergy` |

现在 `src/data/` 的意义是：

```text
先把“数据怎么进系统”这件事拆清楚
再考虑后面怎么封装算法
```

## 4. `tests/`：你自己跑的小检查

这些不是完整论文实验，而是“小块复现检查”。它们的作用是：每拆一个读取函数，就确认它能不能独立跑通。

| 文件 | 跑什么 | 正常说明什么 |
|---|---|---|
| `test_read_fjsp.m` | 读取 `data_sample/Mk01.fjs` | `.fjs` 数据能变成 `problem` 结构，并且不生成 `data.mat` |
| `test_read_machine_data.m` | 读取 `data_sample/机器数据.xlsx` | 机器距离、机器能耗能读出来，并且不改项目根目录 |
| `test_read_agv_data.m` | 读取 `data_sample/AGV数据.xlsx` | AGV 数量、速度、能耗能读出来，并且不改项目根目录 |
| `test_small_nsga2_config.m` | 检查 `configs/small_nsga2_config.m` | 配置文件能读，路径存在，关键参数合理 |
| `test_evaluate_chromosome.m` | 评价 1 条染色体 | `fitness/sorting` 最小评价链路能跑通 |
| `test_small_nsga2.m` | 跑小种群 NSGA-II 2 代 | 基础搜索闭环能跑通 |

你在 MATLAB 里可以这样跑：

```matlab
cd D:\CODEX\code_refactor_project
run('tests/test_read_fjsp.m')
run('tests/test_read_machine_data.m')
run('tests/test_read_agv_data.m')
run('tests/test_small_nsga2_config.m')
```

这些测试不是为了证明算法效果好，而是证明：

```text
数据读取这一步没有崩
读取函数没有乱生成文件
配置入口能打开
以后主程序可以逐步改成调用这些读取函数和配置入口
```

## 5. `data_sample/`：小样本数据区

这个文件夹放的是“轻量样本”，不是完整实验结果。它的价值是：不用一上来跑完整论文实验，也能检查某个模块是否能工作。

| 文件 | 现在是干什么的 | 以后怎么用 |
|---|---|---|
| `Mk01.fjs` | 一个小的标准 FJSP 算例 | 测试 `.fjs` 读取 |
| `机器数据.xlsx` | 机器距离、机器能耗样本 | 测试机器数据读取 |
| `AGV数据.xlsx` | AGV 数量、速度、能耗样本 | 测试 AGV 数据读取 |
| `工件数据.xlsx` | 工件相关 Excel 数据 | 后续如果继续封装 Excel 工件数据时再看 |
| `Parameter_ testing.xlsx` | 指标或参数测试数据 | 后续分析 HV、Spacing、IGD、C-metric 时再用 |
| `集成调度数据.zip` | 原始集成调度数据压缩包 | 数据备份，暂时不要作为默认读取入口 |

## 6. `configs/`：实验参数区

| 文件 | 现在是干什么的 | 以后怎么用 |
|---|---|---|
| `default.yaml` | 预留的默认配置文件 | 后续把种群规模、迭代次数、随机种子、路径等参数慢慢放进来 |

现在很多参数还在 `raw_code/dif_main.m` 和 `raw_code/same_main.m` 里写死。后续配置化时，这个文件夹会变重要。

## 7. `outputs/`：结果输出区

这个文件夹现在主要是预留位置。以后所有自动生成的结果都应该进这里，比如：

| 输出类型 | 以后建议放哪里 |
|---|---|
| 运行日志 | `outputs/logs/` |
| 结果表格 | `outputs/results/` |
| 甘特图 | `outputs/figures/` |
| 指标结果 | `outputs/metrics/` |
| 中间数据 | `outputs/cache/` |

核心原则：

```text
不要让主程序在项目根目录或 raw_code 里悄悄生成、覆盖结果文件
```

## 8. `docs/`：知识地图区

这里放的是你以后回头理解系统、复现系统、迁移到新论文时会反复看的内容。

| 文件 | 回答什么问题 |
|---|---|
| `00_system_overview/beginner_reading_guide.md` | 这套代码到底在做什么？ |
| `00_system_overview/system_layer_architecture.md` | 数据、编码、解码、评价、搜索五层怎么连起来？ |
| `00_system_overview/knowledge_map_workplan.md` | 当前知识地图做到哪了？哪些模块已有第一版？ |
| `00_system_overview/repository_file_guide.md` | 每个文件夹、每类文件是干什么的？ |
| `02_data_flow/data_layer_map.md` | 输入数据有哪些？数据怎么流进算法？ |
| `03_algorithm/search_layer_overview.md` | 算法怎么生成、更新、筛选方案？ |
| `04_decoding/decoding_layer_overview.md` | `sorting.m` 为什么是调度解码核心？ |
| `05_evaluation/evaluation_layer_overview.md` | `fitness.m` 怎么评价一个方案好不好？ |
| `06_experiments/experiment_flow.md` | `dif_main.m` 和 `same_main.m` 到底在跑什么？ |
| `07_reproduction/data_reproduction_risks.md` | 哪些地方会影响复现？ |
| `08_engineering/refactor_roadmap.md` | 后续怎么小步封装，遇到问题怎么办？ |

## 9. 现在你应该怎么用这个仓库

如果你现在只是想看懂项目：

```text
README.md
-> docs/00_system_overview/entrypoint_map.md
-> docs/00_system_overview/repository_file_guide.md
-> docs/00_system_overview/beginner_reading_guide.md
-> docs/00_system_overview/system_layer_architecture.md
```

如果你想跑小块检查：

```text
tests/test_read_fjsp.m
tests/test_read_machine_data.m
tests/test_read_agv_data.m
tests/test_small_nsga2_config.m
```

如果你想看原始论文实验：

```text
raw_code/dif_main.m
raw_code/same_main.m
```

如果你想继续封装：

```text
docs/08_engineering/refactor_roadmap.md
```

## 10. 当前最重要的边界

现在仓库里有两套东西：

```text
raw_code/ = 原始论文代码，保留原貌，不主动改
src/      = 新封装代码，一点点变干净
```

你不要把它们理解成重复劳动。更准确地说：

```text
raw_code 负责“原始可追溯”
src 负责“以后可复用”
tests 负责“拆出来之后能不能独立跑”
docs 负责“我到底理解到哪了”
```
## 11. 2026-05-24 更新：`src/encoding/` 编码层最新状态

当前编码层已经从原始主代码里拆出三个可复用入口：

| 文件 | 当前作用 | 使用边界 |
|---|---|---|
| `src/encoding/split_chromosome.m` | 拆分一条 `chrom`，得到 `OS / MS / AS / SS / extraColumns` | 只拆结构，不判断调度是否可行，不调用解码和评价 |
| `src/encoding/validate_chromosome.m` | 检查一条 `chrom` 的编码层合法性 | 检查长度、OS 次数、MS/AS/SS 范围，不生成种群，不跑算法 |
| `src/encoding/generate_initial_population.m` | 生成少量初始种群，并用 `validate_chromosome` 检查每条 `chrom` | 第一版内部调用原始 `raw_code/NSGA-II/init.m`，但不修改原始文件，不运行 NSGA-II |

这三个入口对应的编码层闭环是：

```text
sample 数据读取
-> generate_initial_population 生成初始 chrom 种群
-> split_chromosome 拆第一条 chrom
-> validate_chromosome 检查第一条 chrom 的编码合法性
```

当前编码层仍然不负责：

```text
不解码 schedule
不调用 sorting.m
不调用 fitness.m
不运行完整算法
不生成 outputs
不计算 makespan / energy
```

## 12. 2026-05-24 更新：编码层 smoke test

编码层最小闭环测试文件是：

```text
tests/test_encoding_layer.m
```

在 MATLAB 里运行：

```matlab
cd D:\CODEX\code_refactor_project
run('tests/test_encoding_layer.m')
```

当前已由用户在 MATLAB 中跑通，输出为：

```text
test_encoding_layer passed: popSize=4, chromosomeLength=275
```

这说明：

```text
data_sample/Mk01.fjs 可以读入 problem
data_sample 下的 AGV sample workbook 可以读入 agvData
编码层可以生成 4 条初始 chrom
第一条 chrom 可以被拆成 OS / MS / AS / SS
第一条 chrom 可以通过 validate_chromosome 编码合法性检查
```

`chromosomeLength=275` 表示当前 sample 的核心编码长度是 `5n`，所以：

```text
n = 55
```

这里的测试只是编码层 smoke test，不代表完整 NSGA-II 算法已经运行，也不代表解码层和评价层已经完成封装。
## 13. 2026-05-25 更新：`src/encoding/` 完整函数清单

前面的 2026-05-24 说明是早期状态。当前编码层已经继续推进，`generate_initial_population.m` 已经不再调用原始 `init.m`，`generate_offspring.m` 也已经不再调用原始 `variation.m`。

| 文件 | 当前作用 | 是否依赖 raw_code |
|---|---|---|
| `src/encoding/split_chromosome.m` | 拆分一条 `chrom` 为 `OS / MS / AS / SS / extraColumns` | 否 |
| `src/encoding/validate_chromosome.m` | 检查单条 `chrom` 的长度、OS 次数、MS/AS/SS 范围 | 否 |
| `src/encoding/validate_population.m` | 检查整个 population，统计合法/非法数量和非法行号 | 否 |
| `src/encoding/generate_initial_population.m` | 自主生成初始 population，并验证每条 `chrom` | 否 |
| `src/encoding/build_rs_upper_bounds.m` | 构造 `RS = [MS, AS, SS]` 的上界 `UP` | 否 |
| `src/encoding/crossover_os_ipox.m` | 执行 `OS` 的 IPOX 交叉 | 否 |
| `src/encoding/crossover_rs_mpx.m` | 执行 `RS` 的 MPX 交叉 | 否 |
| `src/encoding/mutate_os_swap.m` | 执行 `OS` 的交换变异 | 否 |
| `src/encoding/mutate_rs_resample.m` | 执行 `RS` 的多点重采样变异 | 否 |
| `src/encoding/generate_offspring.m` | 组合交叉/变异，生成 offspring，并验证合法性 | 否 |

编码层测试入口：

| 文件 | 作用 |
|---|---|
| `tests/test_encoding_layer.m` | 正常闭环：读 sample、生成 population、验证、生成 offspring、再次验证 |
| `tests/test_encoding_invalid_cases.m` | 异常测试：非法长度、OS/MS/AS/SS 错误、混合 population 统计 |

编码层 demo 入口：

```matlab
run('scripts/run_encoding_smoke.m')
```

这个入口只跑编码层，不调用 `sorting.m`、`fitness.m`、`NSGA2.m`，也不生成 `outputs`。
## 14. 2026-05-25 更新：解码层结构说明文档

当前新增解码层结构说明：

| 文件 | 当前作用 | 使用边界 |
|---|---|---|
| `docs/04_decoding/decoding_layer_structure_note.md` | 说明 `sorting.m` 如何把 `chrom = [OS, MS, AS, SS]` 解码成机器时间表、AGV 时间表和调度过程 | 这是结构说明文档，不是新代码；不运行 MATLAB，不生成 outputs |

这份文档说明：

```text
解码层是什么
sorting.m 的角色
chrom 到调度过程的转换链
OS / MS / AS / SS 在解码中的作用
解码层和编码层、评价层、搜索层的边界
当前仍未封装的部分
```

当前状态：

```text
解码层主流程已经完成结构拆解和文档化。
解码层代码封装尚未开始。
```

## 2026-05-25 更新：`src/decoding/` 解码层最新状态

当前解码层已经从“只理解 `sorting.m`”推进到“第一轮封装 + 测试”。

| 文件 | 当前作用 | 使用边界 |
|---|---|---|
| `src/decoding/decode_chromosome.m` | 解码一条 `chrom`，返回 `schedule/report` | 先检查编码合法性，再调用原始 `sorting.m`；不计算目标值 |
| `src/decoding/decode_population.m` | 解码一个 population，逐条调用 `decode_chromosome` | 统计 `successCount / failureCount / failedIndexes` |
| `tests/test_decoding_layer.m` | 解码层正常 smoke test | 验证合法 chrom 和小 population 能解码 |
| `tests/test_decoding_invalid_cases.m` | 解码层异常测试 | 验证非法 OS/MS/AS/SS、缺字段、空 population、非法 population |
| `tests/test_decoding_compare_sorting.m` | 原始行为对比测试 | 验证 `decode_chromosome` 和 `sorting.m` 的 5 个核心输出一致 |
| `docs/04_decoding/decoding_layer_structure_note.md` | 解码层结构与封装状态说明 | 记录 D1-D8 的理解、接口和边界 |

当前 `decode_chromosome` 输出的核心 schedule 字段是：

```text
schedule.machineTable
schedule.AGVTable
schedule.jobCompleteUnLoad
schedule.agvEGRecord
schedule.agvChargeNum
schedule.parts
schedule.operaNum
schedule.dim
```

当前边界：

```text
不生成 chrom
不做交叉变异
不计算 makespan
不计算 totalEnergy
不做非支配排序
不保存 outputs
```

## 2026-05-25 更新：评价层结构说明文档

当前新增评价层结构说明：

| 文件 | 当前作用 | 使用边界 |
|---|---|---|
| `docs/05_evaluation/evaluation_layer_structure_note.md` | 说明 `fitness.m` 如何初始化 `machineTable / AGVTable`、调用解码、计算 `makespan / totalEnergy` | 这是结构说明文档，不是新代码；不运行 MATLAB，不生成 outputs |

这份文档说明：

```text
评价层是什么
fitness.m 的输入输出
fitness.m 内部步骤
machineTable / AGVTable 初始结构
makespan 如何计算
机器能耗如何计算
AGV 能耗如何计算
评价层和解码层的边界
后续建议封装函数
```

当前状态：

```text
评价层结构已经完成 V1/V2 理解和文档化。
评价层代码封装尚未开始。
```

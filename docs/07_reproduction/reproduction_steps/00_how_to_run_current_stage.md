# 现在这套封装怎么跑

这个文档只解决一个问题：

```text
我现在打开 MATLAB，应该怎么一步步跑已经封装好的东西？
```

如果你只想复制命令，不想看解释，先看：

```text
docs/07_reproduction/reproduction_steps/matlab_command_cheatsheet.md
```

## 当前最新状态

截至当前进度，已经跑通：

```text
single evaluation
small NSGA-II
medium NSGA-II
formal NSGA-II
```

当前还没有实现：

```text
scripts/run_metrics.m
完整 HV / IGD / Spacing / C-metric 计算
多算法对比入口
图表生成入口
```

现在最常用的运行命令是：

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_formal_nsga2_config.m')
run('scripts/run_formal_nsga2.m')
```

formal 已跑通记录：

```text
pop = 30
max_gen = 10
paretoSolutionCount = 2
bestMakespan = 134.446667
bestTotalEnergy = 1770.988667
outputDir = D:\CODEX\code_refactor_project\outputs\formal_nsga2\20260520_224558
```

后续主线已经从“能跑 formal”推进到：

```text
指标入口：run_metrics.m
```

先说清楚：现在还没有完整跑论文实验。

当前已经做到的是：

```text
第 1 段：能单独读取数据
第 2 段：已经知道 fitness/sorting 需要什么输入
第 3 段：已经封装了 evaluate_chromosome 评价入口
第 4 段：已经有 run_single_evaluation.m 串联脚本
第 5 段：小种群 NSGA-II 短迭代已跑通并测试
第 6 段：small_nsga2 已有配置入口
第 7 段：数据与配置扩展检查已跑通
第 8 段：配置入口测试已由你本地跑通
第 9 段：medium_nsga2 已由你本地跑通
第 10 段：运行入口已经整理成检查/运行/未来正式实验三层
第 14-15 段：formal 入口和 formal 配置已经整理
第 17 段：指标入口已经完成设计
```

还没有做到：

```text
完整 dif_main / same_main 复现
完整评价指标汇总
批量对比实验
完整图表生成
```

所以你现在能跑的，分两类。

## 1. 先跑已经有测试的部分

这部分最稳，建议你先跑。

在 MATLAB 里输入：

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_read_fjsp.m')
run('tests/test_read_machine_data.m')
run('tests/test_read_agv_data.m')
run('tests/test_small_nsga2_config.m')
```

前面三条是在检查：

```text
.fjs 能不能读
机器 Excel 能不能读
AGV Excel 能不能读
读取时有没有乱生成文件
```

`test_small_nsga2_config.m` 是第 8 步新增的配置入口测试，用来检查：

```text
配置文件能不能读
配置里的数据路径是否存在
pop / max_gen / seed 等参数是否合理
```

如果这些测试过了，说明：

```text
数据入口和配置入口基本没问题。
```

如果这里就报错，先不要看算法，先查：

- 当前 MATLAB 目录是不是 `D:\CODEX\code_refactor_project`
- `data_sample/` 里的样本文件还在不在
- Excel 文件名或 sheet 名有没有被改
- MATLAB 能不能正常读 Excel

## 2. 跑当前串联脚本

如果你想看“这些小块怎么串起来”，跑：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_single_evaluation.m')
```

这个脚本会做：

```text
读 .fjs
读机器 Excel
读 AGV Excel
生成 1 条 chrom
调用 evaluate_chromosome
输出 makespan 和 totalEnergy
保存结果到 outputs/
```

更具体地说，它的输入和输出是：

| 类型 | 内容 |
|---|---|
| 输入数据 | `data_sample/Mk01.fjs`、`data_sample/机器数据.xlsx`、`data_sample/AGV数据.xlsx` |
| 中间方案 | 原始 `init.m` 随机生成 1 条 `chrom` |
| 评价入口 | `evaluate_chromosome.m` |
| 原始核心 | `raw_code/NSGA-II/fitness.m` 和 `sorting.m` |
| 输出结果 | `makespan`、`totalEnergy`、`summary.txt`、`single_evaluation_result.mat` |

正常情况下，你会看到：

```text
single evaluation finished.
makespan: ...
totalEnergy: ...
outputDir: ...
```

输出会放到：

```text
outputs/single_evaluation/时间戳/
```

你这次已经跑通了一次，命令行结果是：

```text
single evaluation finished.
makespan: 175.016667
totalEnergy: 2147.655667
outputDir: D:\CODEX\code_refactor_project\outputs\single_evaluation\20260519_205602
```

这个结果表示：

```text
1 条随机染色体已经成功被解码和评价。
```

它不是完整论文实验结果，只是当前最小链路的跑通证明。

这个脚本不是完整论文实验。

它只是当前阶段的“最小串联入口”。

## 3. evaluate_chromosome 现在怎么理解

`evaluate_chromosome.m` 现在已经有了，但它还不是一个可以直接“按一下就跑”的完整实验脚本。

它更像一个零件：

```text
给它一条 chrom
给它数据 problem / machineData / agvData
给它参数 config
它帮你调用原始 fitness.m
然后返回 makespan 和 energy
```

也就是说，它的用途是：

```text
以后评价一条调度方案时，不用手动拼 fitness.m 那一长串参数。
```

但是它还缺一个东西：

```text
一条合法 chrom 从哪里来。
```

`chrom` 可以以后由 `init.m` 生成，也可以测试里临时生成。

所以当前阶段不要把 `evaluate_chromosome.m` 理解成“完整运行入口”。

更准确地说：

```text
它是后面 test_evaluate_chromosome.m 要调用的核心函数。
```

现在如果你不想手动准备这些变量，就直接跑：

```matlab
run('scripts/run_single_evaluation.m')
```

因为这个脚本已经帮你把这些步骤串起来了。

## 4. 如果你想手动试 evaluate_chromosome，需要准备什么

这一段是“手动试跑思路”，不是当前最推荐的入口。

你需要准备五样东西：

```text
chrom
problem
machineData
agvData
config
```

其中：

```matlab
problem = read_fjsp(...);
machineData = read_machine_data(...);
agvData = read_agv_data(...);
```

这些已经有函数了。

`config` 目前需要你手动写：

```matlab
config.AGVEG_MAX = 100;
config.AGVEG_MIN = 某个充电阈值;
config.eChargeSpeed = 20;
```

`chrom` 目前还没有新封装入口。

如果临时用原始 `init.m`，你还要加路径：

```matlab
projectRoot = 'D:\CODEX\code_refactor_project';

addpath(fullfile(projectRoot, 'src', 'data'))
addpath(fullfile(projectRoot, 'src', 'evaluation'))
addpath(fullfile(projectRoot, 'raw_code', 'NSGA-II'))
```

注意：

```text
raw_code 里有多个 fitness.m / sorting.m / init.m。
你 addpath 哪个算法目录，就会调用哪个算法目录里的函数。
```

当前建议先用：

```text
raw_code/NSGA-II
```

因为它是基础链路，比改进算法更适合做最小试跑。

## 5. 为什么你现在会觉得“拆太碎”

你这个感觉是对的。

因为现在仓库里有两种文档：

```text
拆解记录：解释我拆了什么、为什么这样拆
运行教程：告诉你打开 MATLAB 具体怎么跑
```

之前多是“拆解记录”，所以你会觉得：

```text
我知道你封装了，但我还是不知道我该怎么跑。
```

以后复现步骤文件夹会按这个规则维护：

```text
00_how_to_run_current_stage.md
    永远写“当前能怎么跑”

01/02/03...
    写每一步拆解、封装、测试的来龙去脉
```

你以后不知道怎么跑时，先看：

```text
docs/07_reproduction/reproduction_steps/00_how_to_run_current_stage.md
```

不要先看第 2 步、第 3 步那些拆解文。

## 6. 当前最推荐你跑什么

现在建议你按这个顺序跑。

第一步，先跑三个读取测试：

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_read_fjsp.m')
run('tests/test_read_machine_data.m')
run('tests/test_read_agv_data.m')
run('tests/test_small_nsga2_config.m')
```

如果这几条正常，说明数据入口和配置入口都能打开。

第二步，再跑串联脚本：

```matlab
run('scripts/run_single_evaluation.m')
```

如果这个也正常，说明：

```text
当前最小链路已经能从数据走到单条方案评价。
```

下一步才适合写：

```text
scripts/run_small_nsga2.m
```

现在这个脚本已经新增。

第三步，跑小种群短迭代：

```matlab
run('scripts/run_small_nsga2.m')
```

这个脚本会用：

```text
pop = 10
max_gen = 2
raw_code/NSGA-II
```

这些参数现在来自：

```text
configs/small_nsga2_config.m
```

以后换数据或改参数，优先改这个配置文件，而不是改运行脚本。

跑通后，说明基础 NSGA-II 的小型搜索闭环能工作。

你已经本地跑通一次，摘要是：

```text
paretoSolutionCount: 3
bestMakespan: 155.886667
bestTotalEnergy: 1890.048000
outputDir: D:\CODEX\code_refactor_project\outputs\small_nsga2\20260519_222017
```

配置化以后，你又跑通了一次，摘要是：

```text
pop: 10, max_gen: 2
paretoSolutionCount: 3
bestMakespan: 155.886667
bestTotalEnergy: 1890.048000
outputDir: D:\CODEX\code_refactor_project\outputs\small_nsga2\20260520_112624
```

你又重复运行了一次配置化小种群脚本，结果仍然稳定：

```text
RUNNING --------> NSGA-II <-------- RUNNING
工件数：10 机器数 6 AGV数 3
GEN: 1  MIN Cmax: 155.9  MIN Energy:1890.05
GEN: 2  MIN Cmax: 155.9  MIN Energy:1890.05
运行时间：0.21005
small NSGA-II finished.
pop: 10, max_gen: 2
paretoSolutionCount: 3
bestMakespan: 155.886667
bestTotalEnergy: 1890.048000
outputDir: D:\CODEX\code_refactor_project\outputs\small_nsga2\20260520_115204
```

当前最远进度已经从“单条染色体评价”推进到：

```text
配置化小种群 NSGA-II 2 代短迭代。
```

这可以看作第一轮最小复现链路已经跑通。

注意，这里的“跑通”指的是：

```text
数据 -> 配置 -> 小规模搜索 -> 目标值摘要 -> outputs
```

不是指完整论文实验已经复现。

完整评价指标、批量对比实验、图表生成，可以等到后面规模和数据流程更稳定以后再整理。

现在暂时不需要为小规模测试生成图片。小规模测试的作用是检查链路是否活着，不是展示最终实验效果。

第四步，如果你想做轻微放大检查，跑 medium 脚本：

```matlab
run('scripts/run_medium_nsga2.m')
```

这个脚本会用：

```text
pop = 20
max_gen = 5
```

这些参数来自：

```text
configs/medium_nsga2_config.m
```

输出会放到：

```text
outputs/medium_nsga2/时间戳/
```

你已经跑通一次，摘要是：

```text
pop: 20, max_gen: 5
paretoSolutionCount: 4
bestMakespan: 135.743333
bestTotalEnergy: 1824.221333
outputDir: D:\CODEX\code_refactor_project\outputs\medium_nsga2\20260520_125615
```

第五步，如果你想跑 formal 第一版，跑：

```matlab
run('scripts/run_formal_nsga2.m')
```

这个脚本会用：

```text
pop = 30
max_gen = 10
```

这些参数来自：

```text
configs/formal_nsga2_config.m
```

输出会放到：

```text
outputs/formal_nsga2/时间戳/
```

你已经跑通一次，摘要是：

```text
paretoSolutionCount: 2
bestMakespan: 134.446667
bestTotalEnergy: 1770.988667
outputDir: D:\CODEX\code_refactor_project\outputs\formal_nsga2\20260520_224558
```

## 7. 以后换数据或改参数看哪里

当前入口是：

```text
configs/small_nsga2_config.m
```

它控制：

```text
使用哪个 .fjs
使用哪个机器 Excel
使用哪个 AGV Excel
使用哪个算法目录
pop / max_gen / p_cross / p_mutation
随机种子
输出目录
```

所以以后你想再跑，不要先改 `src/`，也不要先改 `raw_code/`。

优先顺序是：

```text
1. 把新数据放到 data_sample/ 或后续 data_raw/
2. 改 configs/small_nsga2_config.m
3. 运行 scripts/run_small_nsga2.m
4. 看 outputs/
```

## 8. 下一阶段先做什么

第一轮已经跑通后，下一阶段不建议直接冲完整论文实验。

更稳的顺序是先做：

```text
第 7 步：数据与配置扩展准备
```

这一阶段要解决的是：

```text
以后换一个算例、换一组机器/AGV 数据、放大 pop 和 max_gen 时，应该改哪里、怎么检查、结果放哪里。
```

也就是说，先把“怎么安全扩大规模”讲清楚，再去做完整评价层和图表。

## 9. 最后复现时要不要跑所有小配置

不用每次都从头跑所有小配置。

更实用的做法是：

| 场景 | 建议跑什么 |
|---|---|
| 刚换电脑、刚拉仓库 | 读取测试 + 配置测试 |
| 刚换数据 | 读取测试 + 配置测试 + 小种群测试 |
| 快速确认没坏 | `scripts/run_small_nsga2.m` |
| 想轻微放大看看 | `scripts/run_medium_nsga2.m` |
| 想跑 formal 第一版 | `scripts/run_formal_nsga2.m` |
| 想算指标 | 后续实现 `scripts/run_metrics.m` |

你以后找真正要用的入口，先看：

```text
README.md
-> 项目入口地图
-> 现在这套封装怎么跑
```

## 10. 当前入口分层

以后复现先按三层理解：

| 层级 | 作用 | 入口 |
|---|---|---|
| 检查入口 | 判断环境、数据、配置有没有坏 | `tests/` |
| 运行入口 | 跑当前已封装的 single / small / medium / formal | `scripts/` |
| 指标入口 | 读取 formal 输出并计算指标 | 后续实现 `scripts/run_metrics.m` |

最常用的默认顺序是：

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_small_nsga2_config.m')
run('scripts/run_small_nsga2.m')
```

如果你想轻微放大，再跑：

```matlab
run('scripts/run_medium_nsga2.m')
```

如果你想跑 formal 第一版：

```matlab
run('scripts/run_formal_nsga2.m')
```

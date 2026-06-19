# 项目入口地图：我想做一件事时该打开哪里

这个文档只回答一个问题：

```text
我回来找入口时，应该打开哪个文件？
```

它不是算法原理，也不是逐行代码说明。

## 1. 最常用入口

| 我想做什么 | 打开哪里 | 这是干什么的 |
|---|---|---|
| 看当前做到哪一步 | `docs/00_system_overview/knowledge_map_workplan.md` | 总进度台账 |
| 直接复制 MATLAB 命令 | `docs/07_reproduction/reproduction_steps/matlab_command_cheatsheet.md` | 命令清单 |
| 看 MATLAB 现在怎么跑 | `docs/07_reproduction/reproduction_steps/00_how_to_run_current_stage.md` | 当前运行说明 |
| 改快速检查运行的数据和参数 | `configs/small_nsga2_config.m` | small 配置入口 |
| 改轻微放大运行的数据和参数 | `configs/medium_nsga2_config.m` | medium 配置入口 |
| 看未来正式运行配置 | `configs/formal_nsga2_config.m` | formal 配置入口，由 formal 运行脚本读取 |
| 跑一次小种群 NSGA-II | `scripts/run_small_nsga2.m` | 配置化运行脚本 |
| 跑一次轻微放大 NSGA-II | `scripts/run_medium_nsga2.m` | medium 运行脚本 |
| 跑一次 formal NSGA-II | `scripts/run_formal_nsga2.m` | formal 运行脚本，当前不含指标计算 |
| 读取 formal 结果并生成最小指标摘要 | `scripts/run_metrics.m` | metrics 最小读取脚本 |
| 看未来指标入口怎么设计 | `docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md` | run_metrics.m 应该读取、计算、输出什么 |
| 理解编码-解码怎么迁移到新课题 | `docs/04_decoding/encoding_decoding_application_overview.md` | 从调度对象到编码、解码、评价、搜索的应用框架 |
| 看 `chrom` 真实结构和编码层封装依据 | `docs/04_decoding/encoding_layer_structure_note.md` | 说明 `chrom = [OS, MS, AS, SS]` 怎么生成、交叉、变异 |
| 跑一次单条染色体评价 | `scripts/run_single_evaluation.m` | 单条方案评价脚本 |
| 看复现入口怎么分层 | `docs/07_reproduction/reproduction_steps/10_reproduction_entry_layers.md` | 检查/运行/未来正式实验总入口 |
| 看输出结果放哪里 | `docs/07_reproduction/reproduction_steps/12_outputs_structure.md` | outputs 输出规则 |
| 看每次运行要记录什么 | `docs/07_reproduction/reproduction_steps/13_run_log_and_parameter_record.md` | 运行日志和参数记录规则 |
| 看未来正式实验入口怎么设计 | `docs/07_reproduction/reproduction_steps/14_formal_experiment_entry_design.md` | small / medium / formal / metrics 的入口关系 |
| 看 formal 配置应该有哪些字段 | `docs/07_reproduction/reproduction_steps/15_formal_config_design.md` | 正式实验配置字段设计 |
| 看每个文件夹是干什么的 | `docs/00_system_overview/repository_file_guide.md` | 文件导览 |

## 2. 配置入口在哪里

当前配置入口：

```text
configs/default.yaml
configs/small_nsga2_config.m
configs/medium_nsga2_config.m
configs/formal_nsga2_config.m
```

`default.yaml` 是早期/通用配置占位，当前 MATLAB 主运行入口主要使用 `.m` 配置文件。

`small_nsga2_config.m` 是快速检查档：

```text
pop=10, max_gen=2
```

`medium_nsga2_config.m` 是轻微放大档：

```text
pop=20, max_gen=5
```

`formal_nsga2_config.m` 是未来正式运行配置：

```text
pop=30, max_gen=10
```

它是 formal 配置入口，对应的 formal 运行脚本已经有了。

配置入口和运行入口不要混：

| 类型 | 作用 | 例子 |
|---|---|---|
| 配置入口 | 告诉程序“怎么跑”：数据路径、seed、pop、max_gen、输出目录、能耗参数等 | `configs/formal_nsga2_config.m` |
| 运行入口 | 真正开始执行流程：读取配置、读数据、生成染色体、跑算法、保存结果 | `scripts/run_formal_nsga2.m` |

一句话：

```text
配置入口负责改参数。
运行入口负责开始跑。
```

当前 formal 运行入口是：

```text
scripts/run_formal_nsga2.m
```

你在 MATLAB 或编辑器里打开配置文件，就能看到当前运行用的：

```text
.fjs 路径
机器 Excel 路径
AGV Excel 路径
算法目录
输出目录
随机 seed
pop
max_gen
p_cross
p_mutation
AGV 电量和充电参数
```

以后想换数据或改参数，优先打开它。

不要优先改：

```text
scripts/run_small_nsga2.m
raw_code/
src/
```

## 3. 运行入口在哪里

当前运行入口都在：

```text
scripts/
```

| 运行入口 | MATLAB 命令 | 作用 | 输出位置 |
|---|---|---|---|
| `scripts/run_single_evaluation.m` | `run('scripts/run_single_evaluation.m')` | 读取 sample 数据，生成 1 条染色体并做单条评价 | `outputs/single_evaluation/时间戳/` |
| `scripts/run_small_nsga2.m` | `run('scripts/run_small_nsga2.m')` | 快速检查档，跑 small NSGA-II | `outputs/small_nsga2/时间戳/` |
| `scripts/run_medium_nsga2.m` | `run('scripts/run_medium_nsga2.m')` | 轻微放大档，跑 medium NSGA-II | `outputs/medium_nsga2/时间戳/` |
| `scripts/run_formal_nsga2.m` | `run('scripts/run_formal_nsga2.m')` | formal NSGA-II 第一版运行入口 | `outputs/formal_nsga2/时间戳/` |
| `scripts/run_metrics.m` | `run('scripts/run_metrics.m')` | 读取最新 formal 结果并生成最小 metrics 摘要 | `outputs/formal_nsga2/时间戳/metrics/` |

当前最推荐的快速运行入口是：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_small_nsga2.m')
```

它会做：

```text
读取 configs/small_nsga2_config.m
-> 读取 .fjs / 机器 Excel / AGV Excel
-> 调用原始 NSGA-II
-> 输出 makespan、totalEnergy、Pareto 摘要
-> 保存到 outputs/small_nsga2/时间戳
```

轻微放大运行入口是：

```text
scripts/run_medium_nsga2.m
```

在 MATLAB 里运行：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_medium_nsga2.m')
```

它会读取：

```text
configs/medium_nsga2_config.m
```

并保存到：

```text
outputs/medium_nsga2/时间戳
```

formal 运行入口是：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_formal_nsga2.m')
```

metrics 最小摘要入口是：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_metrics.m')
```

注意：`run_metrics.m` 不重新跑算法，只读取已经存在的 formal 输出结果。

## 4. 测试入口在哪里

这些是“小检查”，不是完整论文实验。

| 检查什么 | 运行什么 |
|---|---|
| `.fjs` 能不能读 | `run('tests/test_read_fjsp.m')` |
| 机器 Excel 能不能读 | `run('tests/test_read_machine_data.m')` |
| AGV Excel 能不能读 | `run('tests/test_read_agv_data.m')` |
| 1 条染色体能不能评价 | `run('tests/test_evaluate_chromosome.m')` |
| 小种群 NSGA-II 能不能跑 2 代 | `run('tests/test_small_nsga2.m')` |
| 配置入口是否完整有效 | `run('tests/test_small_nsga2_config.m')` |
| formal 配置是否完整有效 | `run('tests/test_formal_nsga2_config.m')` |

推荐顺序：

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_read_fjsp.m')
run('tests/test_read_machine_data.m')
run('tests/test_read_agv_data.m')
run('tests/test_evaluate_chromosome.m')
run('tests/test_small_nsga2_config.m')
run('tests/test_small_nsga2.m')
```

## 5. 新封装函数入口在哪里

这些函数不是直接点运行的主入口，它们是脚本和测试会调用的“零件”。

| 函数 | 作用 |
|---|---|
| `src/data/read_fjsp.m` | 读取 `.fjs`，返回 `problem` |
| `src/data/read_machine_data.m` | 读取机器距离和机器能耗 |
| `src/data/read_agv_data.m` | 读取 AGV 数量、速度和能耗 |
| `src/encoding/split_chromosome.m` | 把 1 条 `chrom` 拆成 `OS / MS / AS / SS` |
| `src/encoding/validate_chromosome.m` | 检查 1 条 `chrom` 的编码长度和取值范围是否合法 |
| `src/evaluation/evaluate_chromosome.m` | 给 1 条染色体算 makespan 和 totalEnergy |

你平时不用直接点它们运行。

它们的作用是让上层脚本能更清楚地串起来：

```text
读数据 -> 生成染色体 -> 评价 -> 输出
```

## 6. 原始代码入口在哪里

原始代码都在：

```text
raw_code/
```

当前原则是：

```text
只读，不主动改。
```

常见入口：

| 文件 | 作用 |
|---|---|
| `raw_code/dif_main.m` | 原始对比实验主脚本 |
| `raw_code/same_main.m` | 原始消融或同类实验主脚本 |
| `raw_code/NSGA-II/NSGA2.m` | 基础 NSGA-II 主函数 |
| `raw_code/NSGA-II/init.m` | 生成初始种群 |
| `raw_code/NSGA-II/variation.m` | 对染色体进行交叉和变异，属于编码层/搜索层交界 |
| `raw_code/NSGA-II/non_domination.m` | 非支配排序，属于搜索层 |
| `raw_code/NSGA-II/replace_chrom.m` | 根据排序结果保留下一代种群，属于搜索层 |
| `raw_code/NSGA-II/tournament_selection.m` | 锦标赛选择父代，属于搜索层 |
| `raw_code/NSGA-II/sorting.m` | 把染色体解码成调度过程 |
| `raw_code/NSGA-II/fitness.m` | 计算目标值 |

现在我们的新脚本主要是调用：

```text
raw_code/NSGA-II
```

还没有扩展到完整对比实验。

## 7. 输出去哪里找

当前所有新脚本输出都应该进入：

```text
outputs/
```

小种群运行输出在：

```text
outputs/small_nsga2/时间戳/
```

单条评价输出在：

```text
outputs/single_evaluation/时间戳/
```

medium 小幅放大输出在：

```text
outputs/medium_nsga2/时间戳/
```

formal 运行输出在：

```text
outputs/formal_nsga2/时间戳/
```

metrics 最小摘要输出在：

```text
outputs/formal_nsga2/时间戳/metrics/
```

`outputs/` 是运行产物，不提交到 GitHub。

更完整的输出规则看：

```text
docs/07_reproduction/reproduction_steps/12_outputs_structure.md
```

每次运行应该记录哪些参数、日志和结果摘要，看：

```text
docs/07_reproduction/reproduction_steps/13_run_log_and_parameter_record.md
```

## 8. 一句话记忆

```text
想改怎么跑 -> 打开 configs/
想真的跑 -> 打开 scripts/
想检查有没有坏 -> 打开 tests/
想看原论文代码 -> 打开 raw_code/
想看解释和路线 -> 打开 docs/
想找结果 -> 打开 outputs/
```

最后复现时不用每次跑所有小配置。小配置是体检工具；真正要跑哪个入口，取决于你这次是快速检查、轻微放大，还是未来的正式实验。

更完整的复现入口分层看：

```text
docs/07_reproduction/reproduction_steps/10_reproduction_entry_layers.md
```

未来正式实验入口和指标入口的设计看：

```text
docs/07_reproduction/reproduction_steps/14_formal_experiment_entry_design.md
```

未来 formal 配置字段设计看：

```text
docs/07_reproduction/reproduction_steps/15_formal_config_design.md
```

未来指标入口设计看：

```text
docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md
```

编码-解码应用理解看：

```text
docs/04_decoding/encoding_decoding_application_overview.md
```

编码层结构和后续封装依据看：

```text
docs/04_decoding/encoding_layer_structure_note.md
```

## 9. 当前入口完整性检查

截至当前阶段，入口地图已覆盖：

| 类别 | 当前覆盖 |
|---|---|
| 配置入口 | `configs/default.yaml`、`small_nsga2_config.m`、`medium_nsga2_config.m`、`formal_nsga2_config.m` |
| 运行脚本入口 | `run_single_evaluation.m`、`run_small_nsga2.m`、`run_medium_nsga2.m`、`run_formal_nsga2.m`、`run_metrics.m` |
| 测试入口 | `test_read_fjsp.m`、`test_read_machine_data.m`、`test_read_agv_data.m`、`test_evaluate_chromosome.m`、`test_small_nsga2.m`、`test_small_nsga2_config.m`、`test_formal_nsga2_config.m` |
| 新封装函数入口 | `read_fjsp.m`、`read_machine_data.m`、`read_agv_data.m`、`split_chromosome.m`、`validate_chromosome.m`、`evaluate_chromosome.m` |
| 原始主代码入口 | `dif_main.m`、`same_main.m`、`NSGA2.m`、`init.m`、`variation.m`、`sorting.m`、`fitness.m` |
| 搜索辅助入口 | `non_domination.m`、`replace_chrom.m`、`tournament_selection.m` |
| 关键文档入口 | README、知识地图工作表、入口地图、五层结构、编码层结构笔记、复现步骤、封装路线 |

后续每新增一个脚本、测试、封装函数或关键笔记，都要同步补到：

```text
README.md
docs/00_system_overview/entrypoint_map.md
```
## 10. 2026-05-24 更新：编码层 demo 入口

当前编码层已经有一个独立 demo 运行入口：

| 入口 | MATLAB 命令 | 作用 | 是否生成 outputs |
|---|---|---|---|
| `scripts/run_encoding_smoke.m` | `run('scripts/run_encoding_smoke.m')` | 读取 sample 数据，生成初始 population，验证 population，生成 offspring，再次验证 offspring | 否 |

它只验证编码层：

```text
read_fjsp / read_agv_data
-> generate_initial_population
-> validate_population
-> generate_offspring
-> validate_population
```

它不做：

```text
不运行 NSGA-II
不调用 sorting.m
不调用 fitness.m
不生成 outputs
不修改 raw_code
```

在 MATLAB 中运行：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_encoding_smoke.m')
```

正式 NSGA-II 接入方案见：

```text
docs/03_algorithm/nsga2_encoding_integration_plan.md
```
## 11. 2026-05-25 更新：编码层测试入口

编码层现在有三个常用入口：

| 入口 | MATLAB 命令 | 用途 |
|---|---|---|
| `tests/test_encoding_layer.m` | `run('tests/test_encoding_layer.m')` | 编码层正常闭环测试：生成 population、验证、生成 offspring、再次验证 |
| `tests/test_encoding_invalid_cases.m` | `run('tests/test_encoding_invalid_cases.m')` | 编码层异常测试：确认非法 chrom / population 能被识别 |
| `scripts/run_encoding_smoke.m` | `run('scripts/run_encoding_smoke.m')` | 编码层 demo 入口，适合手动复现编码层流程 |

推荐检查顺序：

```matlab
cd D:\CODEX\code_refactor_project
run('tests/test_encoding_layer.m')
run('tests/test_encoding_invalid_cases.m')
run('scripts/run_encoding_smoke.m')
```

这三个入口都不运行完整 NSGA-II，不调用 `sorting.m` / `fitness.m`，不生成 `outputs`。

## 12. 2026-05-25 更新：新编码层接入搜索层入口

搜索层现在新增一个不改 `raw_code` 的 refactored 小规模入口：

| 入口 | MATLAB 命令 | 用途 | 是否生成 outputs |
|---|---|---|---|
| `scripts/run_small_nsga2_refactored.m` | `run('scripts/run_small_nsga2_refactored.m')` | 小规模 NSGA-II，初始 population 和 offspring 都使用新编码层 | 是 |
| `tests/test_small_nsga2_refactored_encoding.m` | `run('tests/test_small_nsga2_refactored_encoding.m')` | 搜索接入测试，只验证结果结构，不写 outputs | 否 |

`run_small_nsga2_refactored.m` 会输出到：

```text
outputs/small_nsga2_refactored/时间戳/
```

它不修改 `raw_code`。它仍然会通过搜索流程调用 `fitness.m` 和 `sorting.m`，因为这是完整小规模 NSGA-II 必需的评价链路。

### 运行记录

`scripts/run_small_nsga2_refactored.m` 已由用户在 MATLAB 中跑通：

```text
pop: 10
max_gen: 2
paretoSolutionCount: 1
bestMakespan: 138.456667
bestTotalEnergy: 1936.654667
outputDir: outputs/small_nsga2_refactored/20260525_192659
```

如果只是检查结构、不想生成 outputs，优先运行：

```matlab
run('tests/test_small_nsga2_refactored_encoding.m')
```
## 13. 2026-05-25 更新：解码层文档入口

当前解码层结构说明入口是：

| 我想看什么 | 打开哪里 | 说明 |
|---|---|---|
| 看 `sorting.m` 如何把 `chrom` 变成调度过程 | `docs/04_decoding/decoding_layer_structure_note.md` | 解码层结构说明，解释机器时间表、AGV 时间表、OS/MS/AS/SS 在解码中的作用 |

这不是运行入口，而是理解入口。

当前没有新增解码层测试入口，也没有新增 `src/decoding/` 代码。后续进入 D3/D4 后，才会规划或建立：

```text
src/decoding/decode_chromosome.m
tests/test_decoding_layer.m
```

## 2026-05-25 更新：解码层函数与测试入口

当前解码层已经有第一轮封装入口：

| 类型 | 入口 | 作用 |
|---|---|---|
| 结构说明 | `docs/04_decoding/decoding_layer_structure_note.md` | 解释 `sorting.m`、解码层边界、D1-D8 状态 |
| 单条 chrom 解码函数 | `src/decoding/decode_chromosome.m` | 输入一条 `chrom`，返回 `schedule/report` |
| population 解码函数 | `src/decoding/decode_population.m` | 逐条调用 `decode_chromosome`，统计成功/失败 |
| 正常 smoke test | `tests/test_decoding_layer.m` | 验证合法 chrom 和小 population 能解码 |
| 异常测试 | `tests/test_decoding_invalid_cases.m` | 验证非法 chrom、缺字段、空 population、非法 population 能被识别 |
| 原始行为对比 | `tests/test_decoding_compare_sorting.m` | 对比 `decode_chromosome` 和原始 `sorting.m` 的 5 个核心输出字段 |

推荐检查顺序：

```matlab
cd D:\CODEX\code_refactor_project
run('tests/test_decoding_layer.m')
run('tests/test_decoding_invalid_cases.m')
run('tests/test_decoding_compare_sorting.m')
```

已由用户跑通的结果：

```text
test_decoding_layer passed: population=3, operations=55, AGVNum=3
test_decoding_invalid_cases passed
test_decoding_compare_sorting passed: fields matched=5
```

这些入口不计算 `makespan / totalEnergy`，也不是完整 NSGA-II 运行入口。它们只验证解码层。

## 2026-05-25 更新：评价层文档入口

当前评价层结构说明入口是：

| 我想看什么 | 打开哪里 | 说明 |
|---|---|---|
| 看 `fitness.m` 如何初始化时间表、调用解码、计算目标值 | `docs/05_evaluation/evaluation_layer_structure_note.md` | 评价层结构说明，解释 makespan、机器能耗、AGV 能耗和解码层边界 |

这不是运行入口，而是理解入口。当前评价层代码封装尚未开始，后续会从 `create_initial_schedule_tables` 和 `evaluate_schedule` 开始。
## 2026-05-29 更新：independent 主线入口

第 21-25 步完成后，项目新增了一条不依赖 raw `sorting.m` / `fitness.m` / `NSGA2.m` 的 independent 主线。

### independent 配置入口

| 我想改什么 | 打开哪里 | 说明 |
|---|---|---|
| independent small 参数 | `configs/independent_small_config.m` | `pop=10, max_gen=2, seed=42` |
| independent medium 参数 | `configs/independent_medium_config.m` | `pop=20, max_gen=5, seed=42` |
| independent formal 参数 | `configs/independent_formal_config.m` | `pop=30, max_gen=10, seedList=[42,43,44,45,46]` |

### independent 运行入口

| 我想做什么 | MATLAB 命令 | 输出位置 |
|---|---|---|
| 跑 independent small | `run('scripts/run_independent_small_nsga2.m')` | `outputs/independent_small_nsga2/<timestamp>/` |
| 跑 independent medium | `run('scripts/run_independent_medium_nsga2.m')` | `outputs/independent_medium_nsga2/<timestamp>/` |
| 只做 independent formal preflight | `run('scripts/run_independent_formal_nsga2.m')` | 默认不生成 formal 输出 |
| 明确确认后跑 independent formal | `RUN_INDEPENDENT_FORMAL_CONFIRMED = true; run('scripts/run_independent_formal_nsga2.m')` | `outputs/independent_formal_nsga2/<timestamp>/` |

### independent 测试入口

| 检查什么 | MATLAB 命令 |
|---|---|
| independent config 是否完整 | `run('tests/test_independent_experiment_configs.m')` |
| independent formal 是否有保护门 | `run('tests/test_independent_formal_preflight.m')` |
| independent decoding 与 raw sorting 对照 | `run('tests/test_independent_decoding_compare_raw.m')` |
| independent evaluation 与 raw wrapper 对照 | `run('tests/test_independent_evaluation_compare_raw.m')` |
| independent small search 与 raw/refactored small 结构对照 | `run('tests/test_independent_search_compare_raw.m')` |

### independent 说明文档

| 想看什么 | 打开哪里 |
|---|---|
| independent decoding | `docs/04_decoding/independent_decoding_guide.md` |
| independent evaluation | `docs/05_evaluation/independent_evaluation_guide.md` |
| independent search | `docs/03_algorithm/independent_nsga2_search_guide.md` |
| raw 对照总验收 | `docs/07_reproduction/independent_raw_compare_acceptance.md` |
| independent 实验入口 | `docs/06_experiments/independent_experiment_entry_guide.md` |
| 第 21-25 步复现索引 | `docs/07_reproduction/reproduction_steps/README.md` |

# 新项目套用与复现入口顺序

本节用于回答一个实际问题：

```text
以后遇到一个新的论文选题或新的调度项目时，
我应该怎么把当前框架套上去？
先跑什么？
再改什么？
哪些地方要注意？
什么时候才能跑 medium / formal？
```

当前项目已经有独立链路：

```text
independent decoding
independent evaluation
independent NSGA-II search
independent small / medium / formal 入口
metrics / visualization 入口
baseline 对比模板
多 seed 汇总模板
新项目迁移手册
```

所以它可以作为新项目骨架使用。但这不等于“复制过去直接 formal”。正确做法是按层迁移、按层测试。

## 1. 先判断新项目属于哪种情况

### 情况 A：问题结构接近

例如：

```text
仍然是 FJSP + AGV
染色体结构基本不变
目标仍然是 makespan / energy
只是换数据、换参数、换论文场景
```

这种情况最容易套。优先改：

```text
data_sample/
configs/<project_name>_small_config.m
configs/<project_name>_medium_config.m
configs/<project_name>_formal_config.m
scripts/run_<project_name>_small.m
scripts/run_<project_name>_medium.m
scripts/run_<project_name>_formal.m
```

然后按顺序跑：

```matlab
run('tests/test_<project_name>_config.m')
run('scripts/run_<project_name>_small.m')
run('scripts/run_<project_name>_medium.m')
```

small 和 medium 都稳定后，才考虑 formal。

### 情况 B：新增目标函数

例如：

```text
carbonEmission
totalCost
tardiness
robustness
chargingPenalty
```

优先改：

```text
src/evaluation/
configs/
src/metrics/
src/visualization/
tests/test_evaluation_*.m
```

推荐顺序：

```text
1. 先写 compute_<objective_name>.m
2. 写 toy test
3. 更新 objectives 构建逻辑
4. 更新 config.objectives
5. 跑 evaluation tests
6. 跑 independent search small loop
7. 再接 metrics / visualization
```

不要直接在 search 里临时拼目标函数。目标函数应该集中在 evaluation 层。

### 情况 C：调度规则变了

例如：

```text
AGV 充电规则变了
运输路径规则变了
机器约束变了
工序释放时间或 due date 变了
```

优先改：

```text
src/decoding/
src/evaluation/
tests/test_decoding_*.m
tests/test_evaluation_*.m
```

推荐顺序：

```text
1. 写清新规则
2. 修改 independent decoding
3. 用 toy chrom 测单条解码
4. 测 population 解码
5. 修改 evaluation 中相关目标或惩罚项
6. 跑 decoding / evaluation tests
7. 最后才跑 search small loop
```

### 情况 D：算法创新点变了

例如：

```text
自适应变异
局部搜索
VNS / SA / TS
Q-learning 算子选择
精英策略改进
```

优先改：

```text
src/search/
src/encoding/
configs/
tests/test_search_*.m
```

推荐顺序：

```text
1. 新策略默认关闭，先写 config 开关
2. 新增独立 helper，不直接改 formal 入口
3. 写 toy test
4. 跑 independent small loop
5. 跑 medium
6. 最后再做 formal 和 baseline 对比
```

## 2. 新项目最推荐执行顺序

遇到新项目时，从这里开始：

```text
1. 新建或复制一份 small config
2. 把新数据路径写进 config
3. 只跑 config / data dry-run
4. 确认染色体结构是否要改
5. 跑 encoding tests
6. 跑 decoding tests
7. 跑 evaluation tests
8. 跑 independent search small loop
9. 跑 metrics toy / output 接入
10. 跑 visualization toy / output 接入
11. 跑 independent medium
12. 做 formal preflight
13. 明确确认后再跑 independent formal
14. 如果要写论文对比，再跑 baseline comparison
15. 如果要论文统计结果，再跑 multiseed summary
```

不要跳过 small 直接 formal。formal 报错时排查成本最高。

## 3. 新项目最小命令模板

如果只是换数据，推荐先准备：

```text
configs/<project_name>_small_config.m
tests/test_<project_name>_config.m
scripts/run_<project_name>_small.m
```

然后在 MATLAB 里跑：

```matlab
cd('<projectRoot>')
run('tests/test_<project_name>_config.m')
run('scripts/run_<project_name>_small.m')
```

如果 small 通过，再跑：

```matlab
run('scripts/run_<project_name>_medium.m')
```

formal 一定要先有 preflight：

```matlab
run('tests/test_<project_name>_formal_preflight.m')
```

再明确确认：

```matlab
RUN_<PROJECT_NAME>_FORMAL_CONFIRMED = true;
run('scripts/run_<project_name>_formal.m')
```

## 4. 新项目必须检查的输出

每次运行后都检查：

```text
outputs/<experiment_name>/<timestamp>/result.mat
outputs/<experiment_name>/<timestamp>/summary.txt
outputs/<experiment_name>/<timestamp>/run_info.txt
```

summary 里至少要有：

```text
seed
pop
max_gen
runTime
paretoSolutionCount
bestMakespan
bestTotalEnergy 或新目标摘要
```

run_info 里至少要有：

```text
runType
experimentName
datasetName
config
outputDir
seed / seedList
isIndependent
usedRawSearch
usedRawDecoding
usedRawEvaluation
```

如果是新项目正式迁移，`usedRawSearch / usedRawDecoding / usedRawEvaluation` 应该保持为 false 或 0。raw_code 只能作为 baseline 或对照参考。

## 5. 新项目不要做的事

```text
不要修改 raw_code/
不要一开始跑 formal
不要同时改 decoding、evaluation、search
不要把 outputs 提交到 Git
不要把目标函数写在 search 里
不要写死本机绝对路径到可复用代码
不要只看 MATLAB 没报错，要检查 obj_matrix 和 summary
```

## 6. 该看哪些文档

如果你要真正迁移新项目，按这个顺序看：

```text
docs/08_engineering/new_project_migration_guide.md
docs/08_engineering/new_project_migration_rehearsal.md
docs/08_engineering/new_objective_template.md
docs/08_engineering/algorithm_improvement_template.md
docs/08_engineering/baseline_comparison_template.md
docs/08_engineering/paper_experiment_record_template.md
docs/06_experiments/independent_experiment_entry_guide.md
```

一句话：

```text
先换 config 和数据，跑 small；
如果目标变了，改 evaluation；
如果规则变了，改 decoding；
如果算法变了，改 search；
small 稳了再 medium，medium 稳了再 formal。
```

---

# 第 10 步：运行入口分层整理

## 1. 这一步解决什么

现在项目已经有很多入口：

```text
tests/
scripts/run_single_evaluation.m
scripts/run_small_nsga2.m
scripts/run_medium_nsga2.m
scripts/run_formal_nsga2.m
configs/small_nsga2_config.m
configs/medium_nsga2_config.m
configs/formal_nsga2_config.m
outputs/
```

第 10 步不新增代码，也不运行 MATLAB。

它只做一件事：

```text
把这些入口分层，告诉你以后复现时应该先看哪里、跑哪个。
```

## 2. 复现入口分成三层

### 第一层：检查入口

作用：

```text
判断环境、数据、配置有没有坏。
```

这些不是正式实验，而是体检。

| 场景 | 运行 |
|---|---|
| 检查 `.fjs` | `run('tests/test_read_fjsp.m')` |
| 检查机器 Excel | `run('tests/test_read_machine_data.m')` |
| 检查 AGV Excel | `run('tests/test_read_agv_data.m')` |
| 检查配置入口 | `run('tests/test_small_nsga2_config.m')` |
| 检查单条染色体评价 | `run('tests/test_evaluate_chromosome.m')` |
| 检查小种群搜索闭环 | `run('tests/test_small_nsga2.m')` |

建议在这些情况先跑检查入口：

```text
刚拉仓库
刚换电脑
刚换数据
刚改配置
脚本突然报错
```

### 第二层：运行入口

作用：

```text
真正跑一次当前已经封装好的小规模流程。
```

| 档位 | 入口 | 参数 | 用途 |
|---|---|---|---|
| single | `run('scripts/run_single_evaluation.m')` | 1 条染色体 | 看单条方案能否评价 |
| small | `run('scripts/run_small_nsga2.m')` | `pop=10, max_gen=2` | 快速确认搜索流程没坏 |
| medium | `run('scripts/run_medium_nsga2.m')` | `pop=20, max_gen=5` | 轻微放大检查 |
| formal | `run('scripts/run_formal_nsga2.m')` | `pop=30, max_gen=10` | formal NSGA-II 第一版运行骨架 |

这些输出会进入：

```text
outputs/single_evaluation/时间戳/
outputs/small_nsga2/时间戳/
outputs/medium_nsga2/时间戳/
outputs/formal_nsga2/时间戳/
```

### 第三层：指标和后续正式实验扩展入口

作用：

```text
以后读取 formal 结果，计算指标，再扩展到对比实验、消融实验和图表。
```

当前已经完成指标入口设计，但还没有实现代码。

当前缺口：

```text
scripts/run_metrics.m
完整算法对比
完整消融实验
HV / IGD / Spacing / C-metric
Pareto 图
甘特图
能耗图
```

现在不急着做这一层。

原因是：

```text
先把 small / medium 跑稳，
再整理正式实验入口，
不然一上来跑大实验，报错时很难知道问题在哪。
```

## 3. 我以后到底该跑哪个

不用每次都从头跑所有东西。

按你的场景选入口：

| 你现在想做什么 | 建议入口 |
|---|---|
| 第一次拉仓库，想确认能不能用 | 先跑读取测试 + 配置测试 |
| 刚换 `.fjs` 或 Excel | 先跑读取测试，再跑配置测试 |
| 刚改 `pop/max_gen/seed` | 先跑配置测试 |
| 想确认算法链路没坏 | 跑 `scripts/run_small_nsga2.m` |
| 想比 small 稍微大一点 | 跑 `scripts/run_medium_nsga2.m` |
| 想看 1 条方案怎么被评价 | 跑 `scripts/run_single_evaluation.m` |
| 想跑 formal 第一版 | 跑 `scripts/run_formal_nsga2.m` |
| 想计算指标 | 当前只完成设计，后续实现 `scripts/run_metrics.m` |

## 4. 最推荐的默认顺序

如果你隔了一段时间回来，不知道从哪开始，按这个顺序：

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_small_nsga2_config.m')
run('scripts/run_small_nsga2.m')
```

如果这两步都正常，说明：

```text
配置能读
小规模搜索能跑
outputs 能写
```

然后你再决定要不要跑：

```matlab
run('scripts/run_medium_nsga2.m')
run('scripts/run_formal_nsga2.m')
```

## 5. 当前已经跑通到哪里

当前已经跑通：

```text
single evaluation
small NSGA-II:  pop=10, max_gen=2
medium NSGA-II: pop=20, max_gen=5
formal NSGA-II: pop=30, max_gen=10
```

其中 formal 档位已经跑通，最近一次记录为：

```text
outputs/formal_nsga2/20260520_224558
```

当前还没有整理：

```text
完整评价指标
完整论文对比实验
完整图表输出
```

## 6. 一句话记忆

```text
tests 是体检，
configs 是参数说明书，
scripts 是运行按钮，
outputs 是结果抽屉，
docs 是回头找路的地图。
```

# 新项目迁移演练

本文档用于第 30 步：验证当前框架不只是服务当前项目，也能迁移到一个新的论文选题。当前阶段不是新建完整项目，不运行算法，不生成正式结果，只做迁移演练记录和模板字段检查。

## 1. 演练场景

假想新项目：

```text
低碳 FJSP-AGV 调度问题
```

新增内容：

```text
新调度场景：仍然是工件、机器、AGV 协同调度，但数据集换成新的低碳场景。
新目标函数：carbonEmission，基于机器能耗和 AGV 能耗折算碳排放。
新算法改进：adaptiveMutation，自适应变异率，默认关闭，先通过 small smoke test 验收。
```

演练目标：

```text
确认新项目从 data 到 formal 的迁移顺序清楚。
确认 config 字段可以表达新数据、新目标、新算法改进。
确认当前框架可以作为新项目骨架，而不是只能复现当前 raw_code。
```

## 2. 分层迁移表

| 层 | 新项目要做什么 | 本次演练怎么处理 | 完成标准 |
|---|---|---|---|
| data | 换新数据集，明确 FJSP、机器、AGV、碳排放参数来源 | 在模板 config 里保留可替换路径字段 | 路径来自 config，不写死本机路径 |
| encoding | 确认染色体是否仍包含 OS/MS/AS/SS 等段 | 先假设结构可复用；若新增决策变量，再改 encoding | 染色体结构有文档和 smoke test |
| decoding | 确认新约束是否影响机器和 AGV 调度 | 若只是低碳目标，先复用 independent decoding；若新增路径/充电规则，再改 decoding | 单条和 population 解码可运行 |
| evaluation | 新增 carbonEmission 目标 | 计划新增 `compute_carbon_emission`，先不接正式目标 | toy test 和 integration test 通过 |
| search | 先复用 independent NSGA-II | adaptive mutation 作为 config 开关，默认关闭 | small loop 能跑，obj_matrix 非空 |
| metrics | 复用 HV、IGD、Spacing、C-metric | obj_matrix 目标列变化时更新 referencePoint/referenceFront | 指标入口不依赖算法运行 |
| visualization | 复用 Pareto 和 convergence 图 | 根据 carbonEmission 更新坐标轴标签 | 图表从 obj_matrix/curve 生成 |
| configs | 新增新项目 small/medium/formal config | 本次新增 `template_project_small_config.m` | 字段可测，输出在 outputs/ 下 |
| scripts | 新增新项目运行入口 | 本次只写命名建议，不新增脚本 | 入口不写 raw_code，不覆盖 outputs |
| tests | 每层新增最小测试 | 本次新增模板 config 字段测试 | 不运行正式算法也能验收模板 |

## 3. 推荐目录和命名

新项目可以使用下面的命名方式：

```text
configs/low_carbon_fjsp_small_config.m
configs/low_carbon_fjsp_medium_config.m
configs/low_carbon_fjsp_formal_config.m

scripts/run_low_carbon_fjsp_small.m
scripts/run_low_carbon_fjsp_medium.m
scripts/run_low_carbon_fjsp_formal.m

outputs/low_carbon_fjsp_small/<timestamp>/
outputs/low_carbon_fjsp_medium/<timestamp>/
outputs/low_carbon_fjsp_formal/<timestamp>/
```

本次演练只新增：

```text
configs/template_project_small_config.m
tests/test_migration_template_config.m
```

## 4. config 字段要求

新项目 small config 至少要能表达：

```text
project.projectName
dataset.name
dataset.source
paths.fjsp
paths.machineExcel
paths.agvExcel
paths.outputBaseDir
random.seed
algorithm.pop
algorithm.max_gen
objectives.names
improvements.adaptiveMutation.enabled
```

要求：

```text
outputBaseDir 必须在 outputs/ 下。
small 的 pop 不超过 10。
small 的 max_gen 不超过 2。
新目标参数放在 config.objectives 下，不写死到算法函数里。
算法改进参数放在 config.improvements 下，默认关闭。
```

## 5. 从 data 到 formal 的迁移顺序

建议按下面顺序推进：

```text
1. 新增新项目 config，只检查字段，不跑算法。
2. 放入新数据，先跑 data reader 测试。
3. 确认染色体结构，跑 encoding smoke test。
4. 跑 independent decoding toy / invalid / integration test。
5. 新增 carbonEmission evaluation helper，跑 toy test。
6. 更新 objectives 构建逻辑，先跑 evaluation integration test。
7. 复用 independent search，跑 small loop。
8. 接 metrics，确认 obj_matrix 可以算指标。
9. 接 visualization，确认 Pareto / convergence 可生成。
10. 跑 medium 验收。
11. 做 formal preflight。
12. 明确确认后再跑 formal。
```

不要：

```text
不要一开始跑 formal。
不要同时改 data、decoding、evaluation、search。
不要修改 raw_code。
不要提交 outputs。
```

## 6. 每层完成标准

data：

```text
[ ] 新数据路径写入 config
[ ] data reader 返回结构体
[ ] 小样本读取测试通过
[ ] 不生成 data.mat
```

encoding：

```text
[ ] 染色体每段含义写清楚
[ ] 初始种群可生成
[ ] 非法染色体可识别
[ ] small encoding test 通过
```

decoding：

```text
[ ] 单条染色体可独立解码
[ ] population 可独立解码
[ ] 新约束有测试
[ ] 不调用 raw sorting
```

evaluation：

```text
[ ] carbonEmission 公式写清楚
[ ] helper 可单独测试
[ ] objectives.names 与输出列一致
[ ] 不调用 raw fitness
```

search：

```text
[ ] independent search small loop 可跑
[ ] seed 固定
[ ] obj_matrix 非空
[ ] adaptive mutation 默认关闭，开启后有单独测试
```

metrics / visualization：

```text
[ ] metrics 从 obj_matrix 读取
[ ] visualization 从 obj_matrix / curve 读取
[ ] referencePoint / referenceFront 可配置
[ ] 图表输出路径可控
```

experiments：

```text
[ ] small / medium / formal 入口分开
[ ] 输出进入 outputs/<experiment>/<timestamp>/
[ ] summary.txt、run_info.txt、result.mat 可追溯
[ ] outputs 不进 Git
```

## 7. 本次演练检查项

本次只验证模板 config 字段，不运行 MATLAB 算法：

```matlab
run('tests/test_migration_template_config.m')
```

测试应确认：

```text
projectName 存在
dataset paths 可配置
objectives.names 可配置，并包含 carbonEmission
outputBaseDir 在 outputs/ 下
seed 存在
pop/max_gen 存在并保持 small 规模
adaptiveMutation 配置存在
```

## 8. 迁移演练完成标准

本步骤完成后，应满足：

```text
有新项目迁移演练文档
有模板 config
有模板 config 字段测试
知道新项目每层怎么改
知道如何从 small 到 formal
知道如何接新目标、新算法、baseline、metrics、visualization
未运行算法
未修改 raw_code
未提交 outputs
```

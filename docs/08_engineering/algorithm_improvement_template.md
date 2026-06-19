# 新算法改进模板

## 这份模板解决什么问题

以后如果论文创新点放在算法改进上，例如：

```text
改进 NSGA-II
加入 VNS 局部搜索
加入 SA / TS
加入自适应交叉或变异
加入精英策略
加入 Q-learning 算子选择
加入反向学习初始化
```

不要直接去 `raw_code/NSGA-II/NSGA2.m` 里乱改。

推荐做法是：

```text
先定义改进策略属于哪一层
再新增独立函数
再用 toy test 验证形状和边界
再接 small search loop
再跑 medium
最后才 formal
```

当前阶段不是新增正式算法改进。

当前阶段只是建立新算法改进模板。

## 当前 search 链路

当前可参考的搜索入口：

```text
src/search/run_nsga2_with_encoding.m
src/search/nsga2_with_encoding_variation.m
```

当前编码层 variation 入口：

```text
src/encoding/generate_initial_population.m
src/encoding/generate_offspring.m
src/encoding/crossover_os_ipox.m
src/encoding/crossover_rs_mpx.m
src/encoding/mutate_os_swap.m
src/encoding/mutate_rs_resample.m
```

raw baseline 参考：

```text
raw_code/NSGA-II/NSGA2.m
raw_code/NSGA-II/non_domination.m
raw_code/NSGA-II/tournament_selection.m
raw_code/NSGA-II/replace_chrom.m
raw_code/NSGA-II/variation.m
```

当前搜索链路可以概括为：

```text
1. 初始化 population
2. 评价每个 chrom
3. 非支配排序
4. 锦标赛选择
5. 交叉 / 变异生成 offspring
6. 评价 offspring
7. 合并父代和子代
8. 非支配排序
9. 替换 / 精英保留
10. 记录 curve 和 pop_history
11. 输出 obj_matrix / chrom / curve
```

算法改进应该插在这些明确位置，而不是塞进脚本入口。

## 算法改进类型和接入位置

### 编码 / 初始化改进

例子：

```text
启发式初始化
混合初始化
反向学习初始化
基于规则的初始 population
```

推荐接入位置：

```text
src/encoding/generate_initial_population.m
或新增：
src/encoding/generate_initial_population_<strategy>.m
```

注意：

```text
初始化改进只负责生成合法 chrom / population
不要在这里算 fitness
不要在这里写 outputs
```

### 交叉 / 变异改进

例子：

```text
自适应交叉概率
自适应变异概率
新 crossover
新 mutation
算子池选择
```

推荐接入位置：

```text
src/encoding/generate_offspring.m
或新增：
src/encoding/generate_offspring_<strategy>.m
```

如果是新的具体算子，可放在：

```text
src/encoding/crossover_<name>.m
src/encoding/mutate_<name>.m
```

### 选择 / 替换改进

例子：

```text
改进锦标赛选择
精英保留策略
拥挤距离改进
替换策略改进
```

推荐接入位置：

```text
src/search/
```

未来可以按职责拆成：

```text
src/search/selection/
src/search/replacement/
```

### 局部搜索改进

例子：

```text
VNS
SA
TS
邻域搜索
插入 / 交换 / 重排局部搜索
```

推荐接入位置：

```text
src/search/local_search/
```

接入点可以是：

```text
offspring 生成后
fitness 评价前
每代替换后
只对非支配解做局部搜索
```

必须在文档中写清楚接入点。

### 学习策略改进

例子：

```text
Q-learning
强化学习选择算子
自适应算子选择
概率模型更新
```

推荐接入位置：

```text
src/search/adaptive/
```

这类策略通常需要状态、动作、奖励、参数记录，应单独设计 report 和 runInfo。

## 标准函数接口

### population 级改进

推荐接口：

```matlab
[newPopulation, report] = apply_<improvement_name>(population, context, options)
```

### offspring 生成策略

推荐接口：

```matlab
[offspring, report] = generate_offspring_<strategy>(parents, problem, agvData, options)
```

### 局部搜索策略

推荐接口：

```matlab
[improvedChrom, report] = apply_<local_search_name>(chrom, context, options)
```

### 自适应参数策略

推荐接口：

```matlab
[updatedOptions, report] = update_<strategy>_options(history, options)
```

原则：

```text
函数只做自己的策略
输入结构清楚
输出 report
不读写 outputs
不依赖当前工作目录
不直接运行 NSGA-II
```

## context 结构建议

推荐 `context` 包含：

```text
context.problem
context.machineData
context.agvData
context.config
context.generation
context.max_gen
context.history
context.objectiveNames
```

如果策略需要评价函数，也要明确：

```text
context.evaluateFcn
```

不要在策略函数里偷偷调用全局脚本。

## report 结构建议

每个改进函数都建议返回 `report`：

```text
report.isValid
report.strategyName
report.enabled
report.errors
report.warnings
report.stats
```

`stats` 可以包含：

```text
changedCount
acceptedCount
rejectedCount
bestBefore
bestAfter
mutationRate
crossoverRate
operatorCounts
localSearchCount
```

这样以后写论文实验记录时，不需要回头猜策略到底有没有生效。

## options 结构建议

每个策略都应有 options：

```text
options.enabled
options.seed
options.parameters
```

示例：

```matlab
options.enabled = true;
options.seed = 42;
options.parameters.maxIter = 10;
options.parameters.acceptWorse = false;
```

不要硬编码参数。

## config 开关设计

新策略默认不应该直接开在 formal。

建议 config：

```matlab
config.improvements.vns.enabled = true;
config.improvements.vns.maxIter = 10;
config.improvements.vns.neighborhoods = {'swap', 'insert'};

config.improvements.adaptiveMutation.enabled = true;
config.improvements.adaptiveMutation.minRate = 0.05;
config.improvements.adaptiveMutation.maxRate = 0.30;

config.improvements.operatorSelection.enabled = false;
```

原则：

```text
默认关闭新策略
small 先验收
medium 再放大
formal 最后跑
每个开关必须写入 run_info
```

如果策略参数影响论文结果，必须写入：

```text
summary.txt
run_info.txt
config snapshot
```

## 接入 search 的顺序

不要直接改：

```text
raw_code/NSGA-II/NSGA2.m
scripts/run_formal_nsga2.m
```

推荐顺序：

```text
1. 新增独立改进函数
2. 写 toy test
3. 写 invalid case
4. 在 small search loop 中加开关
5. 固定 seed 跑 small
6. 检查 obj_matrix 非空
7. 检查 runInfo 是否记录策略
8. 跑 medium
9. 写 baseline/variant 对比记录
10. 最后 formal
```

不要一边改 search，一边改 evaluation。

如果新策略导致目标函数变化，应先完成新目标函数模板那一层。

## 测试模板

### toy test

命名：

```text
tests/test_algorithm_<strategy>_toy.m
```

目标：

```text
小 population
不跑完整算法
验证输出 shape
验证 report.isValid
验证不会写 outputs
```

### invalid case

命名：

```text
tests/test_algorithm_<strategy>_invalid_cases.m
```

目标：

```text
缺参数能报错
非法概率能报错
空 population 能报错
非法 chrom 能报错
```

### small loop

命名：

```text
tests/test_search_small_loop_<strategy>.m
```

目标：

```text
pop <= 10
max_gen <= 2
seed 固定
obj_matrix 非空
runInfo 记录策略开关
raw_code 无变化
不生成非预期 outputs
```

## baseline / variant 对比模板

算法改进论文实验至少要有：

```text
baseline = 原 NSGA-II
variant = 加了新策略的 NSGA-II
```

对比记录字段：

```text
seed
pop
max_gen
p_cross
p_mutation
strategyName
strategyParameters
bestMakespan
bestTotalEnergy
paretoSolutionCount
HV
IGD
Spacing
C-metric
runTime
outputDir
```

推荐输出结构：

```text
outputs/<experiment_name>/<timestamp>/
  result.mat
  summary.txt
  run_info.txt
  metrics/summary.txt
```

如果做多 seed，对每个 seed 单独记录 run，再汇总统计。

## 常见创新点示例

### 场景 1：自适应变异率

可能改动：

```text
src/encoding/generate_offspring.m
或新增 src/encoding/generate_offspring_adaptive.m
```

测试：

```text
tests/test_algorithm_adaptive_mutation_toy.m
tests/test_algorithm_adaptive_mutation_invalid_cases.m
tests/test_search_small_loop_adaptive_mutation.m
```

注意：

```text
变异率变化要写入 report
每代 min/max mutation rate 要可追溯
```

### 场景 2：局部搜索 VNS

新增：

```text
src/search/local_search/apply_vns.m
```

接入点：

```text
offspring 生成后
或每代替换后
或只对 rank=1 的解做局部搜索
```

测试：

```text
toy population
small loop
baseline/variant 对比
```

### 场景 3：精英策略改进

新增位置：

```text
src/search/replacement/
```

接入点：

```text
replace_chrom 前后
```

注意：

```text
不能破坏 population size
不能丢失 objective columns
必须保持 non-domination 后结构一致
```

### 场景 4：Q-learning 算子选择

新增位置：

```text
src/search/adaptive/
```

需要记录：

```text
state
action
reward
Q table
operatorCounts
```

注意：

```text
随机性要受 seed 控制
Q-learning 参数要进入 config
run_info 要记录 alpha / gamma / epsilon
```

### 场景 5：反向学习初始化

新增位置：

```text
src/encoding/generate_initial_population_opposition.m
```

接入点：

```text
初始化 population 后
首次评价前
```

测试：

```text
population 合法
长度正确
没有越界
small loop obj_matrix 非空
```

## 完成标准

一个算法改进真正完成，至少满足：

```text
策略定义写清
接入位置写清
独立函数可调用
toy test 通过
invalid case 通过
small loop 通过
runInfo 记录策略
baseline/variant 对比可跑
metrics 可计算
visualization 可生成基础图
raw_code 未修改
outputs 不进 Git
```

如果只是模板阶段，则完成标准是：

```text
有中文算法改进模板
说明改进类型
说明接入位置
说明标准接口
说明 config 开关
说明测试方式
说明 baseline/variant 对比方式
不改变当前默认 search
不跑正式实验
```

## 最小安全原则

新增算法改进时始终遵守：

```text
先独立函数，后接 search
先 toy test，后 small loop
先 small，后 medium
最后 formal
raw_code 只读
参数进 config
结果进 outputs
策略记录进 runInfo
baseline 和 variant 分开跑
```

这样算法创新点就不会变成一个难以复现的临时修改。

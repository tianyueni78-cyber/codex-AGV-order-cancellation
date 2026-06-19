# 新项目迁移手册

## 这份手册解决什么问题

这份手册面向以后新的论文选题。

目标不是从零写代码，而是基于当前项目骨架，迁移出一个新的调度优化实验项目：

```text
新数据
新编码
新解码
新评价函数
新搜索策略或算法改进
新实验入口
新指标
新图表
```

当前项目的迁移思路是：

```text
raw_code 保留为原始参考和 baseline
src 作为逐层可测试的实现区
configs 记录参数和路径
scripts 作为实验入口
tests 负责小样本和 dry-run 验收
docs 记录入口、流程和边界
outputs 只放生成结果，不进 Git
```

## 当前哪些模块可以作为新项目骨架

当前可迁移骨架包括：

```text
src/data
  数据读取和结构化

src/encoding
  染色体生成、校验、编码相关逻辑

src/decoding
  单条染色体和 population 解码入口

src/evaluation
  raw wrapper、目标函数拆分、小函数评价

src/search
  小闭环搜索入口和搜索流程封装

src/metrics
  HV、IGD、Spacing、C-metric 等指标入口

src/visualization
  Pareto 图、收敛曲线、受控保存图片入口

configs
  small / medium / formal 配置

scripts
  small / medium / formal / metrics 等运行入口

tests
  smoke、invalid、compare raw、dry-run、static check

docs
  系统说明、层说明、实验说明、工程手册
```

如果新项目问题结构和当前项目很接近，可以复用更多现有模块。

如果新项目问题结构不同，就只保留骨架，逐层替换实现。

## 两种迁移方式

### 方式 A：保留 baseline 迁移

适合：

```text
新项目和当前 AGV/FJSP 调度问题非常接近
只是换数据集
只是新增目标函数
只是加约束
只是改局部搜索或变异策略
```

做法：

```text
raw_code 不改，作为参考和 baseline
src/scripts/configs 作为可控实验框架
每一层改完都加测试
每次正式实验前先跑 small，再跑 medium，最后跑 formal
```

这种方式最快，也最适合论文复现实验和小幅改进实验。

### 方式 B：模块替换迁移

适合：

```text
新项目的问题结构不同
染色体结构不同
解码规则不同
评价目标不同
搜索流程需要换算法
```

做法：

```text
保留目录结构
逐层替换 data / encoding / decoding / evaluation / search
每替换一层都写 tests
每一层先用 toy case 或 small case 验收
不要一口气改完整项目
```

这种方式更稳，适合把当前项目变成另一个论文选题的实验框架。

## 新项目迁移总流程

推荐按这个顺序做：

```text
1. 复制项目骨架
2. 保留 raw_code 作为参考，不直接修改
3. 放入新数据
4. 修改 data reader
5. 确认染色体结构
6. 修改 encoding
7. 修改 decoding
8. 修改 evaluation
9. 修改 search 或复用 search
10. 修改 configs
11. 新增 small smoke test
12. 新增 experiment entry
13. 新增 metrics
14. 新增 visualization
15. 写 run log 和输出说明
16. 跑 small
17. 跑 medium
18. 最后才跑 formal
```

不要跳过前面的层直接跑 formal。

## 通常要改哪些文件

### data_sample

用于放新项目的小样本数据。

常见改动：

```text
新增新数据文件
保留一个最小可运行样本
不要只放大数据
```

### src/data

负责把新数据读成统一结构体。

常见改动：

```text
read_xxx.m
字段命名
路径读取
数据完整性检查
```

验收重点：

```text
不生成 data.mat
不依赖当前工作目录
小样本可读
字段清楚
```

### src/encoding

负责染色体结构、初始解、交叉、变异、校验。

常见改动：

```text
染色体每一段含义
生成初始 population
非法染色体识别
编码长度计算
```

### src/decoding

负责把染色体变成可评价的调度过程或方案结构。

常见改动：

```text
decode_chromosome
decode_population
调度规则
约束落地
baseline 对照
```

### src/evaluation

负责把一个方案算成目标值。

常见改动：

```text
makespan
energy
cost
delay
penalty
constraint violation
objectives
```

如果新增目标函数，通常先改这里。

### src/search

负责搜索流程和算法改进。

常见改动：

```text
选择
交叉
变异
精英保留
局部搜索
新算法主体
```

注意：不要在 search 里偷偷改 evaluation 公式。

### src/metrics

负责论文指标。

常见改动：

```text
HV
IGD
Spacing
C-metric
算法间对比指标
```

要求输入尽量统一为：

```text
obj_matrix
```

### src/visualization

负责论文图表。

常见改动：

```text
Pareto 图
收敛曲线
甘特图
能耗曲线
保存图片规则
```

保存路径必须由外部传入，不要默认写项目根目录。

### configs

负责数据路径、参数、seed、输出目录。

常见改动：

```text
project_name_small_config.m
project_name_medium_config.m
project_name_formal_config.m
```

必须写清：

```text
seed
pop
max_gen
p_cross
p_mutation
outputBaseDir
```

### scripts

负责运行入口。

常见改动：

```text
run_project_small.m
run_project_medium.m
run_project_formal.m
run_project_metrics.m
run_project_visualization.m
```

入口要做的事：

```text
读 config
设 seed
读数据
运行算法
保存 result
写 summary
写 run_info
```

### tests

负责每层验收。

常见测试：

```text
data smoke test
encoding invalid case
decoding compare raw
evaluation toy case
search small loop
experiment config dry-run
metrics toy case
visualization toy case
```

### docs

负责给未来的自己留入口。

常见文档：

```text
系统结构
数据结构
编码说明
解码说明
评价说明
实验入口
输出规范
迁移说明
```

## 不要改哪些文件

### raw_code

不要直接修改。

它的角色是：

```text
原始代码存档
baseline
对照测试来源
行为参考
```

如果要迁移到新项目，也应该复制后作为新项目的原始参考，不要在原地改。

### outputs

不要提交。

不要把不同实验结果混在一起。

推荐结构：

```text
outputs/<experiment_name>/<timestamp>/
```

每个 run 至少包含：

```text
result.mat
summary.txt
run_info.txt
```

### logs / tmp / cache

不要作为源码提交。

如果确实需要日志，也应进入：

```text
outputs/<experiment_name>/<timestamp>/
```

### 历史 docs

不要随手覆盖。

新项目应新增自己的说明文档，保留历史记录。

## 每层迁移 checklist

### data checklist

```text
[ ] 新数据放入 data_sample 或新项目数据目录
[ ] 数据路径写入 configs
[ ] read_xxx 能返回结构体
[ ] 字段含义写入 docs
[ ] 小样本读取测试通过
[ ] 不生成 data.mat
```

### encoding checklist

```text
[ ] 染色体每一段含义写清
[ ] 染色体长度可计算
[ ] generate_initial_population 可运行
[ ] validate_chromosome 可识别非法输入
[ ] encoding smoke test 通过
```

### decoding checklist

```text
[ ] 单条解码可运行
[ ] population 解码可运行
[ ] invalid case 可识别
[ ] 输出结构可被 evaluation 使用
[ ] 若有 raw baseline，compare raw 通过
```

### evaluation checklist

```text
[ ] 单条方案能算目标值
[ ] 目标函数拆成小函数
[ ] objectives 格式清楚
[ ] invalid case 可识别
[ ] baseline 对照或 toy test 通过
```

### search checklist

```text
[ ] small pop/max_gen 可运行
[ ] seed 固定
[ ] obj_matrix 非空
[ ] runInfo 可追溯
[ ] 不跑正式实验
```

### experiment checklist

```text
[ ] small / medium / formal 入口清楚
[ ] 参数来自 config
[ ] seed 可追溯
[ ] outputs 路径清楚
[ ] summary/run_info 清楚
[ ] formal 前有 preflight
```

### metrics checklist

```text
[ ] 指标输入为 obj_matrix
[ ] toy test 通过
[ ] 如果有 baseline，compare raw 或 compare baseline 通过
[ ] 不依赖正式实验才能测试
```

### visualization checklist

```text
[ ] Pareto 图可单独画
[ ] 收敛曲线可单独画
[ ] 保存路径由外部传入
[ ] toy test 通过
[ ] 不默认写项目根目录
```

## 新项目最小启动顺序

建议顺序：

```text
1. 先跑 data tests
2. 再跑 encoding tests
3. 再跑 decoding tests
4. 再跑 evaluation tests
5. 再跑 search small loop
6. 再跑 experiment entry dry-run
7. 再跑 medium
8. 最后才跑 formal
```

不要：

```text
不要一上来跑 formal
不要一上来跑完整大实验
不要一边改数据一边改算法
不要同时改 encoding / decoding / evaluation / search
不要为了图表去改算法逻辑
```

## 新论文选题常见改法

### 场景 1：只换数据集

改动顺序：

```text
1. 放入新数据
2. 修改 configs 路径
3. 修改或复用 src/data
4. 跑 data tests
5. 跑 search small loop
6. 跑 medium
```

不应该直接改：

```text
search
metrics
visualization
```

除非新数据结构导致这些层必须适配。

### 场景 2：新增目标函数

改动顺序：

```text
1. 修改 src/evaluation
2. 修改 build_objectives
3. 修改 metrics 需要的目标列说明
4. 修改 visualization 坐标轴或图表说明
5. 跑 evaluation tests
6. 跑 search small loop
```

注意：

```text
不要在 search 里临时拼目标函数
目标函数应集中在 evaluation 层
```

### 场景 3：新增 AGV 规则

改动顺序：

```text
1. 修改 decoding 中调度规则
2. 修改 evaluation 中 AGV 能耗或约束惩罚
3. 增加 invalid case
4. 跑 decoding tests
5. 跑 evaluation tests
6. 跑 search small loop
```

### 场景 4：改进 NSGA-II

改动顺序：

```text
1. 明确改进点属于 encoding variation 还是 search
2. 修改对应函数
3. 固定 seed
4. 跑 encoding tests
5. 跑 search small loop
6. 跑 medium
7. 最后再 formal
```

### 场景 5：加新算法对比

改动顺序：

```text
1. 新增算法入口
2. 输出统一 obj_matrix
3. 接 metrics
4. 接 visualization
5. 写 baseline 对比文档
6. 跑 small
7. 跑 medium
8. formal 单独任务
```

## 新项目文件命名建议

推荐命名：

```text
configs/<project_name>_small_config.m
configs/<project_name>_medium_config.m
configs/<project_name>_formal_config.m

scripts/run_<project_name>_small.m
scripts/run_<project_name>_medium.m
scripts/run_<project_name>_formal.m
scripts/run_<project_name>_metrics.m
scripts/run_<project_name>_visualization.m

docs/06_experiments/<project_name>_experiment_guide.md
docs/08_engineering/<project_name>_migration_note.md

outputs/<project_name>/<timestamp>/
```

测试命名：

```text
tests/test_<project_name>_data.m
tests/test_<project_name>_encoding.m
tests/test_<project_name>_decoding.m
tests/test_<project_name>_evaluation.m
tests/test_<project_name>_small_loop.m
```

## 迁移完成标准

一个新项目至少满足以下条件，才算完成第一轮迁移：

```text
data 小样本可读
encoding 可生成合法解
decoding 可生成调度过程或方案结构
evaluation 可计算目标值
search small loop 可跑
experiment entry 有 small / medium / formal
outputs / run log 可追溯
metrics 可计算
visualization 可生成基础图
README 或 docs 有入口说明
Git 工作区干净
raw_code 不被修改
outputs 不进 Git
```

## 最小安全原则

迁移时始终遵守：

```text
一次只改一层
每层都有测试
先 small，再 medium，最后 formal
raw_code 只读
outputs 不提交
参数写 config
seed 必须可追溯
文档必须写入口
```

这样新项目不是靠记忆跑起来，而是靠流程跑起来。

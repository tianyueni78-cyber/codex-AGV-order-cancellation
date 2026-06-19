# outputs 与 run log 规范

## 1. 为什么要规范 outputs / run log

实验结果不能只保存一个 `.mat` 文件。每次运行都需要回答：

```text
跑了哪个入口
用了哪个 config
用了哪个 seed
参数是多少
结果保存在哪里
结果摘要是什么
以后能不能复查
```

当前阶段不是正式实验。

当前阶段只规范输出和运行记录。

## 2. outputs 目录结构

所有实验脚本都应写入：

```text
outputs/<experiment_name>/<timestamp>/
```

当前入口对应关系：

```text
scripts/run_small_nsga2.m
-> outputs/small_nsga2/<timestamp>/

scripts/run_small_nsga2_refactored.m
-> outputs/small_nsga2_refactored/<timestamp>/

scripts/run_medium_nsga2.m
-> outputs/medium_nsga2/<timestamp>/

scripts/run_formal_nsga2.m
-> outputs/formal_nsga2/<timestamp>/
```

脚本使用 timestamp 目录；如果同名目录存在，会追加 `_01`、`_02` 等后缀，避免覆盖旧结果。

## 3. 每个 run 目录应包含什么

推荐每个 run 目录至少包含：

```text
result.mat
summary.txt
run_info.txt
```

当前项目中的实际文件名：

```text
small_nsga2_result.mat
small_nsga2_refactored_result.mat
medium_nsga2_result.mat
formal_nsga2_result.mat
summary.txt
run_info.txt
```

## 4. summary.txt 字段

`summary.txt` 给人快速查看本次运行。

推荐字段：

```text
runType
experimentName
datasetName
seed
pop
max_gen
p_cross
p_mutation
runTime
paretoSolutionCount
bestMakespan
bestTotalEnergy
outputDir
```

如果是 refactored small，还应记录：

```text
useRefactoredVariation
```

## 5. run_info.txt 字段

`run_info.txt` 用于完整追溯。

推荐字段：

```text
runType
experimentName
description
datasetName
datasetSource
datasetNote
fjsp
machineExcel
agvExcel
algorithmDir
outputDir
algorithmName
seed
seedList
pop
max_gen
p_cross
p_mutation
AGVEG_MAX
eChargeSpeed
saveSummary
saveMat
saveRunInfo
```

## 6. result.mat 保存什么

`result.mat` 应保存：

```text
NSGA2_Result
chrom
problem
machineData
agvData
config
```

如果入口返回 `runInfo`，也应保存：

```text
runInfo
```

如果没有 `runInfo`，至少应保存关键参数：

```text
p_cross
p_mutation
pop
max_gen
AGVEG_MAX
AGVEG_MIN
eChargeSpeed
```

## 7. 哪些入口会生成 outputs

会生成 outputs：

```text
scripts/run_small_nsga2.m
scripts/run_small_nsga2_refactored.m
scripts/run_medium_nsga2.m
scripts/run_formal_nsga2.m
```

不会生成正式 outputs 的测试入口：

```text
tests/test_experiment_entry_configs.m
tests/test_search_small_loop.m
tests/test_run_log_schema.m
```

## 8. 如何检查污染

运行：

```bash
git status
git status --short -- raw_code
git status --short -- outputs
git status --ignored --short -- outputs
```

再检查：

```powershell
Test-Path logs
Test-Path tmp
Test-Path cache
Test-Path data.mat
```

通过标准：

```text
raw_code/ 无变化
outputs/ 不被 stage
outputs/ 被 .gitignore 忽略
logs/tmp/cache/data.mat 不存在
```

## 9. 后续正式实验怎么使用这套规则

正式实验前先检查：

```text
config 是否完整
seed / seedList 是否明确
outputBaseDir 是否在 outputs/
summary.txt 字段是否完整
run_info.txt 字段是否完整
```

正式实验后检查：

```text
result.mat 是否存在
summary.txt 是否存在
run_info.txt 是否存在
metrics/ 是否按需生成
figures/ 是否按需生成
outputs/ 是否没有被 Git stage
raw_code/ 是否无变化
```

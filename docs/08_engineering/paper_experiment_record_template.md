# 论文实验记录模板

> 这不是实验结果报告。
>
> 这是每次运行实验后填写的记录模板，用来保证实验可复现、结果可追溯、异常可排查。

## 使用场景

这份模板适用于：

```text
small smoke
medium validation
formal run
baseline comparison
ablation study
metrics calculation
visualization
failed run
```

每次实验结束后，都应该复制一份本模板并填写。

## 1. 实验基础信息

```text
实验编号：
实验名称：
实验日期：
执行人：
实验类型：
实验目的：
本次实验是否计划写入论文：
```

实验类型可选：

```text
small smoke
medium validation
formal run
baseline comparison
ablation study
metrics calculation
visualization
failed run
```

## 2. 代码版本

```text
Git branch：
commit hash：
git status 是否干净：
是否有未提交改动：
是否修改 raw_code：
```

记录命令：

```bash
git status
git log -1 --oneline
git status --short -- raw_code
```

填写示例：

```text
Git branch：codex/update-progress-gaps
commit hash：xxxxxxx
git status 是否干净：是
是否有未提交改动：否
是否修改 raw_code：否
```

## 3. 数据与配置

```text
dataset name：
fjsp path：
machineExcel path：
agvExcel path：
config file：
runType：
outputBaseDir：
```

参数：

```text
seed：
seedList：
pop：
max_gen：
p_cross：
p_mutation：
AGVEG_MAX：
eChargeSpeed：
```

算法特有参数：

```text
algorithmName：
variantName：
strategyName：
strategyParameters：
```

## 4. 运行命令

实际运行命令：

```matlab
run('scripts/run_xxx.m')
```

或测试命令：

```matlab
run('tests/test_xxx.m')
```

如果是 metrics 或 visualization：

```matlab
run('scripts/run_metrics.m')
run('scripts/run_visualization.m')
```

本次实际命令：

```text

```

## 5. 输出目录

```text
outputDir：
result.mat：
summary.txt：
run_info.txt：
metricsDir：
figuresDir：
```

输出安全检查：

```text
outputs 是否进 Git：
是否覆盖旧输出：
是否写入 raw_code：
是否写入项目根目录：
```

## 6. 结果摘要

```text
paretoSolutionCount：
bestMakespan：
bestTotalEnergy：
runTime：
obj_matrix shape：
```

如果是新目标函数实验：

```text
objectiveNames：
bestObjectiveValues：
```

如果是失败实验：

```text
失败发生阶段：
最后一条有效输出：
是否有可复用信息：
```

## 7. 指标结果

单次 seed：

```text
HV：
IGD：
Spacing：
C-metric：
```

多 seed：

```text
HV mean：
HV std：
IGD mean：
IGD std：
Spacing mean：
Spacing std：
Runtime mean：
Runtime std：
Best Cmax：
Best Energy：
```

C-metric 两两对比：

| Algorithm A | Algorithm B | C(A,B) | C(B,A) |
|---|---|---:|---:|
|  |  |  |  |

## 8. 图表记录

```text
Pareto 图路径：
收敛曲线路径：
甘特图路径：
能耗曲线路径：
指标图路径：
```

图表可用性：

```text
是否可用于论文：
是否需要重画：
坐标轴是否正确：
图例是否正确：
数据来源是否可追溯：
```

## 9. 异常与风险

```text
是否报错：
是否有 warning：
是否生成异常 outputs：
是否修改 raw_code：
是否结果异常：
是否需要重跑：
```

异常详情：

```text

```

可能风险：

```text

```

## 10. 结论与下一步

```text
本次实验是否通过：
是否可作为论文结果：
是否需要补充实验：
是否需要换 seed 重跑：
是否需要做 baseline 对比：
是否需要重新生成 metrics：
是否需要重新画图：
```

下一步建议：

```text

```

## 11. 完成检查清单

```text
[ ] 实验编号已记录
[ ] 实验目的已记录
[ ] git branch 已记录
[ ] commit hash 已记录
[ ] git status 已检查
[ ] seed / seedList 已记录
[ ] config 已记录
[ ] 数据路径已记录
[ ] 运行命令已记录
[ ] outputDir 已记录
[ ] summary.txt 已检查
[ ] run_info.txt 已检查
[ ] result.mat 已检查
[ ] obj_matrix 已检查
[ ] metrics 已记录
[ ] figures 已记录
[ ] raw_code 未修改
[ ] outputs 未提交
[ ] 异常与风险已记录
[ ] 是否可用于论文已判断
[ ] 下一步已写清
```

## 12. 最小复现信息

如果以后只能保留最少信息，至少保留：

```text
commit hash
config file
seed / seedList
run command
outputDir
summary.txt
run_info.txt
metrics summary
figures path
```

没有这些信息的实验，不建议直接写进论文结果。

## 13. 记录保存建议

建议把每次实验记录放到：

```text
docs/06_experiments/records/<experiment_name>_<date>.md
```

或者对应复现实验目录：

```text
docs/07_reproduction/reproduction_steps/
```

如果记录中包含大量实验输出路径，确认这些路径指向：

```text
outputs/<experiment_name>/<timestamp>/
```

不要把实验结果文件本身提交到 Git。

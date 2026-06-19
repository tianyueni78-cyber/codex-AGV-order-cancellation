# 第 12 步：outputs 输出结构整理

## 1. 这一步解决什么

现在 single / small / medium / formal 都已经能跑，并且都会写入：

```text
outputs/
```

第 12 步不改代码、不运行 MATLAB。

它先把输出规则讲清楚：

```text
每次运行结果放哪里？
每个结果目录里应该有什么？
哪些输出只是本地运行产物，不应该提交 GitHub？
以后正式实验结果应该怎么放？
```

## 2. 当前已经形成的输出目录

当前已有四个运行输出入口：

| 运行类型 | 输出目录 | 来源脚本 |
|---|---|---|
| 单条染色体评价 | `outputs/single_evaluation/时间戳/` | `scripts/run_single_evaluation.m` |
| small NSGA-II | `outputs/small_nsga2/时间戳/` | `scripts/run_small_nsga2.m` |
| medium NSGA-II | `outputs/medium_nsga2/时间戳/` | `scripts/run_medium_nsga2.m` |
| formal NSGA-II | `outputs/formal_nsga2/时间戳/` | `scripts/run_formal_nsga2.m` |

这里的“时间戳”类似：

```text
20260520_132626
```

它的作用是：

```text
每次运行单独存一份，避免覆盖旧结果。
```

## 3. 当前每次运行应该保存什么

### `summary.txt`

这是给人看的文本摘要。

建议包含：

```text
运行类型
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

它的作用是：

```text
不用打开 .mat，也能快速知道这次跑了什么、结果大概怎样。
```

### `*_result.mat`

这是给 MATLAB 复查用的数据文件。

当前运行会保存类似：

```text
single_evaluation_result.mat
small_nsga2_result.mat
medium_nsga2_result.mat
formal_nsga2_result.mat
```

建议里面至少包含：

```text
config
problem
machineData
agvData
chrom
NSGA2_Result 或 result
pop
max_gen
关键能耗参数
```

它的作用是：

```text
以后想回看这次结果，不用重新跑。
```

## 4. 哪些输出不要提交 GitHub

`outputs/` 是运行产物。

原则上：

```text
不提交 outputs/
```

原因：

```text
里面可能越来越大
每个人本地运行时间戳不同
结果会反复生成
提交后仓库会很乱
```

GitHub 上只保存：

```text
代码
配置
测试
文档
小样本数据
```

本地保存：

```text
outputs/
```

## 5. formal 和后续指标结果怎么放

当前 formal 第一版入口已经整理并跑通：

```text
outputs/formal_nsga2/时间戳/
```

未来指标结果建议放在同一次 formal 运行目录下：

```text
outputs/formal_nsga2/时间戳/metrics/
```

以后如果进入多算法对比和消融实验，再考虑：

```text
outputs/future_experiments/
├── comparison/
├── ablation/
├── metrics/
├── figures/
└── logs/
```

含义：

| 目录 | 用途 |
|---|---|
| `comparison/` | 不同算法对比 |
| `ablation/` | 消融实验 |
| `metrics/` | HV / IGD / Spacing / C-metric |
| `figures/` | Pareto 图、甘特图、能耗图 |
| `logs/` | 每次运行日志 |

现在先不创建这些多算法目录，等对比实验入口开始整理时再建。

## 6. 复现时怎么找结果

如果你刚跑了：

```matlab
run('scripts/run_small_nsga2.m')
```

就去看：

```text
outputs/small_nsga2/最新时间戳/
```

如果你刚跑了：

```matlab
run('scripts/run_medium_nsga2.m')
```

就去看：

```text
outputs/medium_nsga2/最新时间戳/
```

如果你刚跑了：

```matlab
run('scripts/run_formal_nsga2.m')
```

就去看：

```text
outputs/formal_nsga2/最新时间戳/
```

每次 MATLAB 命令行也会打印：

```text
outputDir: ...
```

这是最直接的结果位置。

## 7. 第 12 步完成标准

第 12 步完成，不是看有没有新实验结果，而是看规则是否清楚：

```text
single / small / medium / formal 分别输出到哪里
summary.txt 是给人看的
result.mat 是给 MATLAB 复查的
outputs/ 不提交 GitHub
指标结果以后进入 formal 输出目录下的 metrics/
多算法对比以后再单独分 comparison / ablation / figures / logs
```

这一步为后续正式实验入口打基础。

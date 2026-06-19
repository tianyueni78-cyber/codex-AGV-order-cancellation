# 第 13 步：运行日志与参数记录设计

## 1. 这一步解决什么问题

现在 small 和 medium 已经能跑通，但“能跑通”和“以后能复现”不是一回事。

复现时最容易出问题的不是算法突然不见了，而是过一段时间之后忘记：

```text
这次跑的是哪个数据？
用的是哪个配置？
seed 是多少？
pop 和 max_gen 是多少？
结果保存到哪里？
命令行里那几个数字对应哪次运行？
```

所以第 13 步先设计一套运行记录规则。  
本步只更新文档，不新增代码，不运行 MATLAB。

## 2. 每次运行应该记录什么

每次运行至少要能回答 5 类问题。

| 记录类别 | 需要记录的内容 | 为什么重要 |
|---|---|---|
| 运行身份 | `runName`、运行时间、运行脚本、配置文件 | 区分这是 single、small、medium，还是未来正式实验 |
| 输入数据 | `.fjs` 路径、机器 Excel 路径、AGV Excel 路径 | 说明结果到底来自哪组数据 |
| 算法参数 | `pop`、`max_gen`、`p_cross`、`p_mutation`、`seed` | 这些参数会直接影响搜索结果 |
| 能耗参数 | AGV 电量上限、电量下限、充电速度、速度档位、单位能耗 | 能耗目标是否可复现，取决于这些参数有没有记录 |
| 结果摘要 | `bestMakespan`、`bestTotalEnergy`、`paretoSolutionCount`、运行时间、`outputDir` | 快速判断这次运行是否成功，以及结果在哪 |

## 3. 当前已有记录

当前脚本已经做了第一版最小记录：

```text
命令行打印：
pop / max_gen / paretoSolutionCount / bestMakespan / bestTotalEnergy / outputDir

outputs/时间戳目录保存：
summary.txt
*_result.mat
```

这已经足够支持 small / medium 的快速回看。

但如果以后要做更正式的复现，还需要补充更完整的运行元信息。

## 4. 后续建议的输出文件

以后每次运行，一个时间戳目录里建议逐步形成下面结构：

```text
outputs/
└── 实验类型/
    └── 时间戳/
        ├── summary.txt        # 给人快速看的结果摘要
        ├── result.mat         # MATLAB 可继续加载的结果数据
        ├── run_info.txt       # 本次运行的数据、参数、seed、脚本入口
        └── log.txt            # 更详细的运行过程日志，后续需要时再加
```

当前已经有：

```text
summary.txt
*_result.mat
```

后面优先补：

```text
run_info.txt
```

因为它最直接服务于复现。

## 5. summary 和 run_info 的区别

这两个文件不要混在一起理解。

| 文件 | 面向谁 | 记录什么 |
|---|---|---|
| `summary.txt` | 人快速看结果 | 最终指标、Pareto 数量、输出目录 |
| `run_info.txt` | 以后复现实验 | 数据路径、配置文件、seed、参数、脚本入口 |
| `result.mat` | MATLAB 后续分析 | Pareto 解、目标矩阵、曲线等 MATLAB 变量 |
| `log.txt` | 排查问题 | 每代输出、报错上下文、运行过程细节 |

简单记：

```text
summary 看结果。
run_info 看这次怎么跑出来的。
result.mat 给 MATLAB 继续用。
log 用来排查为什么出错。
```

## 6. 为什么这一步重要

论文复现不是只复现一个最终数字，而是要能说明：

```text
同一组数据
同一组参数
同一个 seed
同一个算法入口
能得到可对照的结果
```

如果没有运行记录，后面即使看到一个不错的 makespan 或 energy，也很难判断它是：

```text
small 跑出来的？
medium 跑出来的？
换数据以后跑出来的？
seed 变了以后跑出来的？
参数放大以后跑出来的？
```

所以日志和参数记录不是“写报告用的装饰”，而是复现工程的记账本。

## 7. 当前阶段怎么用

现在你在 MATLAB 跑完后，先看命令行最后一行：

```text
outputDir: ...
```

然后去这个目录里看：

```text
summary.txt
*_result.mat
```

如果以后某次结果很重要，至少手动记住：

```text
跑的是哪个脚本
用的是哪个 config
outputDir 是哪个时间戳目录
bestMakespan 和 bestTotalEnergy 是多少
```

后续代码层会把这些内容自动写入 `run_info.txt`。

## 8. 本步完成标准

第 13 步完成后，当前项目应该清楚：

```text
每次运行要记录哪些参数
每次运行要记录哪些结果
summary / result / run_info / log 分别干什么
为什么 outputDir 是复现时最重要的线索
```

本步不改变算法，也不改变运行结果。

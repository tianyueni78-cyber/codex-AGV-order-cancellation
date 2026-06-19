# 第 11 步：阶段总结与下一阶段路线

## 1. 当前阶段完成到什么程度

当前已经完成的是：

```text
可复用小规模运行骨架
```

它不是完整论文实验，但已经能稳定回答：

```text
数据能不能读？
配置能不能集中管理？
单条染色体能不能评价？
小种群 NSGA-II 能不能跑？
参数轻微放大以后还能不能跑？
结果能不能进入 outputs？
以后回来能不能找到入口？
```

## 2. 当前已经跑通的入口

| 层级 | 入口 | 状态 |
|---|---|---|
| 数据读取 | `tests/test_read_fjsp.m`、`test_read_machine_data.m`、`test_read_agv_data.m` | 已跑通 |
| 配置检查 | `tests/test_small_nsga2_config.m` | 已跑通 |
| 单条评价 | `scripts/run_single_evaluation.m` | 已跑通 |
| small 搜索 | `scripts/run_small_nsga2.m` | 已重复跑通 |
| medium 搜索 | `scripts/run_medium_nsga2.m` | 已重复跑通 |
| formal 搜索 | `scripts/run_formal_nsga2.m` | 已跑通 |
| 入口地图 | `docs/07_reproduction/reproduction_steps/10_reproduction_entry_layers.md` | 已完成 |

当前稳定档位：

```text
small:  pop=10, max_gen=2
medium: pop=20, max_gen=5
formal: pop=30, max_gen=10
```

## 3. 哪些是体检工具，哪些是运行入口

### 体检工具

这些用于排错，不是正式实验：

```text
tests/test_read_fjsp.m
tests/test_read_machine_data.m
tests/test_read_agv_data.m
tests/test_small_nsga2_config.m
tests/test_evaluate_chromosome.m
tests/test_small_nsga2.m
```

### 当前运行入口

这些用于实际跑当前已经封装好的小规模流程：

```text
scripts/run_single_evaluation.m
scripts/run_small_nsga2.m
scripts/run_medium_nsga2.m
scripts/run_formal_nsga2.m
```

### 后续待实现入口

这部分还没有整理：

```text
完整算法对比
完整消融实验
完整指标计算
完整图表输出
```

其中指标入口已经完成设计文档：

```text
docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md
```

## 4. 当前阶段不等于完整论文复现

当前已经完成的是：

```text
复现前的稳定运行骨架
```

还没有完成的是：

```text
完整论文实验复现
```

区别是：

| 当前阶段 | 完整论文实验 |
|---|---|
| 跑 small / medium | 跑完整参数规模 |
| 验证链路稳定 | 生成论文级对比结果 |
| 输出目标值摘要 | 输出完整指标和图表 |
| 便于换数据、排错 | 便于写论文实验部分 |

所以当前不是“没做完”，而是完成了一个独立阶段：

```text
小规模可复用骨架阶段
```

## 5. 后续三条可选路线

### 路线 A：继续工程化

目标：

```text
让项目更像一个可复现实验工程。
```

优先整理：

```text
正式实验入口
输出目录结构
指标入口
运行日志
参数记录
```

适合现在做，因为 small / medium 已经跑稳。

### 路线 B：进入评价层

目标：

```text
理解和整理 HV / IGD / Spacing / C-metric。
```

重点不是跑大实验，而是先弄懂：

```text
每个指标说明什么
输入是什么
输出是什么
由哪个文件计算
```

### 路线 C：进入算法理解

目标：

```text
理解 INSGA-II 里的改进点。
```

可能包括：

```text
VNS
Q-learning
反向学习
改进精英策略
```

## 6. 你已选择的路线

当前选择：

```text
路线 A：继续工程化
```

所以后续主线不是继续盲目放大参数，也不是马上整理评价指标和算法改进。

下一阶段建议聚焦：

```text
正式实验入口怎么整理
outputs 应该怎么分层
运行时应该保存哪些参数和摘要
指标计算入口后续怎么接进来
```

你已提出一个关键使用问题：

```text
我在 MATLAB 命令行到底输入什么？
```

因此路线 A 先补了一个命令清单：

```text
docs/07_reproduction/reproduction_steps/matlab_command_cheatsheet.md
```

它是后续复现时最直接的操作入口。

## 7. 路线 A 当前推进到哪里

路线 A 已经继续推进到：

```text
第 17 步：指标入口设计
```

已经完成：

```text
outputs 输出结构
运行日志与参数记录设计
formal 配置设计与配置文件
formal 配置测试
formal NSGA-II 第一版运行脚本
formal 手动跑通记录
指标入口设计
```

当前还没有实现：

```text
scripts/run_metrics.m
完整 HV / IGD / Spacing / C-metric 计算
多算法对比入口
图表生成入口
```

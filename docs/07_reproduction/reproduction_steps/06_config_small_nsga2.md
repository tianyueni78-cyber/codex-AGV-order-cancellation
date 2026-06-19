# 第 6 步：配置化 small_nsga2

## 1. 这一步为什么做

第 5 步已经证明：

```text
小样本 + 基础 NSGA-II + pop=10 + max_gen=2
```

可以跑通。

但第 5 步还有一个问题：

```text
数据路径和参数写在 scripts/run_small_nsga2.m 里。
```

这会导致以后换数据、改参数时，你必须进脚本里找变量。

第 6 步要解决的是：

```text
以后再跑时，先改配置，不改运行脚本。
```

## 2. 新增了什么

新增配置入口：

```text
configs/small_nsga2_config.m
```

它返回一个 `config` 结构体，集中放：

| 配置内容 | 字段 |
|---|---|
| `.fjs` 路径 | `config.paths.fjsp` |
| 机器 Excel 路径 | `config.paths.machineExcel` |
| AGV Excel 路径 | `config.paths.agvExcel` |
| 算法目录 | `config.paths.algorithmDir` |
| 输出目录 | `config.paths.outputBaseDir` |
| 随机种子 | `config.random.seed` |
| 种群规模 | `config.algorithm.pop` |
| 迭代次数 | `config.algorithm.max_gen` |
| 交叉概率 | `config.algorithm.p_cross` |
| 变异概率 | `config.algorithm.p_mutation` |
| AGV 最大电量 | `config.energy.AGVEG_MAX` |
| 充电速度 | `config.energy.eChargeSpeed` |

## 3. run_small_nsga2.m 现在怎么变

原来脚本里直接写：

```matlab
fjspPath = ...
pop = 10;
max_gen = 2;
rng(42);
```

现在变成：

```matlab
config = small_nsga2_config(projectRoot);
rng(config.random.seed);
problem = read_fjsp(config.paths.fjsp);
pop = config.algorithm.pop;
max_gen = config.algorithm.max_gen;
```

也就是说：

```text
scripts/run_small_nsga2.m 负责跑
configs/small_nsga2_config.m 负责告诉它怎么跑
```

## 4. 以后换数据怎么做

以后如果你有新小样本，先放到类似位置：

```text
data_sample/新算例.fjs
data_sample/机器数据.xlsx
data_sample/AGV数据.xlsx
```

然后改：

```text
configs/small_nsga2_config.m
```

比如改：

```matlab
config.paths.fjsp = fullfile(projectRoot, 'data_sample', '新算例.fjs');
```

不优先改：

```text
scripts/run_small_nsga2.m
```

## 5. 以后改参数怎么做

如果想从短迭代变成稍微大一点的实验，优先改配置：

```matlab
config.algorithm.pop = 20;
config.algorithm.max_gen = 5;
config.random.seed = 42;
```

暂时不要直接追求大实验。

建议放大顺序是：

```text
pop=10, max_gen=2
-> pop=20, max_gen=5
-> pop=50, max_gen=10
-> 再考虑完整规模
```

## 6. 这一步和完整论文实验的关系

这一步不是为了马上写完整论文实验。

它服务的是：

```text
可复用运行骨架。
```

也就是以后你换一个智能调度项目时，也可以沿用这种结构：

```text
configs/  写这次用什么数据和参数
scripts/  按配置运行
src/      放可复用读取/评价函数
tests/    做小规模检查
outputs/  放运行结果
```

完整论文实验只是远期可选目标，不是当前主线。

## 7. 你现在怎么跑

MATLAB 里还是运行同一个脚本：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_small_nsga2.m')
```

区别是：

```text
这次脚本会先读取 configs/small_nsga2_config.m。
```

如果要改数据或参数，先改配置文件。

## 8. 这一步已经跑通了吗

已经由你在 MATLAB 本地跑通。

运行命令：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_small_nsga2.m')
```

本次输出摘要：

```text
RUNNING --------> NSGA-II <-------- RUNNING
工件数：10 机器数 6 AGV数 3
GEN: 1  MIN Cmax: 155.9  MIN Energy:1890.05
GEN: 2  MIN Cmax: 155.9  MIN Energy:1890.05
运行时间：0.27769
small NSGA-II finished.
pop: 10, max_gen: 2
paretoSolutionCount: 3
bestMakespan: 155.886667
bestTotalEnergy: 1890.048000
outputDir: D:\CODEX\code_refactor_project\outputs\small_nsga2\20260520_112624
```

这说明配置文件已经真正参与运行：

```text
configs/small_nsga2_config.m
-> scripts/run_small_nsga2.m
-> 原始 NSGA-II
-> outputs/small_nsga2/时间戳
```

所以以后换数据、改 `pop`、改 `max_gen`、固定随机种子，都应该先看配置文件。

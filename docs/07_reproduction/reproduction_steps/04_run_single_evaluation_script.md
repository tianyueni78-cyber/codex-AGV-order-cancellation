# 第 4 步：把已封装零件串成一个运行脚本

## 1. 这一步在做什么

前面几步已经有了几个零件：

```text
read_fjsp.m
read_machine_data.m
read_agv_data.m
evaluate_chromosome.m
```

但只有零件还不够。

你真正复现时需要一个“按下运行键”的入口。

所以这一步新增：

```text
scripts/run_single_evaluation.m
```

它的作用是：

```text
把数据读取、参数准备、染色体生成、单条染色体评价串起来。
```

## 2. 这个脚本现在会跑什么

它现在跑的是一个最小单方案评价流程：

```text
1. 加载 src/data
2. 加载 src/evaluation
3. 加载 raw_code/NSGA-II
4. 读取 data_sample/Mk01.fjs
5. 读取 data_sample/机器数据.xlsx
6. 读取 data_sample/AGV数据.xlsx
7. 设置 AGV 电量和充电参数
8. 用原始 init.m 生成 1 条染色体
9. 调用 evaluate_chromosome.m
10. 输出 makespan 和 totalEnergy
11. 把结果保存到 outputs/single_evaluation/时间戳/
```

注意：

```text
它不是完整 NSGA-II 实验。
它只是评价 1 条染色体。
```

也就是说，它现在回答的是：

```text
数据读取 -> 生成 chrom -> fitness/sorting 评价
这条最短链路能不能串起来。
```

## 3. 输入、过程、输出分别是什么

这一步可以按三个部分理解。

### 输入：脚本吃什么

`scripts/run_single_evaluation.m` 当前使用的是 `data_sample/` 里的小样本：

| 输入 | 文件或来源 | 读入后变成什么 |
|---|---|---|
| `.fjs` 标准算例 | `data_sample/Mk01.fjs` | `problem` |
| 机器数据 | `data_sample/机器数据.xlsx` | `machineData` |
| AGV 数据 | `data_sample/AGV数据.xlsx` | `agvData` |
| AGV 电量参数 | 脚本里临时设置 | `config` |
| 随机种子 | `rng(42)` | 保证这次随机生成的 `chrom` 可重复 |

其中：

```text
problem     说明工件、工序、候选机器、加工时间
machineData 说明机器距离和机器能耗
agvData     说明 AGV 数量、速度、空载/负载能耗
config      说明电量上限、充电阈值、充电速度
```

### 过程：脚本中间做什么

脚本内部把这些步骤串起来：

```text
read_fjsp
-> read_machine_data
-> read_agv_data
-> init 生成 1 条 chrom
-> evaluate_chromosome
-> 原始 fitness.m
-> 原始 sorting.m
```

你可以把 `chrom` 理解成：

```text
一条随机生成的调度方案。
```

`evaluate_chromosome` 会把这条方案交给原始 `fitness/sorting` 去排程和评价。

### 输出：脚本吐出什么

命令行会显示：

```text
single evaluation finished.
makespan: ...
totalEnergy: ...
outputDir: ...
```

输出目录里会保存两个文件：

| 输出文件 | 里面有什么 |
|---|---|
| `summary.txt` | 方便人看的摘要：`makespan`、机器能耗、AGV 能耗、总能耗 |
| `single_evaluation_result.mat` | MATLAB 数据：`result`、`chrom`、`problem`、`machineData`、`agvData`、`config` |

`result` 里最重要的是：

| 字段 | 含义 |
|---|---|
| `result.makespan` | 这条调度方案的总完工时间 |
| `result.machineEnergy` | 机器能耗 |
| `result.agvEnergy` | AGV 能耗 |
| `result.totalEnergy` | 机器能耗 + AGV 能耗 |
| `result.machineTable` | 机器加工时间表 |
| `result.AGVTable` | AGV 运输/充电时间表 |

## 4. 本次你已经跑通的结果

你这次在 MATLAB 命令行看到：

```text
single evaluation finished.
makespan: 175.016667
totalEnergy: 2147.655667
outputDir: D:\CODEX\code_refactor_project\outputs\single_evaluation\20260519_205602
```

这说明当前最小链路已经跑通：

```text
数据 -> 染色体 -> 解码 -> 评价 -> 输出
```

这两个数字的意思是：

| 指标 | 数值 | 含义 |
|---|---:|---|
| `makespan` | `175.016667` | 这条随机调度方案的总完工时间 |
| `totalEnergy` | `2147.655667` | 这条方案的机器能耗 + AGV 能耗 |

注意：

```text
这不是论文最终结果。
这是 1 条随机染色体的评价结果。
```

它证明的是：

```text
当前串联入口能跑通，不代表算法已经完成完整优化实验。
```

## 5. 你在 MATLAB 里怎么跑

打开 MATLAB，输入：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_single_evaluation.m')
```

如果正常，会在命令行看到类似：

```text
single evaluation finished.
makespan: ...
totalEnergy: ...
outputDir: ...
```

结果会保存到：

```text
outputs/single_evaluation/某个时间戳/
```

里面会有：

| 文件 | 作用 |
|---|---|
| `summary.txt` | 简单结果摘要 |
| `single_evaluation_result.mat` | MATLAB 结果数据 |

## 6. 为什么输出要进 outputs

因为复现时最怕结果到处散。

这个脚本不会把结果写到项目根目录，也不会写到 `raw_code/`。

每次运行都会新建一个时间戳文件夹：

```text
outputs/single_evaluation/20260519_153000/
```

这样不会覆盖上一次运行结果。

## 7. 这个接口以后会怎么变

会变，而且应该变。

现在它是一个临时但有用的串联入口。

后续随着封装深入，它会逐步变化：

| 现在 | 以后 |
|---|---|
| 脚本里直接写样本路径 | 从 `configs/*.yaml` 读取 |
| 脚本里直接写 AGV 参数 | 从配置文件读取 |
| 直接调用原始 `init.m` | 封装自己的初始化入口 |
| 只评价 1 条染色体 | 扩展到小种群短迭代 |
| 只用 `raw_code/NSGA-II` | 以后可配置选择算法 |

所以你可以把它理解成：

```text
当前阶段的临时运行入口。
```

不是最终主程序。

## 8. 如果以后换新数据怎么办

现在最简单的方式是：

```text
把新小样本放到 data_sample/
然后改 scripts/run_single_evaluation.m 里的三行路径
```

对应三类文件：

```matlab
fjspPath = ...
machineExcelPath = ...
agvExcelPath = ...
```

但长期不建议总是改脚本。

后面应该变成：

```text
新数据放 data_raw/ 或 data_sample/
配置文件写路径
脚本读取配置
```

也就是：

```text
换数据 -> 改 config
不改 src
尽量少改 scripts
```

## 9. 现在项目里代码怎么不那么碎

现在可以这样理解：

```text
src/      是零件
scripts/  是把零件串起来的运行入口
tests/    是检查零件有没有坏
outputs/  是运行结果
docs/     是你回头理解和复现的说明
```

这一步补上 `scripts/` 之后，项目就不只是碎零件了。

它开始有一条可以运行的主线：

```text
scripts/run_single_evaluation.m
    -> read_fjsp
    -> read_machine_data
    -> read_agv_data
    -> init
    -> evaluate_chromosome
    -> fitness/sorting
    -> outputs
```

## 10. 这一步的当前状态

当前状态：

```text
拆解：已完成
封装：已完成第一版
串联脚本：已完成第一版
正式测试：由 tests/test_evaluate_chromosome.m 覆盖核心评价链路
手动运行：你已经跑通 scripts/run_single_evaluation.m
```

你可以先自己在 MATLAB 里跑这个脚本。

如果它能跑通，说明当前最小链路已经从“零件”变成“可执行流程”。

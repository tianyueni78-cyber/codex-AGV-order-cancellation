# 第 7 步：数据与配置扩展准备

## 1. 这一步在做什么

第一轮已经跑通：

```text
数据 -> 配置 -> 小种群 NSGA-II -> 目标值摘要 -> outputs
```

第 7 步不急着跑完整论文实验，也不急着画图。

它要解决的是：

```text
以后换数据、改参数、放大规模时，我应该改哪里，怎么检查，怎么避免一跑就报错。
```

这一步属于“扩大规模前的整理”，不是算法重构。

## 2. 为什么先整理数据和配置

现在能跑通的是小规模骨架。

如果直接把 `pop`、`max_gen` 放大，或者直接换新算例，很容易遇到这些问题：

| 风险 | 可能表现 | 先怎么处理 |
|---|---|---|
| `.fjs` 和 Excel 不匹配 | 机器数量、工序机器编号对不上 | 先确认 `.fjs` 的 `machineNum` 与机器 Excel 规模一致 |
| 路径错 | MATLAB 找不到文件或读到旧文件 | 只改 `configs/small_nsga2_config.m`，不在脚本里临时改路径 |
| 随机结果不一致 | 每次跑出来不一样 | 固定 `config.random.seed` |
| 输出混乱 | 不知道哪个结果对应哪次参数 | 每次输出到 `outputs/small_nsga2/时间戳` |
| 规模放太快 | 运行慢、报索引错误、结果难排查 | 先小步放大 `pop` 和 `max_gen` |

所以第 7 步的核心不是“多跑”，而是“让以后能安全多跑”。

## 3. 以后换数据的顺序

以后如果你拿到一组新数据，先按这个顺序走。

第一步，准备输入文件：

```text
.fjs 标准算例
机器数据 Excel
AGV 数据 Excel
```

第二步，放到项目里的数据目录。

当前小样本放在：

```text
data_sample/
```

后面如果数据多了，可以再考虑分出：

```text
data_raw/      原始数据
data_sample/   小样本和调试数据
```

当前阶段先不要大改目录。

第三步，只改配置文件：

```text
configs/small_nsga2_config.m
```

重点改这些字段：

| 想换什么 | 改哪里 |
|---|---|
| `.fjs` 算例 | `config.paths.fjsp` |
| 机器 Excel | `config.paths.machineExcel` |
| AGV Excel | `config.paths.agvExcel` |
| 算法目录 | `config.paths.algorithmDir` |
| 输出目录 | `config.paths.outputBaseDir` |

不要优先改：

```text
scripts/run_small_nsga2.m
src/
raw_code/
```

## 4. 以后改参数的顺序

参数也先从配置文件改。

当前最小运行参数是：

```text
pop = 10
max_gen = 2
seed = 42
```

建议放大顺序：

```text
pop=10, max_gen=2
-> pop=20, max_gen=5
-> pop=50, max_gen=10
-> 再考虑更大规模
```

每放大一步，只先确认：

```text
能跑完
Pareto 解集非空
bestMakespan 非空
bestTotalEnergy 非空
outputs 正常生成
```

暂时不需要马上检查论文级图表。

## 5. 放大规模前要跑哪些检查

建议每次换数据或改参数后，先按这个顺序跑。

### 读取检查

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_read_fjsp.m')
run('tests/test_read_machine_data.m')
run('tests/test_read_agv_data.m')
```

这一步确认：

```text
数据文件能不能被读进 MATLAB。
```

### 单条评价检查

```matlab
run('tests/test_evaluate_chromosome.m')
```

这一步确认：

```text
1 条染色体能不能被 fitness/sorting 正常评价。
```

### 小种群检查

```matlab
run('tests/test_small_nsga2.m')
```

这一步确认：

```text
基础 NSGA-II 能不能完成一个很小的搜索闭环。
```

### 配置化运行

```matlab
run('scripts/run_small_nsga2.m')
```

这一步确认：

```text
配置文件能不能驱动一次实际运行，并把结果写入 outputs。
```

## 6. 小规模时要不要生成图片

暂时不需要。

小规模阶段的作用是检查链路：

```text
能不能读
能不能算
能不能跑完
能不能输出
```

图片适合放在后面：

```text
多次运行稳定
-> 参数规模稳定
-> 评价指标稳定
-> 再整理 Pareto 图、迭代图、甘特图
```

如果现在过早整理图片，反而容易把注意力从“可复用运行骨架”带偏。

## 7. 第 7 步完成标准

第 7 步完成，不是看有没有大实验结果，而是看你是否知道：

```text
新数据放哪里
配置改哪里
参数怎么逐步放大
每一步怎么检查
结果去 outputs 哪里找
出错时先查哪一层
```

当前第 7 步建议的 MATLAB 检查流程已经由你本地跑通：

```text
读取检查
-> 单条评价检查
-> 小种群检查
-> 配置化运行
```

其中配置化运行已经重复通过，最近一次结果写入：

```text
outputs/small_nsga2/20260520_115204
```

这说明第 7 步已经完成了它该完成的事：

```text
不是扩大实验规模，
而是确认扩大规模前的检查顺序可以走通。
```

下一步不是立刻写完整评价层，而是先做一个很小的配置检查任务：

```text
让 small_nsga2 的配置入口也有对应测试，确认脚本确实从配置读取参数。
```

这样后面你换数据或改参数时，就更不容易出现“我以为改了配置，其实脚本没用它”的问题。

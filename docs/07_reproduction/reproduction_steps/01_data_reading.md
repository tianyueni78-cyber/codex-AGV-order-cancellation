# 第 1 步：数据读取封装

## 1. 这一步在复现里负责什么

这一步只解决一个问题：

```text
原始数据能不能稳定、清楚、无副作用地进入 MATLAB？
```

它还不跑算法，也不判断结果好坏。

你可以把它理解成复现的第一道门：

```text
数据读不对，后面的 sorting、fitness、NSGA-II 都没有意义。
```

## 2. 原来代码的问题

原始主脚本里，很多事情混在一起：

```text
读 .fjs
读机器 Excel
读 AGV Excel
设置实验参数
生成染色体
调用算法
画图
写结果
```

这样能跑，但以后复现和排错会比较难：

- 不容易知道错误是数据问题还是算法问题。
- 有些读取逻辑会顺手保存 `data.mat`。
- 有些文件依赖当前 MATLAB 工作目录。
- 机器距离计算还可能写回 Excel。

所以第一步先把“读取数据”单独拆出来。

## 3. 已经封装出的读取函数

### `.fjs` 标准算例读取

| 内容 | 说明 |
|---|---|
| 新函数 | `src/data/read_fjsp.m` |
| 来源逻辑 | `raw_code/benchmarkRead.m` |
| 读取什么 | 工件数、机器数、每个工件的工序、候选机器、加工时间 |
| 返回什么 | `problem` 结构 |
| 是否保存文件 | 不保存 `data.mat` |
| 对应检查 | `tests/test_read_fjsp.m` |

你以后看到：

```text
problem.jobInfo
problem.candidateMachine
problem.machineNum
problem.jobNum
problem.operaNumVec
```

可以理解为：

```text
.fjs 文件已经被整理成算法能用的工件/工序数据。
```

### 机器数据读取

| 内容 | 说明 |
|---|---|
| 新函数 | `src/data/read_machine_data.m` |
| 来源逻辑 | `raw_code/dif_main.m` 和 `raw_code/same_main.m` 里的机器 Excel 读取部分 |
| 读取什么 | 机器距离矩阵、装载站到机器距离、机器到卸载站距离、机器加工能耗、机器空载能耗 |
| 返回什么 | `machineData` 结构 |
| 是否写 Excel | 不写 |
| 对应检查 | `tests/test_read_machine_data.m` |

你以后看到：

```text
machineData.distance_matrix
machineData.machineEnergy
```

可以理解为：

```text
机器之间怎么走、机器加工/空闲怎么耗电，已经读出来了。
```

### AGV 数据读取

| 内容 | 说明 |
|---|---|
| 新函数 | `src/data/read_agv_data.m` |
| 来源逻辑 | `raw_code/dif_main.m` 和 `raw_code/same_main.m` 里的 AGV Excel 读取部分 |
| 读取什么 | AGV 数量、AGV 速度档位、空载能耗、负载能耗 |
| 返回什么 | `agvData` 结构 |
| 是否写文件 | 不写 |
| 对应检查 | `tests/test_read_agv_data.m` |

你以后看到：

```text
agvData.AGVNum
agvData.AGVSpeed
agvData.AGVEnergy.free
agvData.AGVEnergy.load
```

可以理解为：

```text
AGV 有几辆、能跑多快、不同速度下耗多少电，已经读出来了。
```

## 4. 这一步的检查作业

这一阶段有三个小检查：

```matlab
run('tests/test_read_fjsp.m')
run('tests/test_read_machine_data.m')
run('tests/test_read_agv_data.m')
```

它们不是完整实验。

它们只检查：

- 数据文件能不能被读取。
- 关键字段是不是非空。
- 读取过程有没有乱生成或删除项目根目录文件。
- `.fjs` 读取不会再自动保存 `data.mat`。

## 5. 这一步对后续复现有什么用

这一步完成后，后续复现可以少一个大不确定点：

```text
如果读取测试都能过，
再往后出错时，就更可能是参数、染色体、解码、评价或算法搜索的问题。
```

它把问题范围缩小了。

以后真正复现完整实验时，可以按这个顺序排查：

```text
先确认数据读取没坏
再确认单个染色体能评价
再确认小种群短迭代能跑
最后跑完整实验
```

## 6. 现在还没有做什么

这一阶段没有做：

- 没有改 `raw_code/`。
- 没有改 `dif_main.m` 和 `same_main.m`。
- 没有重构 `sorting.m`。
- 没有重构 `fitness.m`。
- 没有跑完整算法。
- 没有保证论文结果复现。

也就是说，这一步只是打好了数据入口的地基。

下一步如果继续，应该先拆解：

```text
fitness/sorting 最小调用链
```

弄清楚一条染色体要被评价，需要哪些输入。


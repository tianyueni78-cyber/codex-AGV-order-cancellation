# 第 9 步：小幅放大参数运行

## 1. 这一步在做什么

第 8 步已经确认：

```text
配置入口能读
路径存在
关键参数合理
```

第 9 步开始验证：

```text
把参数稍微放大以后，配置化运行骨架还能不能跑。
```

这一步仍然不是完整论文实验，也不生成图片。

## 2. 新增了什么

新增 medium 配置：

```text
configs/medium_nsga2_config.m
```

新增 medium 运行脚本：

```text
scripts/run_medium_nsga2.m
```

参数从：

```text
small:  pop=10, max_gen=2
```

放大到：

```text
medium: pop=20, max_gen=5
```

## 3. 为什么不直接改 small 配置

`small_nsga2_config.m` 是快速体检配置。

它的作用是：

```text
换电脑、换数据、怀疑哪里坏了时，先快速检查链路。
```

`medium_nsga2_config.m` 是轻微放大配置。

它的作用是：

```text
确认小配置稳定以后，看看稍大一点的运行还能不能稳定。
```

所以保留两个档位：

| 档位 | 用途 | 参数 |
|---|---|---|
| small | 快速检查 | `pop=10, max_gen=2` |
| medium | 小幅放大 | `pop=20, max_gen=5` |

## 4. 以后复现到底跑哪个

不是每次都要从第 1 步跑到第 9 步。

更实用的理解是：

| 场景 | 建议跑什么 |
|---|---|
| 刚换电脑、刚拉仓库 | 先跑读取测试和配置测试 |
| 刚换数据 | 先跑读取测试、配置测试、小种群测试 |
| 只是想快速确认项目没坏 | 跑 `scripts/run_small_nsga2.m` |
| 想看轻微放大能不能跑 | 跑 `scripts/run_medium_nsga2.m` |
| 以后要做正式实验 | 跑未来专门整理出的正式实验入口 |

也就是说：

```text
小配置不是最终实验，
它是复现前的检查工具。
```

真正复现时，你要找的是：

```text
README.md
-> 项目入口地图
-> 当前运行说明
-> 选择 small / medium / future full 入口
```

## 5. 怎么运行

在 MATLAB 中运行：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_medium_nsga2.m')
```

正常情况下会输出类似：

```text
medium NSGA-II finished.
pop: 20, max_gen: 5
paretoSolutionCount: ...
bestMakespan: ...
bestTotalEnergy: ...
outputDir: ...
```

输出会写入：

```text
outputs/medium_nsga2/时间戳/
```

## 6. 第 9 步完成标准

第 9 步完成的标准不是结果比 small 更好，而是：

```text
medium 配置能被脚本读取
pop=20 和 max_gen=5 生效
算法能跑完
目标值非空
结果能写入 outputs/medium_nsga2/
```

如果它跑通，说明当前骨架已经从“最小检查”推进到“轻微放大检查”。

当前第 9 步已经由你在 MATLAB 本地跑通。

本次输出摘要：

```text
RUNNING --------> NSGA-II <-------- RUNNING
工件数：10 机器数 6 AGV数 3
GEN: 1  MIN Cmax: 138.0  MIN Energy:1967.11
GEN: 2  MIN Cmax: 138.0  MIN Energy:1967.11
GEN: 3  MIN Cmax: 138.0  MIN Energy:1923.10
GEN: 4  MIN Cmax: 135.7  MIN Energy:1863.80
GEN: 5  MIN Cmax: 135.7  MIN Energy:1824.22
运行时间：0.95065
medium NSGA-II finished.
pop: 20, max_gen: 5
paretoSolutionCount: 4
bestMakespan: 135.743333
bestTotalEnergy: 1824.221333
outputDir: D:\CODEX\code_refactor_project\outputs\medium_nsga2\20260520_125615
```

这说明 medium 档位已经通过：

```text
pop=20
max_gen=5
结果写入 outputs/medium_nsga2/
```

之后你又重复运行了一次 medium 档位，结果仍然一致：

```text
pop: 20, max_gen: 5
paretoSolutionCount: 4
bestMakespan: 135.743333
bestTotalEnergy: 1824.221333
outputDir: D:\CODEX\code_refactor_project\outputs\medium_nsga2\20260520_132626
```

这说明当前 `medium_nsga2` 运行不是偶然通过，而是可以重复跑通。

# 第 28 步：baseline 对比实验跑通

## 目标

跑通第一版公平对比闭环：

```text
baseline：raw NSGA-II
variant：independent NSGA-II
```

## 入口

```text
配置：configs/baseline_comparison_config.m
脚本：scripts/run_baseline_comparison_small.m
配置测试：tests/test_baseline_comparison_config.m
运行测试：tests/test_baseline_comparison_small.m
```

MATLAB 命令：

```matlab
run('tests/test_baseline_comparison_config.m')
run('scripts/run_baseline_comparison_small.m')
```

## 已完成结果

已验收输出：

```text
outputs/baseline_comparison_small/20260529_141649/
seed：42
pop：10
max_gen：2
objectiveColumnCount：2
```

结果摘要：

| 项目 | raw baseline | independent variant |
|---|---:|---:|
| Pareto 解数量 | 3 | 1 |
| 最优 makespan | 155.886667 | 138.456667 |
| 最优 totalEnergy | 1890.048000 | 1936.654667 |

这组结果不能简单解释为某一算法全面更好：variant 的 makespan 更低，但 energy 更高，需要结合 Pareto 集和指标综合比较。

## 完成结论

```text
raw baseline small 可运行
independent variant small 可运行
双方使用同一数据、seed、pop、max_gen
双方 obj_matrix 结构可比
raw_code 只读未修改
```

本步骤是 small 单 seed 对比，不是论文最终 baseline 实验。

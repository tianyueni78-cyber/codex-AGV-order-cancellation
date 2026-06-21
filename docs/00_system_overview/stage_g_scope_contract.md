# 阶段 G Step G1：范围确认

本文档确认阶段 G 的研究范围和执行边界。阶段 G 是阶段 F 小规模实验闭环之后的扩展阶段，目标是建立可复现的订单取消场景库，并允许后续基于该场景库批量运行实验。

## 1. 阶段 G 目标

阶段 G 的目标是：

```text
建立可复现的订单取消场景库，
并为后续基于场景库运行实验提供入口。
```

阶段 G 不直接修改阶段 B-E 的核心调度逻辑，而是把实验对象从单个 `Mk01` smoke 场景扩展为一组可复现、可统计、可追踪的取消场景。

## 2. 阶段 G 两部分

阶段 G 包含两部分：

```text
G-A：生成场景库
G-B：基于场景库运行实验
```

### 2.1 G-A：生成场景库

G-A 只负责生成取消场景，不运行调度实验。

应包含：

1. 数据集路径。
2. 取消时间窗口。
3. 取消订单类型。
4. 随机种子。
5. `scenario_id`。
6. `cancel.job_id`。
7. `cancel.cancel_time`。
8. `cancel.policy`。

G-A 禁止：

1. 不写 `outputs/`。
2. 不运行 MATLAB 正式实验。
3. 不调用 NSGA-II。
4. 不生成局部修复或完全重调度候选。
5. 不形成实验结论。

### 2.2 G-B：基于场景库运行实验

G-B 使用 G-A 生成的场景库批量运行阶段 B-E 链路。

应包含：

1. 对每个场景提取取消状态。
2. 对每个场景构造局部修复候选。
3. 对每个场景构造完全重调度候选。
4. 对每个场景计算评价指标。
5. 对每个场景记录策略选择。
6. 汇总不同时间窗口、订单类型和 seed 的结果。

G-B 会写入：

```text
outputs/order_cancellation_scenario_library/<timestamp>/
```

G-B 运行前必须确认，因为它会运行 MATLAB 并生成 `outputs/`。

## 3. 阶段 G 包含内容

阶段 G 包含：

1. 多个取消时刻：早期、中期、后期。
2. 多类取消订单：随机工件、短工件、长工件、关键路径工件、非关键工件。
3. 多个随机种子。
4. 多个小中规模样例数据的扩展入口。
5. 场景库生成测试。
6. 场景库实验汇总测试。
7. 场景库实验脚本入口。

## 4. 阶段 G 不包含内容

阶段 G 不加入：

1. 机器故障。
2. 新订单插入。
3. AGV 故障。
4. 多订单连续取消。
5. 强化学习。
6. 全局最优证明。
7. 论文级大规模结论。

这些内容可以作为后续阶段扩展，但不能混入阶段 G 的场景库主线。

## 5. 运行边界

阶段 G 的运行边界：

1. 场景库生成函数不写 `outputs/`。
2. 场景库测试不写 `outputs/`。
3. 场景库实验脚本会写 `outputs/`。
4. 运行场景库实验前需要确认。
5. 输出目录必须使用相对路径和 timestamp 子目录。
6. 不覆盖历史输出目录。
7. 不修改 `raw_code/`。

## 6. 验收标准

Step G1 的验收标准：

1. 已明确阶段 G 包含 G-A 和 G-B。
2. 已明确场景库生成不写 `outputs/`。
3. 已明确场景库实验会写 `outputs/`。
4. 已明确运行实验前需要确认。
5. 已明确不加入机器故障。
6. 已明确不加入新订单插入。
7. 已明确不加入强化学习。
8. 已明确不声称全局最优。
9. README 已挂阶段 G 范围确认入口。
10. 本步骤未运行 MATLAB。
11. 本步骤未生成 `outputs/`。
12. 本步骤未修改 `raw_code/`。

## 7. 下一步

下一步进入：

```text
Step G2：定义场景库配置
```

建议新增：

```text
configs/order_cancellation_scenario_library.yaml
```

## 8. Step G2：场景库配置

已新增：

```text
configs/order_cancellation_scenario_library.yaml
```

当前配置：

```yaml
datasets:
  - data_sample/Mk01.fjs

cancel_policy: cancel_unstarted_operations_only

time_windows:
  - name: early
    cancel_time_ratio: 0.25
  - name: middle
    cancel_time_ratio: 0.50
  - name: late
    cancel_time_ratio: 0.75

job_categories:
  - random
  - short
  - long
  - critical
  - noncritical

seeds: [1, 2, 3]

output_base_dir: outputs/order_cancellation_scenario_library
```

配置说明：

1. `datasets` 使用相对路径，当前先从 `data_sample/Mk01.fjs` 开始。
2. `cancel_policy` 延续阶段 B-F 的 `cancel_unstarted_operations_only`。
3. `time_windows` 覆盖 early、middle、late 三个取消时刻。
4. `job_categories` 覆盖 random、short、long、critical、noncritical。
5. `seeds` 明确使用 `[1, 2, 3]`。
6. `output_base_dir` 使用相对路径，供 G-B 场景库实验脚本写入 timestamp 输出目录。

Step G2 验收状态：

1. 数据集路径是相对路径。
2. 取消时刻覆盖 early、middle、late。
3. 工件类别覆盖 random、short、long、critical、noncritical。
4. 多 seed 已明确。
5. 输出目录是相对路径。
6. 本步骤未运行 MATLAB。
7. 本步骤未生成 `outputs/`。
8. 本步骤未修改 `raw_code/`。

下一步进入：

```text
Step G3：定义场景结构
```

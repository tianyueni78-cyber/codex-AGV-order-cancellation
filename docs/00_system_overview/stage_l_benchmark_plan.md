# 阶段 L 项目报告：大规模与统计验证

本文档是阶段 L 的主入口。阶段 L 的目标是验证订单取消处理策略在更多实例、更多场景和更多随机种子下是否稳定。

阶段 L 是验证阶段，不新增主算法。它承接阶段 B-K 已经形成的状态提取、候选生成、评价、混合策略和自适应权重流程，只扩展实验实例、场景、随机种子和统计汇总。

## 1. Step L1：阶段 L 范围确认

Step L1 的目标是明确阶段 L 的边界，防止验证阶段变成新的算法开发阶段。

阶段 L 允许做的事情：

1. 扩展 FJSP-AGV 数据实例。
2. 扩展订单取消场景。
3. 扩展随机种子数量。
4. 汇总均值、标准差、胜率和不可行率。
5. 记录每个实例、每个场景和每个 seed 的原始结果。
6. 基于统计范围形成稳定性结论。

阶段 L 不允许做的事情：

1. 不新增机器故障逻辑。
2. 不新增完整插单算法。
3. 不新增强化学习。
4. 不重写局部修复逻辑。
5. 不重写完全重调度逻辑。
6. 不重写评价函数。
7. 不重写自适应权重逻辑。
8. 不声称全局最优。

阶段 L 的验证对象是已有订单取消处理链路：

```text
订单取消事件
  -> 状态提取
  -> 局部修复候选
  -> 完全重调度候选
  -> 评价指标
  -> 混合或自适应策略选择
  -> 多实例、多场景、多 seed 统计验证
```

## 2. Step L1 验收结果

| 验收项 | 结果 |
|---|---|
| 不新增机器故障逻辑 | 通过，阶段 L 只验证订单取消策略 |
| 不新增完整插单算法 | 通过，`insert_order` 仍保持阶段 J 的接口预留状态 |
| 不新增强化学习 | 通过，阶段 L 不训练模型，不引入 RL |
| 不重写局部修复、完全重调度、评价或自适应权重逻辑 | 通过，阶段 L 复用阶段 B-K 已有链路 |
| 只扩展实例、场景、随机种子和统计汇总 | 通过，阶段 L 的新增工作限定在 benchmark 配置、运行入口和汇总分析 |

Step L1 完成标志：阶段 L 已被限定为“大规模与统计验证”阶段。后续可以进入 Step L2：定义 benchmark 配置。

## 3. Step L2：定义 benchmark 配置

Step L2 新增 benchmark 总控配置：

```text
configs/order_cancellation_benchmark.yaml
```

配置内容：

```yaml
datasets:
  - data_sample/Mk01.fjs

scenario_library_config: configs/order_cancellation_scenario_library.yaml

strategies:
  - fixed_weight
  - adaptive_weight

seeds: [1, 2, 3, 4, 5]

max_runtime_minutes: 30
output_base_dir: outputs/order_cancellation_benchmark
```

字段含义：

| 字段 | 含义 |
|---|---|
| `datasets` | benchmark 要遍历的数据实例列表，第一版先保留 `data_sample/Mk01.fjs`，后续可追加更多相对路径实例 |
| `scenario_library_config` | 复用阶段 G 场景库配置，避免在 benchmark 中重复定义场景生成规则 |
| `strategies` | 需要比较的策略，当前包含固定权重 `fixed_weight` 和自适应权重 `adaptive_weight` |
| `seeds` | benchmark 使用的随机种子列表，第一版为 5 个 seed |
| `max_runtime_minutes` | 运行预算字段，后续脚本应在超过预算时停止或缩小实验规模并记录原因 |
| `output_base_dir` | benchmark 输出根目录，后续运行脚本应写入 timestamp 子目录 |

阶段 L2 只定义配置，不运行 benchmark，不写 `outputs/`。

## 4. Step L2 验收结果

| 验收项 | 结果 |
|---|---|
| 每个实例路径都是相对路径 | 通过，当前为 `data_sample/Mk01.fjs` |
| 每个实例有配置记录 | 通过，实例统一记录在 `datasets` 列表中 |
| 随机种子明确 | 通过，`seeds: [1, 2, 3, 4, 5]` |
| 是否启用固定权重、自适应权重明确 | 通过，`strategies` 包含 `fixed_weight` 和 `adaptive_weight` |
| 有运行预算字段 | 通过，`max_runtime_minutes: 30` |

Step L2 完成标志：阶段 L benchmark 配置入口已经建立。后续可以进入 Step L3：定义 benchmark 单次运行结果结构。

## 5. 支持文档入口

README 只挂阶段 L 主文档；阶段 L 依赖的上游文档可从这里进入。

| 文档 | 和阶段 L 的关系 |
|---|---|
| [阶段 G：场景库项目报告](stage_g_project_report.md) | 阶段 L 的场景扩展应复用阶段 G 的场景库思想 |
| [阶段 H：混合修复策略报告](stage_h_hybrid_policy_report.md) | 阶段 L 要验证混合策略触发规则是否稳定 |
| [阶段 K：自适应策略选择](stage_k_adaptive_strategy_plan.md) | 阶段 L 要验证自适应权重规则在更多实例和 seed 下是否稳定 |
| [阶段 E：评价与策略选择](stage_e_work_record.md) | 阶段 L 的统计指标仍来自阶段 E 的 Cmax_delta、SD、TD、energy_delta 和 Y |
| [阶段 G-N 后续路线图](post_stage_f_flexible_dispatch_roadmap.md) | 说明阶段 L 在长期路线中负责稳定性验证，而不是算法扩展 |

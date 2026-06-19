# 源代码迁移导读

本文档记录从 `tianyueni78-cyber/codex-AGV` 迁移了哪些内容，以及这些内容在订单取消项目中如何使用。

## 1. 迁移来源

源仓库：

```text
https://github.com/tianyueni78-cyber/codex-AGV
```

目标仓库：

```text
https://github.com/tianyueni78-cyber/codex-AGV-order-cancellation
```

迁移目的：

```text
在新增订单取消功能之前，先复用原 FJSP-AGV 正常调度基线。
```

## 2. 已迁移目录

| 路径 | 原项目作用 | 本项目作用 |
|---|---|---|
| `raw_code/` | 原始 MATLAB 归档代码和 baseline 行为参考 | 只读基线，不修改 |
| `src/` | 数据、解码、评价、搜索、指标和可视化等重构源码 | 后续订单取消包装函数的主要基础 |
| `configs/` | small、medium、formal、independent 和 baseline 配置 | 后续订单取消配置的起点 |
| `scripts/` | 可复现 MATLAB 运行入口 | 后续订单取消运行脚本的起点 |
| `tests/` | 轻量测试、静态检查和 raw 对照测试 | 后续订单取消烟雾测试的起点 |
| `data_sample/` | 最小样例数据 | 第一批烟雾测试数据 |
| `docs/` | 原项目源码地图、复现步骤和工程说明 | 理解迁移代码的背景资料 |

`outputs/` 没有迁移。新生成的输出应写入本地 `outputs/`，并且不提交 Git。

## 3. 源码层说明

### `src/data/`

负责读取 FJSP、机器和 AGV 数据。

重要文件：

```text
src/data/read_fjsp.m
src/data/read_machine_data.m
src/data/read_agv_data.m
```

订单取消中的用途：

```text
保持不变，复用为基线数据读取层。
```

### `src/encoding/`

负责构造和校验染色体结构。

订单取消中的用途：

```text
在取消事件发生后，对剩余未完成工序复用原编码语义。
在取消子问题契约明确前，不全局修改编码层。
```

### `src/decoding/`

负责将染色体解码为机器和 AGV 调度计划。

订单取消中的用途：

```text
后续很可能通过包装函数复用：冻结已完成任务，排除被取消订单未完成工序，
再对剩余工序解码。
```

### `src/evaluation/`

负责评价解码后的调度计划和目标函数。

订单取消中的用途：

```text
复用最大完工时间和能耗计算。
订单取消专用扰动指标应单独新增，不直接塞进原评价层。
```

### `src/search/`

包含 independent NSGA-II 搜索逻辑。

订单取消中的用途：

```text
当订单取消问题被转化为“剩余未完成工序重调度”后，
作为第一版完全重调度搜索基线。
```

### `src/metrics/`

负责 Pareto 和多目标结果质量指标。

订单取消中的用途：

```text
复用 Pareto 结果汇总。
后续在独立模块中新增 Cmax_delta、SD、TD 和 Y 等订单取消策略指标。
```

### `src/visualization/`

负责生成甘特图和结果图等可视化产物。

订单取消中的用途：

```text
后续用于对比原计划、局部修复计划和完全重调度计划。
```

## 4. 后续建议新增模块

在确认基线调用链之前，不要急着实现这些文件。

建议未来位置：

```text
src/cancellation/create_order_cancellation_event.m
src/cancellation/validate_order_cancellation_event.m
src/cancellation/extract_cancellation_state.m
src/rescheduling/build_order_cancel_local_repair.m
src/rescheduling/build_order_cancel_frozen_problem.m
src/rescheduling/decode_order_cancel_complete_reschedule.m
src/evaluation/evaluate_order_cancel_candidate.m
```

建议未来脚本：

```text
scripts/run_order_cancel_state_smoke.m
scripts/run_order_cancel_local_repair_smoke.m
scripts/run_order_cancel_complete_reschedule_smoke.m
scripts/run_order_cancel_strategy_comparison.m
```

建议未来测试：

```text
tests/test_order_cancellation_event.m
tests/test_order_cancellation_state.m
tests/test_order_cancel_local_repair.m
tests/test_order_cancel_strategy_metrics.m
```

## 5. 第一个安全下一步

第一个实现任务应保持静态、窄范围：

```text
识别迁移后的 codex-AGV 正常调度调用链。
不运行 MATLAB。
不生成 outputs。
不修改 raw_code/。
```

期望证据：

```text
一份简短文档或 README 小节，列出订单取消将复用的数据读取、解码、
AGV 调度、评价和 NSGA-II 入口。
```


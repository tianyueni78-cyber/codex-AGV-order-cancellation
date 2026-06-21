# 阶段 A 工作记录：源码迁移与基线理解

本文档记录阶段 A 已完成的工作、验证方式和边界。阶段 A 只做源码迁移确认与正常调度调用链理解，不实现订单取消算法。

## 1. 阶段目标

阶段 A 的目标是：

```text
保留原 codex-AGV 正常调度基线，并识别正常调度调用链。
```

## 2. 已确认内容

阶段 A 已确认以下迁移目录和基础文档：

```text
raw_code/
src/
configs/
scripts/
tests/
data_sample/
docs/
```

阶段 A 的核心导读文档：

```text
docs/00_system_overview/source_code_migration_map.md
docs/00_system_overview/baseline_call_chain_map.md
```

其中：

1. `source_code_migration_map.md` 说明原 `codex-AGV` 源码迁移后各目录和模块用途。
2. `baseline_call_chain_map.md` 说明正常调度如何从脚本、配置、数据读取、编码、解码、AGV 调度、评价和搜索层进入。

## 3. 阶段 A 工作范围

阶段 A 已完成：

1. 确认原 `codex-AGV` 源码目录已经迁移到新仓库。
2. 阅读项目规则文档，确认订单取消与机器故障分离。
3. 查找正常调度入口，区分 small、independent 和 formal 相关入口。
4. 梳理 FJSP、机器和 AGV 数据读取链路。
5. 梳理编码、解码和 AGV 调度链路。
6. 梳理评价、指标和搜索链路。
7. 写入基线调用链导读文档。
8. 在 README 中增加基线调用链入口。

阶段 A 不包含：

1. 不新增订单取消算法。
2. 不新增局部修复逻辑。
3. 不新增完全重调度逻辑。
4. 不运行 MATLAB。
5. 不生成 `outputs/`。
6. 不修改 `raw_code/`。

## 4. 验证方式

阶段 A 使用静态验收：

1. 检查迁移目录是否存在。
2. 检查关键导读文档是否存在。
3. 检查 README 是否挂载关键导读入口。
4. 检查没有越界新增订单取消算法。
5. 检查 `raw_code/` 没有修改。

阶段 A 不运行 MATLAB，不生成实验输出。

## 5. 阶段 A 完成标志

阶段 A 完成标志是：

```text
原正常调度链路已经写清楚，后续可以进入阶段 B：订单取消事件与状态提取。
```

## 6. 后续入口

阶段 B 从订单取消事件与状态提取开始，入口文档为：

```text
docs/00_system_overview/stage_b_work_record.md
```

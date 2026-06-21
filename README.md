# FJSP-AGV 订单取消动态重调度

本仓库用于在原 `codex-AGV` 的 FJSP-AGV 正常调度代码基础上，研究订单取消发生后的动态重调度问题。

第一阶段研究范围刻意收窄：从一个已经生成的正常 FJSP-AGV 调度计划出发，在已知时刻取消一个订单，修复或重建剩余订单的计划，并比较效率收益与计划扰动。

## 1. 问题范围

订单取消被视为“任务集合变化”问题，不是“机器资源不可用”问题。

第一阶段包含：

1. 以原 `codex-AGV` 的数据读取、解码、AGV 调度、能耗计算和 NSGA-II 代码为基础。
2. 建模一个取消时刻已知的订单取消事件。
3. 冻结取消时刻以前已经完成的任务。
4. 删除被取消订单尚未完成的工序和相关 AGV 运输任务。
5. 为剩余订单生成候选重调度方案。
6. 评价最大完工时间、总能耗和对原计划的扰动。

第一阶段不包含：

1. 机器故障或机器维修时间窗。
2. 多个订单连续取消。
3. 新订单插入。
4. AGV 故障。
5. 加工时间随机变化或取消时刻不确定。
6. 全局最优解证明。

这些内容不是全部“不需要”，而是不进入第一版主线。多个订单连续取消和新订单插入可以作为后续订单变更扩展；机器故障和 AGV 故障应等订单取消闭环稳定后再进入多扰动统一框架；强化学习可作为后续自适应策略选择方向；全局最优证明通常不作为本项目结束条件。

机器故障研究应与本项目保持分离。后续可以扩展为多扰动统一框架，但本项目第一阶段先单独研究订单取消。

## 2. 借鉴论文

本项目借鉴动态重调度论文中的思想，并将其改造到 FJSP-AGV 订单取消场景中。

1. Rener、Salassa 和 T'kindt 的论文：`Single machine rescheduling for new orders: properties and complexity results`，arXiv:2307.14876。

   可借鉴思想：动态事件发生后，新计划不仅要优化生产目标，还要控制对原有任务的扰动。该论文用旧任务完成时间偏移来限制扰动。对应到订单取消问题中，可以度量未取消订单相对原计划的完成时间偏移。

2. Tang 等人的论文：`Deep Reinforcement Learning for Flexible Job Shop Scheduling with Random Job Arrivals`，arXiv:2605.22773。

   可借鉴思想：动态调度可以建模为事件触发流程。本项目第一阶段不使用强化学习，但保留事件触发结构：取消事件、状态提取、候选方案生成、评价和选择。

## 3. 调度思想

计划中的研究链路为：

```text
正常 FJSP-AGV 调度计划
  -> 订单取消事件
  -> 取消时刻状态提取
  -> 局部修复候选方案
  -> 完全重调度候选方案
  -> 指标计算
  -> 最终策略选择
```

项目计划同时生成两类候选方案。

### 3.1 局部修复

局部修复尽量保持原计划不变：

1. 删除被取消订单尚未完成的工序。
2. 删除相关尚未执行的 AGV 运输任务。
3. 在可行时保持剩余订单的原工序顺序、机器选择和 AGV 选择。
4. 仅在约束仍然满足时压缩空闲时间或左移剩余任务。

该策略优先保证计划稳定性和低扰动。

### 3.2 完全重调度

完全重调度冻结已经执行的任务，只对未取消订单中尚未完成的工序重新优化。

第一版实现应尽量复用原项目中的 independent NSGA-II、编码、解码、AGV 调度和评价层。

该策略可能改善最终完工时间和能耗，但会带来更多机器分配和任务时间变化。

## 4. 算法计划

第一版算法基线使用 `codex-AGV` 已有的 independent NSGA-II 搜索。

初始优化目标：

1. 最终卸载完工时间。
2. 总能耗。

订单取消重调度补充指标：

```text
Cmax_delta = 候选最终卸载时间 - 原计划最终卸载时间
SD         = 剩余工序中机器分配发生变化的数量
TD         = 剩余订单完成时间总偏移
Y          = omega1*Cmax_delta + omega2*SD + omega3*TD
```

其中 `TD` 是从新订单重调度论文中借鉴的核心思想：动态重调度不能只看新目标，也要控制原计划的变化。在本项目中，“旧任务”对应未被取消的剩余订单。

第一版不声称全局最优。结果只表示在给定种群规模、迭代代数、随机种子和权重设置下搜索到的较优候选方案。

## 5. 工作计划

### 阶段 A：源码迁移与基线理解

目标：保留原正常调度基线，并识别正常调度调用链。

验收标准：

1. 已迁移原 `codex-AGV` 源码目录。
2. 有源代码导读文档说明数据、编码、解码、搜索、评价、指标、可视化、脚本、测试和原始代码的用途。
3. 暂不新增订单取消算法。

### 阶段 B：订单取消事件与状态提取

目标：定义最小订单取消事件，并提取 `cancel_time` 时刻的调度状态。

计划事件字段：

```matlab
cancel.job_id
cancel.cancel_time
cancel.policy
```

第一版策略：

```text
cancel_unstarted_operations_only
```

验收标准：

1. 能识别已完成、正在加工和尚未开工的工序。
2. 能列出被取消订单尚未完成的工序。
3. 能在样例数据上通过烟雾测试。

### 阶段 C：局部修复候选方案

目标：删除取消订单未完成任务，并构造可行的局部修复计划。

验收标准：

1. 被取消订单的未完成工序不再出现在候选计划中。
2. 剩余工序满足工件工序顺序。
3. 能识别并拒绝机器和 AGV 时间冲突。

### 阶段 D：完全重调度候选方案

目标：复用 independent 解码和搜索层，对剩余未完成工序重新调度。

验收标准：

1. 冻结任务保持不变。
2. 被取消的未完成任务被排除。
3. 剩余任务能解码为可行的 FJSP-AGV 调度计划。

### 阶段 E：评价与策略选择

目标：比较局部修复和完全重调度。

验收标准：

1. 能计算 `Cmax_delta`、`SD`、`TD`、能耗和 `Y`。
2. 最终选择 `Y` 更小的候选方案。
3. 结果写入 `outputs/`。

### 阶段 F：小规模实验

目标：运行一组订单取消场景。

最小场景：

1. 早期取消。
2. 中期取消。
3. 后期取消。

验收标准：

1. 每个场景同时报告局部修复和完全重调度。
2. 每个场景均通过调度约束检查。
3. 多随机种子汇总后再形成研究结论。

## 6. 仓库结构

```text
raw_code/       原 codex-AGV 归档代码，只读基线
src/            从 codex-AGV 迁移的重构源码
configs/        MATLAB 配置文件
scripts/        可复现实验入口
tests/          轻量测试和静态检查
data_sample/    最小样例数据
docs/           源码导读、计划和复现说明
outputs/        生成的输出和日志，不提交 Git
```

## 7. 关键文档入口

后续新增重要项目文档时，必须同步在本节增加入口，避免文档散落后找不到。

| 文档 | 内容 |
|---|---|
| [项目目标与分阶段工作流](docs/00_system_overview/project_goal_workflow.md) | 项目结束目标、阶段 A-F、小目标验收标准、scope 和 token 控制 |
| [源代码迁移导读](docs/00_system_overview/source_code_migration_map.md) | 从原 `codex-AGV` 迁移了哪些源码，以及各层在订单取消项目中的用途 |
| [基线调用链导读](docs/00_system_overview/baseline_call_chain_map.md) | 正常调度入口、配置、数据读取、编码、解码、AGV、评价和搜索链路 |
| [阶段 A 工作记录](docs/00_system_overview/stage_a_work_record.md) | 源码迁移、基线理解、正常调度调用链、阶段 A 验收和阶段 B 入口说明 |
| [订单取消状态分类契约](docs/00_system_overview/order_cancellation_state_contract.md) | 阶段 B 的已完成、正在加工、尚未开工分类规则和边界条件 |
| [阶段 B 工作记录](docs/00_system_overview/stage_b_work_record.md) | 订单取消事件、状态提取、测试入口、smoke 结果和阶段 B 验收记录 |
| [阶段 C 局部修复输入契约](docs/00_system_overview/stage_c_local_repair_contract.md) | 局部修复的输入、支持策略、拒绝条件和禁止行为 |
| [阶段 C 工作记录](docs/00_system_overview/stage_c_work_record.md) | 局部修复候选、删除式修复、可行性检查、测试入口和 smoke 结果 |
| [阶段 D 完全重调度输入与输出契约](docs/00_system_overview/stage_d_complete_rescheduling_contract.md) | 完全重调度候选的输入、输出、冻结任务、重调度任务、排除规则和拒绝条件 |
| [阶段 D 工作记录](docs/00_system_overview/stage_d_work_record.md) | 完全重调度候选、independent 解码复用、新增文件、测试入口和阶段 E 入口说明 |
| [阶段 E 评价与策略选择输入契约](docs/00_system_overview/stage_e_evaluation_contract.md) | 阶段 E 的输入、候选来源、前置可行性、baseline 和禁止行为 |
| [阶段 E 工作记录](docs/00_system_overview/stage_e_work_record.md) | 阶段 E 指标定义、Y、策略选择、新增文件、测试入口、outputs 含义和阶段 F 入口说明 |
| [阶段 F 小规模实验工作计划](docs/00_system_overview/stage_f_work_plan.md) | 阶段 F 的早期/中期/后期取消场景、多随机种子、小规模实验输出和验收标准 |
| [阶段 F Step F1 实验范围确认](docs/00_system_overview/stage_f_scope_contract.md) | 阶段 F 只做单订单取消小规模实验，不加入机器故障、插单、连续取消、强化学习或全局最优证明 |
| [阶段 F 之后灵活调度路线图](docs/00_system_overview/post_stage_f_flexible_dispatch_roadmap.md) | 阶段 G-N 的后续扩展路线，说明如何从第一版闭环走向灵活订单取消调度 |
| [阶段 F Step F9 结果分析模板](docs/00_system_overview/stage_f_result_analysis_template.md) | 小规模实验结果分析口径，规定如何基于多随机种子输出形成第一版结论 |
| [阶段 F 工作记录](docs/00_system_overview/stage_f_work_record.md) | 阶段 F 小规模实验的配置、场景、种子、入口、输出、当前结果状态、局限和后续扩展 |
| [项目文件导览](docs/00_system_overview/repository_file_guide.md) | 原迁移项目的目录和文件用途说明 |
| [入口地图](docs/00_system_overview/entrypoint_map.md) | 原迁移项目中常用任务应查看的入口 |

## 8. Agent 工作规则

本仓库的工作约束见 `AGENTS.md`。

核心规则：

1. 不修改 `raw_code/`。
2. 每次只做一个小任务。
3. 默认先做静态分析。
4. 运行 MATLAB、启动实验或生成 outputs 前先确认。
5. 订单取消代码与机器故障代码保持分离。
6. 通过 configs、scripts、tests 和 outputs 保证可复现。

## 9. 当前状态

当前项目状态：

```text
阶段 A-E 已形成第一版静态文档、候选生成、评价和策略选择链路。
阶段 E 已在 Mk01 小样例 smoke 中跑通评价与策略选择。
下一步进入阶段 F：早期/中期/后期取消的小规模实验。
```

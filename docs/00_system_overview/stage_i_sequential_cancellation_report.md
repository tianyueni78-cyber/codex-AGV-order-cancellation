# 阶段 I 项目报告：多订单连续取消

本文档是阶段 I 的唯一主入口。阶段 I 目标是支持多个订单按时间顺序连续取消，验证状态回放、重复修复、重复重调度和已取消订单不回流能力。

阶段 I 不加入机器故障、新订单插入、连续加工抢占或强化学习。

## 0. 项目报告总览

本节是阶段 I 的项目报告摘要；后面的 Step I1-I9 保留为可追溯的实现记录。阶段 I 的核心不是并行讨论很多新扰动，而是在阶段 B-H 已经闭环的基础上，验证“订单取消可以连续发生时，系统能否按时间顺序重复处理”。

### 0.1 阶段 I 目标

阶段 I 要解决的问题是多订单连续取消：

- 支持至少 2 个取消事件按 `cancel_time` 升序执行。
- 每次事件后都生成局部修复候选、完全重调度候选和混合策略最终选择。
- 后一次事件的状态提取基于前一次最终选择计划。
- 已取消订单的未完成机器工序和 AGV 任务不能在后续计划中回流。
- 每轮计划必须通过约束检查，或明确记录不可行/unsupported 原因。

### 0.2 输入契约

阶段 I 主流程接收：

```matlab
problem
machineData
agvData
initialSchedule
cancelEvents
config
```

第一轮以 `initialSchedule` 为基线；后续轮次以上一轮最终选择的 `machineTable` 和 `AGVTable` 作为新基线。

### 0.3 连续取消事件结构

每个取消事件至少包含：

```matlab
cancelEvents(i).event_id
cancelEvents(i).job_id
cancelEvents(i).cancel_time
cancelEvents(i).policy
```

第一版只支持 `cancel_unstarted_operations_only`。相同 `job_id` 重复取消会被拒绝或记录为 unsupported，避免同一订单被重复处理。

### 0.4 工作流程

阶段 I 对每个取消事件重复调用已有链路：

1. 校验并按 `cancel_time` 排序取消事件。
2. 设置 `currentSchedule = initialSchedule`。
3. 基于 `currentSchedule` 调用阶段 B 提取取消状态。
4. 调用阶段 C 生成局部修复候选。
5. 调用阶段 D 生成完全重调度候选。
6. 调用阶段 E 评价两个候选。
7. 调用阶段 H 混合策略选择最终计划。
8. 把最终计划更新为下一轮 `currentSchedule`。
9. 把当前 `job_id` 加入已取消订单集合，防止后续回流。

### 0.5 已取消订单不回流规则

阶段 I 维护 `cancelledJobSet`。每轮结束后检查：

- 已取消订单未完成机器工序不能出现在后续 `machineTable`。
- 已取消订单未执行 AGV 任务不能出现在后续 `AGVTable`。
- 如果发现回流，当前轮结果标记为不可行，并记录原因。

已完成历史任务保留，因为它们代表取消前已经发生的真实加工和运输。

### 0.6 unsupported 处理规则

如果某次取消命中正在加工工序或正在运输任务，第一版不做抢占、不做工序中断、不做 AGV 中途改派。该事件被记录为 unsupported；默认建议停止后续事件，避免在不完整状态上继续推导。

### 0.7 新增文件清单

| 文件 | 用途 |
|---|---|
| `src/cancellation/validate_sequential_cancellation_events.m` | 校验连续取消事件列表 |
| `src/cancellation/run_sequential_order_cancellations.m` | 连续取消主流程 |
| `tests/test_order_cancellation_sequential_event_validation.m` | 连续取消事件校验测试 |
| `tests/test_order_cancellation_sequential_events.m` | 连续取消主流程测试 |
| `scripts/run_order_cancellation_sequential_smoke.m` | 样例数据 smoke 脚本 |
| `docs/00_system_overview/stage_i_sequential_cancellation_report.md` | 阶段 I 唯一主报告 |

### 0.8 测试入口和结果

测试入口：

```matlab
run('tests/test_order_cancellation_sequential_event_validation.m')
run('tests/test_order_cancellation_sequential_events.m')
```

已收到的测试输出：

```text
test_order_cancellation_sequential_events passed
>>
```

该结果说明：最小构造数据下，连续取消主流程已经能通过核心断言，包括按时间处理事件、每轮产生最终选择、后续轮次基于上一轮最终计划、已取消订单不回流，以及最终约束检查通过。

### 0.9 Smoke 入口和结果

Smoke 入口：

```matlab
run('scripts/run_order_cancellation_sequential_smoke.m')
```

当前报告尚未写入 smoke 输出，因为还没有收到该脚本的实际运行结果。收到输出后，需要补充每轮取消事件、局部修复可行性、完全重调度可行性、混合策略选择原因和最终计划约束检查结果。

### 0.10 局限

阶段 I 只处理连续订单取消，不处理新订单插入。它也不加入机器故障、AGV 故障、强化学习或全局最优证明。

当前连续取消仍建立在第一版策略 `cancel_unstarted_operations_only` 上；正在加工和正在运输的取消先作为 unsupported 处理。阶段 I 的目标是验证连续取消链路可运行，不是给出论文级最终算法结论。

### 0.11 阶段 J 入口

阶段 J 建议进入“订单变更统一框架”：把订单取消和新订单插入都抽象为任务集合变化。阶段 I 的输出可以作为取消侧的基础，但阶段 J 才开始讨论新订单插入；阶段 I 本身不实现新订单插入。

## 1. 阶段 I 目标

阶段 I 的目标是：

```text
支持多个订单按 cancel_time 顺序连续取消，
每次取消后以上一次最终选择计划作为新基线，
验证阶段 B-H 链路能否重复运行。
```

阶段 I 不是重新设计调度器，而是在已有链路上做连续事件回放：

- 阶段 B：提取当前取消时刻状态。
- 阶段 C：生成局部修复候选。
- 阶段 D：生成完全重调度候选。
- 阶段 E：评价两个候选。
- 阶段 H：使用混合策略选择最终计划。
- 阶段 I：把上一轮最终计划作为下一轮新基线，继续处理下一个取消事件。

## 2. Step I1：输入契约

连续取消主函数建议输入：

```matlab
problem
machineData
agvData
initialSchedule
cancelEvents
config
```

建议主函数后续命名为：

```matlab
result = run_sequential_order_cancellations( ...
    problem, machineData, agvData, initialSchedule, cancelEvents, config)
```

## 3. 输入字段说明

| 输入 | 含义 | 阶段 I 用途 |
|---|---|---|
| `problem` | FJSP-AGV 问题实例 | 提供工件、工序、机器和基础问题信息 |
| `machineData` | 机器距离和能耗等数据 | 传入阶段 D/E，支持重调度和评价 |
| `agvData` | AGV 数量、速度和能耗等数据 | 传入阶段 D/E，支持运输调度和评价 |
| `initialSchedule` | 第一轮取消前的基线计划 | 第一次取消事件的状态提取基线 |
| `cancelEvents` | 多个取消事件列表 | 按 `cancel_time` 排序后逐个处理 |
| `config` | 评价、混合策略和阶段 I 控制配置 | 控制评价权重、混合策略阈值和 unsupported 处理方式 |

第一轮使用 `initialSchedule` 作为基线。

后续轮次使用上一轮最终选择的候选计划作为新基线。

## 4. Step I2：连续取消事件列表结构

`cancelEvents` 用于统一描述多个按时间发生的订单取消事件。每个事件必须包含：

```matlab
cancelEvents(i).event_id
cancelEvents(i).job_id
cancelEvents(i).cancel_time
cancelEvents(i).policy
```

字段含义：

| 字段 | 含义 | 第一版要求 |
|---|---|---|
| `event_id` | 连续取消事件编号 | 用于追踪第几次取消，建议唯一 |
| `job_id` | 被取消订单编号 | 必须是有效工件编号 |
| `cancel_time` | 取消发生时刻 | 必须非负 |
| `policy` | 取消处理策略 | 当前只支持 `cancel_unstarted_operations_only` |

当前第一版只支持：

```text
cancel_unstarted_operations_only
```

也就是只取消尚未开工的工序。若连续取消过程中出现正在加工任务取消，先记录为 `unsupported`，不扩展抢占或中断加工逻辑。

事件列表规则：

1. `cancelEvents` 至少包含 2 个取消事件。
2. 主流程需要按 `cancel_time` 升序处理事件。
3. 如果输入时不是升序，后续实现应在主函数或校验函数中稳定排序。
4. 相同 `job_id` 重复取消应拒绝，或标记为无效事件。
5. `cancel_time` 必须非负。
6. `policy` 当前只允许 `cancel_unstarted_operations_only`。

## 5. 基线更新规则

阶段 I 的关键规则是基线回放：

1. `currentSchedule = initialSchedule`。
2. 按 `cancel_time` 升序处理 `cancelEvents`。
3. 每次事件都基于 `currentSchedule` 提取状态。
4. 每次事件都生成局部修复候选和完全重调度候选。
5. 每次事件都调用阶段 E/H 评价并选择最终策略。
6. 如果本轮选择成功，则 `currentSchedule = decision.selected_candidate`。
7. 下一轮取消事件基于更新后的 `currentSchedule` 继续运行。

因此，后一次取消不是重新回到原始正常调度计划，而是接着前一次订单取消后的最终计划继续处理。

## 6. 边界和不做内容

阶段 I 当前明确不做：

- 机器故障。
- AGV 故障。
- 新订单插入。
- 多扰动混合。
- 强化学习。
- 全局最优证明。
- 正在加工任务取消的抢占或中断加工逻辑。

如果连续事件中出现正在加工工序或正在运输任务取消，第一版只记录为 `unsupported`。

## 7. Step I3：校验连续取消事件

阶段 I 新增连续取消事件校验函数：

```text
src/cancellation/validate_sequential_cancellation_events.m
```

建议调用方式：

```matlab
[isValid, sortedEvents, report] = ...
    validate_sequential_cancellation_events(cancelEvents, problem)
```

校验职责：

- 检查 `cancelEvents` 是结构体数组。
- 检查事件数量至少为 2。
- 检查每个事件包含 `event_id`、`job_id`、`cancel_time` 和 `policy`。
- 复用单事件校验逻辑，拒绝非法 `job_id`、非法 `cancel_time` 和未知 `policy`。
- 按 `cancel_time` 升序稳定排序；相同 `cancel_time` 保留输入顺序。
- 重复取消同一 `job_id` 在第一版中直接拒绝，并在 `report.unsupported_events` 中记录原因。

测试入口：

```matlab
run('tests/test_order_cancellation_sequential_event_validation.m')
```

该测试只验证事件校验和排序逻辑，不写 `outputs/`，不运行完整调度实验。

Step I3 完成时应满足：

- 非法 `job_id` 被拒绝。
- 非法 `cancel_time` 被拒绝。
- 未知 `policy` 被拒绝。
- 重复取消同一订单被拒绝并记录为 unsupported。
- 事件排序稳定可复现。

## 8. Step I4：连续取消主流程函数

阶段 I 新增连续取消主流程函数：

```text
src/cancellation/run_sequential_order_cancellations.m
```

建议调用方式：

```matlab
result = run_sequential_order_cancellations( ...
    problem, machineData, agvData, initialSchedule, cancelEvents, config)
```

主流程：

1. 调用 `validate_sequential_cancellation_events` 校验并排序 `cancelEvents`。
2. 设置 `currentSchedule = initialSchedule`。
3. 设置 `cancelledJobSet = []`。
4. 按排序后的事件逐个处理：
   - 检查当前 `job_id` 是否已经取消。
   - 基于 `currentSchedule` 调用阶段 B 状态提取。
   - 调用阶段 C 构造局部修复候选。
   - 调用阶段 D 构造完全重调度候选。
   - 调用阶段 E 评价两个候选。
   - 调用阶段 H 混合策略选择。
   - 如果选择成功，将 `decision.selected_candidate` 作为下一轮 `currentSchedule`。
   - 将当前取消订单加入 `cancelledJobSet`。
5. 返回每一轮 `event_results`、`finalSchedule` 和 `cancelledJobSet`。

第一版完全重调度候选复用当前项目的 first-choice chromosome 构造方式，不启动 NSGA-II 正式搜索。

Step I4 完成时应满足：

- 每次事件后都有局部修复、完全重调度和最终选择记录。
- 后一次状态提取基于前一次选择后的计划。
- 早先取消订单不会在后续计划中回流。
- 函数不写 `outputs/`，只做函数级逻辑。

## 9. Step I5：维护已取消订单集合

阶段 I 主流程维护：

```matlab
cancelledJobSet
cancelledRecords
```

其中：

- `cancelledJobSet` 记录已经成功取消的 `job_id`。
- `cancelledRecords` 记录已经成功取消的完整事件，包括 `event_id`、`job_id`、`cancel_time` 和 `policy`。

防回流检查规则：

1. 当前事件处理时，将历史取消事件和当前取消事件合并为 `cancelledRecordsForEvent`。
2. 阶段 C 生成局部修复候选后，检查该候选的 `machineTable` 和 `AGVTable`。
3. 阶段 D 生成完全重调度候选后，检查该候选的 `machineTable` 和 `AGVTable`。
4. 若候选中存在已取消订单在对应 `cancel_time` 之后仍然出现的机器工序或 AGV 运输任务，则标记为回流。
5. 出现回流的候选被标记为不可行，`candidate.report.rejectedReasons` 增加 `cancelled_job_backflow_detected`。
6. 混合策略选中最终候选后，主流程再次检查选中计划；如果仍有回流，则当前事件结果标记为不可行，并且不更新下一轮 `currentSchedule`。

候选级回流只淘汰对应候选，不会直接判定整轮事件失败；只有最终选中的计划仍然存在回流时，当前事件才会失败。

这个规则允许已取消订单在取消时刻之前已经完成的历史任务继续保留；只有取消时刻之后仍然存在的机器/AGV任务才视为回流。

Step I5 完成时应满足：

- 第一次取消的订单不会在第二次取消后回到 `machineTable`。
- 第一次取消的订单不会在第二次取消后回到 `AGVTable`。
- 阶段 C 候选中不能出现已取消订单的未完成工序或运输任务。
- 阶段 D 候选中不能出现已取消订单的未完成工序或运输任务。
- 后续 baseline 中不能重新出现已取消订单的未完成任务。
- 如果发现回流，当前事件结果标记为不可行。

## 10. Step I6：连续取消后的约束检查

阶段 I 每轮事件都会显式记录候选和最终选择计划的约束检查结果。

复用函数：

```text
check_machine_table_feasibility.m
check_agv_table_feasibility.m
check_job_operation_sequence.m
check_complete_rescheduling_candidate.m
```

局部修复候选约束记录：

```text
eventResult.local_machine_check_isFeasible
eventResult.local_agv_check_isFeasible
eventResult.local_job_sequence_check_isFeasible
```

完全重调度候选约束记录：

```text
eventResult.complete_machine_check_isFeasible
eventResult.complete_agv_check_isFeasible
eventResult.complete_job_sequence_check_isFeasible
eventResult.complete_frozen_consistency_isFeasible
eventResult.complete_cancelled_task_exclusion_isFeasible
```

最终选择计划约束记录：

```text
eventResult.selected_machine_check_isFeasible
eventResult.selected_agv_check_isFeasible
eventResult.selected_job_sequence_check_isFeasible
eventResult.selected_constraint_check_isFeasible
```

如果最终选择计划没有通过机器、AGV 或工序顺序检查，本轮事件会被标记为不可行，`decision_reason` 记为：

```text
selected_constraint_check_failed
```

Step I6 完成时应满足：

- 每轮局部修复候选报告机器冲突、AGV 冲突和工序顺序检查。
- 每轮完全重调度候选报告冻结一致性和取消任务排除检查。
- 最终选择计划也要通过机器、AGV 和工序顺序检查。
- 不可行时记录 `reason`，不静默跳过。

## 11. Step I7：unsupported 情况处理

阶段 I 第一版遇到正在加工或正在运输取消时，不扩展抢占逻辑。

判断规则：

```text
state.has_unsupported_operations == true
state.has_unsupported_agv_tasks == true
```

如果任一条件成立，当前事件直接标记为 unsupported：

```text
eventResult.isUnsupported = true
eventResult.decision_isSelected = false
eventResult.unsupported_reason
eventResult.stop_sequence
```

可能的 `unsupported_reason`：

```text
unsupported_processing_state
unsupported_agv_state
unsupported_processing_and_agv_state
```

第一版不做：

- 工序中断。
- 加工抢占。
- AGV 中途卸载。
- AGV 中途改派。

后续是否继续执行由 config 明确：

```matlab
config.sequential_cancellation.stop_on_unsupported
```

默认值为 `true`，即第一版遇到 unsupported 事件后停止后续取消事件。若后续显式设为 `false`，主流程会保留当前 `currentSchedule`，记录 unsupported 事件，并继续尝试后续事件。

Step I7 完成时应满足：

- unsupported 情况不会崩溃。
- 结果中能说明是哪一轮事件 unsupported。
- 结果中能说明 unsupported 原因。
- 第一版默认停止后续事件。
- 不做工序中断或 AGV 中途卸载/改派。

## 12. Step I8：连续取消单元测试

阶段 I 新增连续取消单元测试：

```text
tests/test_order_cancellation_sequential_events.m
```

运行入口：

```matlab
run('tests/test_order_cancellation_sequential_events.m')
```

测试内容：

- 两个取消事件按时间顺序执行。
- 每次事件后都有最终选择。
- 第二次状态提取基于第一次选择后的计划。
- 第一次取消的订单不会在第二次计划中回流。
- 两次事件后机器无冲突。
- 两次事件后 AGV 无冲突。
- 两次事件后工件顺序满足。
- 正在加工取消被标记为 unsupported。

测试约束：

- 不写 `outputs/`。
- 不跑正式实验。
- 使用 `data_sample/Mk01.fjs` 和最小构造 schedule。
- 不调用长时间 NSGA-II。

Step I8 完成时应满足：

- 连续取消主流程有可直接运行的 MATLAB 测试入口。
- 测试覆盖正常两次连续取消。
- 测试覆盖 unsupported 事件。
- 测试不生成实验输出。

用户已运行该测试，MATLAB 输出：

```text
test_order_cancellation_sequential_events passed
```

该结果说明连续取消主流程测试已通过，包括两次连续取消、基线更新、不回流、约束检查和 unsupported 标记。

## 13. Step I9：样例 smoke 脚本

阶段 I 新增样例 smoke 脚本：

```text
scripts/run_order_cancellation_sequential_smoke.m
```

运行入口：

```matlab
run('scripts/run_order_cancellation_sequential_smoke.m')
```

样例事件：

```text
cancelEvents(1): job_id = 2, cancel_time = 10
cancelEvents(2): job_id = 3, cancel_time = 14
```

打印内容：

- 每轮取消事件的 `event_id`、`job_id`、`cancel_time` 和 `policy`。
- 每轮局部修复和完全重调度候选可行性。
- 每轮最终选择策略和选择原因。
- 每轮是否触发完全重调度。
- 每轮是否 unsupported。
- 每轮已取消订单是否回流。
- 每轮最终计划机器、AGV 和工序顺序约束检查结果。

Step I9 完成时应满足：

- 能打印每轮取消事件。
- 能打印每轮局部修复和完全重调度可行性。
- 能打印每轮最终选择策略和原因。
- 能打印最终计划约束检查结果。
- 不写 `outputs/`。
- 不做正式多随机种子实验。

当前状态：smoke 脚本入口已完成，MATLAB smoke 输出等待用户运行后补充到本报告。

## 14. Step I1 验收标准

Step I1 完成时应满足：

- 明确连续取消主函数输入包括 `problem`、`machineData`、`agvData`、`initialSchedule`、`cancelEvents` 和 `config`。
- 明确 `cancelEvents` 是多个取消事件。
- 明确每个事件包含 `job_id`、`cancel_time` 和 `policy`。
- 明确第一轮使用 `initialSchedule` 作为基线。
- 明确后续轮次使用上一轮最终选择计划作为新基线。
- 明确阶段 I 不新增机器故障、新订单插入或强化学习。

## 15. Step I2 验收标准

Step I2 完成时应满足：

- 已明确 `cancelEvents(i).event_id`、`job_id`、`cancel_time` 和 `policy` 四个字段。
- 已明确至少支持 2 个连续取消事件。
- 已明确事件按 `cancel_time` 升序处理。
- 已明确相同 `job_id` 重复取消要拒绝或标记为无效。
- 已明确 `cancel_time` 非负。
- 已明确 `policy` 当前只支持 `cancel_unstarted_operations_only`。

## 16. 后续步骤入口

下一步进入 Step I10：阶段 I 项目报告整理。

建议重点确认：

- 用户运行测试和 smoke 后，需要把输出结果补进阶段 I 主报告。
- 报告是否汇总新增文件清单、测试入口、smoke 入口和 smoke 输出含义。
- README 是否仍然只挂阶段 I 一个主入口。

## 17. 阶段 I 完成标志

阶段 I 完成时应达到：

- 能按时间顺序处理至少两个订单取消事件。
- 每次取消都能复用阶段 B-H 链路。
- 每次取消后都能输出局部修复、完全重调度和混合策略最终选择。
- 后一次取消基于前一次选择后的计划继续运行。
- 已取消订单不会在后续计划中回流。
- 每轮计划通过约束检查，或明确记录不可行/unsupported 原因。

当前已通过 `test_order_cancellation_sequential_events.m` 验证连续取消主流程。阶段 I 的最终项目报告仍需在用户运行 smoke 后补充 smoke 输出结果。

## 18. Step I11 静态验收结果

本节记录阶段 I 完成前的静态验收。静态验收只检查文件、README 入口和文档覆盖情况，不运行 MATLAB，不生成 `outputs/`。

| 验收项 | 结果 |
|---|---|
| `src/cancellation/run_sequential_order_cancellations.m` 存在 | 通过 |
| 连续取消事件测试存在 | 通过，`tests/test_order_cancellation_sequential_events.m` 已存在 |
| smoke 脚本存在 | 通过，`scripts/run_order_cancellation_sequential_smoke.m` 已存在 |
| 阶段 I 主报告存在 | 通过，当前文档为阶段 I 唯一主报告 |
| README 已挂阶段 I 报告入口 | 通过，README 只挂 `stage_i_sequential_cancellation_report.md` 一个阶段 I 主入口 |
| 至少支持 2 个连续取消事件 | 通过，报告和测试均按至少两个事件设计 |
| 每次事件后都有局部修复、完全重调度和最终选择 | 通过，主流程按阶段 B-H 链路重复执行 |
| 后一次状态提取基于前一次选择后的计划 | 通过，主流程更新 `currentSchedule` 后进入下一轮 |
| 已取消订单不会回流 | 通过，报告定义 `cancelledJobSet` 和回流检查规则 |
| unsupported 情况能清楚记录 | 通过，报告定义 unsupported 原因和停止策略 |
| 没有机器故障 | 通过，阶段 I 明确不加入机器故障 |
| 没有新订单插入 | 通过，阶段 I 明确只处理连续取消，不处理新订单插入 |
| 没有强化学习 | 通过 |
| 没有全局最优证明 | 通过 |
| `raw_code/` 无修改 | 通过，静态验收时 git 工作区干净 |

已收到并记录的测试结果：

```text
test_order_cancellation_sequential_events passed
>>
```

阶段 I 静态验收结论：阶段 I 的文件结构、主报告入口和核心范围控制均满足验收要求。smoke 输出仍需用户运行 `run('scripts/run_order_cancellation_sequential_smoke.m')` 后补充。

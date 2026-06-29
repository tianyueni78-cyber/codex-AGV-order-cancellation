# 项目冻结边界与证据索引

## 1. 这份文件的作用

这份文件只做一件事：把当前订单取消动态重调度项目收成一个可以汇报、可以复核、可以冻结的代码包入口。

它回答四个问题：

1. 现在项目的最终范围是什么。
2. 哪些内容以后不再改主线。
3. 哪些文件是最后该看的证据。
4. 如果还要补齐，下一步按什么顺序做。

## 2. 冻结边界

### 2.1 最终范围

当前项目的最终范围只保留为：

- FJSP-AGV 场景下的订单取消动态重调度。
- 已知 `cancel_time` 的单次取消事件处理。
- 冻结取消时刻前已经完成或正在执行的任务。
- 删除被取消订单尚未完成的任务。
- 生成并比较局部修复与完全重调度候选。
- 做可行性校验、指标评价、策略选择和 CSV 追踪。

### 2.2 后续不再改主线

以下内容不再作为主线继续扩展：

- `raw_code/`。
- `src/` 中已经闭合的订单取消主链路。
- 机器故障主线。
- AGV 故障主线。
- 新订单插入主线。
- 多个订单连续取消主线。
- 强化学习主线。
- 全局最优证明主线。
- 形式化的大规模正式实验主线。
- 把 30 秒搜索入口或正式搜索入口塞进一键收口流程。

### 2.3 只保留为历史记录或扩展预案

以下内容保留，但不再当作当前主线推进：

- `docs/00_system_overview/stage_*.md` 一系列阶段工作记录。
- `docs/00_system_overview/post_stage_flexible_dispatch_roadmap.md`。
- `docs/08_engineering/*.md` 中的模板和预案类文件。
- `docs/07_reproduction/reproduction_steps/*.md` 中的逐步复现过程说明。

这些文件的角色是过程记录、扩展预案或历史路线，不是当前收口结论的唯一依据。

## 3. 证据索引

导师要优先看的，不是全部脚本，而是下面这组“证据入口”。

| 入口 | 它证明什么 | 可信原因 |
|---|---|---|
| [项目总收口文档](project_final_summary.md) | 项目层面的总结论、边界和可写内容 | 这是项目级总入口 |
| [订单取消最终交付说明](order_cancellation_final_delivery_summary.md) | 代码包已到可冻结状态、主链路已闭合 | 汇总了交付状态、规模、smoke 结果和收尾建议 |
| [多策略基线实验结果说明](order_cancellation_strategy_baseline_results.md) | baseline 比较结果和边界 | 有明确数据集、seed、cancelTime 和统计表 |
| [订单取消输出追踪](order_cancellation_output_traceability.md) | 输出 CSV 路径和结果追溯 | 能直接追到具体输出文件 |
| [订单取消大规模实验结果](order_cancellation_large_experiment_results.md) | 大批量结果摘要 | 给出 700 行结果和 run_through 统计 |
| [项目最终收口 Checklist](project_final_checklist.md) | 最终验收页 | 方便导师快速判断是否已经完整冻结 |
| [订单取消交付清单](order_cancellation_delivery_checklist.md) | 收口检查项 | 方便做最终验收核对 |

### 3.1 最终可引用的输出

当前最适合引用的输出，是 traceability 和 baseline 文档里已经指向的这些 CSV：

- `outputs/batch_random_order_cancellation/20260627_131427/batch_random_order_cancellation.csv`
- `outputs/batch_random_order_cancellation/20260627_131448/batch_random_order_cancellation.csv`
- `outputs/batch_random_order_cancellation/20260627_131510/batch_random_order_cancellation.csv`

如果只挑一个最强的批量证据，优先看 `20260627_131510` 这份大批量结果，再回看 `20260627_131448` 的 baseline 对照。

## 4. baseline 封口

baseline 不是“所有输出的默认名称”，而是“对照线”。

### 4.1 baseline 用来对比什么

当前 baseline 主要对比两类东西：

1. `raw_code/` 和当前重构实现是不是同口径。
2. `auto_selection`、`local_only`、`complete_only` 三种策略在同一批样本下表现有什么差异。

### 4.2 哪些结果是主结论

当前可封口的 baseline 结论只有这几条：

- 单数据集 `Mk01.fjs`、`seeds = 1:30`、`cancelTimes = [5 9 13]` 的 270 行结果，已经给出了可统计的策略对照。
- `auto_selection` 和 `local_only` 在这批样本下的成功率、失败率和指标统计一致。
- `complete_only` 的成功率明显更低，但它的失败边界已经被诊断出来。

### 4.3 哪些只是辅助验证

下面这些不应被当作 baseline 的全部含义：

- smoke 结果。
- 大批量结果。
- 追踪 CSV。
- 工程化工具链。

它们是证据补充，不是 baseline 本体。

### 4.4 不要从 baseline 里推出什么

当前 baseline 不能推出：

- 全局最优。
- 跨所有数据集泛化完成。
- 论文级最终实验完成。
- `complete_only` 在所有场景下都可行。
- `auto_selection` 在所有场景下都优于其他策略。

## 5. 最终交付物清单

### 5.1 最后该看的文件

优先级从高到低建议如下：

1. [项目总收口文档](project_final_summary.md)
2. [项目冻结边界与证据索引](project_freeze_and_evidence_index.md)
3. [订单取消最终交付说明](order_cancellation_final_delivery_summary.md)
4. [多策略基线实验结果说明](order_cancellation_strategy_baseline_results.md)
5. [订单取消输出追踪](order_cancellation_output_traceability.md)
6. [订单取消大规模实验结果](order_cancellation_large_experiment_results.md)
7. [项目最终收口 Checklist](project_final_checklist.md)
8. [订单取消交付清单](order_cancellation_delivery_checklist.md)

### 5.2 现在可作为历史材料的文件

这些文件还保留，但不再作为主结论入口：

- `docs/00_system_overview/stage_a_work_record.md`
- `docs/00_system_overview/stage_b_work_record.md`
- `docs/00_system_overview/stage_c_work_record.md`
- `docs/00_system_overview/stage_d_work_record.md`
- `docs/00_system_overview/stage_e_work_record.md`
- `docs/00_system_overview/stage_f_work_record.md`
- `docs/00_system_overview/stage_g_work_record.md`
- `docs/00_system_overview/stage_h_hybrid_policy_report.md`
- `docs/00_system_overview/stage_i_sequential_cancellation_report.md`
- `docs/00_system_overview/stage_j_order_change_framework_plan.md`
- `docs/00_system_overview/stage_k_adaptive_strategy_plan.md`
- `docs/00_system_overview/stage_l_benchmark_plan.md`
- `docs/00_system_overview/stage_m_multi_disruption_interface_plan.md`

## 6. 补齐工作计划

如果现在要把项目真正收口成“范围冻结、证据齐全、结论封版、后续不再改主线”，按下面顺序做就够了。

1. **冻结范围声明**
   - 写一份“最终范围与非范围”说明。
   - 把“以后不再改主线”的话写进总收口文档。
   - 验证：任何人先看总收口文档，都能知道项目到底做到哪里、哪里不再继续。

2. **做一份证据索引**
   - 汇总所有最终该看的文件。
   - 每个文件说明用途、结论、对应证据。
   - 验证：导师只看索引就知道先看什么、为什么可信。

3. **把 baseline 说明单独收口**
   - 明确 baseline 的定义、用途、结果、边界。
   - 让 baseline 从“一个结果文件”变成“一个结论依据”。
   - 验证：baseline 文档里能直接说清楚“比什么、得出什么、不能推出什么”。

4. **整理 README 主入口**
   - README 只保留最重要入口。
   - 其它阶段文档降级为历史材料。
   - 验证：README 第一眼就能看出项目已经冻结，且入口很少。

5. **最后做一次静态核对**
   - 看有没有地方还在暗示“继续迭代主线”。
   - 把语气统一成“已收口、可复现、可引用”。
   - 验证：总收口文档、README、证据索引三者口径一致。

6. **如果需要对外汇报，再做版本封版**
   - 加一个 release/tag。
   - 作为“最终可交付版”。
   - 验证：对外引用时有一个明确版本锚点。

## 7. 一句话结论

这个项目现在最合适的状态不是继续扩主线，而是把主线冻结、把证据收口、把 baseline 封版，然后只保留必要的历史记录和扩展预案。

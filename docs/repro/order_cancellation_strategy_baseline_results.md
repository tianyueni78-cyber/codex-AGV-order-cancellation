# 多策略基线实验结果说明

## 1. 实验目的

本说明文档总结当前这组多策略批量随机订单取消实验的结果，用于判断现有原型在单数据集、多 seed、多 cancel_time、三种 `strategy_policy` 下，能够支持哪些结论，不能支持哪些结论。

本次说明只基于当前批量结果与其汇总文件，不扩展到其他数据集，也不声称全局最优。

## 2. 实验配置

- 数据集：`data_sample/Mk01.fjs`
- seeds：`1:30`
- cancelTimes：`[5 9 13]`
- strategyPolicies：`auto_selection`, `local_only`, `complete_only`
- 原始结果行数：`270`

这 270 行结果对应：

- `1` 个数据集
- `30` 个 seed
- `3` 个 cancelTime
- `3` 个 strategyPolicy

## 3. 输出文件说明

原始结果与汇总文件均位于：

`outputs/batch_random_order_cancellation/20260627_144555/`

文件说明如下：

- `batch_random_order_cancellation.csv`
  - 原始 270 行结果
- `summary_by_strategy_policy.csv`
  - 按 `strategy_policy` 汇总成功率、失败率、可行率及指标统计
- `summary_by_dataset_strategy_policy.csv`
  - 按 `dataset + strategy_policy` 汇总
- `summary_selected_strategy.csv`
  - 统计最终实际选中的 `selected_strategy` 分布
- `summary_error_messages.csv`
  - 统计 `error_message` 分布
- `summary_notes.txt`
  - 记录输入 CSV、输出目录、输入行数，以及缺失列说明

## 4. 按 strategy_policy 的成功率 / feasible_rate / fail_rate 摘要

| strategy_policy | row_count | run_through_count | run_through_rate | fail_count | fail_rate | feasible_count | feasible_rate |
|---|---:|---:|---:|---:|---:|---:|---:|
| auto_selection | 90 | 61 | 0.6778 | 29 | 0.3222 | 61 | 0.6778 |
| local_only | 90 | 61 | 0.6778 | 29 | 0.3222 | 61 | 0.6778 |
| complete_only | 90 | 30 | 0.3333 | 60 | 0.6667 | 30 | 0.3333 |

说明：

- `row_count = 90` 是因为每个 `strategy_policy` 覆盖 `1` 个数据集 × `30` 个 seed × `3` 个 cancelTime。
- `run_through` 与 `feasible` 在当前汇总里数值一致，说明这里记录的是成功运行且可行的结果行数。

## 5. Cmax_delta / SD / TD / Y 的均值和标准差摘要

### 5.1 按 strategy_policy 汇总

| strategy_policy | Cmax_delta_mean | Cmax_delta_std | SD_mean | SD_std | TD_mean | TD_std | Y_mean | Y_std |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| auto_selection | -1.4754 | 1.5122 | 0 | 0 | 0 | 0 | 0.3260 | 0.1180 |
| local_only | -1.4754 | 1.5122 | 0 | 0 | 0 | 0 | 0.3260 | 0.1180 |
| complete_only | -3.6333 | 1.7515 | 2.5444 | 0.8818 | 3.4000 | 0.9322 | 0.5917 | 0.1225 |

说明：

- `Cmax_delta / SD / TD / Y` 的统计来自当前汇总文件。
- `auto_selection` 与 `local_only` 的指标均值和标准差完全相同，这只是当前这一批 `Mk01.fjs`、这组 seeds、这组 cancelTime 下的观察结果。
- 这不构成“两个策略永远等价”的证据。

## 6. selected_strategy 分布说明

`summary_selected_strategy.csv` 显示：

| selected_strategy | count | rate |
|---|---:|---:|
| `<empty>` | 118 | 0.4370 |
| `local_repair` | 122 | 0.4519 |
| `complete_rescheduling` | 30 | 0.1111 |

解释：

- `<empty>` 表示最终未形成可记录的选择结果，通常对应失败或不可行情况。
- `local_repair` 是当前批次中最常见的最终选择。
- `complete_rescheduling` 只在一部分场景下被最终选中。

## 7. error_message 分布说明

`summary_error_messages.csv` 显示：

| error_message | count | rate |
|---|---:|---:|
| `no_feasible_candidate` | 29 | 0.1074 |
| `<empty>` | 152 | 0.5630 |
| `Forced local_only policy could not use local_repair.` | 29 | 0.1074 |
| `Forced complete_only policy could not use complete_rescheduling.` | 60 | 0.2222 |

解释：

- `<empty>` 表示没有错误信息，通常是成功路径。
- `no_feasible_candidate` 表示自动选择时两个候选都不可行。
- 强制策略的失败信息表明：在一部分场景中，被强制选择的候选本身不可行，因此 batch 记录了失败，而没有中断。

## 8. 关于 auto_selection 与 local_only 结果相同的谨慎解释

当前这批结果里，`auto_selection` 与 `local_only` 在 `row_count`、成功率、失败率、指标均值和标准差上都相同。

这里应当谨慎理解为：

- 在当前 `Mk01.fjs`、当前 `seeds`、当前 `cancelTimes`、当前批处理实现下，两者输出一致；
- 这不代表两个策略在所有数据集、所有随机种子、所有取消时刻下都一致；
- 也不代表 `auto_selection` 理论上必然等同于 `local_only`。

更稳妥的表述是：当前样本下，`auto_selection` 没有表现出相对于 `local_only` 的可观察差异。

## 9. 当前实验支持的结论

基于当前 270 行结果，可以支持以下结论：

- 在 `Mk01.fjs` 上，三种 `strategy_policy` 都能形成可统计的批量结果。
- `auto_selection` 与 `local_only` 在当前样本上的成功率、失败率和指标统计一致。
- `complete_only` 在当前样本上的成功率明显低于前两者，但在成功样本上的 `Cmax_delta`、`SD`、`TD`、`Y` 统计与前两者不同。
- `selected_strategy` 和 `error_message` 的分布已经可以用于后续做更系统的结果汇总。
- 当前汇总脚本已经能把原始 batch 结果整理成按 `strategy_policy` 和 `dataset + strategy_policy` 的统计表。

## 10. 当前实验不支持的结论

当前实验不支持以下说法：

- 不支持“全局最优”结论。
- 不支持“跨所有数据集都成立”的结论，因为这里只用了 `Mk01.fjs` 一个数据集。
- 不支持“`auto_selection` 一定优于所有基线”的结论。
- 不支持“`local_only` 一定等价于 `auto_selection`”的普遍性结论。
- 不支持“`complete_only` 在所有条件下都更差或更好”的结论。
- 不支持论文式强结论，例如对总体泛化能力、统计显著性、效应量的最终判定。

## 11. 下一步实验建议

建议按下面顺序继续扩展：

1. 增加数据集
   - 先补多个 `fjs` 数据集，避免单数据集结论外推过度。
2. 增加 seeds
   - 让成功率和指标统计更稳定。
3. 增加 cancelTimes
   - 覆盖更稀疏和更密集的取消时刻，观察策略分化是否更明显。
4. 后续再做论文式图表
   - 先保证数据覆盖足够，再考虑绘制成功率、分布和对比图。

## 12. 结论边界

这份结果说明文档只面向当前这批 `Mk01.fjs` 多策略批量结果，不向外推广到更多数据集或更广泛问题设定。



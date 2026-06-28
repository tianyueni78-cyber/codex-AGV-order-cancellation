# 订单取消算法包状态说明

本文档用于说明当前订单取消动态重调度算法包的代码规模、模块链路、已验证能力、策略边界和后续扩展方向。它是交付说明，不是论文式最终结论。

## 1. 当前代码规模

当前订单取消相关代码规模大致如下：

- 订单取消相关 `.m` 文件：约 `49` 个
- `src/cancellation/*.m`：`35` 个文件，约 `6,597` 行
- `scripts/*order_cancellation*.m`：`14` 个文件，约 `6,499` 行
- 订单取消相关 `.m` 总计：约 `13,096` 行
- `docs/repro` 订单取消相关文档：`6` 个，约 `459` 行

这里的“约”表示当前阶段性统计口径，后续如果脚本或文档继续增长，数字会随之变化。

## 2. 算法链路

当前订单取消处理链路已经形成从事件输入到结果追踪的完整主线：

1. `cancellation event modeling`
2. `state extraction at cancel_time`
3. `frozen prefix extraction`
4. `completed / processing / unstarted task handling`
5. `local repair candidate generation`
6. `complete rescheduling candidate generation`
7. `candidate validation`
8. `strategy selection`
9. `metric evaluation`：`Cmax` / `energy` / `TD` / `SD` / `Y`
10. `batch experiment and CSV traceability`
11. `reproducibility docs`

从结构上看，这条链路已经不是单点 demo，而是能够把事件、候选、验证、选择、评估和批量输出串起来的算法包主线。

## 3. 已验证结果

当前已经稳定验证的结果包括：

- `Mk01` small regression：`15/15 feasible`
- Brandimarte `Mk01`–`Mk10` small smoke regression：`90/90 feasible`
- `A7.1` `Mk01`–`Mk03` strategy smoke comparison：
  - `auto_selection`：`27/27 feasible`
  - `local_only`：`27/27 feasible`
  - `complete_only`：`0/27 feasible`
- `A7.2` / `A9` complete-only diagnostics：
  - `frozen_prefix_infeasible`：`24`
  - `unsupported_processing_state`：`3`
- `A11.1` multi-source smoke coverage：
  - `Brandimarte` + `Barnes` + `Dauzere`
  - `5` 个源数据文件
  - `auto_selection`：`45/45 feasible`
- `A11.2` multi-source local_only smoke：
  - `Brandimarte` + `Barnes` + `Dauzere`
  - `5` 个源数据文件
  - `local_only`：`45/45 feasible`
- `A11.3` second multi-source auto_selection smoke：
  - `Brandimarte` + `Barnes` + `Dauzere`
  - `6` 个源数据文件
  - `auto_selection`：`54/54 feasible`

这些结果说明：当前主流程和诊断链路已经能在小规模 smoke 里稳定运行，并且 complete 侧的拒绝原因可以被追踪到具体分类。

## 4. 策略边界

当前策略边界应当这样理解：

- `auto_selection` 是当前推荐入口
- `local_only` 在已验证 smoke 中稳定
- `complete_only` 是强制 `complete rescheduling` 分支，可能因为 `frozen prefix` 或 `processing state` 边界被拒绝
- `complete_only` 失败不代表 `local repair` 回退失败
- complete rescheduling 的不可用原因现在可以通过 CSV 诊断追踪
- `A11.1` 进一步扩大了跨源数据 smoke 覆盖面，但仍然属于 small smoke，不代表全量泛化或论文级最终实验
- 同一组多源数据上，`auto_selection` 和 `local_only` 都达到了 `45/45 feasible`，这增强了 `local repair` 分支的 smoke 证据，但仍不代表全量泛化或论文级最终实验
- `A11.3` 进一步扩大了跨源、多实例 smoke 覆盖面，但仍然属于 small smoke，不代表全量泛化或论文级最终实验

这里的 `complete_only` 失败是对 forced complete rescheduling 分支的拒绝诊断，不是算法整体退化，也不是 local repair 失败。

## 5. 不能声称的内容

当前仍然不能声称：

- 全局最优
- 全量数据集泛化完成
- 论文级最终实验完成
- `complete_only` 在所有取消场景下都可行

这些边界必须保留，因为当前结果还主要来自阶段性 smoke 和小规模批量验证。

## 6. 下一步低风险路线

如果继续推进，建议优先做低风险扩展，而不是改动现有稳定逻辑：

1. 扩展独立统计脚本，但不要替换现有 batch
2. 增加更多 source dataset 的 smoke
3. 完善论文级统计报告
4. 保持 `A5` / `A6` / `A7` / `A9` 的稳定逻辑不动

这条路线的目标是继续把算法包做厚，而不是回头重写已经稳定的主链路。

## 7. 结论

当前订单取消动态重调度已经具备可交付的算法包轮廓：

- 代码规模足够大，且已经按模块形成主线
- 关键 smoke 和 batch 诊断已经稳定
- `A11.1` 已把 smoke 覆盖从单一数据源扩展到 `Brandimarte`、`Barnes` 和 `Dauzere`
- `A11.2` 进一步确认了同一组多源数据上的 `local_only` 也为 `45/45 feasible`
- `A11.3` 再次确认了第二组多源数据上的 `auto_selection` 也为 `54/54 feasible`
- 策略边界清晰，`complete_only` 的失败原因可追踪
- 后续可以继续围绕统计、文档和更广覆盖的数据集做扩展

但它仍然不是全局最优证明，也不是最终论文结论。

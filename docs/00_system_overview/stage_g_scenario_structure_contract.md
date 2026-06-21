# 阶段 G Step G3：场景结构契约

> 阶段 G 的主要阅读入口已统一为 [阶段 G 项目报告](stage_g_project_report.md)。本文档仅保留历史过程记录，不再从 README 直接入口展示。

本文档定义阶段 G 场景库中每个订单取消场景的字段结构。Step G3 只定义数据契约，不实现生成函数，不运行实验，不写 `outputs/`。

## 1. 场景结构目标

每个场景必须能回答：

1. 它来自哪个数据集。
2. 它对应哪个随机种子。
3. 它属于哪个取消时间窗口。
4. 它属于哪类取消订单。
5. 它取消的是哪个订单。
6. 它在什么时刻取消。
7. 它使用什么取消策略。
8. 它是否有特殊说明或降级处理。

## 2. 必需字段

每个场景必须包含：

```matlab
scenario.scenario_id
scenario.dataset
scenario.seed
scenario.time_window
scenario.job_category
scenario.cancel.job_id
scenario.cancel.cancel_time
scenario.cancel.policy
scenario.cancel_time_ratio
scenario.notes
```

## 3. 字段定义

| 字段 | 类型 | 含义 |
|---|---|---|
| `scenario.scenario_id` | char/string | 场景唯一编号 |
| `scenario.dataset` | char/string | 数据集相对路径 |
| `scenario.seed` | numeric scalar | 随机种子 |
| `scenario.time_window` | char/string | 取消时间窗口名称 |
| `scenario.job_category` | char/string | 取消订单类别 |
| `scenario.cancel.job_id` | numeric scalar | 被取消订单编号 |
| `scenario.cancel.cancel_time` | numeric scalar | 取消时刻 |
| `scenario.cancel.policy` | char/string | 取消策略 |
| `scenario.cancel_time_ratio` | numeric scalar | 取消时刻相对基线 `Cmax` 的比例 |
| `scenario.notes` | cell array/string | 场景生成说明、跳过原因或降级说明 |

## 4. `scenario_id` 规则

`scenario_id` 应能追溯 dataset、time window、job category 和 seed。

建议格式：

```text
<dataset_stem>__<time_window>__<job_category>__seed<seed>
```

示例：

```text
Mk01__early__random__seed1
Mk01__middle__short__seed2
Mk01__late__critical__seed3
```

规则：

1. `scenario_id` 必须唯一。
2. `dataset_stem` 来自数据集文件名，不包含扩展名。
3. 不使用本机绝对路径。
4. 不包含空格。
5. 如果后续多个数据集文件名重复，应在生成函数中追加稳定后缀。

## 5. `dataset` 规则

`scenario.dataset` 必须使用配置中的相对路径。

示例：

```text
data_sample/Mk01.fjs
```

禁止：

```text
D:\CODEX\...
C:\Users\...
/home/...
```

## 6. `time_window` 规则

`scenario.time_window` 来自配置：

```text
early
middle
late
```

对应比例来自：

```matlab
scenario.cancel_time_ratio
```

取消时刻计算口径：

```text
scenario.cancel.cancel_time = baseline_Cmax * scenario.cancel_time_ratio
```

说明：Step G3 只定义该口径，实际计算由后续 `build_order_cancellation_scenarios.m` 实现。

## 7. `job_category` 规则

`scenario.job_category` 来自配置：

```text
random
short
long
critical
noncritical
```

第一版含义：

1. `random`：由 `seed` 控制的可复现随机订单。
2. `short`：工序数最少的订单。
3. `long`：工序数最多的订单。
4. `critical`：基线计划中最后完成的订单。
5. `noncritical`：基线计划中较早完成的订单。

停止条件：

```text
如果无法稳定判断 critical 或 noncritical，
后续生成函数应跳过该类别或在 notes 中写明原因，
不强行伪造关键路径判断。
```

## 8. `cancel` 规则

`scenario.cancel` 必须包含：

```matlab
scenario.cancel.job_id
scenario.cancel.cancel_time
scenario.cancel.policy
```

约束：

1. `job_id` 必须在 `1 <= job_id <= problem.jobNum` 范围内。
2. `cancel_time` 必须是非负数。
3. `policy` 第一版固定为 `cancel_unstarted_operations_only`。

## 9. `notes` 规则

`scenario.notes` 用于记录场景生成中的说明。

可记录：

1. `critical` 或 `noncritical` 判断失败原因。
2. 多个订单并列时的选择规则。
3. 某类场景被跳过的原因。
4. 后续实验中不可行原因的简要引用。

默认值建议为空：

```matlab
scenario.notes = {};
```

## 10. 验收标准

Step G3 的验收标准：

1. 每个场景有唯一 `scenario_id`。
2. 每个场景有 `cancel.job_id`。
3. 每个场景有 `cancel.cancel_time`。
4. 每个场景有 `cancel.policy`。
5. 每个场景能追溯 `dataset`、`time_window`、`job_category` 和 `seed`。
6. 场景路径不写死本机绝对路径。
7. 已说明关键路径无法稳定判断时的停止条件。
8. 本步骤未运行 MATLAB。
9. 本步骤未生成 `outputs/`。
10. 本步骤未修改 `raw_code/`。

## 11. 下一步

下一步进入：

```text
Step G4：实现场景库生成函数
```

建议新增：

```text
src/cancellation/build_order_cancellation_scenarios.m
```

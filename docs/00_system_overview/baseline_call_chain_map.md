# 基线调用链导读

本文档记录迁移后的原 `codex-AGV` 正常调度链路。阶段 B 做订单取消事件与状态提取时，应优先从这里确认复用入口，避免直接改动原始基线逻辑。

## 1. 正常调度入口

当前仓库保留两类正常调度入口：

1. raw 兼容入口：调用 `raw_code/NSGA-II` 中的原始 NSGA-II 和 `fitness.m`。
2. independent 入口：调用 `src/` 中的重构编码、解码、评价和搜索逻辑。

### 1.1 small 入口

raw 版 small：

```text
scripts/run_small_nsga2.m
configs/small_nsga2_config.m
```

调用链：

```text
run_small_nsga2.m
  -> small_nsga2_config(projectRoot)
  -> read_fjsp / read_machine_data / read_agv_data
  -> raw_code/NSGA-II/init
  -> raw_code/NSGA-II/NSGA2
  -> outputs/small_nsga2/
```

independent small：

```text
scripts/run_independent_small_nsga2.m
configs/independent_small_config.m
```

调用链：

```text
run_independent_small_nsga2.m
  -> independent_small_config(projectRoot)
  -> read_fjsp / read_machine_data / read_agv_data
  -> run_independent_nsga2
  -> decode_chromosome_independent
  -> evaluate_decoded_schedule
  -> outputs/independent_small_nsga2/
```

### 1.2 formal 入口

raw 版 formal：

```text
scripts/run_formal_nsga2.m
configs/formal_nsga2_config.m
```

调用链：

```text
run_formal_nsga2.m
  -> formal_nsga2_config(projectRoot)
  -> read_fjsp / read_machine_data / read_agv_data
  -> raw_code/NSGA-II/init
  -> raw_code/NSGA-II/NSGA2
  -> outputs/formal_nsga2/
```

independent formal：

```text
scripts/run_independent_formal_nsga2.m
configs/independent_formal_config.m
```

调用链：

```text
run_independent_formal_nsga2.m
  -> independent_formal_config(projectRoot)
  -> read_fjsp / read_machine_data / read_agv_data
  -> run_independent_nsga2
  -> decode_chromosome_independent
  -> evaluate_decoded_schedule
  -> outputs/independent_formal_nsga2/
```

`run_independent_formal_nsga2.m` 带有 preflight guard。未设置 `RUN_INDEPENDENT_FORMAL_CONFIRMED` 时，只打印配置，不启动正式实验。

## 2. 配置入口

常用配置文件：

```text
configs/small_nsga2_config.m
configs/independent_small_config.m
configs/formal_nsga2_config.m
configs/independent_formal_config.m
configs/independent_medium_config.m
configs/independent_multiseed_config.m
```

配置主要提供：

```text
config.paths.fjsp
config.paths.machineExcel
config.paths.agvExcel
config.paths.outputBaseDir
config.algorithm.pop
config.algorithm.max_gen
config.algorithm.p_cross
config.algorithm.p_mutation
config.random.seed / seedList / currentSeed
config.energy.AGVEG_MAX
config.energy.eChargeSpeed
```

订单取消后续应新增独立配置，例如：

```text
configs/order_cancel_small_config.m
configs/order_cancel_multiseed_config.m
```

不要直接把订单取消字段塞进已有 normal baseline 配置，除非该字段也适用于正常调度。

## 3. 数据读取链路

### 3.1 输入来源

当前 small 和 independent 配置默认使用：

```text
FJSP 数据：data_sample/Mk01.fjs
机器数据：data_sample/机器数据.xlsx
AGV 数据：data_sample/AGV数据.xlsx
```

### 3.2 FJSP 数据

读取入口：

```text
src/data/read_fjsp.m
```

输出结构：

```text
problem.jobInfo
problem.candidateMachine
problem.machineNum
problem.jobNum
problem.operaNumVec
```

含义：

```text
jobInfo：每个工件每道工序在各机器上的加工时间，不能加工的位置为 Inf。
candidateMachine：每个工序可选机器列表。
machineNum：机器数量。
jobNum：工件数量。
operaNumVec：每个工件的工序数量。
```

### 3.3 机器数据

读取入口：

```text
src/data/read_machine_data.m
```

输出结构：

```text
machineData.distance_matrix
machineData.machineEnergy
```

其中：

```text
distance_matrix.load_to_machine
distance_matrix.machine_to_unload
distance_matrix.machine_to_machine
distance_matrix.load_to_unload
machineEnergy.work
machineEnergy.free
```

### 3.4 AGV 数据

读取入口：

```text
src/data/read_agv_data.m
```

输出结构：

```text
agvData.AGVNum
agvData.AGVSpeed
agvData.AGVEnergy
```

其中：

```text
AGVEnergy.free
AGVEnergy.load
```

## 4. 编码链路

核心目录：

```text
src/encoding/
```

核心入口：

```text
src/encoding/generate_initial_population.m
src/encoding/split_chromosome.m
src/encoding/validate_chromosome.m
src/encoding/generate_offspring.m
```

染色体由 `OS + MS + AS + SS` 组成，核心长度为：

```text
5 * sum(problem.operaNumVec)
```

字段含义：

```text
OS：operation sequence，工序顺序编码。每个 job_id 出现次数等于该工件工序数。
MS：machine selection，每道工序选择候选机器列表中的第几个。
AS：AGV assignment，每道工序运输任务选择哪辆 AGV。
SS：speed selection，每道工序两个速度选择，分别对应空载和载货速度。
```

订单取消后续如果只重调度剩余未完成工序，应优先通过包装层构造“剩余任务子问题”，不要直接重写全局编码层。

## 5. 解码链路

raw 兼容解码入口：

```text
src/decoding/decode_chromosome.m
src/decoding/decode_population.m
```

该链路会调用原始 `sorting.m`，适合作为 raw 行为对照。

independent 解码入口：

```text
src/decoding/decode_chromosome_independent.m
src/decoding/decode_population_independent.m
```

后续订单取消更适合优先复用 independent 解码链路，因为它不依赖 raw `sorting.m`，并且直接返回结构化结果：

```text
schedule.machineTable
schedule.AGVTable
schedule.jobCompleteUnLoad
schedule.agvEGRecord
schedule.agvChargeNum
schedule.scheduleContext
schedule.parts
```

解码主流程：

```text
decode_chromosome_independent
  -> validate_chromosome
  -> split_chromosome
  -> build_schedule
  -> insert_operation_block
  -> insert_agv_block
  -> unload_completed_job
```

## 6. AGV 调度链路

AGV 运输在 `src/decoding/decode_chromosome_independent.m` 的 `build_schedule` 中生成。

每解码一个 OS 位置，大致流程为：

```text
1. 根据 OS 判断当前工件。
2. 用 operaRec 计算这是该工件的第几道工序。
3. 用 MS 选择候选机器。
4. 用 AS 选择 AGV。
5. 用 SS 选择空载速度和载货速度。
6. 如果 AGV 电量低，先插入充电相关任务。
7. 如果 AGV 当前位置不在工件当前位置，插入空载运输。
8. 插入载货运输到目标机器。
9. 工件到达后，插入机器加工块。
10. 如果是该工件最后一道工序，安排最终卸载运输。
```

AGV 表插入入口：

```text
insert_agv_block
```

AGV 任务字段大致为：

```text
start
end
job
opera
from_machine
to_machine
status
load_status
charge
```

从代码可读出的状态约定：

```text
load_status = -1：空载运输
load_status = -2：载货运输
load_status = 0：空闲或充电类块
charge = 0：非充电
charge = 1：充电
charge = 2：去充电位置的空载移动
```

特殊位置编码：

```text
-1：装载站
-2：卸载站或充电相关位置
```

订单取消阶段 B 做状态提取时，需要重点读取 `machineTable`、`AGVTable` 和 `jobCompleteUnLoad`，判断哪些任务在 `cancel_time` 前已完成，哪些任务尚未执行。

## 7. 评价链路

independent 评价主入口：

```text
src/evaluation/evaluate_decoded_schedule.m
```

调用链：

```text
evaluate_decoded_schedule
  -> compute_makespan_from_schedule
  -> compute_machine_energy
  -> compute_agv_energy
  -> build_objectives
```

目标向量：

```text
[makespan, totalEnergy]
```

计算规则：

```text
makespan = max(schedule.jobCompleteUnLoad)
totalEnergy = machineEnergy + agvEnergy
```

机器能耗：

```text
src/evaluation/compute_machine_energy.m
```

机器加工块按 `machineEnergy.work` 计能耗，机器空闲块按 `machineEnergy.free` 计能耗，`inf` 结尾块跳过。

AGV 能耗：

```text
src/evaluation/compute_agv_energy.m
```

AGV 能耗从 `agvEGRecord` 中累计相邻电量记录的正向下降值。电量上升通常对应充电，不计为消耗。

raw 兼容评价入口：

```text
src/evaluation/evaluate_chromosome.m
```

该入口调用 raw `fitness.m`，适合对照，不是订单取消第一版优先复用入口。

## 8. NSGA-II 搜索链路

independent 搜索主入口：

```text
src/search/run_independent_nsga2.m
```

调用链：

```text
run_independent_nsga2
  -> generate_initial_population
  -> decode_chromosome_independent
  -> evaluate_decoded_schedule
  -> non_dominated_sort_independent
  -> crowding_distance_independent
  -> tournament_selection_independent
  -> generate_offspring
  -> environmental_selection_independent
```

输出结构：

```text
NSGA2_Result.RunTime
NSGA2_Result.chrom
NSGA2_Result.obj_matrix
NSGA2_Result.curve.min
NSGA2_Result.curve.avg
NSGA2_Result.pop_history
NSGA2_Result.details
```

其中：

```text
obj_matrix：Pareto 前沿目标值矩阵。
curve.min / curve.avg：每代目标最小值和平均值。
details：前沿解对应的解码和评价细节。
```

raw/refactored 混合搜索入口：

```text
src/search/run_nsga2_with_encoding.m
src/search/nsga2_with_encoding_variation.m
```

这两个入口仍可能调用 raw `NSGA2.m` 或 raw `fitness.m`。订单取消第一版应优先复用 `run_independent_nsga2.m`。

## 9. Metrics 与 Visualization

### 9.1 Metrics

主入口：

```text
src/metrics/compute_metric_summary.m
```

基于已有 `objMatrix` 计算：

```text
spacing
hv
igd
cMetric
```

如果没有 `referencePoint`、`referenceFront` 或 `baselineObjMatrix`，对应指标会是 `NaN` 并记录 warning。

`src/metrics/` 是结果后处理层，不参与解码、不参与搜索、不改变调度方案。

### 9.2 Visualization

主要入口：

```text
src/visualization/plot_pareto_front.m
src/visualization/plot_convergence_curve.m
src/visualization/save_figure_safely.m
```

这些函数读取：

```text
objMatrix
NSGA2_Result.curve
```

用于绘制 Pareto 前沿和收敛曲线。`src/visualization/` 是可视化后处理层，不参与调度计算。

## 10. 订单取消第一版复用建议

阶段 B 进入订单取消事件与状态提取时，建议复用以下模块：

```text
src/data/read_fjsp.m
src/data/read_machine_data.m
src/data/read_agv_data.m
src/encoding/split_chromosome.m
src/encoding/validate_chromosome.m
src/decoding/decode_chromosome_independent.m
src/evaluation/evaluate_decoded_schedule.m
src/search/run_independent_nsga2.m
src/metrics/compute_metric_summary.m
src/visualization/plot_pareto_front.m
src/visualization/plot_convergence_curve.m
```

第一版订单取消不应直接修改：

```text
raw_code/
src/decoding/decode_chromosome_independent.m
src/search/run_independent_nsga2.m
```

更稳的接入方式是新增窄包装模块：

```text
src/cancellation/create_order_cancellation_event.m
src/cancellation/validate_order_cancellation_event.m
src/cancellation/extract_cancellation_state.m
src/rescheduling/build_order_cancel_local_repair.m
src/rescheduling/build_order_cancel_frozen_problem.m
src/rescheduling/decode_order_cancel_complete_reschedule.m
src/evaluation/evaluate_order_cancel_candidate.m
```

阶段 B 的直接接入点应是：

```text
正常计划的 machineTable
正常计划的 AGVTable
正常计划的 jobCompleteUnLoad
订单取消事件 cancel.job_id / cancel.cancel_time / cancel.policy
```

也就是说，阶段 B 先做“事件 + 状态提取”，不要提前生成局部修复或完全重调度方案。


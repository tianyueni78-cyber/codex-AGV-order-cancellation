# 新目标函数模板

## 这份模板解决什么问题

以后如果论文创新点需要新增目标函数，例如：

```text
碳排放
总成本
AGV 等待时间
机器负载均衡
总延迟
鲁棒性
充电次数惩罚
```

不要直接去 `raw_code/fitness.m` 里乱改。

推荐做法是：

```text
先在 src/evaluation 写独立目标函数
再写 toy test
再决定是否接入 objectives
再检查 search / metrics / visualization 的连锁影响
最后才进入 small / medium / formal
```

当前阶段不是新增正式目标。

当前阶段只是建立以后新增目标函数的模板。

## 当前目标函数结构

当前项目默认目标仍然是：

```text
objectives = [makespan, totalEnergy]
```

相关入口：

```text
src/evaluation/evaluate_chromosome.m
src/evaluation/compute_makespan_from_schedule.m
src/evaluation/compute_machine_energy.m
src/evaluation/compute_agv_energy.m
src/evaluation/build_objectives.m
```

当前 `build_objectives.m` 的职责是：

```text
输入 makespan / machineEnergy / agvEnergy
计算 totalEnergy
输出 objectives = [makespan, totalEnergy]
```

所以新增目标时，第一反应不应该是改 search，而应该先判断：

```text
这个新目标是不是 evaluation 层的事情？
它需要哪些输入？
它能不能单独测试？
它会不会改变 objectives 的列数和含义？
```

## 新目标函数应该放在哪里

推荐放在：

```text
src/evaluation/
```

命名建议：

```text
compute_carbon_emission.m
compute_total_cost.m
compute_agv_waiting_time.m
compute_machine_load_balance.m
compute_total_tardiness.m
compute_robust_makespan.m
compute_charge_penalty.m
```

不要放在：

```text
raw_code/
src/search/
scripts/
configs/
```

原因：

```text
raw_code 是原始参考，不直接修改
search 负责搜索，不负责定义目标函数公式
scripts 负责入口，不负责目标函数计算
configs 只放参数，不放计算逻辑
```

## 标准函数接口

如果目标依赖完整调度结果，建议接口：

```matlab
value = compute_<objective_name>(schedule, problem, machineData, agvData, config)
```

如果目标依赖评价上下文，建议接口：

```matlab
value = compute_<objective_name>(context)
```

推荐的 `context` 结构：

```text
context.schedule
context.problem
context.machineData
context.agvData
context.config
context.components
```

其中 `components` 可以包含：

```text
components.makespan
components.machineEnergy
components.agvEnergy
components.totalEnergy
components.machineTable
components.AGVTable
components.agvEGRecord
components.agvChargeNum
```

如果目标只依赖少量组件，可以用更小的接口。例如：

```matlab
carbonEmission = compute_carbon_emission(totalEnergy, carbonFactor)
```

原则是：

```text
输入越清楚越好
不要在函数内部读文件
不要在函数内部跑算法
不要在函数内部写 outputs
不要依赖当前工作目录
```

## 目标函数分类

### 只依赖 schedule 的目标

例子：

```text
makespan
机器负载均衡
AGV 等待时间
最大完工时间差
空闲时间
```

典型输入：

```text
machineTable
AGVTable
jobCompleteUnLoad
operation start/end time
```

### 依赖能耗或成本参数的目标

例子：

```text
totalEnergy
carbonEmission
electricityCost
chargingCost
maintenanceCost
```

典型输入：

```text
machineEnergy
AGVEnergy
machineTable
AGVTable
carbonFactor
electricityPrice
chargePrice
```

### 依赖 due date / priority 的目标

例子：

```text
totalTardiness
weightedTardiness
lateJobCount
earlinessPenalty
```

典型输入：

```text
job completion time
dueDates
jobWeights
penaltyWeight
```

### 依赖随机扰动或鲁棒性的目标

例子：

```text
robustMakespan
scheduleStability
expectedDelay
worseCaseEnergy
```

典型输入：

```text
base schedule
scenario list
processing time perturbation
AGV speed perturbation
simulation result
```

这类目标通常更重，不建议一开始就接 formal，应先做 toy test。

## 新增目标函数步骤

新增一个目标函数时，按这个顺序走：

```text
1. 明确目标定义
2. 明确输入字段
3. 新增 compute_xxx.m
4. 新增 toy test
5. 如有 raw/baseline，新增 compare test
6. 更新 build_objectives 或新增 build_multi_objectives
7. 更新 search 中 obj_num 或目标列假设
8. 更新 metrics 和 visualization
9. 更新 config 中目标开关、权重或参数
10. 更新文档
```

注意：第 6 到第 9 步不是每次都必须马上执行。

如果只是先写目标函数 helper，可以先不接入默认 objectives。

## 目标函数测试模板

测试文件命名：

```text
tests/test_evaluation_<objective_name>.m
```

测试内容建议：

```text
手工小样本
边界情况
缺字段情况
非负/有限值检查
和 baseline 对照
```

示例：

```matlab
energy = 100;
carbonFactor = 0.58;
expectedValue = 58;

value = compute_carbon_emission(energy, carbonFactor);
assert(abs(value - expectedValue) < 1e-12);
```

再例如加权能耗：

```matlab
machineEnergy = 80;
agvEnergy = 20;
machineWeight = 1.0;
agvWeight = 1.5;
expectedValue = 110;

value = compute_weighted_total_energy(machineEnergy, agvEnergy, machineWeight, agvWeight);
assert(abs(value - expectedValue) < 1e-12);
```

测试原则：

```text
先 toy test
再 small case
最后才 search small loop
不因为一个新目标直接跑 medium/formal
```

## 接入 build_objectives 的注意事项

当前默认：

```text
objectives = [makespan, totalEnergy]
```

如果只是替换第二目标，例如：

```text
[makespan, carbonEmission]
```

需要同步更新：

```text
build_objectives
summary.txt 字段名
metrics 文档
visualization 轴标签
实验说明
论文表格说明
```

如果新增第三目标，例如：

```text
[makespan, totalEnergy, totalTardiness]
```

必须检查：

```text
obj_num
non_domination
replace_chrom
obj_matrix
metrics
plot
summary.txt
run_info.txt
```

不要只改 evaluation，就以为三目标已经完成。

## 接入 search 的注意事项

搜索层通常会默认目标矩阵的列数和含义。

新增目标前要检查：

```text
NSGA-II 非支配排序是否支持新目标数
拥挤距离是否支持新目标数
结果 obj_matrix 是否保存所有目标列
summary 是否仍然只写 bestMakespan / bestTotalEnergy
metrics 是否需要 referencePoint / referenceFront 变化
visualization 是否仍然是二维 Pareto 图
```

如果搜索层当前只按两目标写死，就不能直接塞第三目标。

推荐做法：

```text
先写目标 helper
再写 evaluation test
再写 build_objectives 变体
再写 search small loop
再考虑 medium
最后 formal
```

## config 设计建议

目标函数参数不要硬编码在函数里。

建议未来 config 结构：

```matlab
config.objectives.names = {'makespan', 'totalEnergy'};
config.objectives.enabled = {'makespan', 'carbonEmission'};
config.objectives.weights = [];
```

如果目标需要参数：

```matlab
config.objectives.carbonFactor = 0.58;
config.objectives.electricityPrice = 0.8;
config.objectives.dueDates = [];
config.objectives.penaltyWeight = 100;
```

如果是多目标优化：

```text
weights 可以为空
不要把多目标偷偷变成加权单目标
```

如果是加权目标：

```text
文档里必须写清权重含义
测试里必须覆盖权重变化
```

## metrics 联动

新增目标后，metrics 层可能需要更新。

需要检查：

```text
obj_matrix 列数是否变化
HV referencePoint 维度是否变化
IGD referenceFront 维度是否变化
C-metric 是否仍然同维度比较
Spacing 是否仍然可计算
论文表格字段是否变化
```

如果新目标是第三目标，当前二维 HV 和二维 Pareto 图可能不够用。

不要在 metrics 里猜目标列含义，应由 config 或文档明确。

## visualization 联动

新增目标后，图表层需要检查：

```text
Pareto 图坐标轴名称
二维还是三维
收敛曲线显示哪些目标
summary 图表字段
论文图标题
```

如果仍然画二维图，要明确选择哪两个目标。

例如：

```text
x = makespan
y = carbonEmission
```

不要继续写 `Total energy` 轴标签。

## 完成标准

一个新目标函数真正接入完成，至少满足：

```text
目标定义写清
输入字段写清
compute_xxx.m 可单独调用
toy test 通过
invalid case 有覆盖或风险记录
build_objectives 或 build_multi_objectives 更新
search small loop 通过
metrics 能处理新的 obj_matrix
visualization 轴标签正确
config 参数可追溯
docs 写明新目标含义
未修改 raw_code
未污染 outputs
```

如果只是模板阶段，则完成标准是：

```text
有中文模板文档
说明新目标放哪里
说明标准接口
说明测试方式
说明接入 search 的影响
说明 config 参数设计
说明 metrics / visualization 联动
不改变当前默认 objectives
不跑正式实验
```

## 最小安全原则

新增目标函数时始终遵守：

```text
先 helper，后接入
先 toy test，后 search
先 small，后 medium
最后才 formal
不改 raw_code
不在 search 里写目标公式
不硬编码参数
不忘记 metrics 和 visualization
```

这能避免把“论文创新目标”改成一个难以复现的临时补丁。

# 第 8 步：配置入口测试

## 1. 这一步在做什么

第 6 步已经建立了配置入口：

```text
configs/small_nsga2_config.m
```

第 7 步已经确认：

```text
读取检查 -> 单条评价检查 -> 小种群检查 -> 配置化运行
```

可以走通。

第 8 步要补的是一个更小的检查：

```text
配置文件本身是不是完整、可读、路径有效、参数合理。
```

它不运行完整 NSGA-II。

## 2. 新增了什么

新增测试：

```text
tests/test_small_nsga2_config.m
```

这个测试只检查配置，不跑算法主流程。

## 3. 它检查什么

它会检查：

| 检查对象 | 检查内容 |
|---|---|
| `config.paths.fjsp` | `.fjs` 文件是否存在 |
| `config.paths.machineExcel` | 机器 Excel 是否存在 |
| `config.paths.agvExcel` | AGV Excel 是否存在 |
| `config.paths.algorithmDir` | 算法目录是否存在 |
| `config.paths.outputBaseDir` | 输出目录字段是否存在 |
| `config.algorithm.pop` | 是否为正整数 |
| `config.algorithm.max_gen` | 是否为正整数 |
| `config.algorithm.p_cross` | 是否在 0 到 1 之间 |
| `config.algorithm.p_mutation` | 是否在 0 到 1 之间 |
| `config.random.seed` | 是否存在并且是数字 |
| `config.energy.AGVEG_MAX` | 是否为正数 |
| `config.energy.eChargeSpeed` | 是否为正数 |

还会检查：

```text
测试不能在项目根目录乱生成文件。
```

## 4. 为什么这一步有用

以后你换数据或改参数时，最容易犯的错误不是算法错，而是：

```text
路径写错
文件不存在
参数空了
pop / max_gen 写成不合理值
交叉率或变异率超出 0 到 1
```

配置入口测试可以在运行 NSGA-II 之前先提醒你。

也就是说，它是：

```text
换数据和改参数前的门口检查。
```

## 5. 怎么运行

在 MATLAB 中运行：

```matlab
cd D:\CODEX\code_refactor_project
run('tests/test_small_nsga2_config.m')
```

正常时会输出类似：

```text
test_small_nsga2_config passed: pop=10, max_gen=2, seed=42
```

## 6. 这一步和小种群测试的区别

`test_small_nsga2_config.m` 只检查配置：

```text
配置文件能不能读
路径和参数是否合理
```

`test_small_nsga2.m` 会真的跑小种群算法：

```text
配置和数据能不能支撑 NSGA-II 跑完 2 代
```

所以顺序建议是：

```text
先跑 test_small_nsga2_config.m
再跑 test_small_nsga2.m
最后再跑 scripts/run_small_nsga2.m
```

## 7. 第 8 步完成标准

第 8 步完成的标准是：

```text
配置入口有独立测试
测试不跑完整算法
测试不生成 outputs
测试能提前发现路径和参数问题
```

当前第 8 步已经由你在 MATLAB 本地跑通。

本次输出：

```text
test_small_nsga2_config passed: pop=10, max_gen=2, seed=42
```

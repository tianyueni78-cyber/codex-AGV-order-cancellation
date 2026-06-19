# independent 实验入口说明

## 1. 本阶段目标

本阶段建立完全 independent 的实验入口。这里的 independent 指：

```text
不调用 raw_code/NSGA-II/NSGA2.m
不调用 raw fitness.m
不调用 raw sorting.m
搜索流程只调用 src/encoding、src/decoding、src/evaluation、src/search
```

当前阶段仍然按 small -> medium -> formal preflight 的顺序推进。formal 入口只做运行前检查，默认不启动正式实验。

## 2. 入口与配置

| 档位 | 配置 | 脚本 | 用途 |
|---|---|---|---|
| independent small | `configs/independent_small_config.m` | `scripts/run_independent_small_nsga2.m` | 小规模 smoke 验收 |
| independent medium | `configs/independent_medium_config.m` | `scripts/run_independent_medium_nsga2.m` | 中等规模验收 |
| independent formal | `configs/independent_formal_config.m` | `scripts/run_independent_formal_nsga2.m` | formal 运行前检查，默认不跑正式实验 |

## 3. 参数规则

当前参数：

```text
independent small:
  pop = 10
  max_gen = 2
  seed = 42

independent medium:
  pop = 20
  max_gen = 5
  seed = 42

independent formal:
  pop = 30
  max_gen = 10
  seedList = [42, 43, 44, 45, 46]
  currentSeed = 42
```

## 4. 输出目录

每次运行会写入独立输出目录：

```text
outputs/independent_small_nsga2/<timestamp>/
outputs/independent_medium_nsga2/<timestamp>/
outputs/independent_formal_nsga2/<timestamp>/
```

small 和 medium 每个 run 目录包含：

```text
result.mat
summary.txt
run_info.txt
```

`outputs/` 不提交 Git。

## 5. MATLAB 运行命令

先运行配置 dry-run：

```matlab
run('tests/test_independent_experiment_configs.m')
run('tests/test_independent_formal_preflight.m')
```

运行 independent small：

```matlab
run('scripts/run_independent_small_nsga2.m')
```

运行 independent medium：

```matlab
run('scripts/run_independent_medium_nsga2.m')
```

formal 默认只做 preflight：

```matlab
run('scripts/run_independent_formal_nsga2.m')
```

如果以后明确要跑 independent formal，需要单独开任务，并显式设置确认变量：

```matlab
RUN_INDEPENDENT_FORMAL_CONFIRMED = true;
run('scripts/run_independent_formal_nsga2.m')
```

## 6. 通过后应检查什么

small / medium 运行后检查：

```text
result.mat 存在
summary.txt 存在
run_info.txt 存在
obj_matrix 非空
runInfo.isIndependent = 1
usedRawSearch = 0
usedRawDecoding = 0
usedRawEvaluation = 0
```

formal preflight 检查：

```text
脚本存在
配置字段完整
默认不会启动正式实验
需要确认变量才会运行 formal
```

## 7. 当前没有完成什么

当前阶段不是论文正式实验，不验证最终论文指标，也不跑多 seed formal。正式 formal 应该在 raw 对照、small、medium 都通过后单独开任务。

## 8. 完成标准

本阶段完成后，项目具备：

```text
independent small 可跑
independent medium 可跑
independent formal 有 preflight
输出目录独立
summary/run_info/result 完整
不依赖 raw_code
outputs 不进 Git
```

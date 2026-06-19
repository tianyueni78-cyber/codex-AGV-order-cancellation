# 实验入口规范说明

## 1. 当前阶段说明

当前阶段不是正式实验。

当前阶段只规范实验入口，不验证论文结果。

本阶段目标是把 small、medium、formal 三类入口的用途、配置来源、seed、输出目录和运行方式写清楚，避免后续复现实验时混淆入口或污染输出。

## 2. small / medium / formal 的区别

| 入口类型 | 用途 | 运行成本 | 是否建议常跑 | 输出目录 |
|---|---|---|---|---|
| small | smoke test / 小闭环验收 | 低 | 可以 | `outputs/small_nsga2/<timestamp>/` |
| small_refactored | 验证 refactored encoding/search 小闭环 | 低 | 可以 | `outputs/small_nsga2_refactored/<timestamp>/` |
| medium | 中等规模复现 / 轻微放大检查 | 中 | 不建议频繁跑 | `outputs/medium_nsga2/<timestamp>/` |
| formal | 正式实验入口 | 高 | 不建议在验收阶段跑 | `outputs/formal_nsga2/<timestamp>/` |

推荐顺序：

```text
先跑配置 dry-run
-> 再跑 search small loop 测试
-> 需要时手动跑 small 脚本
-> medium/formal 另开任务
```

## 3. 推荐先跑哪个入口

日常验收优先跑测试入口：

```matlab
run('tests/test_experiment_entry_configs.m')
run('tests/test_search_small_loop.m')
```

这两个入口用于确认：

```text
配置字段完整
seed 可追溯
输出目录在 outputs/ 下
small search loop 可运行
结果结构非空
```

如果只是确认项目没有坏，不建议直接跑 medium 或 formal。

## 4. 每个入口对应脚本和 config

| 入口 | 脚本 | 配置 |
|---|---|---|
| small | `scripts/run_small_nsga2.m` | `configs/small_nsga2_config.m` |
| small_refactored | `scripts/run_small_nsga2_refactored.m` | `configs/small_nsga2_config.m`，脚本内改输出目录 |
| medium | `scripts/run_medium_nsga2.m` | `configs/medium_nsga2_config.m` |
| formal | `scripts/run_formal_nsga2.m` | `configs/formal_nsga2_config.m` |

`configs/default.yaml` 当前不是 NSGA-II 实验入口的主要配置来源。

## 5. 每个入口输出目录

脚本入口会写 `outputs/`：

```text
scripts/run_small_nsga2.m
-> outputs/small_nsga2/<timestamp>/

scripts/run_small_nsga2_refactored.m
-> outputs/small_nsga2_refactored/<timestamp>/

scripts/run_medium_nsga2.m
-> outputs/medium_nsga2/<timestamp>/

scripts/run_formal_nsga2.m
-> outputs/formal_nsga2/<timestamp>/
```

这些脚本都使用 timestamp 目录。如果同名目录已经存在，会追加：

```text
_01
_02
...
```

所以旧 outputs 不会被覆盖。

## 6. seed 在哪里

small：

```text
configs/small_nsga2_config.m
config.random.seed = 42
```

medium：

```text
configs/medium_nsga2_config.m
继承 small seed
config.random.seed = 42
```

formal：

```text
configs/formal_nsga2_config.m
config.random.seedList = 42
config.random.currentSeed = config.random.seed
```

脚本中通过 `rng(...)` 固定随机种子。

## 7. 参数在哪里

small 参数：

```text
configs/small_nsga2_config.m
pop = 10
max_gen = 2
p_cross = 0.8
p_mutation = 0.2
```

medium 参数：

```text
configs/medium_nsga2_config.m
pop = 20
max_gen = 5
其余参数继承 small
```

formal 参数：

```text
configs/formal_nsga2_config.m
pop = 30
max_gen = 10
其余参数继承 medium/small
```

能耗参数来自：

```text
config.energy.AGVEG_MAX
config.energy.eChargeSpeed
```

## 8. MATLAB 运行命令

先切到项目根目录：

```matlab
cd('D:\CODEX\code_refactor_project')
```

推荐 dry-run 配置检查：

```matlab
run('tests/test_experiment_entry_configs.m')
```

推荐 small search loop 检查：

```matlab
run('tests/test_search_small_loop.m')
```

如果需要手动运行 small 脚本：

```matlab
run('scripts/run_small_nsga2.m')
```

如果需要手动运行 refactored small 脚本：

```matlab
run('scripts/run_small_nsga2_refactored.m')
```

本阶段不要运行：

```matlab
run('scripts/run_medium_nsga2.m')
run('scripts/run_formal_nsga2.m')
```

medium/formal 应另开任务。

## 9. 哪些入口会生成 outputs

会生成 outputs 的入口：

```text
scripts/run_small_nsga2.m
scripts/run_small_nsga2_refactored.m
scripts/run_medium_nsga2.m
scripts/run_formal_nsga2.m
```

不会生成正式 outputs 的推荐测试入口：

```text
tests/test_experiment_entry_configs.m
tests/test_search_small_loop.m
tests/test_small_nsga2_config.m
```

`outputs/` 已在 `.gitignore` 中，不应提交到 Git。

## 10. 哪些入口不要在验收阶段跑

本阶段不要跑：

```text
scripts/run_medium_nsga2.m
scripts/run_formal_nsga2.m
```

原因：

```text
medium 是中等规模复现，运行成本更高
formal 是正式实验入口，不应混入入口规范化验收
```

当前阶段只确认配置、路径、seed、输出规则。

## 11. 如何确认没有污染 raw_code

运行：

```bash
git status
git status --short -- raw_code
```

再检查：

```powershell
git status --short -- outputs
git status --ignored --short -- outputs
Test-Path logs
Test-Path tmp
Test-Path cache
Test-Path data.mat
```

通过标准：

```text
raw_code/ 无变化
outputs/ 不被 stage
outputs/ 被 .gitignore 忽略
logs/tmp/cache/data.mat 不存在
```

## 12. 后续正式实验应该另开任务

后续如果要跑 medium 或 formal，应另开任务处理：

```text
medium 运行验收
formal 运行前检查
formal 正式运行
metrics 指标计算
visualization 图表生成
论文实验记录
```

不要在实验入口规范化任务里直接跑 formal。

这一阶段完成后，只说明：

```text
入口用途清楚
参数来源清楚
seed 清楚
输出目录清楚
不会写 raw_code
不会覆盖旧 outputs
```

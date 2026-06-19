# 第 25 步：independent small / medium / formal 验收

## 目标

这一阶段建立完全 independent 的实验入口：

```text
independent small
independent medium
independent formal preflight
```

small 和 medium 真实运行；formal 只做 preflight，默认不启动正式实验。

## 新增配置入口

```text
configs/independent_small_config.m
configs/independent_medium_config.m
configs/independent_formal_config.m
```

## 新增运行入口

```text
scripts/run_independent_small_nsga2.m
scripts/run_independent_medium_nsga2.m
scripts/run_independent_formal_nsga2.m
```

## 新增测试入口

```matlab
run('tests/test_independent_experiment_configs.m')
run('tests/test_independent_formal_preflight.m')
```

说明文档：

```text
docs/06_experiments/independent_experiment_entry_guide.md
```

## MATLAB 运行命令

运行 independent small：

```matlab
run('scripts/run_independent_small_nsga2.m')
```

运行 independent medium：

```matlab
run('scripts/run_independent_medium_nsga2.m')
```

运行 independent formal preflight：

```matlab
run('scripts/run_independent_formal_nsga2.m')
```

真正运行 independent formal 需要显式确认：

```matlab
RUN_INDEPENDENT_FORMAL_CONFIRMED = true;
run('scripts/run_independent_formal_nsga2.m')
```

## 输出目录

```text
outputs/independent_small_nsga2/<timestamp>/
outputs/independent_medium_nsga2/<timestamp>/
outputs/independent_formal_nsga2/<timestamp>/
```

small / medium 每个 run 目录包含：

```text
result.mat
summary.txt
run_info.txt
```

## 已完成内容

```text
independent small 已运行并通过
independent medium 已运行并通过
independent formal preflight 已通过
formal 默认没有启动正式实验
raw_code 未修改
outputs 未提交
```

## 当前结论

第 25 步完成后，项目已经具备第一版 independent 实验入口：

```text
src 是 independent 实现
scripts 有 independent small / medium / formal 入口
tests 有 independent 验收和 raw 对照
docs 有入口说明
raw_code 保持只读 baseline
```


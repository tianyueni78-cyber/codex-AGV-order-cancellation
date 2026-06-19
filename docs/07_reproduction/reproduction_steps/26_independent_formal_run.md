# 第 26 步：independent formal 真正运行

## 目标

验证 independent 链路不只能够通过 small / medium 测试，还能在 formal 档位真实运行并产生可追溯结果。

## 运行入口

```text
配置：configs/independent_formal_config.m
脚本：scripts/run_independent_formal_nsga2.m
检查：tests/test_independent_formal_preflight.m
```

MATLAB 命令：

```matlab
run('tests/test_independent_formal_preflight.m')
RUN_INDEPENDENT_FORMAL_CONFIRMED = true;
run('scripts/run_independent_formal_nsga2.m')
```

## 已完成结果

最新一次已验收运行：

```text
输出目录：outputs/independent_formal_nsga2/20260529_143851/
dataset：Mk01
seed：42
pop：30
max_gen：10
runTime：7.625127
paretoSolutionCount：4
bestMakespan：111.853333
bestTotalEnergy：1669.020000
```

输出文件：

```text
result.mat
summary.txt
run_info.txt
```

独立性标记：

```text
isIndependent = 1
usedRawSearch = 0
usedRawDecoding = 0
usedRawEvaluation = 0
```

## 完成结论

```text
independent formal 已真实跑通
obj_matrix 非空
curve.min / curve.avg 可用
运行参数和结果可追溯
raw_code 未修改
outputs 未提交 Git
```

本步骤证明当前数据和当前 formal 参数能够运行，不代表任意更大数据或任意参数都已经验证。

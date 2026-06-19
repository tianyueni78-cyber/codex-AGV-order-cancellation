# 第 30 步：新项目迁移演练

## 目标

验证当前项目不只能够复现 Mk01，还能够作为新论文选题的工程骨架。

## 演练场景

```text
新问题：低碳 FJSP-AGV 调度
新目标：carbonEmission
新算法改进：adaptiveMutation
```

## 新增内容

```text
迁移演练文档：
docs/08_engineering/new_project_migration_rehearsal.md

模板配置：
configs/template_project_small_config.m

字段测试：
tests/test_migration_template_config.m
```

测试命令：

```matlab
run('tests/test_migration_template_config.m')
```

测试已通过，确认模板能够表达：

```text
projectName
可配置数据路径
objectives.names
carbonEmission
outputBaseDir
seed
pop / max_gen
adaptiveMutation 开关
```

## 迁移顺序

```text
config / data dry-run
-> encoding
-> decoding
-> evaluation
-> independent small
-> metrics / visualization
-> independent medium
-> formal preflight
-> independent formal
-> baseline / multiseed
```

## 完成结论

当前框架已经具备迁移模板和迁移操作说明，可以用于相近的 FJSP-AGV 新项目。

这不表示任意新问题都可以零修改运行。新项目仍需根据变化范围替换：

```text
数据变更 -> data / config
染色体变更 -> encoding
调度规则变更 -> decoding
目标变更 -> evaluation
算法改进 -> search
```

本步骤是迁移演练和模板验收，没有创建完整的新论文项目，也没有运行新项目 formal。

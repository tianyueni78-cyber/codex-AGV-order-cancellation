# visualization 图表层说明

## 这一层是做什么的

visualization 图表层负责把算法结果转换成可复用的图表入口。

它接收已经算好的数据，例如：

```text
objMatrix
curve
schedule
energyHistory
```

然后画图或保存图片。

当前阶段不运行 NSGA-II，不运行 medium/formal，也不读取正式 outputs。

## 当前已经完成的入口

代码入口：

```text
src/visualization/plot_pareto_front.m
src/visualization/plot_convergence_curve.m
src/visualization/save_figure_safely.m
```

辅助函数：

```text
src/visualization/get_option.m
src/visualization/validate_visual_matrix.m
```

测试入口：

```text
tests/test_visualization_toy_cases.m
tests/test_visualization_save_figure.m
```

## Pareto 图输入

`plot_pareto_front` 接收二维目标矩阵：

```matlab
objMatrix = [
    makespan, totalEnergy
    makespan, totalEnergy
];

fig = plot_pareto_front(objMatrix, options);
```

当前版本只支持二维目标图，因为当前项目主要目标是：

```text
makespan
totalEnergy
```

## 收敛曲线输入

`plot_convergence_curve` 接收搜索结果中的 curve 结构：

```matlab
curve.min
curve.avg
```

示例：

```matlab
fig = plot_convergence_curve(curve, options);
```

如果 `curve.avg` 存在，会用虚线画平均值；`curve.min` 是必需字段。

## 保存图片规则

`save_figure_safely` 只保存到外部传入的路径：

```matlab
save_figure_safely(fig, fullfile(outputDir, 'pareto.png'));
```

这一层不会默认写入项目根目录，也不会默认写入 `raw_code/`。

正式实验接入时，推荐保存到：

```text
outputs/<experiment_name>/<timestamp>/figures/
```

## raw 绘图代码现状

只读检查发现：

```text
raw_code/machine_AGV_gantt_chart.m
raw_code/energy_plot.m
raw_code/dif_main.m
raw_code/same_main.m
```

raw 脚本会直接 `figure`，并把图片保存到相对 `figures/` 目录。

当前阶段没有修改这些 raw 文件。

## 当前没有完成什么

当前阶段不是正式画论文图。

当前阶段没有运行正式实验。

当前阶段没有实现机器/AGV 甘特图的新接口。

当前阶段没有实现 AGV 能耗曲线的新接口。

甘特图需要稳定的 `machineTable`、`AGVTable`、工件标签和颜色映射；能耗曲线需要稳定的 `agvEGRecord` 和 `agvChargeNum`。这两类图建议后续单独验收，避免把图表层一次拆得太大。

## 如何运行测试

在 MATLAB 中运行：

```matlab
run('tests/test_visualization_toy_cases.m')
run('tests/test_visualization_save_figure.m')
```

`test_visualization_toy_cases.m` 不保存图片，不生成 outputs。

`test_visualization_save_figure.m` 只保存到 MATLAB 临时目录，用来验证保存路径由调用方控制。

## 后续如何接正式 outputs

正式实验跑完后，可以从：

```text
outputs/<experiment_name>/<timestamp>/result.mat
```

读取：

```text
objMatrix
curve
```

然后调用：

```matlab
fig = plot_pareto_front(objMatrix, options);
save_figure_safely(fig, fullfile(outputDir, 'figures', 'pareto.png'));

fig = plot_convergence_curve(curve, options);
save_figure_safely(fig, fullfile(outputDir, 'figures', 'convergence.png'));
```

这样新项目只要能输出 `objMatrix` 和 `curve`，就可以复用这一层画基础论文图。

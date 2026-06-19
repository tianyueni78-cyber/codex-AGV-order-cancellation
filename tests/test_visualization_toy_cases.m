projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'src', 'visualization'));

oldVisible = get(0, 'DefaultFigureVisible');
set(0, 'DefaultFigureVisible', 'off');
cleanup = onCleanup(@() set(0, 'DefaultFigureVisible', oldVisible));

objMatrix = [
    10, 100
    12, 90
    15, 80
];

curve = struct();
curve.min = [
    15, 12, 10
    120, 100, 80
];
curve.avg = [
    20, 16, 13
    150, 130, 100
];

paretoOptions = struct();
paretoOptions.visible = 'off';
paretoOptions.xLabel = 'Makespan';
paretoOptions.yLabel = 'Total energy';
paretoOptions.title = 'Toy Pareto';
figPareto = plot_pareto_front(objMatrix, paretoOptions);
assert(ishghandle(figPareto, 'figure'), 'Pareto plot should return a figure handle.');

curveOptions = struct();
curveOptions.visible = 'off';
curveOptions.objectiveNames = {'makespan', 'energy'};
figCurve = plot_convergence_curve(curve, curveOptions);
assert(ishghandle(figCurve, 'figure'), 'Convergence plot should return a figure handle.');

close(figPareto);
close(figCurve);

fprintf('test_visualization_toy_cases passed: Pareto and convergence figures created without outputs\n');

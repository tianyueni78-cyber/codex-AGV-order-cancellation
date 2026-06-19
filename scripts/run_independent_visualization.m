clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'src', 'visualization'));

formalOutputBaseDir = fullfile(projectRoot, 'outputs', ...
    'independent_formal_nsga2');
formalRunDir = find_latest_run_dir(formalOutputBaseDir);
resultPath = fullfile(formalRunDir, 'result.mat');

if ~isfile(resultPath)
    error('run_independent_visualization:ResultNotFound', ...
        'Could not find independent formal result file: %s', resultPath);
end

resultData = load(resultPath, 'NSGA2_Result');
if ~isfield(resultData, 'NSGA2_Result')
    error('run_independent_visualization:MissingNSGA2Result', ...
        'result.mat is missing NSGA2_Result.');
end

NSGA2_Result = resultData.NSGA2_Result;
if ~isfield(NSGA2_Result, 'obj_matrix') || ...
        ~isfield(NSGA2_Result, 'curve')
    error('run_independent_visualization:MissingResultFields', ...
        'NSGA2_Result must contain obj_matrix and curve.');
end

figuresDir = fullfile(formalRunDir, 'figures');
if ~exist(figuresDir, 'dir')
    mkdir(figuresDir);
end

plotOptions = struct();
plotOptions.visible = 'off';
plotOptions.xLabel = 'Makespan';
plotOptions.yLabel = 'Total energy';
plotOptions.title = 'Independent formal Pareto front';
paretoFig = plot_pareto_front(NSGA2_Result.obj_matrix, plotOptions);
save_figure_safely(paretoFig, fullfile(figuresDir, 'pareto.png'));
close(paretoFig);

curveOptions = struct();
curveOptions.visible = 'off';
curveOptions.objectiveNames = {'makespan', 'totalEnergy'};
curveOptions.title = 'Independent formal convergence';
convergenceFig = plot_convergence_curve(NSGA2_Result.curve, curveOptions);
save_figure_safely(convergenceFig, fullfile(figuresDir, 'convergence.png'));
close(convergenceFig);

fprintf('independent visualization finished.\n');
fprintf('sourceRunDir: %s\n', formalRunDir);
fprintf('paretoFigure: %s\n', fullfile(figuresDir, 'pareto.png'));
fprintf('convergenceFigure: %s\n', fullfile(figuresDir, 'convergence.png'));

function latestRunDir = find_latest_run_dir(baseDir)
if ~exist(baseDir, 'dir')
    error('run_independent_visualization:BaseDirNotFound', ...
        'Independent formal output base directory does not exist: %s', baseDir);
end

items = dir(baseDir);
isRunDir = [items.isdir] & ~ismember({items.name}, {'.', '..'});
runDirs = items(isRunDir);
if isempty(runDirs)
    error('run_independent_visualization:NoRunDirsFound', ...
        'No independent formal run directories found under: %s', baseDir);
end

[~, idx] = max([runDirs.datenum]);
latestRunDir = fullfile(baseDir, runDirs(idx).name);
end

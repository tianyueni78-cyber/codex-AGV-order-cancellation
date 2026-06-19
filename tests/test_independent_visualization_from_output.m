clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'visualization'));

runDir = find_latest_run_dir(fullfile(projectRoot, 'outputs', ...
    'independent_formal_nsga2'));
resultPath = fullfile(runDir, 'result.mat');
assert(isfile(resultPath), 'Independent formal result.mat should exist.');

data = load(resultPath, 'NSGA2_Result');
assert(isfield(data, 'NSGA2_Result'), 'NSGA2_Result is missing.');
assert(isfield(data.NSGA2_Result, 'obj_matrix'), 'obj_matrix is missing.');
assert(isfield(data.NSGA2_Result, 'curve'), 'curve is missing.');

beforeRootFiles = dir(projectRoot);
beforeRootNames = sort({beforeRootFiles.name});

paretoFig = plot_pareto_front(data.NSGA2_Result.obj_matrix, ...
    struct('visible', 'off'));
assert(ishghandle(paretoFig, 'figure'), ...
    'plot_pareto_front should return a figure.');
close(paretoFig);

curveFig = plot_convergence_curve(data.NSGA2_Result.curve, ...
    struct('visible', 'off'));
assert(ishghandle(curveFig, 'figure'), ...
    'plot_convergence_curve should return a figure.');
close(curveFig);

afterRootFiles = dir(projectRoot);
afterRootNames = sort({afterRootFiles.name});
assert(isequal(beforeRootNames, afterRootNames), ...
    'Visualization test created or removed project-root files.');

fprintf(['test_independent_visualization_from_output passed: ', ...
    'runDir=%s, objRows=%d, curveGen=%d\n'], ...
    runDir, size(data.NSGA2_Result.obj_matrix, 1), ...
    size(data.NSGA2_Result.curve.min, 2));

function latestRunDir = find_latest_run_dir(baseDir)
assert(isfolder(baseDir), ...
    'Independent formal output base directory does not exist.');
items = dir(baseDir);
isRunDir = [items.isdir] & ~ismember({items.name}, {'.', '..'});
runDirs = items(isRunDir);
assert(~isempty(runDirs), 'No independent formal run directories found.');
[~, idx] = max([runDirs.datenum]);
latestRunDir = fullfile(baseDir, runDirs(idx).name);
end

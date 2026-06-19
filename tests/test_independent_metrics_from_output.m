clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'metrics'));

runDir = find_latest_run_dir(fullfile(projectRoot, 'outputs', ...
    'independent_formal_nsga2'));
resultPath = fullfile(runDir, 'result.mat');
assert(isfile(resultPath), 'Independent formal result.mat should exist.');

data = load(resultPath, 'NSGA2_Result');
assert(isfield(data, 'NSGA2_Result'), 'NSGA2_Result is missing.');
assert(isfield(data.NSGA2_Result, 'obj_matrix'), 'obj_matrix is missing.');

summary = compute_metric_summary(data.NSGA2_Result.obj_matrix, struct());
assert(isstruct(summary), 'Metric summary should be a struct.');
assert(summary.solutionCount > 0, 'solutionCount should be positive.');
assert(summary.objectiveCount == 2, 'objectiveCount should be 2.');
assert(isfinite(summary.spacing), 'spacing should be finite.');
assert(isnan(summary.hv), 'hv should be NaN without referencePoint.');
assert(isnan(summary.igd), 'igd should be NaN without referenceFront.');
assert(isnan(summary.cMetric), ...
    'cMetric should be NaN without baselineObjMatrix.');
assert(numel(summary.warnings) >= 3, ...
    'Missing-reference warnings should be recorded.');

fprintf(['test_independent_metrics_from_output passed: ', ...
    'runDir=%s, solutionCount=%d, spacing=%.6f\n'], ...
    runDir, summary.solutionCount, summary.spacing);

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

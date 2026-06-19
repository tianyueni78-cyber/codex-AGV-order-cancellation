clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'src', 'metrics'));

formalOutputBaseDir = fullfile(projectRoot, 'outputs', ...
    'independent_formal_nsga2');
formalRunDir = find_latest_run_dir(formalOutputBaseDir);
resultPath = fullfile(formalRunDir, 'result.mat');

if ~isfile(resultPath)
    error('run_independent_metrics:ResultNotFound', ...
        'Could not find independent formal result file: %s', resultPath);
end

resultData = load(resultPath, 'NSGA2_Result', 'runInfo', 'config');
if ~isfield(resultData, 'NSGA2_Result')
    error('run_independent_metrics:MissingNSGA2Result', ...
        'result.mat is missing NSGA2_Result.');
end

NSGA2_Result = resultData.NSGA2_Result;
if ~isfield(NSGA2_Result, 'obj_matrix')
    error('run_independent_metrics:MissingObjMatrix', ...
        'NSGA2_Result is missing obj_matrix.');
end

objMatrix = NSGA2_Result.obj_matrix;
options = struct();
metricSummary = compute_metric_summary(objMatrix, options);

metricsDir = fullfile(formalRunDir, 'metrics');
if ~exist(metricsDir, 'dir')
    mkdir(metricsDir);
end

summaryPath = fullfile(metricsDir, 'summary.txt');
write_metric_summary(summaryPath, formalRunDir, metricSummary);

save(fullfile(metricsDir, 'metrics_result.mat'), ...
    'metricSummary', 'objMatrix', 'formalRunDir');

fprintf('independent metrics summary finished.\n');
fprintf('sourceRunDir: %s\n', formalRunDir);
fprintf('solutionCount: %d\n', metricSummary.solutionCount);
fprintf('objectiveCount: %d\n', metricSummary.objectiveCount);
fprintf('spacing: %.6f\n', metricSummary.spacing);
fprintf('hv: %.6f\n', metricSummary.hv);
fprintf('igd: %.6f\n', metricSummary.igd);
fprintf('cMetric: %.6f\n', metricSummary.cMetric);
fprintf('metricsDir: %s\n', metricsDir);

function latestRunDir = find_latest_run_dir(baseDir)
if ~exist(baseDir, 'dir')
    error('run_independent_metrics:BaseDirNotFound', ...
        'Independent formal output base directory does not exist: %s', baseDir);
end

items = dir(baseDir);
isRunDir = [items.isdir] & ~ismember({items.name}, {'.', '..'});
runDirs = items(isRunDir);
if isempty(runDirs)
    error('run_independent_metrics:NoRunDirsFound', ...
        'No independent formal run directories found under: %s', baseDir);
end

[~, idx] = max([runDirs.datenum]);
latestRunDir = fullfile(baseDir, runDirs(idx).name);
end

function write_metric_summary(summaryPath, formalRunDir, metricSummary)
fid = fopen(summaryPath, 'w');
if isequal(fid, -1)
    error('run_independent_metrics:SummaryOpenFailed', ...
        'Could not open metrics summary file: %s', summaryPath);
end
cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, 'independent metrics summary\n');
fprintf(fid, 'sourceRunDir: %s\n', formalRunDir);
fprintf(fid, 'solutionCount: %d\n', metricSummary.solutionCount);
fprintf(fid, 'objectiveCount: %d\n', metricSummary.objectiveCount);
fprintf(fid, 'spacing: %.6f\n', metricSummary.spacing);
fprintf(fid, 'hv: %.6f\n', metricSummary.hv);
fprintf(fid, 'igd: %.6f\n', metricSummary.igd);
fprintf(fid, 'cMetric: %.6f\n', metricSummary.cMetric);
for i = 1:numel(metricSummary.warnings)
    fprintf(fid, 'warning: %s\n', metricSummary.warnings{i});
end
clear cleanupObj
end

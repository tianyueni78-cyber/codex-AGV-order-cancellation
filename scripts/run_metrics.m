clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

formalOutputBaseDir = fullfile(projectRoot, 'outputs', 'formal_nsga2');
formalRunDir = find_latest_run_dir(formalOutputBaseDir);
resultPath = fullfile(formalRunDir, 'formal_nsga2_result.mat');

if ~isfile(resultPath)
    error('run_metrics:ResultNotFound', ...
        'Could not find formal result file: %s', resultPath);
end

resultData = load(resultPath, 'NSGA2_Result', 'config');
if ~isfield(resultData, 'NSGA2_Result')
    error('run_metrics:MissingNSGA2Result', ...
        'formal_nsga2_result.mat is missing NSGA2_Result.');
end

NSGA2_Result = resultData.NSGA2_Result;
if ~isfield(NSGA2_Result, 'obj_matrix')
    error('run_metrics:MissingObjMatrix', ...
        'NSGA2_Result is missing obj_matrix.');
end

obj_matrix = NSGA2_Result.obj_matrix;
if isempty(obj_matrix) || size(obj_matrix, 2) < 2
    error('run_metrics:InvalidObjMatrix', ...
        'obj_matrix should be non-empty and contain at least two columns.');
end

makespanValues = obj_matrix(:, 1);
totalEnergyValues = obj_matrix(:, 2);

metrics = struct();
metrics.sourceRunDir = formalRunDir;
metrics.paretoSolutionCount = size(obj_matrix, 1);
metrics.bestMakespan = min(makespanValues);
metrics.worstMakespan = max(makespanValues);
metrics.bestTotalEnergy = min(totalEnergyValues);
metrics.worstTotalEnergy = max(totalEnergyValues);
metrics.meanMakespan = mean(makespanValues);
metrics.meanTotalEnergy = mean(totalEnergyValues);

metricsDir = fullfile(formalRunDir, 'metrics');
if ~exist(metricsDir, 'dir')
    mkdir(metricsDir);
end

summaryPath = fullfile(metricsDir, 'metrics_summary.txt');
write_metrics_summary(summaryPath, metrics);

metricsResultPath = fullfile(metricsDir, 'metrics_result.mat');
save(metricsResultPath, 'metrics', 'obj_matrix');

tablePath = fullfile(metricsDir, 'metrics_table.csv');
write_metrics_table(tablePath, metrics);

fprintf('metrics summary finished.\n');
fprintf('sourceRunDir: %s\n', formalRunDir);
fprintf('paretoSolutionCount: %d\n', metrics.paretoSolutionCount);
fprintf('bestMakespan: %.6f\n', metrics.bestMakespan);
fprintf('bestTotalEnergy: %.6f\n', metrics.bestTotalEnergy);
fprintf('metricsDir: %s\n', metricsDir);

function latestRunDir = find_latest_run_dir(baseDir)
if ~exist(baseDir, 'dir')
    error('run_metrics:BaseDirNotFound', ...
        'Formal output base directory does not exist: %s', baseDir);
end

items = dir(baseDir);
isRunDir = [items.isdir] & ~ismember({items.name}, {'.', '..'});
runDirs = items(isRunDir);
if isempty(runDirs)
    error('run_metrics:NoRunDirsFound', ...
        'No formal run directories found under: %s', baseDir);
end

[~, idx] = max([runDirs.datenum]);
latestRunDir = fullfile(baseDir, runDirs(idx).name);
end

function write_metrics_summary(summaryPath, metrics)
fid = fopen(summaryPath, 'w');
if isequal(fid, -1)
    error('run_metrics:SummaryOpenFailed', ...
        'Could not open metrics summary file: %s', summaryPath);
end
cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, 'metrics summary\n');
fprintf(fid, 'sourceRunDir: %s\n', metrics.sourceRunDir);
fprintf(fid, 'paretoSolutionCount: %d\n', metrics.paretoSolutionCount);
fprintf(fid, 'bestMakespan: %.6f\n', metrics.bestMakespan);
fprintf(fid, 'worstMakespan: %.6f\n', metrics.worstMakespan);
fprintf(fid, 'bestTotalEnergy: %.6f\n', metrics.bestTotalEnergy);
fprintf(fid, 'worstTotalEnergy: %.6f\n', metrics.worstTotalEnergy);
fprintf(fid, 'meanMakespan: %.6f\n', metrics.meanMakespan);
fprintf(fid, 'meanTotalEnergy: %.6f\n', metrics.meanTotalEnergy);
clear cleanupObj
end

function write_metrics_table(tablePath, metrics)
fid = fopen(tablePath, 'w');
if isequal(fid, -1)
    error('run_metrics:TableOpenFailed', ...
        'Could not open metrics table file: %s', tablePath);
end
cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, 'metric,value\n');
fprintf(fid, 'paretoSolutionCount,%d\n', metrics.paretoSolutionCount);
fprintf(fid, 'bestMakespan,%.6f\n', metrics.bestMakespan);
fprintf(fid, 'worstMakespan,%.6f\n', metrics.worstMakespan);
fprintf(fid, 'bestTotalEnergy,%.6f\n', metrics.bestTotalEnergy);
fprintf(fid, 'worstTotalEnergy,%.6f\n', metrics.worstTotalEnergy);
fprintf(fid, 'meanMakespan,%.6f\n', metrics.meanMakespan);
fprintf(fid, 'meanTotalEnergy,%.6f\n', metrics.meanTotalEnergy);
clear cleanupObj
end

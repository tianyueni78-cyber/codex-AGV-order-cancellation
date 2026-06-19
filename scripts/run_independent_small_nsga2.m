clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

add_independent_paths(projectRoot);
config = independent_small_config(projectRoot);

rng(config.random.currentSeed);
[problem, machineData, agvData] = load_independent_data(config);

options = struct();
options.label = config.experiment.runType;
[NSGA2_Result, initialPopulation, runInfo] = run_independent_nsga2( ...
    config, problem, machineData, agvData, options);

runDir = create_independent_run_dir(config.paths.outputBaseDir);
save_independent_result(runDir, 'result.mat', NSGA2_Result, ...
    initialPopulation, runInfo, problem, machineData, agvData, config);
write_independent_summary(fullfile(runDir, 'summary.txt'), ...
    config, NSGA2_Result, runDir);
write_independent_run_info(fullfile(runDir, 'run_info.txt'), ...
    config, runInfo, runDir);
print_independent_result(config, NSGA2_Result, runDir);

function add_independent_paths(projectRoot)
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'search'));
end

function [problem, machineData, agvData] = load_independent_data(config)
problem = read_fjsp(config.paths.fjsp);
machineData = read_machine_data(config.paths.machineExcel, problem.machineNum);
agvData = read_agv_data(config.paths.agvExcel);
end

function runDir = create_independent_run_dir(baseDir)
if ~exist(baseDir, 'dir')
    mkdir(baseDir);
end

stamp = datestr(now, 'yyyymmdd_HHMMSS');
runDir = fullfile(baseDir, stamp);
suffix = 1;
while exist(runDir, 'dir')
    runDir = fullfile(baseDir, sprintf('%s_%02d', stamp, suffix));
    suffix = suffix + 1;
end
mkdir(runDir);
end

function save_independent_result(runDir, fileName, NSGA2_Result, ...
    initialPopulation, runInfo, problem, machineData, agvData, config)
if config.output.saveMat
    save(fullfile(runDir, fileName), 'NSGA2_Result', ...
        'initialPopulation', 'runInfo', 'problem', 'machineData', ...
        'agvData', 'config');
end
end

function write_independent_summary(summaryPath, config, NSGA2_Result, runDir)
if ~config.output.saveSummary
    return
end
objMatrix = NSGA2_Result.obj_matrix;
fid = fopen(summaryPath, 'w');
if isequal(fid, -1)
    error('run_independent_small_nsga2:SummaryOpenFailed', ...
        'Could not open summary file: %s', summaryPath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, 'independent NSGA-II result\n');
fprintf(fid, 'runType: %s\n', config.experiment.runType);
fprintf(fid, 'experimentName: %s\n', config.experiment.name);
fprintf(fid, 'datasetName: %s\n', config.dataset.name);
fprintf(fid, 'seed: %g\n', config.random.currentSeed);
fprintf(fid, 'pop: %d\n', config.algorithm.pop);
fprintf(fid, 'max_gen: %d\n', config.algorithm.max_gen);
fprintf(fid, 'p_cross: %.6f\n', config.algorithm.p_cross);
fprintf(fid, 'p_mutation: %.6f\n', config.algorithm.p_mutation);
fprintf(fid, 'runTime: %.6f\n', NSGA2_Result.RunTime);
fprintf(fid, 'paretoSolutionCount: %d\n', size(objMatrix, 1));
fprintf(fid, 'bestMakespan: %.6f\n', min(objMatrix(:, 1)));
fprintf(fid, 'bestTotalEnergy: %.6f\n', min(objMatrix(:, 2)));
fprintf(fid, 'outputDir: %s\n', runDir);
clear cleanupObj
end

function write_independent_run_info(runInfoPath, config, runInfo, runDir)
if ~config.output.saveRunInfo
    return
end
fid = fopen(runInfoPath, 'w');
if isequal(fid, -1)
    error('run_independent_small_nsga2:RunInfoOpenFailed', ...
        'Could not open run info file: %s', runInfoPath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, 'runType: %s\n', config.experiment.runType);
fprintf(fid, 'experimentName: %s\n', config.experiment.name);
fprintf(fid, 'description: %s\n', config.experiment.description);
fprintf(fid, 'datasetName: %s\n', config.dataset.name);
fprintf(fid, 'datasetSource: %s\n', config.dataset.source);
fprintf(fid, 'datasetNote: %s\n', config.dataset.note);
fprintf(fid, 'fjsp: %s\n', config.paths.fjsp);
fprintf(fid, 'machineExcel: %s\n', config.paths.machineExcel);
fprintf(fid, 'agvExcel: %s\n', config.paths.agvExcel);
fprintf(fid, 'implementationDir: %s\n', config.paths.implementationDir);
fprintf(fid, 'outputDir: %s\n', runDir);
fprintf(fid, 'algorithmName: %s\n', config.algorithm.name);
fprintf(fid, 'seed: %g\n', config.random.currentSeed);
fprintf(fid, 'seedList: %s\n', mat2str(config.random.seedList));
fprintf(fid, 'pop: %d\n', config.algorithm.pop);
fprintf(fid, 'max_gen: %d\n', config.algorithm.max_gen);
fprintf(fid, 'p_cross: %.6f\n', config.algorithm.p_cross);
fprintf(fid, 'p_mutation: %.6f\n', config.algorithm.p_mutation);
fprintf(fid, 'AGVEG_MAX: %.6f\n', config.energy.AGVEG_MAX);
fprintf(fid, 'eChargeSpeed: %.6f\n', config.energy.eChargeSpeed);
fprintf(fid, 'isIndependent: %d\n', runInfo.isIndependent);
fprintf(fid, 'usedRawSearch: %d\n', runInfo.usedRawSearch);
fprintf(fid, 'usedRawDecoding: %d\n', runInfo.usedRawDecoding);
fprintf(fid, 'usedRawEvaluation: %d\n', runInfo.usedRawEvaluation);
clear cleanupObj
end

function print_independent_result(config, NSGA2_Result, runDir)
objMatrix = NSGA2_Result.obj_matrix;
fprintf('independent NSGA-II finished.\n');
fprintf('runType: %s, seed: %g\n', ...
    config.experiment.runType, config.random.currentSeed);
fprintf('pop: %d, max_gen: %d\n', ...
    config.algorithm.pop, config.algorithm.max_gen);
fprintf('paretoSolutionCount: %d\n', size(objMatrix, 1));
fprintf('bestMakespan: %.6f\n', min(objMatrix(:, 1)));
fprintf('bestTotalEnergy: %.6f\n', min(objMatrix(:, 2)));
fprintf('outputDir: %s\n', runDir);
end

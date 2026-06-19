if exist('RUN_INDEPENDENT_FORMAL_CONFIRMED', 'var')
    formalConfirmed = RUN_INDEPENDENT_FORMAL_CONFIRMED;
else
    formalConfirmed = false;
end
clearvars -except formalConfirmed
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'configs'));
config = independent_formal_config(projectRoot);

fprintf('independent formal preflight passed.\n');
fprintf('experimentName: %s\n', config.experiment.name);
fprintf('runType: %s\n', config.experiment.runType);
fprintf('seedList: %s\n', mat2str(config.random.seedList));
fprintf('currentSeed: %g\n', config.random.currentSeed);
fprintf('pop: %d, max_gen: %d\n', ...
    config.algorithm.pop, config.algorithm.max_gen);
fprintf('outputBaseDir: %s\n', config.paths.outputBaseDir);

if ~formalConfirmed
    fprintf('formal run is guarded and was not started.\n');
    return
end

fprintf('formal run confirmed and will start.\n');

addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'search'));

rng(config.random.currentSeed);
problem = read_fjsp(config.paths.fjsp);
machineData = read_machine_data(config.paths.machineExcel, problem.machineNum);
agvData = read_agv_data(config.paths.agvExcel);

options = struct();
options.label = config.experiment.runType;
[NSGA2_Result, initialPopulation, runInfo] = run_independent_nsga2( ...
    config, problem, machineData, agvData, options);

runDir = create_independent_run_dir(config.paths.outputBaseDir);
if config.output.saveMat
    save(fullfile(runDir, 'result.mat'), 'NSGA2_Result', ...
        'initialPopulation', 'runInfo', 'problem', 'machineData', ...
        'agvData', 'config');
end
write_independent_summary(fullfile(runDir, 'summary.txt'), ...
    config, NSGA2_Result, runDir);
write_independent_run_info(fullfile(runDir, 'run_info.txt'), ...
    config, runInfo, runDir);

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

function write_independent_summary(summaryPath, config, NSGA2_Result, runDir)
if ~config.output.saveSummary
    return
end
objMatrix = NSGA2_Result.obj_matrix;
fid = fopen(summaryPath, 'w');
if isequal(fid, -1)
    error('run_independent_formal_nsga2:SummaryOpenFailed', ...
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
    error('run_independent_formal_nsga2:RunInfoOpenFailed', ...
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

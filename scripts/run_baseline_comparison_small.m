clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'search'));

config = baseline_comparison_config(projectRoot);
addpath(config.paths.algorithmDir);

[problem, machineData, agvData] = load_comparison_data(config);

rng(config.comparison.seed);
[baselineResult, baselineChrom, baselineRunInfo] = run_raw_baseline( ...
    config, problem, machineData, agvData);

rng(config.comparison.seed);
[variantResult, variantInitialPopulation, variantRunInfo] = ...
    run_independent_nsga2(config, problem, machineData, agvData, ...
    struct('label', config.comparison.variantName));

validate_comparison_outputs(baselineResult, variantResult, ...
    baselineRunInfo, variantRunInfo, config);

runDir = create_run_dir(config.paths.outputBaseDir);
if config.output.saveMat
    save(fullfile(runDir, 'result.mat'), 'baselineResult', ...
        'variantResult', 'baselineChrom', 'variantInitialPopulation', ...
        'baselineRunInfo', 'variantRunInfo', 'problem', 'machineData', ...
        'agvData', 'config');
end

if config.output.saveSummary
    write_summary(fullfile(runDir, 'summary.txt'), config, ...
        baselineResult, variantResult, runDir);
end

if config.output.saveRunInfo
    write_run_info(fullfile(runDir, 'run_info.txt'), config, ...
        baselineRunInfo, variantRunInfo, runDir);
end

fprintf('baseline comparison small finished.\n');
fprintf('baselineName: %s, baselineSolutions: %d\n', ...
    config.comparison.baselineName, size(baselineResult.obj_matrix, 1));
fprintf('variantName: %s, variantSolutions: %d\n', ...
    config.comparison.variantName, size(variantResult.obj_matrix, 1));
fprintf('seed: %g, pop: %d, max_gen: %d\n', ...
    config.comparison.seed, config.algorithm.pop, config.algorithm.max_gen);
fprintf('outputDir: %s\n', runDir);

function [problem, machineData, agvData] = load_comparison_data(config)
problem = read_fjsp(config.paths.fjsp);
machineData = read_machine_data(config.paths.machineExcel, problem.machineNum);
agvData = read_agv_data(config.paths.agvExcel);
end

function [result, chrom, runInfo] = run_raw_baseline(config, problem, ...
    machineData, agvData)
distanceMatrix = machineData.distance_matrix;
machineEnergy = machineData.machineEnergy;
AGVEnergy = agvData.AGVEnergy;
AGVEG_MAX = config.energy.AGVEG_MAX;
eChargeSpeed = config.energy.eChargeSpeed;

distanceMax = max([max(distanceMatrix.machine_to_machine(:)), ...
    max(distanceMatrix.load_to_machine), ...
    max(distanceMatrix.machine_to_unload), ...
    distanceMatrix.load_to_unload]);
AGVEG_MIN = distanceMax / agvData.AGVSpeed(end) * ...
    (AGVEnergy.free(end) + AGVEnergy.load(end)) + 1e-6;

speedNum = length(agvData.AGVSpeed);
chrom = init(config.algorithm.pop, problem.jobNum, problem.operaNumVec, ...
    problem.candidateMachine, agvData.AGVNum, speedNum);

result = NSGA2(config.algorithm.p_cross, config.algorithm.p_mutation, ...
    config.algorithm.pop, chrom, config.algorithm.max_gen, ...
    problem.jobNum, problem.jobInfo, problem.operaNumVec, ...
    problem.machineNum, agvData.AGVNum, agvData.AGVSpeed, ...
    problem.candidateMachine, distanceMatrix, machineEnergy, AGVEnergy, ...
    AGVEG_MAX, AGVEG_MIN, eChargeSpeed);

runInfo = struct();
runInfo.algorithmName = config.comparison.baselineName;
runInfo.seed = config.comparison.seed;
runInfo.pop = config.algorithm.pop;
runInfo.max_gen = config.algorithm.max_gen;
runInfo.p_cross = config.algorithm.p_cross;
runInfo.p_mutation = config.algorithm.p_mutation;
runInfo.isIndependent = false;
runInfo.usedRawSearch = true;
runInfo.usedRawDecoding = true;
runInfo.usedRawEvaluation = true;
end

function validate_comparison_outputs(baselineResult, variantResult, ...
    baselineRunInfo, variantRunInfo, config)
assert(~isempty(baselineResult.obj_matrix), ...
    'Baseline obj_matrix should not be empty.');
assert(~isempty(variantResult.obj_matrix), ...
    'Variant obj_matrix should not be empty.');
assert(size(baselineResult.obj_matrix, 2) == ...
    size(variantResult.obj_matrix, 2), ...
    'Baseline and variant objective column counts should match.');
assert(baselineRunInfo.seed == config.comparison.seed, ...
    'Baseline seed mismatch.');
assert(variantRunInfo.isIndependent, ...
    'Variant runInfo should report independent implementation.');
assert(variantRunInfo.pop == baselineRunInfo.pop, ...
    'Variant pop should match baseline pop.');
assert(variantRunInfo.max_gen == baselineRunInfo.max_gen, ...
    'Variant max_gen should match baseline max_gen.');
assert(~variantRunInfo.usedRawSearch && ~variantRunInfo.usedRawDecoding && ...
    ~variantRunInfo.usedRawEvaluation, ...
    'Variant should not use raw search, decoding, or evaluation.');
end

function runDir = create_run_dir(baseDir)
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

function write_summary(summaryPath, config, baselineResult, variantResult, runDir)
fid = fopen(summaryPath, 'w');
if isequal(fid, -1)
    error('run_baseline_comparison_small:SummaryOpenFailed', ...
        'Could not open summary file: %s', summaryPath);
end
cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, 'baseline comparison small\n');
fprintf(fid, 'baselineName: %s\n', config.comparison.baselineName);
fprintf(fid, 'variantName: %s\n', config.comparison.variantName);
fprintf(fid, 'datasetName: %s\n', config.dataset.name);
fprintf(fid, 'seed: %g\n', config.comparison.seed);
fprintf(fid, 'pop: %d\n', config.algorithm.pop);
fprintf(fid, 'max_gen: %d\n', config.algorithm.max_gen);
fprintf(fid, 'baselineSolutionCount: %d\n', size(baselineResult.obj_matrix, 1));
fprintf(fid, 'variantSolutionCount: %d\n', size(variantResult.obj_matrix, 1));
fprintf(fid, 'objectiveColumnCount: %d\n', size(baselineResult.obj_matrix, 2));
fprintf(fid, 'baselineBestMakespan: %.6f\n', min(baselineResult.obj_matrix(:, 1)));
fprintf(fid, 'baselineBestTotalEnergy: %.6f\n', min(baselineResult.obj_matrix(:, 2)));
fprintf(fid, 'variantBestMakespan: %.6f\n', min(variantResult.obj_matrix(:, 1)));
fprintf(fid, 'variantBestTotalEnergy: %.6f\n', min(variantResult.obj_matrix(:, 2)));
fprintf(fid, 'outputDir: %s\n', runDir);
clear cleanupObj
end

function write_run_info(runInfoPath, config, baselineRunInfo, ...
    variantRunInfo, runDir)
fid = fopen(runInfoPath, 'w');
if isequal(fid, -1)
    error('run_baseline_comparison_small:RunInfoOpenFailed', ...
        'Could not open run info file: %s', runInfoPath);
end
cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, 'runType: %s\n', config.experiment.runType);
fprintf(fid, 'experimentName: %s\n', config.experiment.name);
fprintf(fid, 'description: %s\n', config.experiment.description);
fprintf(fid, 'datasetName: %s\n', config.dataset.name);
fprintf(fid, 'baselineName: %s\n', config.comparison.baselineName);
fprintf(fid, 'variantName: %s\n', config.comparison.variantName);
fprintf(fid, 'seed: %g\n', config.comparison.seed);
fprintf(fid, 'pop: %d\n', config.algorithm.pop);
fprintf(fid, 'max_gen: %d\n', config.algorithm.max_gen);
fprintf(fid, 'p_cross: %.6f\n', config.algorithm.p_cross);
fprintf(fid, 'p_mutation: %.6f\n', config.algorithm.p_mutation);
fprintf(fid, 'outputDir: %s\n', runDir);
fprintf(fid, 'baselineUsedRawSearch: %d\n', baselineRunInfo.usedRawSearch);
fprintf(fid, 'baselineUsedRawDecoding: %d\n', baselineRunInfo.usedRawDecoding);
fprintf(fid, 'baselineUsedRawEvaluation: %d\n', baselineRunInfo.usedRawEvaluation);
fprintf(fid, 'variantIsIndependent: %d\n', variantRunInfo.isIndependent);
fprintf(fid, 'variantUsedRawSearch: %d\n', variantRunInfo.usedRawSearch);
fprintf(fid, 'variantUsedRawDecoding: %d\n', variantRunInfo.usedRawDecoding);
fprintf(fid, 'variantUsedRawEvaluation: %d\n', variantRunInfo.usedRawEvaluation);
clear cleanupObj
end

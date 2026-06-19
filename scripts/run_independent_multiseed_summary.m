clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'search'));

config = independent_multiseed_config(projectRoot);
assert(config.algorithm.pop <= 10, ...
    'Multiseed acceptance should use small pop <= 10.');
assert(config.algorithm.max_gen <= 2, ...
    'Multiseed acceptance should use small max_gen <= 2.');

[problem, machineData, agvData] = load_independent_data(config);
runDir = create_run_dir(config.paths.outputBaseDir);

seedList = config.random.seedList(:)';
seedResults = repmat(create_empty_seed_result(), numel(seedList), 1);

for i = 1:numel(seedList)
    seed = seedList(i);
    seedConfig = config;
    seedConfig.random.seed = seed;
    seedConfig.random.currentSeed = seed;
    seedConfig.random.seedList = seedList;

    rng(seed);
    [NSGA2_Result, initialPopulation, runInfo] = run_independent_nsga2( ...
        seedConfig, problem, machineData, agvData, ...
        struct('label', sprintf('multiseed-%d', seed)));

    seedDir = fullfile(runDir, sprintf('seed_%d', seed));
    if ~exist(seedDir, 'dir')
        mkdir(seedDir);
    end

    save(fullfile(seedDir, 'result.mat'), 'NSGA2_Result', ...
        'initialPopulation', 'runInfo', 'problem', 'machineData', ...
        'agvData', 'seedConfig');
    write_seed_summary(fullfile(seedDir, 'summary.txt'), seedConfig, ...
        NSGA2_Result, seedDir);
    write_seed_run_info(fullfile(seedDir, 'run_info.txt'), seedConfig, ...
        runInfo, seedDir);

    seedResults(i).seed = seed;
    seedResults(i).paretoSolutionCount = size(NSGA2_Result.obj_matrix, 1);
    seedResults(i).bestMakespan = min(NSGA2_Result.obj_matrix(:, 1));
    seedResults(i).bestTotalEnergy = min(NSGA2_Result.obj_matrix(:, 2));
    seedResults(i).runTime = NSGA2_Result.RunTime;
    seedResults(i).outputDir = seedDir;
end

aggregate = build_aggregate(seedResults);
if config.output.saveAggregateSummary
    write_aggregate_summary(fullfile(runDir, 'aggregate_summary.txt'), ...
        config, aggregate, seedResults, runDir);
end
if config.output.saveAggregateMat
    save(fullfile(runDir, 'aggregate_result.mat'), ...
        'aggregate', 'seedResults', 'config', 'runDir');
end

fprintf('independent multiseed summary finished.\n');
fprintf('runDir: %s\n', runDir);
fprintf('seedList: %s\n', mat2str(seedList));
fprintf('bestMakespanMean: %.6f\n', aggregate.bestMakespan.mean);
fprintf('bestMakespanStd: %.6f\n', aggregate.bestMakespan.std);
fprintf('bestTotalEnergyMean: %.6f\n', aggregate.bestTotalEnergy.mean);
fprintf('bestTotalEnergyStd: %.6f\n', aggregate.bestTotalEnergy.std);

function [problem, machineData, agvData] = load_independent_data(config)
problem = read_fjsp(config.paths.fjsp);
machineData = read_machine_data(config.paths.machineExcel, problem.machineNum);
agvData = read_agv_data(config.paths.agvExcel);
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

function seedResult = create_empty_seed_result()
seedResult = struct('seed', NaN, 'paretoSolutionCount', NaN, ...
    'bestMakespan', NaN, 'bestTotalEnergy', NaN, 'runTime', NaN, ...
    'outputDir', '');
end

function aggregate = build_aggregate(seedResults)
makespan = [seedResults.bestMakespan];
energy = [seedResults.bestTotalEnergy];
runTime = [seedResults.runTime];
paretoCount = [seedResults.paretoSolutionCount];

aggregate = struct();
aggregate.seedCount = numel(seedResults);
aggregate.bestMakespan = summarize_vector(makespan);
aggregate.bestTotalEnergy = summarize_vector(energy);
aggregate.runTime = summarize_vector(runTime);
aggregate.paretoSolutionCount = summarize_vector(paretoCount);
end

function summary = summarize_vector(values)
summary = struct();
summary.mean = mean(values);
summary.std = std(values);
summary.best = min(values);
summary.worst = max(values);
end

function write_seed_summary(summaryPath, config, NSGA2_Result, seedDir)
objMatrix = NSGA2_Result.obj_matrix;
fid = fopen(summaryPath, 'w');
if isequal(fid, -1)
    error('run_independent_multiseed_summary:SeedSummaryOpenFailed', ...
        'Could not open seed summary file: %s', summaryPath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, 'independent multiseed seed summary\n');
fprintf(fid, 'seed: %g\n', config.random.currentSeed);
fprintf(fid, 'pop: %d\n', config.algorithm.pop);
fprintf(fid, 'max_gen: %d\n', config.algorithm.max_gen);
fprintf(fid, 'runTime: %.6f\n', NSGA2_Result.RunTime);
fprintf(fid, 'paretoSolutionCount: %d\n', size(objMatrix, 1));
fprintf(fid, 'bestMakespan: %.6f\n', min(objMatrix(:, 1)));
fprintf(fid, 'bestTotalEnergy: %.6f\n', min(objMatrix(:, 2)));
fprintf(fid, 'outputDir: %s\n', seedDir);
clear cleanupObj
end

function write_seed_run_info(runInfoPath, config, runInfo, seedDir)
fid = fopen(runInfoPath, 'w');
if isequal(fid, -1)
    error('run_independent_multiseed_summary:RunInfoOpenFailed', ...
        'Could not open seed run info file: %s', runInfoPath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, 'runType: %s\n', config.experiment.runType);
fprintf(fid, 'experimentName: %s\n', config.experiment.name);
fprintf(fid, 'seed: %g\n', config.random.currentSeed);
fprintf(fid, 'seedList: %s\n', mat2str(config.random.seedList));
fprintf(fid, 'pop: %d\n', config.algorithm.pop);
fprintf(fid, 'max_gen: %d\n', config.algorithm.max_gen);
fprintf(fid, 'outputDir: %s\n', seedDir);
fprintf(fid, 'isIndependent: %d\n', runInfo.isIndependent);
fprintf(fid, 'usedRawSearch: %d\n', runInfo.usedRawSearch);
fprintf(fid, 'usedRawDecoding: %d\n', runInfo.usedRawDecoding);
fprintf(fid, 'usedRawEvaluation: %d\n', runInfo.usedRawEvaluation);
clear cleanupObj
end

function write_aggregate_summary(summaryPath, config, aggregate, ...
    seedResults, runDir)
fid = fopen(summaryPath, 'w');
if isequal(fid, -1)
    error('run_independent_multiseed_summary:AggregateOpenFailed', ...
        'Could not open aggregate summary file: %s', summaryPath);
end
cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, 'independent multiseed aggregate summary\n');
fprintf(fid, 'runType: %s\n', config.experiment.runType);
fprintf(fid, 'experimentName: %s\n', config.experiment.name);
fprintf(fid, 'seedList: %s\n', mat2str(config.random.seedList));
fprintf(fid, 'seedCount: %d\n', aggregate.seedCount);
fprintf(fid, 'pop: %d\n', config.algorithm.pop);
fprintf(fid, 'max_gen: %d\n', config.algorithm.max_gen);
fprintf(fid, 'bestMakespanMean: %.6f\n', aggregate.bestMakespan.mean);
fprintf(fid, 'bestMakespanStd: %.6f\n', aggregate.bestMakespan.std);
fprintf(fid, 'bestMakespanBest: %.6f\n', aggregate.bestMakespan.best);
fprintf(fid, 'bestMakespanWorst: %.6f\n', aggregate.bestMakespan.worst);
fprintf(fid, 'bestTotalEnergyMean: %.6f\n', aggregate.bestTotalEnergy.mean);
fprintf(fid, 'bestTotalEnergyStd: %.6f\n', aggregate.bestTotalEnergy.std);
fprintf(fid, 'bestTotalEnergyBest: %.6f\n', aggregate.bestTotalEnergy.best);
fprintf(fid, 'bestTotalEnergyWorst: %.6f\n', aggregate.bestTotalEnergy.worst);
fprintf(fid, 'runTimeMean: %.6f\n', aggregate.runTime.mean);
fprintf(fid, 'runTimeStd: %.6f\n', aggregate.runTime.std);
fprintf(fid, 'paretoSolutionCountMean: %.6f\n', ...
    aggregate.paretoSolutionCount.mean);
fprintf(fid, 'outputDir: %s\n', runDir);
for i = 1:numel(seedResults)
    fprintf(fid, 'seed_%d_outputDir: %s\n', ...
        seedResults(i).seed, seedResults(i).outputDir);
end
clear cleanupObj
end

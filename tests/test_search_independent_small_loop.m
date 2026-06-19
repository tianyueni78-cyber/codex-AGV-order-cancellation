clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'search'));

config = small_nsga2_config(projectRoot);
assert(config.algorithm.pop <= 10, 'Independent small loop pop should be <= 10.');
assert(config.algorithm.max_gen <= 2, 'Independent small loop max_gen should be <= 2.');
assert(isfield(config.random, 'seed') && isfinite(config.random.seed), ...
    'Independent small loop seed should be fixed.');
rng(config.random.seed);

beforeFiles = dir(projectRoot);
beforeNames = sort({beforeFiles.name});

problem = read_fjsp(config.paths.fjsp);
machineData = read_machine_data(config.paths.machineExcel, problem.machineNum);
agvData = read_agv_data(config.paths.agvExcel);

options = struct();
options.label = 'independent-small-loop';
[NSGA2_Result, initialPopulation, runInfo] = run_independent_nsga2( ...
    config, problem, machineData, agvData, options);

operaNum = sum(problem.operaNumVec);
dim = 5 * operaNum;
assert(~isempty(initialPopulation), 'Initial population should not be empty.');
assert(size(initialPopulation, 1) == config.algorithm.pop, ...
    'Initial population size mismatch.');
assert(size(initialPopulation, 2) == dim, ...
    'Initial chromosome length mismatch.');

assert(isstruct(runInfo), 'runInfo should be a struct.');
assert(runInfo.isIndependent, 'runInfo.isIndependent should be true.');
assert(~runInfo.usedRawSearch, 'Independent search should not use raw search.');
assert(~runInfo.usedRawDecoding, 'Independent search should not use raw decoding.');
assert(~runInfo.usedRawEvaluation, 'Independent search should not use raw evaluation.');

assert(isstruct(NSGA2_Result), 'NSGA2_Result should be a struct.');
assert(isfield(NSGA2_Result, 'obj_matrix'), 'obj_matrix is missing.');
assert(~isempty(NSGA2_Result.obj_matrix), 'obj_matrix is empty.');
assert(size(NSGA2_Result.obj_matrix, 2) == 2, ...
    'obj_matrix should contain two objectives.');
assert(all(isfinite(NSGA2_Result.obj_matrix(:))), ...
    'obj_matrix contains non-finite values.');
assert(isfield(NSGA2_Result, 'curve'), 'curve is missing.');
assert(isfield(NSGA2_Result.curve, 'min'), 'curve.min is missing.');
assert(isfield(NSGA2_Result.curve, 'avg'), 'curve.avg is missing.');
assert(size(NSGA2_Result.curve.min, 2) == config.algorithm.max_gen, ...
    'curve.min column count should match max_gen.');
assert(size(NSGA2_Result.curve.avg, 2) == config.algorithm.max_gen, ...
    'curve.avg column count should match max_gen.');

afterFiles = dir(projectRoot);
afterNames = sort({afterFiles.name});
assert(isequal(beforeNames, afterNames), ...
    'test_search_independent_small_loop created or removed project-root files.');

fprintf(['test_search_independent_small_loop passed: pop=%d, max_gen=%d, ', ...
    'seed=%g, paretoSolutionCount=%d, bestMakespan=%.6f, bestTotalEnergy=%.6f\n'], ...
    runInfo.pop, runInfo.max_gen, config.random.seed, ...
    size(NSGA2_Result.obj_matrix, 1), min(NSGA2_Result.obj_matrix(:, 1)), ...
    min(NSGA2_Result.obj_matrix(:, 2)));

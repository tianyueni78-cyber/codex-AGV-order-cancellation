clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'search'));

config = small_nsga2_config(projectRoot);
assert(config.algorithm.pop <= 10, ...
    'Small search loop pop should be <= 10.');
assert(config.algorithm.max_gen <= 2, ...
    'Small search loop max_gen should be <= 2.');
assert(isfield(config.random, 'seed') && isfinite(config.random.seed), ...
    'Small search loop seed should be fixed.');
rng(config.random.seed);

beforeFiles = dir(projectRoot);
beforeNames = sort({beforeFiles.name});

problem = read_fjsp(config.paths.fjsp);
machineData = read_machine_data(config.paths.machineExcel, problem.machineNum);
agvData = read_agv_data(config.paths.agvExcel);

options = struct();
options.useRefactoredVariation = true;

[NSGA2_Result, chrom, runInfo] = run_nsga2_with_encoding( ...
    config, problem, machineData, agvData, options);

operaNum = sum(problem.operaNumVec);
dim = 5 * operaNum;

assert(~isempty(chrom), 'Initial population should not be empty.');
assert(size(chrom, 1) == config.algorithm.pop, ...
    'Initial population size does not match config.algorithm.pop.');
assert(size(chrom, 2) == dim, ...
    'Chromosome length does not match 5 * sum(problem.operaNumVec).');

assert(isstruct(runInfo), 'runInfo should be a struct.');
assert(runInfo.pop == config.algorithm.pop, 'runInfo.pop mismatch.');
assert(runInfo.max_gen == config.algorithm.max_gen, ...
    'runInfo.max_gen mismatch.');
assert(runInfo.useRefactoredVariation, ...
    'Search small loop should use refactored variation.');

assert(isstruct(NSGA2_Result), 'NSGA2_Result should be a struct.');
assert(isfield(NSGA2_Result, 'obj_matrix'), ...
    'NSGA2_Result.obj_matrix is missing.');
assert(~isempty(NSGA2_Result.obj_matrix), ...
    'NSGA2_Result.obj_matrix is empty.');
assert(size(NSGA2_Result.obj_matrix, 2) == 2, ...
    'NSGA2_Result.obj_matrix should contain two objectives.');
assert(all(isfinite(NSGA2_Result.obj_matrix(:))), ...
    'NSGA2_Result.obj_matrix contains non-finite values.');

assert(isfield(NSGA2_Result, 'curve'), 'NSGA2_Result.curve is missing.');
assert(isfield(NSGA2_Result.curve, 'min'), ...
    'NSGA2_Result.curve.min is missing.');
assert(size(NSGA2_Result.curve.min, 2) == config.algorithm.max_gen, ...
    'NSGA2_Result.curve.min column count does not match max_gen.');
assert(all(isfinite(NSGA2_Result.curve.min(:))), ...
    'NSGA2_Result.curve.min contains non-finite values.');

afterFiles = dir(projectRoot);
afterNames = sort({afterFiles.name});
assert(isequal(beforeNames, afterNames), ...
    'test_search_small_loop created or removed files in the project root.');

fprintf(['test_search_small_loop passed: pop=%d, max_gen=%d, ', ...
    'seed=%g, paretoSolutionCount=%d, bestMakespan=%.6f, ', ...
    'bestTotalEnergy=%.6f\n'], ...
    runInfo.pop, runInfo.max_gen, config.random.seed, ...
    size(NSGA2_Result.obj_matrix, 1), ...
    min(NSGA2_Result.obj_matrix(:, 1)), ...
    min(NSGA2_Result.obj_matrix(:, 2)));

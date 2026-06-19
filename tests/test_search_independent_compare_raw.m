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
assert(config.algorithm.pop <= 10, 'Raw compare smoke should use small pop.');
assert(config.algorithm.max_gen <= 2, 'Raw compare smoke should use small max_gen.');

problem = read_fjsp(config.paths.fjsp);
machineData = read_machine_data(config.paths.machineExcel, problem.machineNum);
agvData = read_agv_data(config.paths.agvExcel);

rng(config.random.seed);
[independentResult, ~, independentRunInfo] = run_independent_nsga2( ...
    config, problem, machineData, agvData, struct('label', 'independent-raw-compare'));

rng(config.random.seed);
rawOptions = struct();
rawOptions.useRefactoredVariation = true;
[rawResult, ~, rawRunInfo] = run_nsga2_with_encoding( ...
    config, problem, machineData, agvData, rawOptions);

assert(independentRunInfo.isIndependent, ...
    'Independent runInfo should report independent search.');
assert(rawRunInfo.useRefactoredVariation, ...
    'Raw compare should use the existing refactored-variation smoke path.');

assert(~isempty(independentResult.obj_matrix), ...
    'Independent obj_matrix should not be empty.');
assert(~isempty(rawResult.obj_matrix), ...
    'Raw smoke obj_matrix should not be empty.');
assert(size(independentResult.obj_matrix, 2) == size(rawResult.obj_matrix, 2), ...
    'Objective column counts should match.');
assert(size(independentResult.curve.min, 2) == size(rawResult.curve.min, 2), ...
    'Curve generation counts should match.');
assert(all(isfinite(independentResult.obj_matrix(:))), ...
    'Independent obj_matrix should contain finite values.');
assert(all(isfinite(rawResult.obj_matrix(:))), ...
    'Raw smoke obj_matrix should contain finite values.');

fprintf(['test_search_independent_compare_raw passed: ', ...
    'independentSolutions=%d, rawSolutions=%d, objectiveColumns=%d\n'], ...
    size(independentResult.obj_matrix, 1), size(rawResult.obj_matrix, 1), ...
    size(independentResult.obj_matrix, 2));

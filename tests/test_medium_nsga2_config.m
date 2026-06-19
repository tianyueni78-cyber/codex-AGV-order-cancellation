projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'configs'));

smallConfig = small_nsga2_config(projectRoot);
mediumConfig = medium_nsga2_config(projectRoot);

expectedOutputBaseDir = fullfile(projectRoot, 'outputs', 'medium_nsga2');
assert(strcmp(mediumConfig.paths.outputBaseDir, expectedOutputBaseDir), ...
    'medium outputBaseDir should be outputs/medium_nsga2.');

assert(isfield(mediumConfig, 'random') && isfield(mediumConfig.random, 'seed'), ...
    'medium config should define random.seed.');
assert(isnumeric(mediumConfig.random.seed) && isscalar(mediumConfig.random.seed), ...
    'medium random.seed should be a numeric scalar.');

assert(mediumConfig.algorithm.pop > smallConfig.algorithm.pop, ...
    'medium pop should be larger than small pop.');
assert(mediumConfig.algorithm.max_gen > smallConfig.algorithm.max_gen, ...
    'medium max_gen should be larger than small max_gen.');
assert(mediumConfig.algorithm.pop == 20, 'medium pop should be 20 for acceptance.');
assert(mediumConfig.algorithm.max_gen == 5, 'medium max_gen should be 5 for acceptance.');

requiredAlgorithmFields = {'p_cross', 'p_mutation'};
for i = 1:numel(requiredAlgorithmFields)
    fieldName = requiredAlgorithmFields{i};
    assert(isfield(mediumConfig.algorithm, fieldName), ...
        'medium config is missing algorithm.%s.', fieldName);
end

requiredPathFields = {'fjsp', 'machineExcel', 'agvExcel', 'algorithmDir'};
for i = 1:numel(requiredPathFields)
    fieldName = requiredPathFields{i};
    assert(isfield(mediumConfig.paths, fieldName), ...
        'medium config is missing paths.%s.', fieldName);
    assert(exist(mediumConfig.paths.(fieldName), 'file') == 2 || ...
        exist(mediumConfig.paths.(fieldName), 'dir') == 7, ...
        'medium config path does not exist: %s.', mediumConfig.paths.(fieldName));
end

fprintf(['test_medium_nsga2_config passed: pop=%d, max_gen=%d, seed=%g, ', ...
    'outputBaseDir=%s\n'], ...
    mediumConfig.algorithm.pop, mediumConfig.algorithm.max_gen, ...
    mediumConfig.random.seed, mediumConfig.paths.outputBaseDir);

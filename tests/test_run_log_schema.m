clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'configs'));

smallConfig = small_nsga2_config(projectRoot);
mediumConfig = medium_nsga2_config(projectRoot);
formalConfig = formal_nsga2_config(projectRoot);

assert_run_log_config(smallConfig, projectRoot, 'small');
assert_run_log_config(mediumConfig, projectRoot, 'medium');
assert_run_log_config(formalConfig, projectRoot, 'formal');

assert_script_contains(fullfile(projectRoot, 'scripts', 'run_small_nsga2.m'), ...
    {'runType', 'experimentName', 'datasetName', 'seed:', ...
    'run_info.txt', 'write_run_info'});
assert_script_contains(fullfile(projectRoot, 'scripts', 'run_small_nsga2_refactored.m'), ...
    {'runType', 'experimentName', 'datasetName', 'seed:', ...
    'run_info.txt', 'write_run_info', 'useRefactoredVariation'});
assert_script_contains(fullfile(projectRoot, 'scripts', 'run_medium_nsga2.m'), ...
    {'runType', 'experimentName', 'datasetName', 'seed:', ...
    'run_info.txt', 'write_run_info'});
assert_script_contains(fullfile(projectRoot, 'scripts', 'run_formal_nsga2.m'), ...
    {'experimentName', 'datasetName', 'seed:', ...
    'run_info.txt', 'write_run_info'});

fprintf(['test_run_log_schema passed: summary/run_info fields are ', ...
    'traceable for small, medium, and formal entries\n']);

function assert_run_log_config(config, projectRoot, label)
assert(isfield(config, 'paths'), [label, ' config missing paths.']);
assert(isfield(config.paths, 'outputBaseDir'), ...
    [label, ' config missing outputBaseDir.']);
assert(startsWith(char(config.paths.outputBaseDir), ...
    char(fullfile(projectRoot, 'outputs'))), ...
    [label, ' outputBaseDir should be under outputs/.']);

assert(isfield(config, 'random'), [label, ' config missing random.']);
assert(isfield(config.random, 'seed'), ...
    [label, ' config missing random.seed.']);
assert(isnumeric(config.random.seed) && isscalar(config.random.seed) && ...
    isfinite(config.random.seed), ...
    [label, ' random.seed should be a finite scalar.']);

assert(isfield(config, 'algorithm'), [label, ' config missing algorithm.']);
requiredAlgorithmFields = {'pop', 'max_gen', 'p_cross', 'p_mutation'};
for i = 1:numel(requiredAlgorithmFields)
    fieldName = requiredAlgorithmFields{i};
    assert(isfield(config.algorithm, fieldName), ...
        [label, ' config algorithm missing field: ', fieldName]);
end

assert(isfield(config, 'energy'), [label, ' config missing energy.']);
assert(isfield(config.energy, 'AGVEG_MAX'), ...
    [label, ' config energy missing AGVEG_MAX.']);
assert(isfield(config.energy, 'eChargeSpeed'), ...
    [label, ' config energy missing eChargeSpeed.']);
end

function assert_script_contains(scriptPath, patterns)
assert(isfile(scriptPath), ['Script file does not exist: ', scriptPath]);
text = fileread(scriptPath);
for i = 1:numel(patterns)
    assert(~isempty(strfind(text, patterns{i})), ...
        ['Expected script to contain "', patterns{i}, '": ', scriptPath]);
end
end

clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'configs'));

beforeFiles = dir(projectRoot);
beforeNames = sort({beforeFiles.name});

config = baseline_comparison_config(projectRoot);

assert(isstruct(config), 'Config should be a struct.');
assert(isfield(config, 'comparison'), 'Config missing comparison.');
assert(strcmp(config.comparison.baselineName, 'raw_nsga2'), ...
    'Baseline should be raw_nsga2.');
assert(strcmp(config.comparison.variantName, 'independent_nsga2'), ...
    'Variant should be independent_nsga2.');
assert(config.comparison.seed == config.random.seed, ...
    'Comparison seed should match config random seed.');
assert(config.algorithm.pop <= 10, 'Small comparison pop should be <= 10.');
assert(config.algorithm.max_gen <= 2, ...
    'Small comparison max_gen should be <= 2.');

expectedOutputBaseDir = fullfile(projectRoot, 'outputs', ...
    'baseline_comparison_small');
assert(strcmp(config.paths.outputBaseDir, expectedOutputBaseDir), ...
    'Output base dir should be outputs/baseline_comparison_small.');

assert(isfile(config.paths.fjsp), 'Configured .fjs file does not exist.');
assert(isfile(config.paths.machineExcel), ...
    'Configured machine Excel file does not exist.');
assert(isfile(config.paths.agvExcel), ...
    'Configured AGV Excel file does not exist.');
assert(isfolder(config.paths.algorithmDir), ...
    'Raw algorithmDir should exist for baseline.');
assert(isfolder(config.paths.implementationDir), ...
    'Implementation dir should exist for variant.');

afterFiles = dir(projectRoot);
afterNames = sort({afterFiles.name});
assert(isequal(beforeNames, afterNames), ...
    'test_baseline_comparison_config created project-root files.');

fprintf(['test_baseline_comparison_config passed: baseline=%s, ', ...
    'variant=%s, seed=%g, pop=%d, max_gen=%d\n'], ...
    config.comparison.baselineName, config.comparison.variantName, ...
    config.comparison.seed, config.algorithm.pop, config.algorithm.max_gen);

clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'configs'));

beforeFiles = dir(projectRoot);
beforeNames = sort({beforeFiles.name});

config = independent_multiseed_config(projectRoot);

assert(strcmp(config.experiment.runType, 'independent_multiseed_small'), ...
    'Unexpected multiseed runType.');
assert(isequal(config.random.seedList, [42, 43, 44, 45, 46]), ...
    'seedList should be [42, 43, 44, 45, 46].');
assert(config.random.currentSeed == config.random.seedList(1), ...
    'currentSeed should start from the first seed.');
assert(config.algorithm.pop <= 10, 'multiseed pop should be <= 10.');
assert(config.algorithm.max_gen <= 2, ...
    'multiseed max_gen should be <= 2.');
assert(strcmp(config.paths.outputBaseDir, ...
    fullfile(projectRoot, 'outputs', 'independent_multiseed')), ...
    'outputBaseDir should be outputs/independent_multiseed.');
assert(config.output.saveAggregateSummary, ...
    'saveAggregateSummary should be true.');
assert(config.output.saveAggregateMat, ...
    'saveAggregateMat should be true.');

afterFiles = dir(projectRoot);
afterNames = sort({afterFiles.name});
assert(isequal(beforeNames, afterNames), ...
    'test_independent_multiseed_config created project-root files.');

fprintf(['test_independent_multiseed_config passed: seedList=%s, ', ...
    'pop=%d, max_gen=%d\n'], mat2str(config.random.seedList), ...
    config.algorithm.pop, config.algorithm.max_gen);

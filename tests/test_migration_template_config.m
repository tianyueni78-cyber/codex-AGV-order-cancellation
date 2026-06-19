clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
addpath(fullfile(projectRoot, 'configs'));

config = template_project_small_config(projectRoot);

assert(isfield(config, 'project'), 'config.project should exist.');
assert(isfield(config.project, 'projectName'), ...
    'config.project.projectName should exist.');
assert(~isempty(config.project.projectName), ...
    'config.project.projectName should not be empty.');

assert(isfield(config, 'paths'), 'config.paths should exist.');
requiredPathFields = {'fjsp', 'machineExcel', 'agvExcel', ...
    'outputBaseDir', 'implementationDir'};
for i = 1:numel(requiredPathFields)
    fieldName = requiredPathFields{i};
    assert(isfield(config.paths, fieldName), ...
        'config.paths.%s should exist.', fieldName);
    assert(ischar(config.paths.(fieldName)) || isstring(config.paths.(fieldName)), ...
        'config.paths.%s should be configurable text.', fieldName);
end

expectedOutputRoot = fullfile(projectRoot, 'outputs');
assert(startsWith(char(config.paths.outputBaseDir), expectedOutputRoot), ...
    'config.paths.outputBaseDir should be under outputs/.');

assert(isfield(config, 'objectives'), 'config.objectives should exist.');
assert(isfield(config.objectives, 'names'), ...
    'config.objectives.names should exist.');
assert(iscell(config.objectives.names), ...
    'config.objectives.names should be a cell array.');
assert(any(strcmp(config.objectives.names, 'carbonEmission')), ...
    'template objective names should include carbonEmission.');

assert(isfield(config, 'random'), 'config.random should exist.');
assert(isfield(config.random, 'seed'), 'config.random.seed should exist.');
assert(isnumeric(config.random.seed) && isscalar(config.random.seed), ...
    'config.random.seed should be a numeric scalar.');

assert(isfield(config, 'algorithm'), 'config.algorithm should exist.');
assert(isfield(config.algorithm, 'pop'), 'config.algorithm.pop should exist.');
assert(isfield(config.algorithm, 'max_gen'), ...
    'config.algorithm.max_gen should exist.');
assert(config.algorithm.pop > 0 && config.algorithm.pop <= 10, ...
    'template small pop should be in (0, 10].');
assert(config.algorithm.max_gen > 0 && config.algorithm.max_gen <= 2, ...
    'template small max_gen should be in (0, 2].');

assert(isfield(config, 'improvements'), ...
    'config.improvements should exist for migration rehearsal.');
assert(isfield(config.improvements, 'adaptiveMutation'), ...
    'config.improvements.adaptiveMutation should exist.');

fprintf('test_migration_template_config passed: migration template config fields are valid\n');

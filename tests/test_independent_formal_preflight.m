clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

scriptPath = fullfile(projectRoot, 'scripts', ...
    'run_independent_formal_nsga2.m');
assert(isfile(scriptPath), ...
    'scripts/run_independent_formal_nsga2.m should exist.');

text = fileread(scriptPath);

requiredSnippets = {
    'independent_formal_config'
    'RUN_INDEPENDENT_FORMAL_CONFIRMED'
    'formal run is guarded and was not started'
    'run_independent_nsga2'
    'outputBaseDir'
    'result.mat'
    'summary.txt'
    'run_info.txt'
};

for i = 1:numel(requiredSnippets)
    snippet = requiredSnippets{i};
    assert(contains(text, snippet), ...
        'Independent formal entry missing required snippet: %s', snippet);
end

forbiddenSnippets = {
    'addpath(config.paths.algorithmDir)'
    'NSGA2('
    'fitness('
    'sorting('
    'run_medium_nsga2'
    'run_formal_nsga2'
};

for i = 1:numel(forbiddenSnippets)
    snippet = forbiddenSnippets{i};
    assert(~contains(text, snippet), ...
        'Independent formal entry contains forbidden snippet: %s', snippet);
end

fprintf('test_independent_formal_preflight passed: formal entry is guarded and independent\n');

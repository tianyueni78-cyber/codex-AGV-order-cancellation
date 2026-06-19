clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

scriptPath = fullfile(projectRoot, 'scripts', ...
    'run_independent_multiseed_summary.m');
assert(isfile(scriptPath), ...
    'scripts/run_independent_multiseed_summary.m should exist.');

text = fileread(scriptPath);

requiredSnippets = {
    'independent_multiseed_config'
    'config.random.seedList'
    'run_independent_nsga2'
    'seed_%d'
    'aggregate_summary.txt'
    'aggregate_result.mat'
    'bestMakespan'
    'bestTotalEnergy'
    'std'
    'worst'
};

for i = 1:numel(requiredSnippets)
    snippet = requiredSnippets{i};
    assert(contains(text, snippet), ...
        'Multiseed summary script missing required snippet: %s', snippet);
end

forbiddenSnippets = {
    'NSGA2('
    'fitness('
    'sorting('
    'run_formal_nsga2'
    'run_medium_nsga2'
};

for i = 1:numel(forbiddenSnippets)
    snippet = forbiddenSnippets{i};
    assert(~contains(text, snippet), ...
        'Multiseed summary script contains forbidden snippet: %s', snippet);
end

fprintf('test_independent_multiseed_summary_dryrun passed: script structure is independent and aggregate-ready\n');

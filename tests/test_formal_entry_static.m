clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
scriptPath = fullfile(projectRoot, 'scripts', 'run_formal_nsga2.m');

assert(isfile(scriptPath), 'scripts/run_formal_nsga2.m should exist.');

text = fileread(scriptPath);

requiredSnippets = {
    'formal_nsga2_config'
    'rng(config.random.currentSeed)'
    'create_run_dir(config.paths.outputBaseDir)'
    'formal_nsga2_result.mat'
    'summary.txt'
    'run_info.txt'
    'write_run_info'
    'config.output.saveMat'
    'config.output.saveSummary'
    'config.output.saveRunInfo'
};

for i = 1:numel(requiredSnippets)
    snippet = requiredSnippets{i};
    assert(contains(text, snippet), ...
        'Formal entry is missing required behavior: %s', snippet);
end

forbiddenSnippets = {
    'run_medium_nsga2'
    'run_small_nsga2'
    'cd(''raw_code'
    'cd("raw_code'
};

for i = 1:numel(forbiddenSnippets)
    snippet = forbiddenSnippets{i};
    assert(~contains(text, snippet), ...
        'Formal entry should not contain forbidden snippet: %s', snippet);
end

fprintf('test_formal_entry_static passed: formal entry uses config, timestamp output, result/summary/run_info\n');

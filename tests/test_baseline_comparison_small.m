clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

beforeRawStatus = get_git_status(projectRoot, 'raw_code');

run(fullfile(projectRoot, 'scripts', 'run_baseline_comparison_small.m'));

runDir = find_latest_run_dir(fullfile(projectRoot, 'outputs', ...
    'baseline_comparison_small'));
resultPath = fullfile(runDir, 'result.mat');
summaryPath = fullfile(runDir, 'summary.txt');
runInfoPath = fullfile(runDir, 'run_info.txt');

assert(isfile(resultPath), 'result.mat should exist.');
assert(isfile(summaryPath), 'summary.txt should exist.');
assert(isfile(runInfoPath), 'run_info.txt should exist.');

data = load(resultPath, 'baselineResult', 'variantResult', ...
    'baselineRunInfo', 'variantRunInfo', 'config');

assert(~isempty(data.baselineResult.obj_matrix), ...
    'Baseline obj_matrix should not be empty.');
assert(~isempty(data.variantResult.obj_matrix), ...
    'Variant obj_matrix should not be empty.');
assert(size(data.baselineResult.obj_matrix, 2) == ...
    size(data.variantResult.obj_matrix, 2), ...
    'Objective column count should match.');
assert(data.baselineRunInfo.seed == data.config.comparison.seed, ...
    'Baseline seed should match config.');
assert(data.variantRunInfo.pop == data.baselineRunInfo.pop, ...
    'Variant pop should match baseline pop.');
assert(data.variantRunInfo.max_gen == data.baselineRunInfo.max_gen, ...
    'Variant max_gen should match baseline max_gen.');
assert(data.variantRunInfo.isIndependent, ...
    'Variant should report independent implementation.');
assert(~data.variantRunInfo.usedRawSearch && ...
    ~data.variantRunInfo.usedRawDecoding && ...
    ~data.variantRunInfo.usedRawEvaluation, ...
    'Variant should not use raw search, decoding, or evaluation.');

afterRawStatus = get_git_status(projectRoot, 'raw_code');
assert(strcmp(beforeRawStatus, afterRawStatus), ...
    'raw_code status changed during baseline comparison.');

fprintf(['test_baseline_comparison_small passed: runDir=%s, ', ...
    'baselineRows=%d, variantRows=%d, objectiveCols=%d\n'], ...
    runDir, size(data.baselineResult.obj_matrix, 1), ...
    size(data.variantResult.obj_matrix, 1), ...
    size(data.baselineResult.obj_matrix, 2));

function statusText = get_git_status(projectRoot, pathSpec)
[statusCode, statusText] = system(sprintf( ...
    'git -C "%s" status --short -- %s', projectRoot, pathSpec));
assert(statusCode == 0, 'git status failed.');
statusText = strtrim(statusText);
end

function latestRunDir = find_latest_run_dir(baseDir)
assert(isfolder(baseDir), 'Baseline comparison output dir missing.');
items = dir(baseDir);
isRunDir = [items.isdir] & ~ismember({items.name}, {'.', '..'});
runDirs = items(isRunDir);
assert(~isempty(runDirs), 'No baseline comparison run dirs found.');
[~, idx] = max([runDirs.datenum]);
latestRunDir = fullfile(baseDir, runDirs(idx).name);
end

clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
addpath(fullfile(projectRoot, 'src', 'data'));

sampleFiles = dir(fullfile(projectRoot, 'data_sample', '**', '*.fjs'));
assert(~isempty(sampleFiles), ...
    ['No .fjs sample found under data_sample. ', ...
     'Extract or add a small .fjs sample there before running this test.']);

samplePath = fullfile(sampleFiles(1).folder, sampleFiles(1).name);
dataMatPath = fullfile(projectRoot, 'data.mat');
hadDataMat = exist(dataMatPath, 'file') == 2;

problem = read_fjsp(samplePath);

assert(isfield(problem, 'jobNum') && ~isempty(problem.jobNum), ...
    'problem.jobNum is missing or empty.');
assert(isfield(problem, 'machineNum') && ~isempty(problem.machineNum), ...
    'problem.machineNum is missing or empty.');
assert(isfield(problem, 'operaNumVec') && ~isempty(problem.operaNumVec), ...
    'problem.operaNumVec is missing or empty.');

hasDataMatAfter = exist(dataMatPath, 'file') == 2;
assert(hasDataMatAfter == hadDataMat, 'read_fjsp generated data.mat.');

fprintf('test_read_fjsp passed: %s\n', samplePath);

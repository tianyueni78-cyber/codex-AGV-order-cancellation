clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
addpath(fullfile(projectRoot, 'src', 'data'));

agvFiles = dir(fullfile(projectRoot, 'data_sample', 'AGV*.xlsx'));
assert(~isempty(agvFiles), 'AGV sample Excel file is missing.');
excelPath = fullfile(agvFiles(1).folder, agvFiles(1).name);

beforeFiles = dir(projectRoot);
beforeNames = sort({beforeFiles.name});

agvData = read_agv_data(excelPath);

assert(isfield(agvData, 'AGVNum'), 'agvData.AGVNum is missing.');
assert(isfield(agvData, 'AGVSpeed'), 'agvData.AGVSpeed is missing.');
assert(isfield(agvData, 'AGVEnergy'), 'agvData.AGVEnergy is missing.');

assert(~isempty(agvData.AGVNum), 'agvData.AGVNum is empty.');
assert(~isempty(agvData.AGVSpeed), 'agvData.AGVSpeed is empty.');
assert(~isempty(agvData.AGVEnergy.free), 'agvData.AGVEnergy.free is empty.');
assert(~isempty(agvData.AGVEnergy.load), 'agvData.AGVEnergy.load is empty.');
assert(numel(agvData.AGVEnergy.free) == numel(agvData.AGVSpeed), ...
    'Free energy vector length does not match AGVSpeed length.');
assert(numel(agvData.AGVEnergy.load) == numel(agvData.AGVSpeed), ...
    'Load energy vector length does not match AGVSpeed length.');

afterFiles = dir(projectRoot);
afterNames = sort({afterFiles.name});
assert(isequal(beforeNames, afterNames), ...
    'read_agv_data created or removed files in the project root.');

fprintf('test_read_agv_data passed: %s\n', excelPath);

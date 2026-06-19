clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
addpath(fullfile(projectRoot, 'src', 'data'));

excelPath = fullfile(projectRoot, 'data_sample', '机器数据.xlsx');
machineNum = 6;

beforeFiles = dir(projectRoot);
beforeNames = sort({beforeFiles.name});

machineData = read_machine_data(excelPath, machineNum);

assert(isfield(machineData, 'distance_matrix'), ...
    'machineData.distance_matrix is missing.');
assert(isfield(machineData, 'machineEnergy'), ...
    'machineData.machineEnergy is missing.');

distance_matrix = machineData.distance_matrix;
assert(numel(distance_matrix.load_to_machine) == machineNum, ...
    'load_to_machine length does not match machineNum.');
assert(numel(distance_matrix.machine_to_unload) == machineNum, ...
    'machine_to_unload length does not match machineNum.');
assert(all(size(distance_matrix.machine_to_machine) == [machineNum, machineNum]), ...
    'machine_to_machine size does not match machineNum.');
assert(~isempty(distance_matrix.load_to_unload), ...
    'load_to_unload is empty.');

machineEnergy = machineData.machineEnergy;
assert(~isempty(machineEnergy.work), 'machineEnergy.work is empty.');
assert(~isempty(machineEnergy.free), 'machineEnergy.free is empty.');

afterFiles = dir(projectRoot);
afterNames = sort({afterFiles.name});
assert(isequal(beforeNames, afterNames), ...
    'read_machine_data created or removed files in the project root.');

fprintf('test_read_machine_data passed: %s\n', excelPath);

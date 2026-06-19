clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'raw_code', 'NSGA-II'));

[problem, machineData, agvData, config, chrom] = make_sorting_compare_case();

[rawMachineTable, rawAGVTable, rawJobCompleteUnLoad, ...
    rawAgvEGRecord, rawAgvChargeNum] = sorting( ...
    chrom, problem.jobNum, problem.jobInfo, problem.operaNumVec, ...
    agvData.AGVNum, agvData.AGVSpeed, problem.candidateMachine, ...
    machineData.distance_matrix, agvData.AGVEnergy, config.AGVEG_MAX, ...
    config.AGVEG_MIN, config.eChargeSpeed, ...
    config.machineTable, config.AGVTable);

[schedule, report] = decode_chromosome( ...
    chrom, problem, machineData, agvData, config);

assert(report.isValid, strjoin(report.errors, newline));
assert(strcmp(report.decodingStatus, 'decoded'), ...
    'decode_chromosome should report decoded.');

assert(isequaln(schedule.machineTable, rawMachineTable), ...
    'machineTable differs between sorting.m and decode_chromosome.');
assert(isequaln(schedule.AGVTable, rawAGVTable), ...
    'AGVTable differs between sorting.m and decode_chromosome.');
assert(isequaln(schedule.jobCompleteUnLoad, rawJobCompleteUnLoad), ...
    'jobCompleteUnLoad differs between sorting.m and decode_chromosome.');
assert(isequaln(schedule.agvEGRecord, rawAgvEGRecord), ...
    'agvEGRecord differs between sorting.m and decode_chromosome.');
assert(isequaln(schedule.agvChargeNum, rawAgvChargeNum), ...
    'agvChargeNum differs between sorting.m and decode_chromosome.');

fprintf('test_decoding_compare_sorting passed: fields matched=%d\n', 5);

function [problem, machineData, agvData, config, chrom] = make_sorting_compare_case()
problem = struct();
problem.jobNum = 2;
problem.machineNum = 3;
problem.operaNumVec = [2, 1];
problem.candidateMachine = cell(2, 2);
problem.candidateMachine{1, 1} = [1, 2];
problem.candidateMachine{1, 2} = [2];
problem.candidateMachine{2, 1} = [1, 3];
problem.jobInfo = cell(1, 2);
problem.jobInfo{1} = [
    5, 6, inf
    inf, 4, inf
];
problem.jobInfo{2} = [
    3, inf, 7
];

machineData = struct();
machineData.distance_matrix = struct();
machineData.distance_matrix.machine_to_machine = [
    0, 2, 3
    2, 0, 4
    3, 4, 0
];
machineData.distance_matrix.load_to_machine = [1, 2, 3];
machineData.distance_matrix.machine_to_unload = [1, 2, 3];
machineData.distance_matrix.load_to_unload = 1;

agvData = struct();
agvData.AGVNum = 2;
agvData.AGVSpeed = [1.0, 1.5, 2.0];
agvData.AGVEnergy = struct();
agvData.AGVEnergy.free = [1.0, 1.2, 1.4];
agvData.AGVEnergy.load = [1.4, 1.6, 1.8];

config = struct();
config.AGVEG_MAX = 100;
config.AGVEG_MIN = 1;
config.eChargeSpeed = 20;
config.machineTable = create_initial_machine_table(problem.machineNum);
config.AGVTable = create_initial_agv_table(agvData.AGVNum);

OS = [1, 2, 1];
MS = [2, 1, 1];
AS = [1, 2, 1];
SS = [1, 2, 1, 2, 1, 2];
chrom = [OS, MS, AS, SS];
end

function machineTable = create_initial_machine_table(machineNum)
machineTable = cell(1, machineNum);
for machineIdx = 1:machineNum
    machineTable{machineIdx} = struct( ...
        'start', 0, ...
        'end', inf, ...
        'job', 0, ...
        'opera', 0);
end
end

function AGVTable = create_initial_agv_table(AGVNum)
AGVTable = cell(1, AGVNum);
for agvIdx = 1:AGVNum
    AGVTable{agvIdx} = repmat(struct( ...
        'start', 0, ...
        'end', 0, ...
        'job', 0, ...
        'opera', 0, ...
        'from_machine', -1, ...
        'to_machine', -1, ...
        'status', 0), 1, 2);
    AGVTable{agvIdx}(2).end = inf;
end
end

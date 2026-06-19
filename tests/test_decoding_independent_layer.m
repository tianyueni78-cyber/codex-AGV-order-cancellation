clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));

[problem, machineData, agvData, config, chrom] = make_independent_decoding_case();

[schedule, report] = decode_chromosome_independent( ...
    chrom, problem, machineData, agvData, config);

assert(report.isValid, strjoin(report.errors, newline));
assert(strcmp(report.decodingStatus, 'decoded-independent'), ...
    'Independent decoding status should be decoded-independent.');

assert(isfield(schedule, 'machineTable'), 'machineTable is missing.');
assert(isfield(schedule, 'AGVTable'), 'AGVTable is missing.');
assert(isfield(schedule, 'jobCompleteUnLoad'), 'jobCompleteUnLoad is missing.');
assert(isfield(schedule, 'scheduleContext'), 'scheduleContext is missing.');
assert(numel(schedule.machineTable) == problem.machineNum, ...
    'machineTable machine count mismatch.');
assert(numel(schedule.AGVTable) == agvData.AGVNum, ...
    'AGVTable AGV count mismatch.');
assert(numel(schedule.jobCompleteUnLoad) == problem.jobNum, ...
    'jobCompleteUnLoad job count mismatch.');
assert(count_scheduled_operations(schedule.machineTable) == ...
    sum(problem.operaNumVec), ...
    'Independent decoding should schedule every operation once.');
assert(all(schedule.jobCompleteUnLoad >= 0), ...
    'jobCompleteUnLoad should be non-negative.');

population = [chrom; chrom];
[schedules, populationReport] = decode_population_independent( ...
    population, problem, machineData, agvData, config);

assert(populationReport.isValid, ...
    'Independent population decode report should be valid.');
assert(populationReport.successCount == 2, ...
    'Independent population successCount mismatch.');
assert(populationReport.failureCount == 0, ...
    'Independent population should not contain failures.');
assert(numel(schedules) == 2, ...
    'Independent decoded schedules count mismatch.');

fprintf('test_decoding_independent_layer passed: operations=%d, AGVNum=%d\n', ...
    sum(problem.operaNumVec), agvData.AGVNum);

function [problem, machineData, agvData, config, chrom] = make_independent_decoding_case()
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

function operationCount = count_scheduled_operations(machineTable)
operationCount = 0;
for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    jobs = [blocks.job];
    operationCount = operationCount + sum(jobs > 0);
end
end

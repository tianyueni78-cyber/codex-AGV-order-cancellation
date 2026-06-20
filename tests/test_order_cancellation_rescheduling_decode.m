clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));

problem = make_problem();
machineData = make_machine_data();
agvData = make_agv_data();
schedule = make_schedule();
cancel = create_order_cancellation_event(2, 10);
state = extract_cancellation_state(problem, schedule, cancel);
prefix = extract_frozen_schedule_prefix(schedule, state, cancel);
remainingSet = build_remaining_operation_set(state, cancel);
reschedulingProblem = build_rescheduling_problem( ...
    problem, machineData, agvData, remainingSet, cancel);
constraints = build_rescheduling_constraints(prefix, remainingSet, cancel);

config = make_decode_config(cancel.cancel_time);
chrom = make_rescheduling_chromosome();
candidate = decode_complete_rescheduling_candidate( ...
    reschedulingProblem, constraints, chrom, config);

assert(candidate.isFeasible, strjoin(candidate.report.errors, newline));
assert(candidate.report.decodeReport.isValid, ...
    'Independent decode report should be valid.');
assert(strcmp(candidate.report.decodeReport.decodingStatus, ...
    'decoded-independent'), ...
    'D7 should reuse independent decoder.');
assert(isfield(candidate, 'machineTable'), 'machineTable is missing.');
assert(isfield(candidate, 'AGVTable'), 'AGVTable is missing.');
assert(count_scheduled_operations(candidate.machineTable) == 2, ...
    'Remaining decoded schedule should contain two operations.');
assert(~operation_exists(candidate.machineTable, 2, 2), ...
    'Cancelled unfinished operation must not appear in machineTable.');
assert(~agv_task_exists(candidate.AGVTable, 2, 2), ...
    'Cancelled unfinished AGV task must not appear in AGVTable.');
assert(operation_exists(candidate.machineTable, 1, 2), ...
    'Original job 1 operation 2 should be mapped back.');
assert(operation_exists(candidate.machineTable, 3, 2), ...
    'Original job 3 operation 2 should be mapped back.');
assert(all([candidate.rescheduled_operations.start_time] >= ...
    cancel.cancel_time), ...
    'Decoded remaining operations should start no earlier than cancel_time.');

badConstraints = constraints;
badConstraints.isFeasible = false;
candidate = decode_complete_rescheduling_candidate( ...
    reschedulingProblem, badConstraints, chrom, config);
assert(~candidate.isFeasible, ...
    'Infeasible constraints should reject decoding.');
assert(~isempty(candidate.report.rejectedReasons), ...
    'Rejected decoding should record a reason.');

fprintf('test_order_cancellation_rescheduling_decode passed\n');

function problem = make_problem()
problem = struct();
problem.jobNum = 3;
problem.machineNum = 3;
problem.operaNumVec = [2, 2, 2];
problem.candidateMachine = cell(3, 2);
problem.candidateMachine{1, 1} = [1, 2];
problem.candidateMachine{1, 2} = [2, 3];
problem.candidateMachine{2, 1} = [2];
problem.candidateMachine{2, 2} = [1, 3];
problem.candidateMachine{3, 1} = [1];
problem.candidateMachine{3, 2} = [2, 3];
problem.jobInfo = cell(1, 3);
problem.jobInfo{1} = [
    5, 6, inf
    inf, 4, 7
];
problem.jobInfo{2} = [
    inf, 3, inf
    8, inf, 5
];
problem.jobInfo{3} = [
    2, inf, inf
    inf, 6, 4
];
end

function machineData = make_machine_data()
machineData = struct();
machineData.distance_matrix.machine_to_machine = [
    0, 2, 3
    2, 0, 4
    3, 4, 0
];
machineData.distance_matrix.load_to_machine = [1, 2, 3];
machineData.distance_matrix.machine_to_unload = [1, 2, 3];
machineData.distance_matrix.load_to_unload = 1;
end

function agvData = make_agv_data()
agvData = struct();
agvData.AGVNum = 2;
agvData.AGVSpeed = [1.0, 1.5, 2.0];
agvData.AGVEnergy.free = [1.0, 1.2, 1.4];
agvData.AGVEnergy.load = [1.4, 1.6, 1.8];
end

function schedule = make_schedule()
schedule = struct();
schedule.machineTable = cell(1, 2);
schedule.machineTable{1} = [
    make_machine_block(0, 4, 1, 1)
    make_machine_block(10, 14, 1, 2)
    make_machine_block(14, 18, 3, 2)
    make_machine_block(18, inf, 0, 0)
];
schedule.machineTable{2} = [
    make_machine_block(0, 3, 3, 1)
    make_machine_block(3, 8, 2, 1)
    make_machine_block(12, 15, 2, 2)
    make_machine_block(15, inf, 0, 0)
];

schedule.AGVTable = cell(1, 2);
schedule.AGVTable{1} = [
    make_agv_block(0, 4, 1, 1)
    make_agv_block(4, 8, 2, 1)
    make_agv_block(12, 16, 2, 2)
    make_agv_block(16, inf, 0, 0)
];
schedule.AGVTable{2} = [
    make_agv_block(0, 3, 3, 1)
    make_agv_block(10, 13, 3, 2)
    make_agv_block(13, inf, 0, 0)
];
end

function config = make_decode_config(cancelTime)
config = struct();
config.AGVEG_MAX = 100;
config.AGVEG_MIN = 1;
config.eChargeSpeed = 20;
config.machineTable = {};
config.AGVTable = {};
config.reschedulingStartTime = cancelTime;
end

function chrom = make_rescheduling_chromosome()
OS = [1, 2];
MS = [1, 1];
AS = [1, 2];
SS = [1, 2, 1, 2];
chrom = [OS, MS, AS, SS];
end

function block = make_machine_block(startTime, endTime, jobId, operationId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
end

function block = make_agv_block(startTime, endTime, jobId, operationId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
block.from_machine = -1;
block.to_machine = -1;
block.status = [];
block.load_status = -2;
block.charge = 0;
end

function operationCount = count_scheduled_operations(machineTable)
operationCount = 0;
for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    operationCount = operationCount + sum([blocks.job] > 0);
end
end

function exists = operation_exists(machineTable, jobId, operationId)
exists = false;
for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    for blockIdx = 1:numel(blocks)
        if blocks(blockIdx).job == jobId && ...
                blocks(blockIdx).opera == operationId
            exists = true;
            return
        end
    end
end
end

function exists = agv_task_exists(AGVTable, jobId, operationId)
exists = false;
for agvIdx = 1:numel(AGVTable)
    blocks = AGVTable{agvIdx};
    for blockIdx = 1:numel(blocks)
        if blocks(blockIdx).job == jobId && ...
                blocks(blockIdx).opera == operationId
            exists = true;
            return
        end
    end
end
end

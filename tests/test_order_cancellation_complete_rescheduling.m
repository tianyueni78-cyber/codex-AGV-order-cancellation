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
chrom = make_rescheduling_chromosome();
config = make_decode_config();

candidate = build_complete_rescheduling_candidate( ...
    problem, machineData, agvData, schedule, state, cancel, chrom, config);

assert(candidate.isFeasible, strjoin(candidate.report.errors, newline));
assert(operation_exists(candidate.machineTable, 2, 1), ...
    'Frozen completed operation should remain.');
assert(~operation_exists(candidate.machineTable, 2, 2), ...
    'Cancelled unfinished operation should be excluded.');
assert(operation_exists(candidate.machineTable, 1, 2), ...
    'Remaining operation should be rescheduled.');
assert(operation_exists(candidate.machineTable, 3, 2), ...
    'Remaining operation should be rescheduled.');
assert(all_rescheduled_starts_after_cancel(candidate, cancel.cancel_time), ...
    'Rescheduled operations must start no earlier than cancel_time.');
assert(candidate.report.completeFeasibilityCheck.frozenConsistencyCheck.isFeasible, ...
    'Frozen consistency check should pass.');
assert(candidate.report.completeFeasibilityCheck.cancelledTaskExclusionCheck.isFeasible, ...
    'Cancelled task exclusion check should pass.');

constraints = rebuild_constraints(problem, schedule, state, cancel);

candidateWithMachineConflict = force_machine_time_conflict(candidate);
[isFeasible, report] = check_complete_rescheduling_candidate( ...
    problem, candidateWithMachineConflict, constraints, cancel);
assert(~isFeasible, 'Machine time conflict should be rejected.');
assert(~report.machineConflictCheck.isFeasible, ...
    'Machine conflict check should fail.');

candidateWithAgvConflict = force_agv_time_conflict(candidate);
[isFeasible, report] = check_complete_rescheduling_candidate( ...
    problem, candidateWithAgvConflict, constraints, cancel);
assert(~isFeasible, 'AGV time conflict should be rejected.');
assert(~report.agvConflictCheck.isFeasible, ...
    'AGV conflict check should fail.');

candidateWithSequenceError = force_job_sequence_error(candidate);
[isFeasible, report] = check_complete_rescheduling_candidate( ...
    problem, candidateWithSequenceError, constraints, cancel);
assert(~isFeasible, 'Job sequence error should be rejected.');
assert(~report.jobSequenceCheck.isFeasible, ...
    'Job sequence check should fail.');

unsupportedSchedule = make_schedule_with_processing();
unsupportedState = extract_cancellation_state(problem, unsupportedSchedule, cancel);
candidate = build_complete_rescheduling_candidate( ...
    problem, machineData, agvData, unsupportedSchedule, unsupportedState, ...
    cancel, chrom, config);
assert(~candidate.isFeasible, ...
    'Unsupported processing state should reject complete rescheduling.');
assert(~isempty(candidate.report.rejectedReasons), ...
    'Unsupported rejection should record a reason.');

fprintf('test_order_cancellation_complete_rescheduling passed\n');

function constraints = rebuild_constraints(problem, schedule, state, cancel)
prefix = extract_frozen_schedule_prefix(schedule, state, cancel);
remainingSet = build_remaining_operation_set(state, cancel);
constraints = build_rescheduling_constraints(prefix, remainingSet, cancel);
assert(constraints.isFeasible, strjoin(constraints.report.errors, newline));
end

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

function schedule = make_schedule_with_processing()
schedule = make_schedule();
schedule.machineTable{1}(2).start = 8;
schedule.machineTable{1}(2).end = 12;
end

function config = make_decode_config()
config = struct();
config.AGVEG_MAX = 100;
config.AGVEG_MIN = 1;
config.eChargeSpeed = 20;
config.machineTable = {};
config.AGVTable = {};
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

function startsOk = all_rescheduled_starts_after_cancel(candidate, cancelTime)
startsOk = true;
for i = 1:numel(candidate.rescheduled_operations)
    if candidate.rescheduled_operations(i).start_time < cancelTime
        startsOk = false;
        return
    end
end
end

function candidate = force_machine_time_conflict(candidate)
for machineIdx = 1:numel(candidate.machineTable)
    realBlockIdx = find([candidate.machineTable{machineIdx}.job] > 0);
    if numel(realBlockIdx) < 2
        continue
    end

    firstIdx = realBlockIdx(1);
    secondIdx = realBlockIdx(2);
    firstBlock = candidate.machineTable{machineIdx}(firstIdx);
    candidate.machineTable{machineIdx}(secondIdx).start = ...
        firstBlock.start + 0.5;
    candidate.machineTable{machineIdx}(secondIdx).end = ...
        firstBlock.end + 1;
    return
end

error('test_order_cancellation_complete_rescheduling:NoMachinePair', ...
    'Test candidate must contain two real operations on one machine.');
end

function candidate = force_agv_time_conflict(candidate)
for agvIdx = 1:numel(candidate.AGVTable)
    realBlockIdx = find([candidate.AGVTable{agvIdx}.job] > 0);
    if numel(realBlockIdx) < 2
        continue
    end

    firstIdx = realBlockIdx(1);
    secondIdx = realBlockIdx(2);
    firstBlock = candidate.AGVTable{agvIdx}(firstIdx);
    candidate.AGVTable{agvIdx}(secondIdx).start = ...
        firstBlock.start + 0.5;
    candidate.AGVTable{agvIdx}(secondIdx).end = firstBlock.end + 1;
    return
end

error('test_order_cancellation_complete_rescheduling:NoAgvPair', ...
    'Test candidate must contain two real AGV tasks on one AGV.');
end

function candidate = force_job_sequence_error(candidate)
[firstLocation, secondLocation] = find_job_operation_pair(candidate, 1, 1, 2);
firstBlock = candidate.machineTable{firstLocation.machine_id}( ...
    firstLocation.block_index);

candidate.machineTable{secondLocation.machine_id}( ...
    secondLocation.block_index).start = firstBlock.start;
candidate.machineTable{secondLocation.machine_id}( ...
    secondLocation.block_index).end = firstBlock.end - 1;
end

function [firstLocation, secondLocation] = find_job_operation_pair( ...
    candidate, jobId, firstOperationId, secondOperationId)
firstLocation = [];
secondLocation = [];

for machineIdx = 1:numel(candidate.machineTable)
    blocks = candidate.machineTable{machineIdx};
    for blockIdx = 1:numel(blocks)
        if blocks(blockIdx).job == jobId && ...
                blocks(blockIdx).opera == firstOperationId
            firstLocation = make_block_location(machineIdx, blockIdx);
        end
        if blocks(blockIdx).job == jobId && ...
                blocks(blockIdx).opera == secondOperationId
            secondLocation = make_block_location(machineIdx, blockIdx);
        end
    end
end

if isempty(firstLocation) || isempty(secondLocation)
    error('test_order_cancellation_complete_rescheduling:MissingJobPair', ...
        'Test candidate must contain job %d operations %d and %d.', ...
        jobId, firstOperationId, secondOperationId);
end
end

function location = make_block_location(machineId, blockIndex)
location = struct();
location.machine_id = machineId;
location.block_index = blockIndex;
end

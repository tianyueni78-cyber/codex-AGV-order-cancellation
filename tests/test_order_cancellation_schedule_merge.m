clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

cancel = create_order_cancellation_event(2, 10);
constraints = make_constraints(cancel);
decodedCandidate = make_decoded_candidate();
candidate = merge_frozen_and_rescheduled_schedule( ...
    constraints, decodedCandidate, cancel);

assert(candidate.isFeasible, strjoin(candidate.report.errors, newline));
assert(operation_exists(candidate.machineTable, 2, 1), ...
    'Completed cancelled-job operation should remain frozen history.');
assert(operation_exists(candidate.machineTable, 1, 2), ...
    'Rescheduled non-cancelled operation should appear.');
assert(operation_exists(candidate.machineTable, 3, 2), ...
    'Rescheduled non-cancelled operation should appear.');
assert(~operation_exists(candidate.machineTable, 2, 2), ...
    'Cancelled unfinished operation must not appear.');
assert(~agv_task_exists(candidate.AGVTable, 2, 2), ...
    'Cancelled unfinished AGV task must not appear.');

assert(get_operation_start(candidate.machineTable, 2, 1) == 3, ...
    'Frozen operation start time should not change.');
assert(get_operation_end(candidate.machineTable, 2, 1) == 8, ...
    'Frozen operation end time should not change.');
assert(get_operation_start(candidate.machineTable, 1, 2) >= ...
    cancel.cancel_time, ...
    'Rescheduled operation should start no earlier than cancel_time.');

assert(iscell(candidate.machineTable), ...
    'Merged machineTable should be a cell array.');
assert(iscell(candidate.AGVTable), ...
    'Merged AGVTable should be a cell array.');
assert(all(isfield(candidate.machineTable{1}, ...
    {'start', 'end', 'job', 'opera'})), ...
    'Merged machine blocks should match stage C table format.');
assert(all(isfield(candidate.AGVTable{1}, ...
    {'start', 'end', 'job', 'opera', 'from_machine', 'to_machine'})), ...
    'Merged AGV blocks should match stage C table format.');

decodedCandidateWithLeak = decodedCandidate;
decodedCandidateWithLeak.machineTable{2}(end + 1) = ...
    make_machine_block(18, 21, 2, 2);
candidate = merge_frozen_and_rescheduled_schedule( ...
    constraints, decodedCandidateWithLeak, cancel);
assert(~candidate.isFeasible, ...
    'Merged candidate should reject excluded operation leakage.');

decodedCandidateEarly = decodedCandidate;
decodedCandidateEarly.machineTable{1}(1).start = 9;
didFail = false;
try
    merge_frozen_and_rescheduled_schedule( ...
        constraints, decodedCandidateEarly, cancel);
catch
    didFail = true;
end
assert(didFail, ...
    'Rescheduled suffix starting before cancel_time should be rejected.');

fprintf('test_order_cancellation_schedule_merge passed\n');

function constraints = make_constraints(cancel)
constraints = struct();
constraints.cancel = cancel;
constraints.earliest_start_time = cancel.cancel_time;
constraints.isFeasible = true;
constraints.frozen_machine_occupancy = [
    make_machine_occupancy(2, 2, 1, 3, 8)
    make_machine_occupancy(1, 1, 1, 0, 4)
];
constraints.frozen_agv_occupancy = [
    make_agv_occupancy(1, 2, 1, 4, 8)
    make_agv_occupancy(2, 1, 1, 0, 3)
];
end

function candidate = make_decoded_candidate()
candidate = struct();
candidate.machineTable = cell(1, 2);
candidate.machineTable{1} = [
    make_machine_block(10, 14, 1, 2)
    make_machine_block(14, inf, 0, 0)
];
candidate.machineTable{2} = [
    make_machine_block(12, 16, 3, 2)
    make_machine_block(16, inf, 0, 0)
];

candidate.AGVTable = cell(1, 2);
candidate.AGVTable{1} = [
    make_agv_block(10, 12, 1, 2)
    make_agv_block(12, inf, 0, 0)
];
candidate.AGVTable{2} = [
    make_agv_block(12, 15, 3, 2)
    make_agv_block(15, inf, 0, 0)
];

candidate.excluded_operations = make_excluded_operation(2, 2);
candidate.isFeasible = true;
candidate.report = struct();
candidate.report.errors = {};
candidate.report.warnings = {};
candidate.report.rejectedReasons = {};
end

function record = make_machine_occupancy(machineId, jobId, operationId, ...
    startTime, endTime)
record = struct();
record.machine_id = machineId;
record.job_id = jobId;
record.operation_id = operationId;
record.start_time = startTime;
record.end_time = endTime;
record.source = 'test';
end

function record = make_agv_occupancy(agvId, jobId, operationId, ...
    startTime, endTime)
record = struct();
record.agv_id = agvId;
record.job_id = jobId;
record.operation_id = operationId;
record.start_time = startTime;
record.end_time = endTime;
record.from_machine = -1;
record.to_machine = -1;
record.source = 'test';
end

function operation = make_excluded_operation(jobId, operationId)
operation = struct();
operation.job_id = jobId;
operation.operation_id = operationId;
operation.machine_id = [];
operation.block_index = [];
operation.start_time = [];
operation.end_time = [];
operation.status = 'unstarted';
operation.source = 'test';
operation.exclude_reason = 'cancelled_order_unfinished_operation';
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
block.status = 0;
block.load_status = [];
block.charge = [];
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

function startTime = get_operation_start(machineTable, jobId, operationId)
startTime = [];
for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    for blockIdx = 1:numel(blocks)
        if blocks(blockIdx).job == jobId && ...
                blocks(blockIdx).opera == operationId
            startTime = blocks(blockIdx).start;
            return
        end
    end
end
end

function endTime = get_operation_end(machineTable, jobId, operationId)
endTime = [];
for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    for blockIdx = 1:numel(blocks)
        if blocks(blockIdx).job == jobId && ...
                blocks(blockIdx).opera == operationId
            endTime = blocks(blockIdx).end;
            return
        end
    end
end
end


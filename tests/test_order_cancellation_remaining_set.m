clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

problem = make_problem();
schedule = make_schedule();
cancel = create_order_cancellation_event(2, 10);
state = extract_cancellation_state(problem, schedule, cancel);
remainingSet = build_remaining_operation_set(state, cancel);

assert(remainingSet.isFeasible, strjoin(remainingSet.report.errors, newline));
assert(remainingSet.report.operationCount == 2, ...
    'Remaining set should contain unfinished non-cancelled operations.');
assert(remainingSet.report.excludedOperationCount == 1, ...
    'Excluded operation count mismatch.');

remainingKeys = operation_keys(remainingSet.operations);
assert(isequal(sort(remainingKeys), sort([102, 302])), ...
    'Remaining set should contain unfinished operations from non-cancelled jobs.');
assert(~any(floor(remainingKeys ./ 100) == cancel.job_id), ...
    'Cancelled job operations must not enter remaining set.');
assert(~any(remainingKeys == 201), ...
    'Completed historical operation must not enter remaining set.');
assert(~any(remainingKeys == 202), ...
    'Cancelled unfinished operation must not enter remaining set.');

excludedKeys = operation_keys(remainingSet.excluded_operations);
assert(isequal(excludedKeys, 202), ...
    'Cancelled unfinished operation should be recorded as excluded.');
assert(strcmp(remainingSet.excluded_operations(1).exclude_reason, ...
    'cancelled_order_unfinished_operation'), ...
    'Excluded operation should record exclude_reason.');

for i = 1:numel(remainingSet.operations)
    assert(isfield(remainingSet.operations(i), 'job_id'), ...
        'Remaining operation requires job_id.');
    assert(isfield(remainingSet.operations(i), 'operation_id'), ...
        'Remaining operation requires operation_id.');
    assert(isfield(remainingSet.operations(i), 'machine_id'), ...
        'Remaining operation should keep optional machine_id.');
end

stateWithCancelledLeak = state;
stateWithCancelledLeak.remaining_unfinished_operations(end + 1) = ...
    state.cancelled_unfinished_operations(1);
remainingSet = build_remaining_operation_set(stateWithCancelledLeak, cancel);
assert(~remainingSet.isFeasible, ...
    'Cancelled unfinished operation leaking into remaining set should fail.');
assert(~isempty(remainingSet.report.errors), ...
    'Leak failure should record errors.');

stateWithCompletedLeak = state;
stateWithCompletedLeak.remaining_unfinished_operations(end + 1) = ...
    state.completed_operations(1);
remainingSet = build_remaining_operation_set(stateWithCompletedLeak, cancel);
assert(~remainingSet.isFeasible, ...
    'Completed operation leaking into remaining set should fail.');

mismatchedCancel = create_order_cancellation_event(1, 10);
didFail = false;
try
    build_remaining_operation_set(state, mismatchedCancel);
catch
    didFail = true;
end
assert(didFail, 'Mismatched cancel input should be rejected.');

fprintf('test_order_cancellation_remaining_set passed\n');

function problem = make_problem()
problem = struct();
problem.jobNum = 3;
problem.operaNumVec = [2, 2, 2];
end

function schedule = make_schedule()
schedule = struct();
schedule.machineTable = make_machine_table();
schedule.AGVTable = make_agv_table();
end

function machineTable = make_machine_table()
machineTable = cell(1, 2);

machineTable{1} = [
    make_machine_block(0, 6, 1, 1)
    make_machine_block(6, 12, 1, 2)
    make_machine_block(12, inf, 0, 0)
];

machineTable{2} = [
    make_machine_block(0, 3, 3, 1)
    make_machine_block(3, 8, 2, 1)
    make_machine_block(8, 11, 3, 2)
    make_machine_block(12, 15, 2, 2)
    make_machine_block(15, inf, 0, 0)
];
end

function AGVTable = make_agv_table()
AGVTable = cell(1, 2);

AGVTable{1} = [
    make_agv_block(0, 4, 1, 1)
    make_agv_block(4, 8, 2, 1)
    make_agv_block(12, 16, 2, 2)
    make_agv_block(16, inf, 0, 0)
];

AGVTable{2} = [
    make_agv_block(0, 3, 3, 1)
    make_agv_block(8, 11, 3, 2)
    make_agv_block(11, inf, 0, 0)
];
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

function keys = operation_keys(operations)
keys = zeros(1, numel(operations));
for i = 1:numel(operations)
    keys(i) = operations(i).job_id * 100 + operations(i).operation_id;
end
end


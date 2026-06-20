clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

problem = struct();
problem.jobNum = 3;

schedule = struct();
schedule.machineTable = make_machine_table();
schedule.AGVTable = make_agv_table();

cancel = create_order_cancellation_event(2, 10);
state = extract_cancellation_state(problem, schedule, cancel);

assert(state.operation_count == 6, ...
    'All real operations should be collected from machineTable.');
assert(numel(state.completed_operations) == 3, ...
    'Completed operation count mismatch.');
assert(numel(state.processing_operations) == 2, ...
    'Processing operation count mismatch.');
assert(numel(state.unstarted_operations) == 1, ...
    'Unstarted operation count mismatch.');

assert(all([state.completed_operations.end_time] <= cancel.cancel_time), ...
    'Completed operations must end no later than cancel_time.');
assert(all([state.unstarted_operations.start_time] >= cancel.cancel_time), ...
    'Unstarted operations must start no earlier than cancel_time.');
assert(all([state.processing_operations.start_time] < cancel.cancel_time) && ...
    all(cancel.cancel_time < [state.processing_operations.end_time]), ...
    'Processing operation must strictly contain cancel_time.');

cancelledKeys = operation_keys(state.cancelled_unfinished_operations);
assert(isequal(cancelledKeys, 202), ...
    'Cancelled unfinished operations should exclude completed job 2 operations.');

remainingKeys = operation_keys(state.remaining_unfinished_operations);
assert(isequal(sort(remainingKeys), sort([102, 302])), ...
    'Remaining unfinished operations should include unfinished non-cancelled jobs.');

assert(~any(cancelledKeys == 201), ...
    'Completed cancelled-job operation must not enter cancellation list.');

assert(isempty(state.unsupported_operations), ...
    'Job 2 cancellation should not have unsupported processing operations.');
assert(state.agv_task_count == 5, ...
    'All real AGV tasks should be collected from AGVTable.');
assert(numel(state.completed_agv_tasks) == 3, ...
    'Completed AGV task count mismatch.');
assert(numel(state.processing_agv_tasks) == 1, ...
    'Processing AGV task count mismatch.');
assert(numel(state.unstarted_agv_tasks) == 1, ...
    'Unstarted AGV task count mismatch.');
assert(isequal(agv_task_keys(state.cancelled_unfinished_agv_tasks), 202), ...
    'Cancelled unfinished AGV tasks should include job 2 unstarted transport.');
assert(~any(agv_task_keys(state.cancelled_unfinished_agv_tasks) == 201), ...
    'Completed job 2 AGV task should remain historical.');
assert(isempty(state.unsupported_agv_tasks), ...
    'Job 2 cancellation should not have unsupported AGV tasks.');

cancel = create_order_cancellation_event(3, 10);
state = extract_cancellation_state(problem, schedule, cancel);
unsupportedKeys = operation_keys(state.unsupported_operations);
assert(isequal(unsupportedKeys, 302), ...
    'Processing cancelled-job operation should be marked unsupported.');
assert(state.has_unsupported_operations, ...
    'State should report unsupported operations.');
assert(isequal(agv_task_keys(state.unsupported_agv_tasks), 302), ...
    'Processing cancelled-job AGV task should be marked unsupported.');
assert(state.has_unsupported_agv_tasks, ...
    'State should report unsupported AGV tasks.');

cancel = create_order_cancellation_event(1, 6);
state = extract_cancellation_state(problem, schedule, cancel);
assert(any(operation_keys(state.completed_operations) == 101), ...
    'cancel_time == end should classify operation as completed.');
assert(any(operation_keys(state.unstarted_operations) == 102), ...
    'cancel_time == start should classify operation as unstarted.');

fprintf('test_order_cancellation_state passed\n');

function machineTable = make_machine_table()
machineTable = cell(1, 2);

machineTable{1} = [
    make_block(0, 0, 0, 0, 0)
    make_block(0, 6, 1, 1, 0)
    make_block(6, 12, 1, 2, 0)
    make_block(12, inf, 0, 0, 0)
];

machineTable{2} = [
    make_block(0, 3, 3, 1, 0)
    make_block(3, 8, 2, 1, 0)
    make_block(8, 11, 3, 2, 0)
    make_block(12, 15, 2, 2, 0)
    make_block(15, inf, 0, 0, 0)
];
end

function AGVTable = make_agv_table()
AGVTable = cell(1, 2);

AGVTable{1} = [
    make_agv_block(0, 0, 0, 0, -1, -1, 0)
    make_agv_block(0, 4, 1, 1, -1, 1, -2)
    make_agv_block(4, 8, 2, 1, -1, 2, -2)
    make_agv_block(12, 16, 2, 2, 2, -2, -2)
    make_agv_block(16, inf, 0, 0, -2, -2, 0)
];

AGVTable{2} = [
    make_agv_block(0, 3, 3, 1, -1, 2, -2)
    make_agv_block(8, 11, 3, 2, 2, -2, -2)
    make_agv_block(11, inf, 0, 0, -2, -2, 0)
];
end

function block = make_block(startTime, endTime, jobId, operationId, agvId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
block.AGV = agvId;
end

function block = make_agv_block(startTime, endTime, jobId, operationId, ...
    fromMachine, toMachine, loadStatus)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
block.from_machine = fromMachine;
block.to_machine = toMachine;
block.status = [];
block.load_status = loadStatus;
block.charge = 0;
end

function keys = operation_keys(operations)
keys = zeros(1, numel(operations));
for i = 1:numel(operations)
    keys(i) = operations(i).job_id * 100 + operations(i).operation_id;
end
end

function keys = agv_task_keys(agvTasks)
keys = zeros(1, numel(agvTasks));
for i = 1:numel(agvTasks)
    keys(i) = agvTasks(i).job_id * 100 + agvTasks(i).operation_id;
end
end

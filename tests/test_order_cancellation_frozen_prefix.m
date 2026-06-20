clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

problem = make_problem();
schedule = make_schedule();
cancel = create_order_cancellation_event(2, 10);
state = extract_cancellation_state(problem, schedule, cancel);
prefix = extract_frozen_schedule_prefix(schedule, state, cancel);

assert(numel(prefix.frozen_operations) == 3, ...
    'Completed machine operations should enter frozen_operations.');
assert(numel(prefix.frozen_agv_tasks) == 3, ...
    'Completed AGV tasks should enter frozen_agv_tasks.');
assert(prefix.report.frozenOperationCount == 3, ...
    'frozenOperationCount mismatch.');
assert(prefix.report.frozenAgvTaskCount == 3, ...
    'frozenAgvTaskCount mismatch.');

assert(all([prefix.frozen_operations.end_time] <= cancel.cancel_time), ...
    'Frozen operations must end no later than cancel_time.');
assert(all([prefix.frozen_agv_tasks.end_time] <= cancel.cancel_time), ...
    'Frozen AGV tasks must end no later than cancel_time.');
assert(isequal(operation_times(prefix.frozen_operations), ...
    operation_times(state.completed_operations)), ...
    'Frozen operation start/end times must remain unchanged.');
assert(isequal(agv_task_times(prefix.frozen_agv_tasks), ...
    agv_task_times(state.completed_agv_tasks)), ...
    'Frozen AGV task start/end times must remain unchanged.');

assert(prefix.has_unsupported_operations, ...
    'Processing machine operations should be marked unsupported.');
assert(prefix.has_unsupported_agv_tasks, ...
    'Processing AGV tasks should be marked unsupported.');
assert(~prefix.isFeasible, ...
    'Prefix with processing tasks should be infeasible in stage D.');
assert(isequal(operation_keys(prefix.unsupported_operations), ...
    operation_keys(state.processing_operations)), ...
    'Processing operations should be reported as unsupported.');
assert(isequal(agv_task_keys(prefix.unsupported_agv_tasks), ...
    agv_task_keys(state.processing_agv_tasks)), ...
    'Processing AGV tasks should be reported as unsupported.');

scheduleNoProcessing = make_completed_or_unstarted_schedule();
cancel = create_order_cancellation_event(2, 10);
state = extract_cancellation_state(problem, scheduleNoProcessing, cancel);
prefix = extract_frozen_schedule_prefix(scheduleNoProcessing, state, cancel);
assert(~prefix.has_unsupported_operations, ...
    'No processing operations should mean no unsupported operations.');
assert(~prefix.has_unsupported_agv_tasks, ...
    'No processing AGV tasks should mean no unsupported AGV tasks.');
assert(prefix.isFeasible, ...
    'Prefix without processing tasks should be feasible.');

mismatchedCancel = create_order_cancellation_event(1, 10);
didFail = false;
try
    extract_frozen_schedule_prefix(scheduleNoProcessing, state, mismatchedCancel);
catch
    didFail = true;
end
assert(didFail, 'Mismatched cancel input should be rejected.');

fprintf('test_order_cancellation_frozen_prefix passed\n');

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

function schedule = make_completed_or_unstarted_schedule()
schedule = struct();
schedule.machineTable = cell(1, 2);
schedule.machineTable{1} = [
    make_machine_block(0, 4, 1, 1)
    make_machine_block(4, 8, 1, 2)
    make_machine_block(10, 14, 3, 2)
    make_machine_block(14, inf, 0, 0)
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

function keys = agv_task_keys(agvTasks)
keys = zeros(1, numel(agvTasks));
for i = 1:numel(agvTasks)
    keys(i) = agvTasks(i).job_id * 100 + agvTasks(i).operation_id;
end
end

function times = operation_times(operations)
times = zeros(numel(operations), 2);
for i = 1:numel(operations)
    times(i, :) = [operations(i).start_time, operations(i).end_time];
end
end

function times = agv_task_times(agvTasks)
times = zeros(numel(agvTasks), 2);
for i = 1:numel(agvTasks)
    times(i, :) = [agvTasks(i).start_time, agvTasks(i).end_time];
end
end


clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

problem = make_problem();
schedule = make_completed_or_unstarted_schedule();
cancel = create_order_cancellation_event(2, 10);
state = extract_cancellation_state(problem, schedule, cancel);
prefix = extract_frozen_schedule_prefix(schedule, state, cancel);
remainingSet = build_remaining_operation_set(state, cancel);
constraints = build_rescheduling_constraints(prefix, remainingSet, cancel);

assert(constraints.isFeasible, strjoin(constraints.report.errors, newline));
assert(constraints.earliest_start_time == cancel.cancel_time, ...
    'earliest_start_time should equal cancel_time.');
assert(numel(constraints.frozen_machine_occupancy) == ...
    numel(prefix.frozen_operations), ...
    'Frozen machine occupancy count mismatch.');
assert(numel(constraints.frozen_agv_occupancy) == ...
    numel(prefix.frozen_agv_tasks), ...
    'Frozen AGV occupancy count mismatch.');
assert(isequal(machine_times(constraints.frozen_machine_occupancy), ...
    machine_times(prefix.frozen_operations)), ...
    'Frozen machine operation times must remain unchanged.');
assert(isequal(agv_times(constraints.frozen_agv_occupancy), ...
    agv_times(prefix.frozen_agv_tasks)), ...
    'Frozen AGV task times must remain unchanged.');

assert(all([remainingSet.operations.start_time] >= cancel.cancel_time), ...
    'Constructed remaining operations should start no earlier than cancel_time.');

remainingSetWithEarlyTask = remainingSet;
remainingSetWithEarlyTask.operations(1).start_time = cancel.cancel_time - 1;
constraints = build_rescheduling_constraints( ...
    prefix, remainingSetWithEarlyTask, cancel);
assert(~constraints.isFeasible, ...
    'Remaining operation starting before cancel_time should be rejected.');
assert(~isempty(constraints.report.errors), ...
    'Early remaining operation should produce an error.');

scheduleWithProcessing = make_schedule_with_processing();
state = extract_cancellation_state(problem, scheduleWithProcessing, cancel);
prefix = extract_frozen_schedule_prefix(scheduleWithProcessing, state, cancel);
remainingSet = build_remaining_operation_set(state, cancel);
constraints = build_rescheduling_constraints(prefix, remainingSet, cancel);
assert(~constraints.isFeasible, ...
    'Infeasible frozen prefix should reject constraints.');
assert(~isempty(constraints.report.rejectedReasons), ...
    'Infeasible prefix should record a rejected reason.');

mismatchedCancel = create_order_cancellation_event(1, 10);
didFail = false;
try
    build_rescheduling_constraints(prefix, remainingSet, mismatchedCancel);
catch
    didFail = true;
end
assert(didFail, 'Mismatched cancel input should be rejected.');

fprintf('test_order_cancellation_rescheduling_constraints passed\n');

function problem = make_problem()
problem = struct();
problem.jobNum = 3;
problem.operaNumVec = [2, 2, 2];
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

function schedule = make_schedule_with_processing()
schedule = make_completed_or_unstarted_schedule();
schedule.machineTable{1}(3).start = 8;
schedule.machineTable{1}(3).end = 12;
schedule.AGVTable{2}(2).start = 8;
schedule.AGVTable{2}(2).end = 11;
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

function times = machine_times(records)
times = zeros(numel(records), 2);
for i = 1:numel(records)
    times(i, :) = [records(i).start_time, records(i).end_time];
end
end

function times = agv_times(records)
times = zeros(numel(records), 2);
for i = 1:numel(records)
    times(i, :) = [records(i).start_time, records(i).end_time];
end
end


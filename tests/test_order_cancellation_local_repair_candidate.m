clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

problem = make_problem();
schedule = make_schedule();

cancel = create_order_cancellation_event(2, 10);
state = extract_cancellation_state(problem, schedule, cancel);
candidate = build_local_repair_candidate(problem, schedule, state, cancel);

assert(candidate.isFeasible, strjoin(candidate.report.errors, newline));
assert(~operation_exists(candidate.machineTable, 2, 2), ...
    'Cancelled unstarted machine operation should be removed.');
assert(~agv_task_exists(candidate.AGVTable, 2, 2), ...
    'Cancelled unstarted AGV task should be removed.');
assert(operation_exists(candidate.machineTable, 2, 1), ...
    'Completed cancelled operation should remain historical.');
assert(agv_task_exists(candidate.AGVTable, 2, 1), ...
    'Completed cancelled AGV task should remain historical.');
assert(candidate.report.removedOperationCount == 1, ...
    'removedOperationCount mismatch.');
assert(candidate.report.removedAgvTaskCount == 1, ...
    'removedAgvTaskCount mismatch.');
assert(candidate.report.machineConflictCheck.isFeasible, ...
    'Machine conflict check should pass.');
assert(candidate.report.agvConflictCheck.isFeasible, ...
    'AGV conflict check should pass.');
assert(candidate.report.jobSequenceCheck.isFeasible, ...
    'Job sequence check should pass.');

cancel = create_order_cancellation_event(3, 10);
state = extract_cancellation_state(problem, schedule, cancel);
candidate = build_local_repair_candidate(problem, schedule, state, cancel);
assert(~candidate.isFeasible, ...
    'Unsupported processing state should be rejected.');
assert(~isempty(candidate.report.rejectedReasons), ...
    'Unsupported rejection should be recorded.');

cancel = create_order_cancellation_event(2, 10);
scheduleWithMachineConflict = make_schedule();
scheduleWithMachineConflict.machineTable{2}(3).start = 7;
state = extract_cancellation_state(problem, scheduleWithMachineConflict, cancel);
candidate = build_local_repair_candidate( ...
    problem, scheduleWithMachineConflict, state, cancel);
assert(~candidate.isFeasible, ...
    'Machine conflict should make local repair infeasible.');
assert(~candidate.report.machineConflictCheck.isFeasible, ...
    'Machine conflict check should fail.');

scheduleWithAgvConflict = make_schedule();
scheduleWithAgvConflict.AGVTable{1}(3).start = 4;
state = extract_cancellation_state(problem, scheduleWithAgvConflict, cancel);
candidate = build_local_repair_candidate( ...
    problem, scheduleWithAgvConflict, state, cancel);
assert(~candidate.isFeasible, ...
    'AGV conflict should make local repair infeasible.');
assert(~candidate.report.agvConflictCheck.isFeasible, ...
    'AGV conflict check should fail.');

scheduleWithSequenceError = make_schedule();
scheduleWithSequenceError.machineTable{1}(2).start = 4;
state = extract_cancellation_state(problem, scheduleWithSequenceError, cancel);
candidate = build_local_repair_candidate( ...
    problem, scheduleWithSequenceError, state, cancel);
assert(~candidate.isFeasible, ...
    'Job sequence error should make local repair infeasible.');
assert(~candidate.report.jobSequenceCheck.isFeasible, ...
    'Job sequence check should fail.');

fprintf('test_order_cancellation_local_repair_candidate passed\n');

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
    make_machine_block(0, 5, 1, 1)
    make_machine_block(5, 9, 1, 2)
    make_machine_block(9, inf, 0, 0)
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
    make_agv_block(8, 11, 3, 2)
    make_agv_block(12, 16, 2, 2)
    make_agv_block(16, inf, 0, 0)
];

AGVTable{2} = [
    make_agv_block(0, 3, 3, 1)
    make_agv_block(3, inf, 0, 0)
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

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
candidate = remove_cancelled_machine_operations( ...
    problem, schedule, state, cancel);

assert(candidate.isFeasible, ...
    'Unstarted cancellation should produce a feasible machine-removal candidate.');
assert(numel(candidate.removed_operations) == 1, ...
    'Exactly one unstarted machine operation should be removed.');
assert(operation_exists(candidate.machineTable, 2, 1), ...
    'Completed cancelled-job operation should remain historical.');
assert(~operation_exists(candidate.machineTable, 2, 2), ...
    'Unstarted cancelled-job operation should be removed.');
assert(operation_exists(candidate.machineTable, 1, 2), ...
    'Non-cancelled operation should remain.');
assert(operation_start(candidate.machineTable, 1, 2) == ...
    operation_start(schedule.machineTable, 1, 2), ...
    'Remaining operation start time should not move.');
assert(operation_end(candidate.machineTable, 1, 2) == ...
    operation_end(schedule.machineTable, 1, 2), ...
    'Remaining operation end time should not move.');
assert(isequaln(candidate.AGVTable, schedule.AGVTable), ...
    'Step C3 should not modify AGVTable.');
assert(candidate.report.removedOperationCount == 1, ...
    'removedOperationCount mismatch.');
assert(candidate.report.removedAgvTaskCount == 0, ...
    'Step C3 should not remove AGV tasks.');

cancel = create_order_cancellation_event(3, 10);
state = extract_cancellation_state(problem, schedule, cancel);
candidate = remove_cancelled_machine_operations( ...
    problem, schedule, state, cancel);

assert(~candidate.isFeasible, ...
    'Processing cancelled operation should reject machine removal.');
assert(isempty(candidate.removed_operations), ...
    'Rejected candidate should not remove machine operations.');
assert(isequaln(candidate.machineTable, schedule.machineTable), ...
    'Rejected candidate should keep machineTable unchanged.');
assert(~isempty(candidate.report.rejectedReasons), ...
    'Rejected candidate should explain why it is infeasible.');

fprintf('test_order_cancellation_machine_removal passed\n');

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

function startTime = operation_start(machineTable, jobId, operationId)
block = find_operation(machineTable, jobId, operationId);
startTime = block.start;
end

function endTime = operation_end(machineTable, jobId, operationId)
block = find_operation(machineTable, jobId, operationId);
endTime = block.end;
end

function block = find_operation(machineTable, jobId, operationId)
for machineIdx = 1:numel(machineTable)
    blocks = machineTable{machineIdx};
    for blockIdx = 1:numel(blocks)
        if blocks(blockIdx).job == jobId && ...
                blocks(blockIdx).opera == operationId
            block = blocks(blockIdx);
            return
        end
    end
end

error('test_order_cancellation_machine_removal:MissingOperation', ...
    'Operation was not found.');
end

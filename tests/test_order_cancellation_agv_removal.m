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
candidate = remove_cancelled_agv_tasks(problem, schedule, state, cancel);

assert(candidate.isFeasible, ...
    'Unstarted cancellation should produce a feasible AGV-removal candidate.');
assert(numel(candidate.removed_agv_tasks) == 1, ...
    'Exactly one unstarted AGV task should be removed.');
assert(agv_task_exists(candidate.AGVTable, 2, 1), ...
    'Completed cancelled-job AGV task should remain historical.');
assert(~agv_task_exists(candidate.AGVTable, 2, 2), ...
    'Unstarted cancelled-job AGV task should be removed.');
assert(agv_task_exists(candidate.AGVTable, 1, 1), ...
    'Non-cancelled AGV task should remain.');
assert(agv_task_start(candidate.AGVTable, 1, 1) == ...
    agv_task_start(schedule.AGVTable, 1, 1), ...
    'Remaining AGV task start time should not move.');
assert(agv_task_end(candidate.AGVTable, 1, 1) == ...
    agv_task_end(schedule.AGVTable, 1, 1), ...
    'Remaining AGV task end time should not move.');
assert(isequaln(candidate.machineTable, schedule.machineTable), ...
    'Step C4 should not modify machineTable.');
assert(candidate.report.removedOperationCount == 0, ...
    'Step C4 should not remove machine operations.');
assert(candidate.report.removedAgvTaskCount == 1, ...
    'removedAgvTaskCount mismatch.');

cancel = create_order_cancellation_event(3, 10);
state = extract_cancellation_state(problem, schedule, cancel);
candidate = remove_cancelled_agv_tasks(problem, schedule, state, cancel);

assert(~candidate.isFeasible, ...
    'Processing cancelled AGV task should reject AGV removal.');
assert(isempty(candidate.removed_agv_tasks), ...
    'Rejected candidate should not remove AGV tasks.');
assert(isequaln(candidate.AGVTable, schedule.AGVTable), ...
    'Rejected candidate should keep AGVTable unchanged.');
assert(~isempty(candidate.report.rejectedReasons), ...
    'Rejected candidate should explain why it is infeasible.');

fprintf('test_order_cancellation_agv_removal passed\n');

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

function startTime = agv_task_start(AGVTable, jobId, operationId)
block = find_agv_task(AGVTable, jobId, operationId);
startTime = block.start;
end

function endTime = agv_task_end(AGVTable, jobId, operationId)
block = find_agv_task(AGVTable, jobId, operationId);
endTime = block.end;
end

function block = find_agv_task(AGVTable, jobId, operationId)
for agvIdx = 1:numel(AGVTable)
    blocks = AGVTable{agvIdx};
    for blockIdx = 1:numel(blocks)
        if blocks(blockIdx).job == jobId && ...
                blocks(blockIdx).opera == operationId
            block = blocks(blockIdx);
            return
        end
    end
end

error('test_order_cancellation_agv_removal:MissingAgvTask', ...
    'AGV task was not found.');
end

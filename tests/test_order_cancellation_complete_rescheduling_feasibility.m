clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

problem = make_problem();
cancel = create_order_cancellation_event(2, 10);
constraints = make_constraints(cancel);
candidate = make_candidate();

[isFeasible, report] = check_complete_rescheduling_candidate( ...
    problem, candidate, constraints, cancel);
assert(isFeasible, strjoin(report.errors, newline));
assert(report.machineConflictCheck.isFeasible, ...
    'Machine conflict check should pass.');
assert(report.agvConflictCheck.isFeasible, ...
    'AGV conflict check should pass.');
assert(report.jobSequenceCheck.isFeasible, ...
    'Job sequence check should pass.');
assert(report.frozenConsistencyCheck.isFeasible, ...
    'Frozen consistency check should pass.');
assert(report.cancelledTaskExclusionCheck.isFeasible, ...
    'Cancelled task exclusion check should pass.');

candidateWithMachineConflict = make_candidate();
candidateWithMachineConflict.machineTable{1}(2).start = 3;
[isFeasible, report] = check_complete_rescheduling_candidate( ...
    problem, candidateWithMachineConflict, constraints, cancel);
assert(~isFeasible, 'Machine conflict should be rejected.');
assert(~report.machineConflictCheck.isFeasible, ...
    'Machine conflict check should fail.');

candidateWithAgvConflict = make_candidate();
candidateWithAgvConflict.AGVTable{1}(2).start = 2;
[isFeasible, report] = check_complete_rescheduling_candidate( ...
    problem, candidateWithAgvConflict, constraints, cancel);
assert(~isFeasible, 'AGV conflict should be rejected.');
assert(~report.agvConflictCheck.isFeasible, ...
    'AGV conflict check should fail.');

candidateWithSequenceError = make_candidate();
candidateWithSequenceError.machineTable{1}(2).start = 2;
candidateWithSequenceError.machineTable{1}(2).end = 3;
[isFeasible, report] = check_complete_rescheduling_candidate( ...
    problem, candidateWithSequenceError, constraints, cancel);
assert(~isFeasible, 'Job sequence error should be rejected.');
assert(~report.jobSequenceCheck.isFeasible, ...
    'Job sequence check should fail.');

candidateWithChangedFrozen = make_candidate();
candidateWithChangedFrozen.machineTable{1}(1).end = 5;
[isFeasible, report] = check_complete_rescheduling_candidate( ...
    problem, candidateWithChangedFrozen, constraints, cancel);
assert(~isFeasible, 'Changed frozen task should be rejected.');
assert(~report.frozenConsistencyCheck.isFeasible, ...
    'Frozen consistency check should fail.');

candidateWithCancelledLeak = make_candidate();
candidateWithCancelledLeak.machineTable{2}(end + 1) = ...
    make_machine_block(18, 21, 2, 2);
[isFeasible, report] = check_complete_rescheduling_candidate( ...
    problem, candidateWithCancelledLeak, constraints, cancel);
assert(~isFeasible, 'Cancelled task leakage should be rejected.');
assert(~report.cancelledTaskExclusionCheck.isFeasible, ...
    'Cancelled task exclusion check should fail.');

fprintf('test_order_cancellation_complete_rescheduling_feasibility passed\n');

function problem = make_problem()
problem = struct();
problem.jobNum = 3;
problem.operaNumVec = [2, 2, 2];
end

function constraints = make_constraints(cancel)
constraints = struct();
constraints.cancel = cancel;
constraints.frozen_machine_occupancy = [
    make_machine_occupancy(1, 1, 1, 0, 4)
    make_machine_occupancy(2, 2, 1, 3, 8)
];
constraints.frozen_agv_occupancy = [
    make_agv_occupancy(1, 1, 1, 0, 3)
    make_agv_occupancy(2, 2, 1, 4, 8)
];
end

function candidate = make_candidate()
candidate = struct();
candidate.machineTable = cell(1, 2);
candidate.machineTable{1} = [
    make_machine_block(0, 4, 1, 1)
    make_machine_block(10, 14, 1, 2)
    make_machine_block(14, inf, 0, 0)
];
candidate.machineTable{2} = [
    make_machine_block(3, 8, 2, 1)
    make_machine_block(12, 16, 3, 2)
    make_machine_block(16, inf, 0, 0)
];

candidate.AGVTable = cell(1, 2);
candidate.AGVTable{1} = [
    make_agv_block(0, 3, 1, 1)
    make_agv_block(10, 12, 1, 2)
    make_agv_block(12, inf, 0, 0)
];
candidate.AGVTable{2} = [
    make_agv_block(4, 8, 2, 1)
    make_agv_block(12, 15, 3, 2)
    make_agv_block(15, inf, 0, 0)
];

candidate.excluded_operations = make_excluded_operation(2, 2);
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

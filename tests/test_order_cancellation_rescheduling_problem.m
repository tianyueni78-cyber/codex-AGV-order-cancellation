clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));

problem = make_problem();
machineData = make_machine_data();
agvData = make_agv_data();
schedule = make_schedule();
cancel = create_order_cancellation_event(2, 10);
state = extract_cancellation_state(problem, schedule, cancel);
remainingSet = build_remaining_operation_set(state, cancel);

originalProblem = problem;
reschedulingProblem = build_rescheduling_problem( ...
    problem, machineData, agvData, remainingSet, cancel);
tempProblem = reschedulingProblem.problem;

assert(reschedulingProblem.isFeasible, ...
    strjoin(reschedulingProblem.report.errors, newline));
assert(isequaln(problem, originalProblem), ...
    'Original problem must not be modified.');
assert(isequaln(reschedulingProblem.machineData, machineData), ...
    'machineData should be preserved.');
assert(isequaln(reschedulingProblem.agvData, agvData), ...
    'agvData should be preserved.');

assert(tempProblem.jobNum == 2, ...
    'Temporary problem should contain two remaining jobs.');
assert(tempProblem.machineNum == problem.machineNum, ...
    'Temporary problem should preserve machineNum.');
assert(isequal(tempProblem.operaNumVec, [1, 1]), ...
    'Temporary operaNumVec should contain only remaining operations.');
assert(isequal(tempProblem.original_job_ids, [1, 3]), ...
    'Temporary problem should exclude cancelled job id.');
assert(~any([reschedulingProblem.operation_map.original_job_id] == ...
    cancel.job_id), ...
    'Cancelled job must not enter operation_map.');
assert(isequal(sort(operation_keys(reschedulingProblem.excluded_operations)), ...
    202), ...
    'Cancelled unfinished operation should be recorded as excluded.');

assert(has_independent_problem_fields(tempProblem), ...
    'Temporary problem should expose fields required by independent decoder.');
assert(isequal(tempProblem.candidateMachine{1, 1}, ...
    problem.candidateMachine{1, 2}), ...
    'Candidate machines should be copied for remaining job 1 operation 2.');
assert(isequal(tempProblem.jobInfo{1}(1, :), problem.jobInfo{1}(2, :)), ...
    'Processing times should be copied for remaining job 1 operation 2.');
assert(isequal(tempProblem.candidateMachine{2, 1}, ...
    problem.candidateMachine{3, 2}), ...
    'Candidate machines should be copied for remaining job 3 operation 2.');

remainingSetWithCancelLeak = remainingSet;
remainingSetWithCancelLeak.isFeasible = false;
remainingSetWithCancelLeak.report.errors = {'leak'};
reschedulingProblem = build_rescheduling_problem( ...
    problem, machineData, agvData, remainingSetWithCancelLeak, cancel);
assert(~reschedulingProblem.isFeasible, ...
    'Infeasible remaining set should reject rescheduling problem.');

mismatchedCancel = create_order_cancellation_event(1, 10);
didFail = false;
try
    build_rescheduling_problem( ...
        problem, machineData, agvData, remainingSet, mismatchedCancel);
catch
    didFail = true;
end
assert(didFail, 'Mismatched cancel input should be rejected.');

fprintf('test_order_cancellation_rescheduling_problem passed\n');

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
machineData.distance_matrix.load_to_machine = [1, 2, 3];
machineData.distance_matrix.machine_to_unload = [3, 2, 1];
machineData.distance_matrix.machine_to_machine = eye(3);
machineData.machineEnergy.process = [1, 1, 1];
end

function agvData = make_agv_data()
agvData = struct();
agvData.AGVNum = 2;
agvData.AGVSpeed = [1, 2];
agvData.AGVEnergy.free = [1, 1.2];
agvData.AGVEnergy.load = [1.5, 1.8];
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

function hasFields = has_independent_problem_fields(problem)
requiredFields = {'jobNum', 'machineNum', 'operaNumVec', ...
    'candidateMachine', 'jobInfo'};
hasFields = true;
for i = 1:numel(requiredFields)
    hasFields = hasFields && isfield(problem, requiredFields{i});
end
end


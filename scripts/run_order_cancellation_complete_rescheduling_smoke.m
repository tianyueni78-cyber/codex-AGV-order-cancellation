clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));

problem = read_fjsp(fullfile(projectRoot, 'data_sample', 'Mk01.fjs'));
machineData = build_sample_machine_data(problem.machineNum);
agvData = build_sample_agv_data();
schedule = build_sample_schedule(problem.machineNum);

cancelJobId = min(2, problem.jobNum);
cancelTime = 10;
cancel = create_order_cancellation_event(cancelJobId, cancelTime);

state = extract_cancellation_state(problem, schedule, cancel);
remainingSet = build_remaining_operation_set(state, cancel);
chrom = build_first_choice_chromosome(remainingSet, problem, agvData);
config = build_decode_config();

candidate = build_complete_rescheduling_candidate( ...
    problem, machineData, agvData, schedule, state, cancel, chrom, config);

fprintf('order cancellation complete rescheduling smoke\n');
fprintf('dataset: data_sample/Mk01.fjs\n');
fprintf('cancel.job_id: %d\n', cancel.job_id);
fprintf('cancel.cancel_time: %.6f\n', cancel.cancel_time);
fprintf('cancel.policy: %s\n', cancel.policy);
fprintf('completed_operations: %d\n', numel(state.completed_operations));
fprintf('completed_agv_tasks: %d\n', numel(state.completed_agv_tasks));
fprintf('cancelled_unfinished_operations: %d\n', ...
    numel(state.cancelled_unfinished_operations));
fprintf('cancelled_unfinished_agv_tasks: %d\n', ...
    numel(state.cancelled_unfinished_agv_tasks));
fprintf('remaining_unfinished_operations: %d\n', ...
    numel(state.remaining_unfinished_operations));
fprintf('unsupported_operations: %d\n', numel(state.unsupported_operations));
fprintf('unsupported_agv_tasks: %d\n', numel(state.unsupported_agv_tasks));
fprintf('frozen_operations: %d\n', numel(candidate.frozen_operations));
fprintf('frozen_agv_tasks: %d\n', numel(candidate.frozen_agv_tasks));
fprintf('excluded_operations: %d\n', numel(candidate.excluded_operations));
fprintf('rescheduled_operations: %d\n', ...
    numel(candidate.rescheduled_operations));
fprintf('candidate.isFeasible: %d\n', candidate.isFeasible);

if isfield(candidate.report, 'completeFeasibilityCheck')
    check = candidate.report.completeFeasibilityCheck;
    fprintf('machineConflictCheck.isFeasible: %d\n', ...
        check.machineConflictCheck.isFeasible);
    fprintf('agvConflictCheck.isFeasible: %d\n', ...
        check.agvConflictCheck.isFeasible);
    fprintf('jobSequenceCheck.isFeasible: %d\n', ...
        check.jobSequenceCheck.isFeasible);
    fprintf('frozenConsistencyCheck.isFeasible: %d\n', ...
        check.frozenConsistencyCheck.isFeasible);
    fprintf('cancelledTaskExclusionCheck.isFeasible: %d\n', ...
        check.cancelledTaskExclusionCheck.isFeasible);
end

fprintf('error_count: %d\n', numel(candidate.report.errors));
fprintf('rejected_reason_count: %d\n', ...
    numel(candidate.report.rejectedReasons));

function schedule = build_sample_schedule(machineNum)
schedule = struct();
schedule.machineTable = build_sample_machine_table(machineNum);
schedule.AGVTable = build_sample_agv_table();
end

function machineTable = build_sample_machine_table(machineNum)
machineTable = cell(1, machineNum);

for machineIdx = 1:machineNum
    machineTable{machineIdx} = make_machine_block(0, inf, 0, 0);
end

machineTable{1} = [
    make_machine_block(0, 4, 1, 1)
    make_machine_block(10, 14, 1, 2)
    make_machine_block(14, inf, 0, 0)
];

machineTable{2} = [
    make_machine_block(0, 3, 3, 1)
    make_machine_block(3, 8, 2, 1)
    make_machine_block(12, 15, 2, 2)
    make_machine_block(15, inf, 0, 0)
];

if machineNum >= 3
    machineTable{3} = [
        make_machine_block(14, 18, 3, 2)
        make_machine_block(18, inf, 0, 0)
    ];
end
end

function AGVTable = build_sample_agv_table()
AGVTable = cell(1, 2);

AGVTable{1} = [
    make_agv_block(0, 4, 1, 1, -1, 1, -2)
    make_agv_block(4, 8, 2, 1, -1, 2, -2)
    make_agv_block(12, 16, 2, 2, 2, -2, -2)
    make_agv_block(16, inf, 0, 0, -2, -2, 0)
];

AGVTable{2} = [
    make_agv_block(0, 3, 3, 1, -1, 2, -2)
    make_agv_block(10, 13, 3, 2, 2, -2, -2)
    make_agv_block(13, inf, 0, 0, -2, -2, 0)
];
end

function machineData = build_sample_machine_data(machineNum)
machineData = struct();
machineData.distance_matrix = struct();
machineData.distance_matrix.machine_to_machine = zeros(machineNum, machineNum);
for i = 1:machineNum
    for j = 1:machineNum
        machineData.distance_matrix.machine_to_machine(i, j) = abs(i - j);
    end
end
machineData.distance_matrix.load_to_machine = 1:machineNum;
machineData.distance_matrix.machine_to_unload = machineNum:-1:1;
machineData.distance_matrix.load_to_unload = 1;
end

function agvData = build_sample_agv_data()
agvData = struct();
agvData.AGVNum = 2;
agvData.AGVSpeed = [1.0, 1.5, 2.0];
agvData.AGVEnergy.free = [1.0, 1.2, 1.4];
agvData.AGVEnergy.load = [1.4, 1.6, 1.8];
end

function config = build_decode_config()
config = struct();
config.AGVEG_MAX = 100;
config.AGVEG_MIN = 1;
config.eChargeSpeed = 20;
config.machineTable = {};
config.AGVTable = {};
end

function chrom = build_first_choice_chromosome(remainingSet, problem, agvData)
operations = remainingSet.operations;
[~, order] = sortrows([[operations.job_id]', [operations.operation_id]']);
operations = operations(order);

originalJobIds = unique([operations.job_id], 'stable');
tempJobIds = zeros(1, numel(operations));
for i = 1:numel(operations)
    tempJobIds(i) = find(originalJobIds == operations(i).job_id, 1);
end

operaNum = numel(operations);
OS = tempJobIds;
MS = ones(1, operaNum);
AS = mod(0:(operaNum - 1), agvData.AGVNum) + 1;
SS = ones(1, operaNum * 2);
if numel(agvData.AGVSpeed) >= 2
    SS(2:2:end) = 2;
end

for i = 1:operaNum
    candidateMachines = problem.candidateMachine{ ...
        operations(i).job_id, operations(i).operation_id};
    if isempty(candidateMachines)
        error('complete_rescheduling_smoke:MissingCandidateMachine', ...
            'Remaining operation has no candidate machine.');
    end
    MS(i) = 1;
end

chrom = [OS, MS, AS, SS];
end

function block = make_machine_block(startTime, endTime, jobId, operationId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
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

clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'cancellation'));

problem = read_fjsp(fullfile(projectRoot, 'data_sample', 'Mk01.fjs'));
schedule = build_sample_schedule();

cancelJobId = min(2, problem.jobNum);
cancelTime = 10;
cancel = create_order_cancellation_event(cancelJobId, cancelTime);

state = extract_cancellation_state(problem, schedule, cancel);
candidate = build_local_repair_candidate(problem, schedule, state, cancel);

fprintf('order cancellation local repair smoke\n');
fprintf('dataset: data_sample/Mk01.fjs\n');
fprintf('cancel.job_id: %d\n', cancel.job_id);
fprintf('cancel.cancel_time: %.6f\n', cancel.cancel_time);
fprintf('cancel.policy: %s\n', cancel.policy);
fprintf('cancelled_unfinished_operations: %d\n', ...
    numel(state.cancelled_unfinished_operations));
fprintf('cancelled_unfinished_agv_tasks: %d\n', ...
    numel(state.cancelled_unfinished_agv_tasks));
fprintf('unsupported_operations: %d\n', ...
    numel(state.unsupported_operations));
fprintf('unsupported_agv_tasks: %d\n', ...
    numel(state.unsupported_agv_tasks));
fprintf('removed_operations: %d\n', ...
    numel(candidate.removed_operations));
fprintf('removed_agv_tasks: %d\n', ...
    numel(candidate.removed_agv_tasks));
fprintf('candidate.isFeasible: %d\n', candidate.isFeasible);
fprintf('machineConflictCheck.isFeasible: %d\n', ...
    candidate.report.machineConflictCheck.isFeasible);
fprintf('agvConflictCheck.isFeasible: %d\n', ...
    candidate.report.agvConflictCheck.isFeasible);
fprintf('jobSequenceCheck.isFeasible: %d\n', ...
    candidate.report.jobSequenceCheck.isFeasible);
fprintf('error_count: %d\n', numel(candidate.report.errors));
fprintf('rejected_reason_count: %d\n', ...
    numel(candidate.report.rejectedReasons));

function schedule = build_sample_schedule()
schedule = struct();
schedule.machineTable = build_sample_machine_table();
schedule.AGVTable = build_sample_agv_table();
end

function machineTable = build_sample_machine_table()
machineTable = cell(1, 3);

machineTable{1} = [
    make_machine_block(0, 6, 1, 1)
    make_machine_block(6, 12, 1, 2)
    make_machine_block(12, inf, 0, 0)
];

machineTable{2} = [
    make_machine_block(0, 3, 3, 1)
    make_machine_block(3, 8, 2, 1)
    make_machine_block(12, 15, 2, 2)
    make_machine_block(15, inf, 0, 0)
];

machineTable{3} = [
    make_machine_block(8, 11, 3, 2)
    make_machine_block(11, inf, 0, 0)
];
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
    make_agv_block(8, 11, 3, 2, 2, -2, -2)
    make_agv_block(11, inf, 0, 0, -2, -2, 0)
];
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

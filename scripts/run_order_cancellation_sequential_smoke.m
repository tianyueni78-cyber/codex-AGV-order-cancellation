clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

problem = read_fjsp(fullfile(projectRoot, 'data_sample', 'Mk01.fjs'));
machineData = build_sample_machine_data(problem.machineNum);
agvData = build_sample_agv_data();
initialSchedule = build_sample_schedule(problem.machineNum);
config = build_local_stable_config();

cancelEvents = [
    make_event(1, 2, 10)
    make_event(2, 3, 14)
];

result = run_sequential_order_cancellations( ...
    problem, machineData, agvData, initialSchedule, cancelEvents, config);

fprintf('order cancellation sequential smoke\n');
fprintf('dataset: data_sample/Mk01.fjs\n');
fprintf('event_count: %d\n', numel(cancelEvents));
fprintf('completed_event_count: %d\n', result.completed_event_count);
fprintf('result.isFeasible: %d\n', result.isFeasible);
fprintf('cancelledJobSet: %s\n', format_numeric_vector(result.cancelledJobSet));
fprintf('unsupported_event_count: %d\n', ...
    numel(result.report.unsupported_events));

for i = 1:numel(result.event_results)
    eventResult = result.event_results(i);
    fprintf('event_%d.event_id: %d\n', i, eventResult.event_id);
    fprintf('event_%d.job_id: %d\n', i, eventResult.job_id);
    fprintf('event_%d.cancel_time: %.6f\n', i, eventResult.cancel_time);
    fprintf('event_%d.policy: %s\n', i, eventResult.policy);
    fprintf('event_%d.local_candidate.isFeasible: %d\n', i, ...
        eventResult.local_candidate_isFeasible);
    fprintf('event_%d.complete_candidate.isFeasible: %d\n', i, ...
        eventResult.complete_candidate_isFeasible);
    fprintf('event_%d.decision.isSelected: %d\n', i, ...
        eventResult.decision_isSelected);
    fprintf('event_%d.selected_strategy: %s\n', i, ...
        eventResult.selected_strategy);
    fprintf('event_%d.decision.reason: %s\n', i, ...
        eventResult.decision_reason);
    fprintf('event_%d.triggered_complete_rescheduling: %d\n', i, ...
        eventResult.triggered_complete_rescheduling);
    fprintf('event_%d.isUnsupported: %d\n', i, ...
        eventResult.isUnsupported);
    fprintf('event_%d.unsupported_reason: %s\n', i, ...
        eventResult.unsupported_reason);
    fprintf('event_%d.cancelled_job_backflow_detected: %d\n', i, ...
        eventResult.cancelled_job_backflow_detected);
    fprintf('event_%d.local_machine_check.isFeasible: %d\n', i, ...
        eventResult.local_machine_check_isFeasible);
    fprintf('event_%d.local_agv_check.isFeasible: %d\n', i, ...
        eventResult.local_agv_check_isFeasible);
    fprintf('event_%d.local_job_sequence_check.isFeasible: %d\n', i, ...
        eventResult.local_job_sequence_check_isFeasible);
    fprintf('event_%d.complete_machine_check.isFeasible: %d\n', i, ...
        eventResult.complete_machine_check_isFeasible);
    fprintf('event_%d.complete_agv_check.isFeasible: %d\n', i, ...
        eventResult.complete_agv_check_isFeasible);
    fprintf('event_%d.complete_job_sequence_check.isFeasible: %d\n', i, ...
        eventResult.complete_job_sequence_check_isFeasible);
    fprintf('event_%d.complete_frozen_consistency.isFeasible: %d\n', i, ...
        eventResult.complete_frozen_consistency_isFeasible);
    fprintf('event_%d.complete_cancelled_task_exclusion.isFeasible: %d\n', ...
        i, eventResult.complete_cancelled_task_exclusion_isFeasible);
    fprintf('event_%d.selected_machine_check.isFeasible: %d\n', i, ...
        eventResult.selected_machine_check_isFeasible);
    fprintf('event_%d.selected_agv_check.isFeasible: %d\n', i, ...
        eventResult.selected_agv_check_isFeasible);
    fprintf('event_%d.selected_job_sequence_check.isFeasible: %d\n', i, ...
        eventResult.selected_job_sequence_check_isFeasible);
    fprintf('event_%d.selected_constraint_check.isFeasible: %d\n', i, ...
        eventResult.selected_constraint_check_isFeasible);
end

function event = make_event(eventId, jobId, cancelTime)
event = struct();
event.event_id = eventId;
event.job_id = jobId;
event.cancel_time = cancelTime;
event.policy = 'cancel_unstarted_operations_only';
end

function config = build_local_stable_config()
config = struct();
config.hybrid_policy = struct();
config.hybrid_policy.enable_complete_if_local_infeasible = true;
config.hybrid_policy.use_stage_e_y_selection = false;
config.hybrid_policy.cmax_delta_threshold = Inf;
config.hybrid_policy.energy_delta_threshold = Inf;
config.hybrid_policy.idle_waste_threshold = Inf;
config.hybrid_policy.threshold_validation_status = ...
    'pending_stage_l_validation';
config.sequential_cancellation = struct();
config.sequential_cancellation.stop_on_unsupported = true;
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
machineData.machineEnergy = struct();
machineData.machineEnergy.work = ones(1, machineNum) * 2;
machineData.machineEnergy.free = ones(1, machineNum);
end

function agvData = build_sample_agv_data()
agvData = struct();
agvData.AGVNum = 2;
agvData.AGVSpeed = [1.0, 1.5, 2.0];
agvData.AGVEnergy.free = [1.0, 1.2, 1.4];
agvData.AGVEnergy.load = [1.4, 1.6, 1.8];
end

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
    make_agv_block(10, 12, 1, 2, 1, 1, -2)
    make_agv_block(12, 16, 2, 2, 2, -2, -2)
    make_agv_block(16, inf, 0, 0, -2, -2, 0)
];

AGVTable{2} = [
    make_agv_block(0, 3, 3, 1, -1, 2, -2)
    make_agv_block(4, 8, 2, 1, -1, 2, -2)
    make_agv_block(10, 13, 3, 2, 2, -2, -2)
    make_agv_block(13, inf, 0, 0, -2, -2, 0)
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

function value = format_numeric_vector(values)
if isempty(values)
    value = '[]';
else
    parts = arrayfun(@(x) sprintf('%g', x), values, ...
        'UniformOutput', false);
    value = ['[', strjoin(parts, ', '), ']'];
end
end

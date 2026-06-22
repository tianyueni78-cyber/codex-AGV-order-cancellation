clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

datasetPath = fullfile(projectRoot, 'data_sample', 'Mk01.fjs');
problem = read_fjsp(datasetPath);
machineData = build_sample_machine_data(problem.machineNum);
agvData = build_sample_agv_data();
baselineSchedule = build_sample_schedule(problem.machineNum);

cancelJobId = min(2, problem.jobNum);
cancelTime = 10;
cancel = create_order_cancellation_event(cancelJobId, cancelTime);

state = extract_cancellation_state(problem, baselineSchedule, cancel);
localCandidate = build_local_repair_candidate( ...
    problem, baselineSchedule, state, cancel);

remainingSet = build_remaining_operation_set(state, cancel);
chrom = build_first_choice_chromosome(remainingSet, problem, agvData);
decodeConfig = build_decode_config();
completeCandidate = build_complete_rescheduling_candidate( ...
    problem, machineData, agvData, baselineSchedule, state, cancel, ...
    chrom, decodeConfig);

wideConfig = build_wide_evaluation_config();
[localPreEvaluation, completePreEvaluation] = evaluate_candidates( ...
    baselineSchedule, localCandidate, completeCandidate, cancel, ...
    machineData, agvData, wideConfig);
baseConfig = build_minmax_evaluation_config( ...
    localPreEvaluation, completePreEvaluation, wideConfig);
baseConfig.adaptive.remaining_operation_count_high = 3;

[fixedLocalEvaluation, fixedCompleteEvaluation] = evaluate_candidates( ...
    baselineSchedule, localCandidate, completeCandidate, cancel, ...
    machineData, agvData, baseConfig);
fixedSelection = select_order_cancellation_strategy( ...
    fixedLocalEvaluation, fixedCompleteEvaluation);

adaptiveResult = select_adaptive_cancellation_strategy( ...
    baselineSchedule, state, cancel, localCandidate, completeCandidate, ...
    machineData, agvData, baseConfig);

fprintf('order cancellation adaptive strategy smoke\n');
fprintf('dataset: data_sample/Mk01.fjs\n');
fprintf('cancel.job_id: %d\n', cancel.job_id);
fprintf('cancel.cancel_time: %.6f\n', cancel.cancel_time);
fprintf('cancel.policy: %s\n', cancel.policy);
fprintf('local_candidate.isFeasible: %d\n', localCandidate.isFeasible);
fprintf('complete_candidate.isFeasible: %d\n', completeCandidate.isFeasible);
print_features(adaptiveResult.features);
print_weights('fixed_weights', baseConfig.weights);
print_weights('adaptive_weights', adaptiveResult.weights);
print_applied_rules(adaptiveResult.adaptive_report);
print_selection('fixed_selection', fixedSelection);
print_selection('adaptive_selection', adaptiveResult.selection);
fprintf('adaptive_report.reason: %s\n', adaptiveResult.adaptive_report.reason);
fprintf('adaptive_report.isAdaptive: %d\n', ...
    adaptiveResult.adaptive_report.isAdaptive);

function [localEvaluation, completeEvaluation] = evaluate_candidates( ...
    baselineSchedule, localCandidate, completeCandidate, cancel, ...
    machineData, agvData, config)
localEvaluation = evaluate_order_cancellation_candidate( ...
    baselineSchedule, localCandidate, cancel, machineData, agvData, ...
    config, 'local_repair');
completeEvaluation = evaluate_order_cancellation_candidate( ...
    baselineSchedule, completeCandidate, cancel, machineData, agvData, ...
    config, 'complete_rescheduling');
end

function print_features(features)
fprintf('features.cancel_time_ratio: %.6f\n', features.cancel_time_ratio);
fprintf('features.remaining_operation_count: %d\n', ...
    features.remaining_operation_count);
fprintf('features.cancelled_operation_count: %d\n', ...
    features.cancelled_operation_count);
fprintf('features.frozen_operation_ratio: %.6f\n', ...
    features.frozen_operation_ratio);
fprintf('features.remaining_agv_task_count: %d\n', ...
    features.remaining_agv_task_count);
fprintf('features.cancelled_agv_task_count: %d\n', ...
    features.cancelled_agv_task_count);
fprintf('features.local_repair_feasible: %d\n', ...
    features.local_repair_feasible);
fprintf('features.complete_rescheduling_feasible: %d\n', ...
    features.complete_rescheduling_feasible);
fprintf('features.unsupported_flag: %d\n', features.unsupported_flag);
end

function print_weights(label, weights)
fprintf('%s.Cmax_delta: %.6f\n', label, weights.Cmax_delta);
fprintf('%s.SD: %.6f\n', label, weights.SD);
fprintf('%s.TD: %.6f\n', label, weights.TD);
fprintf('%s.energy_delta: %.6f\n', label, weights.energy_delta);
end

function print_applied_rules(report)
fprintf('adaptive_report.applied_rule_count: %d\n', ...
    numel(report.applied_rules));
for i = 1:numel(report.applied_rules)
    fprintf('adaptive_report.applied_rule_%d: %s\n', ...
        i, report.applied_rules{i});
end
end

function print_selection(label, selection)
fprintf('%s.isSelected: %d\n', label, selection.isSelected);
fprintf('%s.name: %s\n', label, selection.name);
fprintf('%s.reason: %s\n', label, selection.reason);
fprintf('%s.Y: %.6f\n', label, value_or_nan(selection, 'selectedY'));
end

function value = value_or_nan(s, fieldName)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = NaN;
end
end

function config = build_wide_evaluation_config()
config = struct();
config.weights = struct();
config.weights.Cmax_delta = 0.25;
config.weights.SD = 0.25;
config.weights.TD = 0.25;
config.weights.energy_delta = 0.25;
config.normalization = struct();
config.normalization.Cmax_delta = make_bounds(-100, 100);
config.normalization.SD = make_bounds(0, 100);
config.normalization.TD = make_bounds(0, 100);
config.normalization.energy_delta = make_bounds(-1000, 1000);
end

function config = build_minmax_evaluation_config( ...
    localEvaluation, completeEvaluation, fallbackConfig)
config = fallbackConfig;
if ~localEvaluation.metrics.isFeasible || ...
        ~completeEvaluation.metrics.isFeasible
    return
end

metricNames = {'Cmax_delta', 'SD', 'TD', 'energy_delta'};
for i = 1:numel(metricNames)
    metricName = metricNames{i};
    localValue = localEvaluation.metrics.(metricName);
    completeValue = completeEvaluation.metrics.(metricName);
    config.normalization.(metricName) = make_bounds( ...
        min(localValue, completeValue), max(localValue, completeValue));
end
end

function bounds = make_bounds(minValue, maxValue)
bounds = struct();
bounds.min = minValue;
bounds.max = maxValue;
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

function config = build_decode_config()
config = struct();
config.AGVEG_MAX = 100;
config.AGVEG_MIN = 1;
config.eChargeSpeed = 20;
config.machineTable = {};
config.AGVTable = {};
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
        error('adaptive_strategy_smoke:MissingCandidateMachine', ...
            'Remaining operation has no candidate machine.');
    end
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

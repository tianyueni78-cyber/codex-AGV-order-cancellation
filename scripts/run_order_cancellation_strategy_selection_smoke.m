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
config = build_minmax_evaluation_config( ...
    localPreEvaluation, completePreEvaluation, wideConfig);

[localEvaluation, completeEvaluation] = evaluate_candidates( ...
    baselineSchedule, localCandidate, completeCandidate, cancel, ...
    machineData, agvData, config);

selection = select_order_cancellation_strategy( ...
    localEvaluation, completeEvaluation);

outputDir = create_output_dir(projectRoot);
write_summary_json(outputDir, datasetPath, cancel, config, state, ...
    localCandidate, completeCandidate, localEvaluation, completeEvaluation, ...
    selection);
write_metrics_csv(outputDir, localEvaluation, completeEvaluation);
write_selected_strategy(outputDir, selection);

fprintf('order cancellation strategy selection smoke\n');
fprintf('dataset: data_sample/Mk01.fjs\n');
fprintf('cancel.job_id: %d\n', cancel.job_id);
fprintf('cancel.cancel_time: %.6f\n', cancel.cancel_time);
fprintf('cancel.policy: %s\n', cancel.policy);
fprintf('completed_operations: %d\n', numel(state.completed_operations));
fprintf('cancelled_unfinished_operations: %d\n', ...
    numel(state.cancelled_unfinished_operations));
fprintf('remaining_unfinished_operations: %d\n', ...
    numel(state.remaining_unfinished_operations));
fprintf('local_candidate.isFeasible: %d\n', localCandidate.isFeasible);
fprintf('complete_candidate.isFeasible: %d\n', completeCandidate.isFeasible);
print_evaluation('local_repair', localEvaluation);
print_evaluation('complete_rescheduling', completeEvaluation);
fprintf('selected.isSelected: %d\n', selection.isSelected);
fprintf('selected.name: %s\n', selection.name);
fprintf('selected.reason: %s\n', selection.reason);
fprintf('selected.Y: %.6f\n', value_or_nan(selection, 'selectedY'));
fprintf('output_dir: %s\n', outputDir);
fprintf('summary_json: %s\n', fullfile(outputDir, 'summary.json'));
fprintf('metrics_csv: %s\n', fullfile(outputDir, 'metrics.csv'));
fprintf('selected_strategy_txt: %s\n', ...
    fullfile(outputDir, 'selected_strategy.txt'));

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

function outputDir = create_output_dir(projectRoot)
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
outputDir = fullfile(projectRoot, 'outputs', ...
    'order_cancellation_strategy_selection', timestamp);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end
end

function write_summary_json(outputDir, datasetPath, cancel, config, state, ...
    localCandidate, completeCandidate, localEvaluation, ...
    completeEvaluation, selection)
summary = struct();
summary.smoke_name = 'order_cancellation_strategy_selection';
summary.dataset = relative_dataset_name(datasetPath);
summary.cancel = cancel;
summary.weights = config.weights;
summary.normalization = config.normalization;
summary.stateCounts = struct();
summary.stateCounts.completed_operations = numel(state.completed_operations);
summary.stateCounts.completed_agv_tasks = numel(state.completed_agv_tasks);
summary.stateCounts.cancelled_unfinished_operations = ...
    numel(state.cancelled_unfinished_operations);
summary.stateCounts.cancelled_unfinished_agv_tasks = ...
    numel(state.cancelled_unfinished_agv_tasks);
summary.stateCounts.remaining_unfinished_operations = ...
    numel(state.remaining_unfinished_operations);
summary.localCandidateFeasible = localCandidate.isFeasible;
summary.completeCandidateFeasible = completeCandidate.isFeasible;
summary.localRepair = summarize_evaluation(localEvaluation);
summary.completeRescheduling = summarize_evaluation(completeEvaluation);
summary.selectedStrategy = selection;
summary.scope = struct();
summary.scope.multiseed = false;
summary.scope.formal_experiment = false;
summary.scope.nsga2_search = false;
summary.scope.research_conclusion = false;

write_text(fullfile(outputDir, 'summary.json'), jsonencode(summary));
end

function name = relative_dataset_name(datasetPath)
[~, fileName, ext] = fileparts(datasetPath);
name = fullfile('data_sample', [fileName, ext]);
end

function write_metrics_csv(outputDir, localEvaluation, completeEvaluation)
filePath = fullfile(outputDir, 'metrics.csv');
fid = fopen(filePath, 'w');
if fid < 0
    error('strategy_selection_smoke:FileOpenFailed', ...
        'Cannot open metrics.csv for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, ['strategy,isFeasible,Cmax,Cmax_delta,SD,TD,energy,', ...
    'energy_delta,Y\n']);
write_metric_row(fid, localEvaluation);
write_metric_row(fid, completeEvaluation);
end

function write_metric_row(fid, evaluation)
fprintf(fid, '%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n', ...
    evaluation.strategyName, evaluation.metrics.isFeasible, ...
    value_or_nan(evaluation.metrics, 'Cmax'), ...
    value_or_nan(evaluation.metrics, 'Cmax_delta'), ...
    value_or_nan(evaluation.metrics, 'SD'), ...
    value_or_nan(evaluation.metrics, 'TD'), ...
    value_or_nan(evaluation.metrics, 'energy'), ...
    value_or_nan(evaluation.metrics, 'energy_delta'), ...
    value_or_nan(evaluation.metrics, 'Y'));
end

function write_selected_strategy(outputDir, selection)
lines = {
    sprintf('isSelected: %d', selection.isSelected)
    sprintf('name: %s', selection.name)
    sprintf('reason: %s', selection.reason)
    sprintf('selectedY: %.6f', value_or_nan(selection, 'selectedY'))
};
write_text(fullfile(outputDir, 'selected_strategy.txt'), ...
    strjoin(lines, newline));
end

function write_text(filePath, text)
fid = fopen(filePath, 'w');
if fid < 0
    error('strategy_selection_smoke:FileOpenFailed', ...
        'Cannot open file for writing: %s', filePath);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', text);
end

function summary = summarize_evaluation(evaluation)
summary = struct();
summary.strategyName = evaluation.strategyName;
summary.metrics = evaluation.metrics;
summary.rejectedReasons = evaluation.report.rejectedReasons;
summary.errors = evaluation.report.errors;
summary.warnings = evaluation.report.warnings;
summary.errorCount = numel(evaluation.report.errors);
summary.warningCount = numel(evaluation.report.warnings);
end

function print_evaluation(label, evaluation)
fprintf('%s.isFeasible: %d\n', label, evaluation.metrics.isFeasible);
fprintf('%s.Cmax_delta: %.6f\n', label, ...
    value_or_nan(evaluation.metrics, 'Cmax_delta'));
fprintf('%s.SD: %.6f\n', label, value_or_nan(evaluation.metrics, 'SD'));
fprintf('%s.TD: %.6f\n', label, value_or_nan(evaluation.metrics, 'TD'));
fprintf('%s.energy: %.6f\n', label, ...
    value_or_nan(evaluation.metrics, 'energy'));
fprintf('%s.energy_delta: %.6f\n', label, ...
    value_or_nan(evaluation.metrics, 'energy_delta'));
fprintf('%s.Y: %.6f\n', label, value_or_nan(evaluation.metrics, 'Y'));
print_report_messages(label, 'error', evaluation.report.errors);
print_report_messages(label, 'warning', evaluation.report.warnings);
end

function print_report_messages(label, messageType, messages)
for i = 1:numel(messages)
    fprintf('%s.%s_%d: %s\n', label, messageType, i, messages{i});
end
end

function value = value_or_nan(s, fieldName)
if isfield(s, fieldName) && ~isempty(s.(fieldName))
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
        error('strategy_selection_smoke:MissingCandidateMachine', ...
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

function result = run_sequential_order_cancellations( ...
    problem, machineData, agvData, initialSchedule, cancelEvents, config)
%RUN_SEQUENTIAL_ORDER_CANCELLATIONS Run sequential order cancellations.
%   The stage-I driver replays multiple cancellation events in time order.
%   Each event runs the existing stage B-H pipeline, then the selected
%   candidate becomes the baseline schedule for the next event. This
%   function does not read files, write outputs, or run population search.

if nargin < 5
    error('run_sequential_order_cancellations:MissingInput', ...
        ['problem, machineData, agvData, initialSchedule, and ', ...
        'cancelEvents are required.']);
end
if nargin < 6 || isempty(config)
    config = struct();
end

[isEventsValid, sortedEvents, validationReport] = ...
    validate_sequential_cancellation_events(cancelEvents, problem);

result = empty_result(initialSchedule, sortedEvents, validationReport);
if ~isEventsValid
    result.report.errors = validationReport.errors;
    result.report.unsupported_events = validationReport.unsupported_events;
    return
end

currentSchedule = initialSchedule;
cancelledJobSet = [];
cancelledRecords = sortedEvents([]);
eventResults = event_result_template([]);

for i = 1:numel(sortedEvents)
    event = sortedEvents(i);
    if any(cancelledJobSet == event.job_id)
        eventResult = rejected_event_result(event, ...
            'duplicate_job_cancellation');
        eventResults(end + 1) = eventResult;
        result.report.errors{end + 1} = sprintf( ...
            'Event %g repeats cancelled job_id %g.', ...
            event.event_id, event.job_id);
        break
    end

    [eventResult, currentSchedule] = run_one_event( ...
        problem, machineData, agvData, currentSchedule, event, config, ...
        cancelledRecords);
    eventResults(end + 1) = eventResult;

    if eventResult.decision_isSelected
        cancelledJobSet(end + 1) = event.job_id;
        cancelledRecords(end + 1) = event;
    else
        break
    end
end

result.event_results = eventResults;
result.finalSchedule = currentSchedule;
result.cancelledJobSet = cancelledJobSet;
result.completed_event_count = numel(eventResults);
result.isFeasible = ~isempty(eventResults) && ...
    all([eventResults.decision_isSelected]);
result.report.isFeasible = result.isFeasible;
end

function [eventResult, nextSchedule] = run_one_event( ...
    problem, machineData, agvData, currentSchedule, event, config, ...
    cancelledRecords)
cancel = create_order_cancellation_event( ...
    event.job_id, event.cancel_time, event.policy);

state = extract_cancellation_state(problem, currentSchedule, cancel);
localCandidate = build_local_repair_candidate( ...
    problem, currentSchedule, state, cancel);

remainingSet = build_remaining_operation_set(state, cancel);
chrom = build_first_choice_chromosome(remainingSet, problem, agvData);
decodeConfig = build_decode_config(config);
completeCandidate = build_complete_rescheduling_candidate( ...
    problem, machineData, agvData, currentSchedule, state, cancel, ...
    chrom, decodeConfig);

cancelledRecordsForEvent = [cancelledRecords, event];
[localCandidate, localBackflowReport] = reject_backflow_candidate( ...
    localCandidate, cancelledRecordsForEvent, 'local_repair');
[completeCandidate, completeBackflowReport] = reject_backflow_candidate( ...
    completeCandidate, cancelledRecordsForEvent, 'complete_rescheduling');

wideConfig = build_wide_evaluation_config(config);
[localPreEvaluation, completePreEvaluation] = evaluate_candidates( ...
    currentSchedule, localCandidate, completeCandidate, cancel, ...
    machineData, agvData, wideConfig);
evaluationConfig = build_minmax_evaluation_config( ...
    localPreEvaluation, completePreEvaluation, wideConfig, config);

[localEvaluation, completeEvaluation] = evaluate_candidates( ...
    currentSchedule, localCandidate, completeCandidate, cancel, ...
    machineData, agvData, evaluationConfig);

decision = select_hybrid_cancellation_policy( ...
    localCandidate, completeCandidate, localEvaluation, ...
    completeEvaluation, evaluationConfig);

eventResult = build_event_result( ...
    event, state, localCandidate, completeCandidate, localEvaluation, ...
    completeEvaluation, decision, cancelledRecords, localBackflowReport, ...
    completeBackflowReport);

nextSchedule = currentSchedule;
if eventResult.cancelled_job_backflow_detected
    eventResult.decision_isSelected = false;
    eventResult.selected_strategy = '';
    eventResult.decision_reason = 'cancelled_job_backflow_detected';
elseif decision.isSelected
    nextSchedule = decision.selected_candidate;
    selectedBackflowReport = check_cancelled_job_backflow( ...
        nextSchedule, cancelledRecordsForEvent, 'selected_candidate');
    eventResult.selected_candidate_backflow_detected = ...
        selectedBackflowReport.hasBackflow;
    eventResult.cancelled_job_backflow_detected = ...
        eventResult.cancelled_job_backflow_detected || ...
        selectedBackflowReport.hasBackflow;
    eventResult.details.selectedBackflowReport = selectedBackflowReport;
    if selectedBackflowReport.hasBackflow
        nextSchedule = currentSchedule;
        eventResult.decision_isSelected = false;
        eventResult.selected_strategy = '';
        eventResult.decision_reason = 'cancelled_job_backflow_detected';
    end
end
end

function result = empty_result(initialSchedule, sortedEvents, validationReport)
result = struct();
result.isFeasible = false;
result.initialSchedule = initialSchedule;
result.finalSchedule = initialSchedule;
result.sortedEvents = sortedEvents;
result.event_results = event_result_template([]);
result.cancelledJobSet = [];
result.completed_event_count = 0;
result.report = struct();
result.report.eventValidation = validationReport;
result.report.errors = {};
result.report.warnings = {};
result.report.unsupported_events = {};
result.report.isFeasible = false;
end

function eventResult = event_result_template(initialValue)
eventResult = struct();
eventResult.event_id = initialValue;
eventResult.job_id = initialValue;
eventResult.cancel_time = initialValue;
eventResult.policy = '';
eventResult.state_has_unsupported_operations = false;
eventResult.state_has_unsupported_agv_tasks = false;
eventResult.local_candidate_isFeasible = false;
eventResult.complete_candidate_isFeasible = false;
eventResult.local_evaluation_isFeasible = false;
eventResult.complete_evaluation_isFeasible = false;
eventResult.decision_isSelected = false;
eventResult.selected_strategy = '';
eventResult.decision_reason = '';
eventResult.triggered_complete_rescheduling = false;
eventResult.local_candidate_backflow_detected = false;
eventResult.complete_candidate_backflow_detected = false;
eventResult.selected_candidate_backflow_detected = false;
eventResult.cancelled_job_backflow_detected = false;
eventResult.details = struct();
if isempty(initialValue)
    eventResult = eventResult([]);
end
end

function eventResult = rejected_event_result(event, reason)
eventResult = event_result_template(0);
eventResult.event_id = event.event_id;
eventResult.job_id = event.job_id;
eventResult.cancel_time = event.cancel_time;
eventResult.policy = event.policy;
eventResult.decision_reason = reason;
eventResult.details = struct();
end

function eventResult = build_event_result( ...
    event, state, localCandidate, completeCandidate, localEvaluation, ...
    completeEvaluation, decision, cancelledRecords, localBackflowReport, ...
    completeBackflowReport)
eventResult = event_result_template(0);
eventResult.event_id = event.event_id;
eventResult.job_id = event.job_id;
eventResult.cancel_time = event.cancel_time;
eventResult.policy = event.policy;
eventResult.state_has_unsupported_operations = ...
    state.has_unsupported_operations;
eventResult.state_has_unsupported_agv_tasks = state.has_unsupported_agv_tasks;
eventResult.local_candidate_isFeasible = localCandidate.isFeasible;
eventResult.complete_candidate_isFeasible = completeCandidate.isFeasible;
eventResult.local_evaluation_isFeasible = localEvaluation.metrics.isFeasible;
eventResult.complete_evaluation_isFeasible = ...
    completeEvaluation.metrics.isFeasible;
eventResult.decision_isSelected = decision.isSelected;
eventResult.selected_strategy = decision.selected_strategy;
eventResult.decision_reason = decision.reason;
eventResult.triggered_complete_rescheduling = ...
    decision.triggered_complete_rescheduling;
eventResult.local_candidate_backflow_detected = ...
    localBackflowReport.hasBackflow;
eventResult.complete_candidate_backflow_detected = ...
    completeBackflowReport.hasBackflow;
eventResult.selected_candidate_backflow_detected = false;
eventResult.cancelled_job_backflow_detected = ...
    localBackflowReport.hasBackflow || completeBackflowReport.hasBackflow;
eventResult.details = struct();
eventResult.details.state = state;
eventResult.details.localCandidate = localCandidate;
eventResult.details.completeCandidate = completeCandidate;
eventResult.details.localEvaluation = localEvaluation;
eventResult.details.completeEvaluation = completeEvaluation;
eventResult.details.decision = decision;
eventResult.details.cancelledEventsBeforeEvent = cancelledRecords;
eventResult.details.localBackflowReport = localBackflowReport;
eventResult.details.completeBackflowReport = completeBackflowReport;
end

function [candidate, backflowReport] = reject_backflow_candidate( ...
    candidate, cancelledRecords, candidateName)
backflowReport = check_cancelled_job_backflow( ...
    candidate, cancelledRecords, candidateName);
if ~backflowReport.hasBackflow
    return
end

candidate.isFeasible = false;
if ~isfield(candidate, 'report') || ~isstruct(candidate.report)
    candidate.report = struct();
end
if ~isfield(candidate.report, 'errors')
    candidate.report.errors = {};
end
if ~isfield(candidate.report, 'rejectedReasons')
    candidate.report.rejectedReasons = {};
end
candidate.report.errors{end + 1} = sprintf( ...
    '%s contains unfinished tasks from already cancelled jobs.', ...
    candidateName);
candidate.report.rejectedReasons{end + 1} = ...
    'cancelled_job_backflow_detected';
candidate.report.cancelledJobBackflowCheck = backflowReport;
end

function decodeConfig = build_decode_config(config)
decodeConfig = struct();
decodeConfig.AGVEG_MAX = read_numeric_config(config, 'AGVEG_MAX', 100);
decodeConfig.AGVEG_MIN = read_numeric_config(config, 'AGVEG_MIN', 1);
decodeConfig.eChargeSpeed = read_numeric_config(config, 'eChargeSpeed', 20);
decodeConfig.machineTable = {};
decodeConfig.AGVTable = {};
end

function value = read_numeric_config(config, fieldName, defaultValue)
if isstruct(config) && isfield(config, fieldName) && ...
        isnumeric(config.(fieldName)) && isscalar(config.(fieldName))
    value = config.(fieldName);
else
    value = defaultValue;
end
end

function config = build_wide_evaluation_config(sourceConfig)
if isstruct(sourceConfig) && isfield(sourceConfig, 'evaluation') && ...
        has_complete_evaluation_config(sourceConfig.evaluation)
    config = sourceConfig.evaluation;
else
    config = default_evaluation_config();
end

if isstruct(sourceConfig) && isfield(sourceConfig, 'hybrid_policy')
    config.hybrid_policy = sourceConfig.hybrid_policy;
end
end

function config = default_evaluation_config()
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

function hasConfig = has_complete_evaluation_config(config)
hasConfig = isstruct(config) && isfield(config, 'weights') && ...
    isfield(config, 'normalization');
end

function bounds = make_bounds(minValue, maxValue)
bounds = struct();
bounds.min = minValue;
bounds.max = maxValue;
end

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

function config = build_minmax_evaluation_config( ...
    localEvaluation, completeEvaluation, fallbackConfig, sourceConfig)
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

if isstruct(sourceConfig) && isfield(sourceConfig, 'hybrid_policy')
    config.hybrid_policy = sourceConfig.hybrid_policy;
end
end

function chrom = build_first_choice_chromosome(remainingSet, problem, agvData)
operations = remainingSet.operations;
if isempty(operations)
    chrom = [];
    return
end

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
if isfield(agvData, 'AGVSpeed') && numel(agvData.AGVSpeed) >= 2
    SS(2:2:end) = 2;
end

for i = 1:operaNum
    candidateMachines = problem.candidateMachine{ ...
        operations(i).job_id, operations(i).operation_id};
    if isempty(candidateMachines)
        error('run_sequential_order_cancellations:MissingCandidateMachine', ...
            'Remaining operation has no candidate machine.');
    end
end

chrom = [OS, MS, AS, SS];
end

function report = check_cancelled_job_backflow( ...
    schedule, cancelledRecords, scheduleName)
report = struct();
report.scheduleName = scheduleName;
report.hasBackflow = false;
report.machineBackflowTasks = backflow_task_template([]);
report.agvBackflowTasks = backflow_task_template([]);
report.errors = {};

if isempty(cancelledRecords)
    return
end

if ~isfield(schedule, 'machineTable')
    report.errors{end + 1} = sprintf( ...
        '%s.machineTable is required for backflow check.', scheduleName);
    return
end

for machineIdx = 1:numel(schedule.machineTable)
    rows = schedule.machineTable{machineIdx};
    for rowIdx = 1:numel(rows)
        row = rows(rowIdx);
        task = backflow_schedule_task( ...
            row, cancelledRecords, 'machine', machineIdx, rowIdx);
        if ~isempty(task)
            report.machineBackflowTasks(end + 1) = task;
        end
    end
end

if ~isfield(schedule, 'AGVTable')
    report.hasBackflow = ~isempty(report.machineBackflowTasks);
    return
end

for agvIdx = 1:numel(schedule.AGVTable)
    rows = schedule.AGVTable{agvIdx};
    for rowIdx = 1:numel(rows)
        row = rows(rowIdx);
        task = backflow_schedule_task( ...
            row, cancelledRecords, 'agv', agvIdx, rowIdx);
        if ~isempty(task)
            report.agvBackflowTasks(end + 1) = task;
        end
    end
end
report.hasBackflow = ~isempty(report.machineBackflowTasks) || ...
    ~isempty(report.agvBackflowTasks);
end

function task = backflow_schedule_task( ...
    row, cancelledRecords, resourceType, resourceId, blockIndex)
task = backflow_task_template([]);
if ~isfield(row, 'job') || ~isfield(row, 'end') || row.job <= 0
    return
end

for i = 1:numel(cancelledRecords)
    record = cancelledRecords(i);
    if row.job == record.job_id && row.end > record.cancel_time
        task = backflow_task_template(0);
        task.resource_type = resourceType;
        task.resource_id = resourceId;
        task.block_index = blockIndex;
        task.event_id = record.event_id;
        task.job_id = row.job;
        task.operation_id = read_block_field(row, 'opera', NaN);
        task.start_time = read_block_field(row, 'start', NaN);
        task.end_time = row.end;
        task.cancel_time = record.cancel_time;
        return
    end
end
end

function task = backflow_task_template(initialValue)
task = struct();
task.resource_type = '';
task.resource_id = initialValue;
task.block_index = initialValue;
task.event_id = initialValue;
task.job_id = initialValue;
task.operation_id = initialValue;
task.start_time = initialValue;
task.end_time = initialValue;
task.cancel_time = initialValue;
if isempty(initialValue)
    task = task([]);
end
end

function value = read_block_field(row, fieldName, defaultValue)
if isfield(row, fieldName)
    value = row.(fieldName);
else
    value = defaultValue;
end
end

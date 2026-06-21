function result = run_order_cancellation_scenario( ...
    problem, machineData, agvData, baselineSchedule, scenario, seed, config)
%RUN_ORDER_CANCELLATION_SCENARIO Run one stage-F cancellation scenario.
%   result = RUN_ORDER_CANCELLATION_SCENARIO(problem, machineData, agvData,
%   baselineSchedule, scenario, seed, config) runs the existing stage B-E
%   pipeline for one scenario. It does not read files, write outputs, run
%   NSGA-II population search, or create a new scheduling algorithm line.

if nargin < 6
    error('run_order_cancellation_scenario:MissingInput', ...
        ['problem, machineData, agvData, baselineSchedule, scenario, ', ...
        'and seed are required.']);
end
if nargin < 7 || isempty(config)
    config = struct();
end

require_problem(problem);
require_scenario(scenario);
if ~isempty(seed)
    rng(seed);
end

scenarioName = read_string_field(scenario, 'name', 'unnamed_scenario');
cancelJobId = resolve_cancel_job_id(problem, scenario, config);
cancelTime = resolve_cancel_time(baselineSchedule, scenario);
cancelPolicy = resolve_cancel_policy(scenario, config);
cancel = create_order_cancellation_event( ...
    cancelJobId, cancelTime, cancelPolicy);

state = extract_cancellation_state(problem, baselineSchedule, cancel);
localCandidate = build_local_repair_candidate( ...
    problem, baselineSchedule, state, cancel);

remainingSet = build_remaining_operation_set(state, cancel);
chrom = build_first_choice_chromosome(remainingSet, problem, agvData);
decodeConfig = build_decode_config(config);
completeCandidate = build_complete_rescheduling_candidate( ...
    problem, machineData, agvData, baselineSchedule, state, cancel, ...
    chrom, decodeConfig);

wideConfig = build_wide_evaluation_config(config);
[localPreEvaluation, completePreEvaluation] = evaluate_candidates( ...
    baselineSchedule, localCandidate, completeCandidate, cancel, ...
    machineData, agvData, wideConfig);
evaluationConfig = build_minmax_evaluation_config( ...
    localPreEvaluation, completePreEvaluation, wideConfig);

[localEvaluation, completeEvaluation] = evaluate_candidates( ...
    baselineSchedule, localCandidate, completeCandidate, cancel, ...
    machineData, agvData, evaluationConfig);
selection = select_order_cancellation_strategy( ...
    localEvaluation, completeEvaluation);

result = build_result_row( ...
    scenarioName, seed, cancel, state, localCandidate, ...
    completeCandidate, localEvaluation, completeEvaluation, selection, ...
    evaluationConfig);
end

function require_problem(problem)
requiredFields = {'jobNum', 'machineNum', 'candidateMachine'};
for i = 1:numel(requiredFields)
    if ~isstruct(problem) || ~isfield(problem, requiredFields{i})
        error('run_order_cancellation_scenario:InvalidProblem', ...
            'problem.%s is required.', requiredFields{i});
    end
end
end

function require_scenario(scenario)
if ~isstruct(scenario)
    error('run_order_cancellation_scenario:InvalidScenario', ...
        'scenario must be a struct.');
end
if ~isfield(scenario, 'cancel_time') && ...
        ~isfield(scenario, 'cancel_time_ratio')
    error('run_order_cancellation_scenario:InvalidScenario', ...
        'scenario.cancel_time or scenario.cancel_time_ratio is required.');
end
end

function cancelJobId = resolve_cancel_job_id(problem, scenario, config)
if isfield(scenario, 'cancel_job_id')
    cancelJobId = scenario.cancel_job_id;
elseif isfield(scenario, 'job_id')
    cancelJobId = scenario.job_id;
elseif isstruct(config) && isfield(config, 'cancel_job_id')
    cancelJobId = config.cancel_job_id;
else
    cancelJobId = min(2, problem.jobNum);
end
end

function cancelTime = resolve_cancel_time(baselineSchedule, scenario)
if isfield(scenario, 'cancel_time')
    cancelTime = scenario.cancel_time;
    return
end

[cmaxMetrics, cmaxReport] = evaluate_candidate_cmax( ...
    baselineSchedule, baselineSchedule);
if ~cmaxMetrics.isFeasible
    error('run_order_cancellation_scenario:InvalidBaselineCmax', ...
        strjoin(cmaxReport.errors, newline));
end
cancelTime = cmaxMetrics.Cmax * scenario.cancel_time_ratio;
end

function policy = resolve_cancel_policy(scenario, config)
if isfield(scenario, 'cancel_policy')
    policy = scenario.cancel_policy;
elseif isstruct(config) && isfield(config, 'cancel_policy')
    policy = config.cancel_policy;
else
    policy = 'cancel_unstarted_operations_only';
end
end

function value = read_string_field(record, fieldName, defaultValue)
if isfield(record, fieldName) && ~isempty(record.(fieldName))
    value = record.(fieldName);
else
    value = defaultValue;
end
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
    return
end

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
        error('run_order_cancellation_scenario:MissingCandidateMachine', ...
            'Remaining operation has no candidate machine.');
    end
end

chrom = [OS, MS, AS, SS];
end

function result = build_result_row( ...
    scenarioName, seed, cancel, state, localCandidate, ...
    completeCandidate, localEvaluation, completeEvaluation, selection, ...
    evaluationConfig)
result = struct();
result.scenario_name = scenarioName;
result.seed = seed;
result.cancel_job_id = cancel.job_id;
result.cancel_time = cancel.cancel_time;
result.cancel_policy = cancel.policy;
result.completed_operations = numel(state.completed_operations);
result.cancelled_unfinished_operations = ...
    numel(state.cancelled_unfinished_operations);
result.remaining_unfinished_operations = ...
    numel(state.remaining_unfinished_operations);
result.local_candidate_isFeasible = localCandidate.isFeasible;
result.complete_candidate_isFeasible = completeCandidate.isFeasible;
result.local_machine_check_isFeasible = get_nested_feasibility( ...
    localCandidate, {'report', 'machineConflictCheck'});
result.local_agv_check_isFeasible = get_nested_feasibility( ...
    localCandidate, {'report', 'agvConflictCheck'});
result.local_job_sequence_check_isFeasible = get_nested_feasibility( ...
    localCandidate, {'report', 'jobSequenceCheck'});
result.complete_machine_check_isFeasible = get_nested_feasibility( ...
    completeCandidate, {'report', 'completeFeasibilityCheck', ...
    'machineConflictCheck'});
result.complete_agv_check_isFeasible = get_nested_feasibility( ...
    completeCandidate, {'report', 'completeFeasibilityCheck', ...
    'agvConflictCheck'});
result.complete_job_sequence_check_isFeasible = get_nested_feasibility( ...
    completeCandidate, {'report', 'completeFeasibilityCheck', ...
    'jobSequenceCheck'});
result.complete_frozen_check_isFeasible = get_nested_feasibility( ...
    completeCandidate, {'report', 'completeFeasibilityCheck', ...
    'frozenConsistencyCheck'});
result.complete_cancelled_exclusion_check_isFeasible = ...
    get_nested_feasibility(completeCandidate, ...
    {'report', 'completeFeasibilityCheck', ...
    'cancelledTaskExclusionCheck'});
result.local_rejectedReasons = get_report_messages( ...
    localCandidate, 'rejectedReasons');
result.complete_rejectedReasons = get_report_messages( ...
    completeCandidate, 'rejectedReasons');
result.local_error_count = numel(get_report_messages( ...
    localCandidate, 'errors'));
result.complete_error_count = numel(get_report_messages( ...
    completeCandidate, 'errors'));
result.local_isFeasible = localEvaluation.metrics.isFeasible;
result.complete_isFeasible = completeEvaluation.metrics.isFeasible;
result.local_Cmax_delta = value_or_nan( ...
    localEvaluation.metrics, 'Cmax_delta');
result.complete_Cmax_delta = value_or_nan( ...
    completeEvaluation.metrics, 'Cmax_delta');
result.local_SD = value_or_nan(localEvaluation.metrics, 'SD');
result.complete_SD = value_or_nan(completeEvaluation.metrics, 'SD');
result.local_TD = value_or_nan(localEvaluation.metrics, 'TD');
result.complete_TD = value_or_nan(completeEvaluation.metrics, 'TD');
result.local_energy_delta = value_or_nan( ...
    localEvaluation.metrics, 'energy_delta');
result.complete_energy_delta = value_or_nan( ...
    completeEvaluation.metrics, 'energy_delta');
result.local_Y = value_or_nan(localEvaluation.metrics, 'Y');
result.complete_Y = value_or_nan(completeEvaluation.metrics, 'Y');
result.selected_strategy = selection.name;
result.selected_reason = selection.reason;
result.selected_Y = value_or_nan(selection, 'selectedY');

result.details = struct();
result.details.cancel = cancel;
result.details.state = state;
result.details.localCandidate = localCandidate;
result.details.completeCandidate = completeCandidate;
result.details.localEvaluation = localEvaluation;
result.details.completeEvaluation = completeEvaluation;
result.details.selection = selection;
result.details.evaluationConfig = evaluationConfig;
end

function value = value_or_nan(s, fieldName)
if isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = NaN;
end
end

function value = get_nested_feasibility(record, fieldPath)
value = false;
current = record;
for i = 1:numel(fieldPath)
    fieldName = fieldPath{i};
    if ~isstruct(current) || ~isfield(current, fieldName)
        return
    end
    current = current.(fieldName);
end

if isstruct(current) && isfield(current, 'isFeasible') && ...
        ~isempty(current.isFeasible)
    value = logical(current.isFeasible);
end
end

function messages = get_report_messages(candidate, fieldName)
messages = {};
if ~isstruct(candidate) || ~isfield(candidate, 'report') || ...
        ~isstruct(candidate.report) || ~isfield(candidate.report, fieldName)
    return
end
messages = candidate.report.(fieldName);
end
